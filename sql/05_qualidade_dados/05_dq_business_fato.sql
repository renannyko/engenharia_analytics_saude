/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 05_dq_business_fato.sql
CAMADA: qualidade_dados
OBJETO: dq_business_fato
ESCOPO: business - fct_procedimentos
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para a fato de procedimentos,
validando granularidade, unicidade, completude das chaves dimensionais,
integridade referencial e utilizacao controlada dos Default Members.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Unicidade.
2. Completude.
3. Consistencia.
4. Validade.
5. Integridade referencial.
6. Acuracia.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. O grao da fato e definido por id_item.
2. Cada id_item deve aparecer uma unica vez.
3. A Surrogate Key da fato deve ser unica e preenchida.
4. Todas as chaves dimensionais devem estar preenchidas.
5. Toda chave dimensional deve possuir correspondencia na respectiva dimensao.
6. O Default Member e permitido quando previsto pela arquitetura.
7. O uso do Default Member de paciente e esperado para Late Arriving Dimensions.
8. Os controles nao alteram os dados avaliados.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - FATO
-- ========================================================================================

CREATE OR REPLACE VIEW dq_business_fato AS

WITH controles AS (

    SELECT
        'DQ_FCT_001' AS id_teste,
        'unicidade_id_item_fct_procedimentos' AS ds_teste,
        'UNICIDADE' AS ds_dimensao_dq,
        COUNT(*) AS qt_erros
    FROM (
        SELECT id_item
        FROM engenharia_analytics_saude_dev.business.fct_procedimentos
        GROUP BY id_item
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_FCT_002',
        'unicidade_id_sk_fato_procedimento',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_sk_fato_procedimento
        FROM engenharia_analytics_saude_dev.business.fct_procedimentos
        GROUP BY id_sk_fato_procedimento
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_FCT_003',
        'completude_id_sk_fato_procedimento',
        'COMPLETUDE',
        COUNT_IF(id_sk_fato_procedimento IS NULL)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_004',
        'completude_chaves_dimensionais',
        'COMPLETUDE',
        COUNT_IF(
               id_sk_paciente IS NULL
            OR id_sk_procedimento IS NULL
            OR id_sk_unidade IS NULL
            OR id_sk_medico IS NULL
            OR id_sk_data IS NULL
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_005',
        'integridade_referencial_dim_paciente',
        'CONSISTENCIA',
        COUNT(*)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f
    LEFT JOIN engenharia_analytics_saude_dev.business.dim_paciente AS d
        ON f.id_sk_paciente = d.id_sk_paciente
    WHERE d.id_sk_paciente IS NULL


    UNION ALL


    SELECT
        'DQ_FCT_006',
        'integridade_referencial_dim_procedimento',
        'CONSISTENCIA',
        COUNT(*)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f
    LEFT JOIN engenharia_analytics_saude_dev.business.dim_procedimento AS d
        ON f.id_sk_procedimento = d.id_sk_procedimento
    WHERE d.id_sk_procedimento IS NULL


    UNION ALL


    SELECT
        'DQ_FCT_007',
        'integridade_referencial_dim_unidade',
        'CONSISTENCIA',
        COUNT(*)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f
    LEFT JOIN engenharia_analytics_saude_dev.business.dim_unidade AS d
        ON f.id_sk_unidade = d.id_sk_unidade
    WHERE d.id_sk_unidade IS NULL


    UNION ALL


    SELECT
        'DQ_FCT_008',
        'integridade_referencial_dim_medico',
        'CONSISTENCIA',
        COUNT(*)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f
    LEFT JOIN engenharia_analytics_saude_dev.business.dim_medico AS d
        ON f.id_sk_medico = d.id_sk_medico
    WHERE d.id_sk_medico IS NULL


    UNION ALL


    SELECT
        'DQ_FCT_009',
        'integridade_referencial_dim_data',
        'CONSISTENCIA',
        COUNT(*)
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f
    LEFT JOIN engenharia_analytics_saude_dev.business.dim_data AS d
        ON f.id_sk_data = d.id_sk_data
    WHERE d.id_sk_data IS NULL


    UNION ALL


    SELECT
        'DQ_FCT_010',
        'completude_campos_criticos_fct_procedimentos',
        'COMPLETUDE',
        COUNT_IF(
               id_item IS NULL
            OR id_atendimento IS NULL
            OR dt_atendimento IS NULL
            OR vl_item_bruto IS NULL
            OR vl_desconto_item IS NULL
            OR vl_item_liquido IS NULL
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_011',
        'coerencia_valor_liquido_item',
        'ACURACIA',
        COUNT_IF(
            ROUND(
                vl_item_bruto - vl_desconto_item,
                2
            ) <> vl_item_liquido
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_012',
        'late_arriving_dimension_paciente',
        'CONSISTENCIA',
        ABS(
            COUNT(DISTINCT id_atendimento) - 10
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos
    WHERE id_sk_paciente = MD5('-1')


    UNION ALL


    SELECT
        'DQ_FCT_013',
        'default_member_inesperado_procedimento',
        'CONSISTENCIA',
        COUNT_IF(
            id_sk_procedimento = MD5('-1')
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_014',
        'default_member_inesperado_unidade',
        'CONSISTENCIA',
        COUNT_IF(
            id_sk_unidade = MD5('-1')
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_015',
        'default_member_inesperado_medico',
        'CONSISTENCIA',
        COUNT_IF(
            id_sk_medico = MD5('-1')
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos


    UNION ALL


    SELECT
        'DQ_FCT_016',
        'default_member_inesperado_data',
        'CONSISTENCIA',
        COUNT_IF(
            id_sk_data = MD5('-1')
        )
    FROM engenharia_analytics_saude_dev.business.fct_procedimentos

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