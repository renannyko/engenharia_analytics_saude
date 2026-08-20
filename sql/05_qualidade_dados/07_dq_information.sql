/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 07_dq_information.sql
CAMADA: qualidade_dados
OBJETO: dq_information
ESCOPO: information
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para os produtos analiticos da camada
Information, validando preservacao de granularidade, consistencia com a camada
Business e reconciliacao das metricas agregadas.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Consistencia.
2. Unicidade.
3. Completude.
4. Acuracia.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. A vw_analise_procedimentos deve preservar o grao de 1 linha por id_item.
2. A volumetria da View detalhada deve reconciliar com a fct_procedimentos.
3. Os Late Arriving Dimensions de paciente devem permanecer identificaveis.
4. A agg_faturamento_mensal_unidade deve preservar os totais financeiros.
5. A soma dos atendimentos agregados deve reconciliar com o total de atendimentos.
6. Os controles nao alteram os dados avaliados.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA qualidade_dados;


-- ========================================================================================
-- 2. VIEW DE CONTROLES DE QUALIDADE - INFORMATION
-- ========================================================================================

CREATE OR REPLACE VIEW dq_information AS

WITH controles AS (

    SELECT
        'DQ_INF_001' AS id_teste,
        'volumetria_fato_vs_vw_analise_procedimentos' AS ds_teste,
        'CONSISTENCIA' AS ds_dimensao_dq,

        ABS(
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.business.fct_procedimentos
            )
            -
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
            )
        ) AS qt_erros


    UNION ALL


    SELECT
        'DQ_INF_002',
        'unicidade_id_item_vw_analise_procedimentos',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT
            id_item
        FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
        GROUP BY
            id_item
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_INF_003',
        'completude_campos_criticos_vw_analise_procedimentos',
        'COMPLETUDE',

        COUNT_IF(
               id_item IS NULL
            OR id_atendimento IS NULL
            OR dt_atendimento IS NULL
            OR cd_procedimento IS NULL
            OR id_unidade IS NULL
            OR id_medico IS NULL
            OR vl_item_bruto IS NULL
            OR vl_desconto_item IS NULL
            OR vl_item_liquido IS NULL
        )

    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos


    UNION ALL


    SELECT
        'DQ_INF_004',
        'late_arriving_paciente_information',
        'CONSISTENCIA',

        ABS(
            COUNT(DISTINCT id_atendimento) - 10
        )

    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos

    WHERE lg_paciente_nao_identificado = TRUE


    UNION ALL


    SELECT
        'DQ_INF_005',
        'reconciliacao_vl_bruto_information_vs_business',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_item_bruto)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
                -
                (
                    SELECT SUM(vl_item_bruto)
                    FROM engenharia_analytics_saude_dev.business.fct_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_006',
        'reconciliacao_vl_desconto_information_vs_business',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_desconto_item)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
                -
                (
                    SELECT SUM(vl_desconto_item)
                    FROM engenharia_analytics_saude_dev.business.fct_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_007',
        'reconciliacao_vl_liquido_information_vs_business',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_item_liquido)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
                -
                (
                    SELECT SUM(vl_item_liquido)
                    FROM engenharia_analytics_saude_dev.business.fct_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_008',
        'reconciliacao_vl_bruto_agg_mensal',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_bruto)
                    FROM engenharia_analytics_saude_dev.information.agg_faturamento_mensal_unidade
                )
                -
                (
                    SELECT SUM(vl_item_bruto)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_009',
        'reconciliacao_vl_desconto_agg_mensal',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_desconto)
                    FROM engenharia_analytics_saude_dev.information.agg_faturamento_mensal_unidade
                )
                -
                (
                    SELECT SUM(vl_desconto_item)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_010',
        'reconciliacao_vl_liquido_agg_mensal',
        'ACURACIA',

        IFF(
            ABS(
                (
                    SELECT SUM(vl_liquido)
                    FROM engenharia_analytics_saude_dev.information.agg_faturamento_mensal_unidade
                )
                -
                (
                    SELECT SUM(vl_item_liquido)
                    FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
                )
            ) > 0.01,
            1,
            0
        )


    UNION ALL


    SELECT
        'DQ_INF_011',
        'reconciliacao_qt_atendimentos_agg_mensal',
        'CONSISTENCIA',

        ABS(
            (
                SELECT SUM(qt_atendimentos)
                FROM engenharia_analytics_saude_dev.information.agg_faturamento_mensal_unidade
            )
            -
            (
                SELECT COUNT(DISTINCT id_atendimento)
                FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos
            )
        )

)

SELECT
    id_teste,
    ds_teste,
    ds_dimensao_dq,
    qt_erros,

    IFF(
        qt_erros = 0,
        'APROVADO',
        'REPROVADO'
    ) AS ds_status

FROM controles
;