/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 06_dq_reconciliacao_financeira.sql
CAMADA: qualidade_dados
OBJETO: dq_reconciliacao_financeira
ESCOPO: business - reconciliacao financeira
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de acuracia financeira, reconciliando os valores
registrados no nivel do atendimento com os valores distribuidos entre os itens
da fct_procedimentos.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Acuracia.
2. Consistencia.
3. Completude.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. O valor bruto da fato deve reconciliar com o valor bruto do atendimento.
2. O desconto rateado entre os itens deve reconciliar com o desconto do atendimento.
3. O valor liquido dos itens deve reconciliar com o valor liquido do atendimento.
4. A reconciliacao considera tolerancia de 0,01 para diferencas monetarias.
5. Todos os atendimentos da Staging devem possuir itens na fato.
6. Nenhuma regra financeira e recalculada neste controle.
7. Os controles nao alteram os dados avaliados.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - RECONCILIACAO FINANCEIRA
-- ========================================================================================

CREATE OR REPLACE VIEW dq_reconciliacao_financeira AS

WITH valores_fato AS (

    SELECT
        id_atendimento,
        SUM(vl_item_bruto) AS vl_bruto_fato,
        SUM(vl_desconto_item) AS vl_desconto_fato,
        SUM(vl_item_liquido) AS vl_liquido_fato
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos
    GROUP BY
        id_atendimento

),

reconciliacao AS (

    SELECT
        a.id_atendimento,

        a.vl_bruto AS vl_bruto_origem,
        f.vl_bruto_fato,

        a.vl_desconto AS vl_desconto_origem,
        f.vl_desconto_fato,

        a.vl_liquido AS vl_liquido_origem,
        f.vl_liquido_fato,

        ROUND(
            COALESCE(f.vl_bruto_fato, 0) - a.vl_bruto,
            2
        ) AS vl_diferenca_bruto,

        ROUND(
            COALESCE(f.vl_desconto_fato, 0) - a.vl_desconto,
            2
        ) AS vl_diferenca_desconto,

        ROUND(
            COALESCE(f.vl_liquido_fato, 0) - a.vl_liquido,
            2
        ) AS vl_diferenca_liquido

    FROM engenharia_analytics_saude_dev.staging.stg_atendimentos AS a

    LEFT JOIN valores_fato AS f
        ON a.id_atendimento = f.id_atendimento

),

controles AS (

    SELECT
        'DQ_FIN_001' AS id_teste,
        'reconciliacao_valor_bruto_por_atendimento' AS ds_teste,
        'ACURACIA' AS ds_dimensao_dq,
        COUNT_IF(
            ABS(vl_diferenca_bruto) > 0.01
        ) AS qt_erros
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_002',
        'reconciliacao_desconto_por_atendimento',
        'ACURACIA',
        COUNT_IF(
            ABS(vl_diferenca_desconto) > 0.01
        )
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_003',
        'reconciliacao_valor_liquido_por_atendimento',
        'ACURACIA',
        COUNT_IF(
            ABS(vl_diferenca_liquido) > 0.01
        )
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_004',
        'atendimentos_sem_itens_na_fato',
        'COMPLETUDE',
        COUNT_IF(
            vl_bruto_fato IS NULL
        )
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_005',
        'reconciliacao_global_valor_bruto',
        'ACURACIA',
        IFF(
            ABS(
                SUM(vl_bruto_fato)
                -
                SUM(vl_bruto_origem)
            ) > 0.01,
            1,
            0
        )
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_006',
        'reconciliacao_global_desconto',
        'ACURACIA',
        IFF(
            ABS(
                SUM(vl_desconto_fato)
                -
                SUM(vl_desconto_origem)
            ) > 0.01,
            1,
            0
        )
    FROM reconciliacao


    UNION ALL


    SELECT
        'DQ_FIN_007',
        'reconciliacao_global_valor_liquido',
        'ACURACIA',
        IFF(
            ABS(
                SUM(vl_liquido_fato)
                -
                SUM(vl_liquido_origem)
            ) > 0.01,
            1,
            0
        )
    FROM reconciliacao

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