/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 02_dq_staging.sql
CAMADA: qualidade_dados
OBJETO: dq_staging
ESCOPO: staging
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para a camada Staging, validando
preservacao de volumetria, completude de campos criticos, sucesso das conversoes
de tipos e consistencia entre Raw e Staging.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Completude.
2. Consistencia.
3. Validade.
4. Unicidade.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. A Staging deve preservar a granularidade da camada Raw.
2. Conversoes invalidas realizadas com TRY_TO_* resultam em NULL e devem ser detectadas.
3. Campos criticos nao devem apresentar valores nulos inesperados.
4. Nenhuma regra de negocio e validada nesta etapa.
5. Os controles nao alteram os dados avaliados.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - STAGING
-- ========================================================================================

CREATE OR REPLACE VIEW dq_staging AS

WITH controles AS (

    SELECT
        'DQ_STG_001' AS id_teste,
        'volumetria_raw_vs_staging_atendimentos' AS ds_teste,
        'CONSISTENCIA' AS ds_dimensao_dq,

        ABS(
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.raw.raw_atendimentos
            )
            -
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.staging.stg_atendimentos
            )
        ) AS qt_erros


    UNION ALL


    SELECT
        'DQ_STG_002',
        'volumetria_raw_vs_staging_procedimentos_itens',
        'CONSISTENCIA',

        ABS(
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.raw.raw_procedimentos_itens
            )
            -
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens
            )
        )


    UNION ALL


    SELECT
        'DQ_STG_003',
        'volumetria_raw_vs_staging_cadastro_pacientes',
        'CONSISTENCIA',

        ABS(
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.raw.raw_cadastro_pacientes
            )
            -
            (
                SELECT COUNT(*)
                FROM engenharia_analytics_saude_dev.staging.stg_cadastro_pacientes
            )
        )


    UNION ALL


    SELECT
        'DQ_STG_004',
        'completude_campos_criticos_stg_atendimentos',
        'COMPLETUDE',

        COUNT_IF(
               id_atendimento IS NULL
            OR id_paciente IS NULL
            OR dt_atendimento IS NULL
            OR id_unidade IS NULL
        )

    FROM engenharia_analytics_saude_dev.staging.stg_atendimentos


    UNION ALL


    SELECT
        'DQ_STG_005',
        'validade_valores_monetarios_stg_atendimentos',
        'VALIDADE',

        COUNT_IF(
               vl_bruto IS NULL
            OR vl_desconto IS NULL
            OR vl_liquido IS NULL
        )

    FROM engenharia_analytics_saude_dev.staging.stg_atendimentos


    UNION ALL


    SELECT
        'DQ_STG_006',
        'unicidade_id_atendimento_stg_atendimentos',
        'UNICIDADE',

        COUNT(*)

    FROM (

        SELECT
            id_atendimento
        FROM engenharia_analytics_saude_dev.staging.stg_atendimentos
        GROUP BY
            id_atendimento
        HAVING COUNT(*) > 1

    )


    UNION ALL


    SELECT
        'DQ_STG_007',
        'completude_campos_criticos_stg_procedimentos_itens',
        'COMPLETUDE',

        COUNT_IF(
               id_item IS NULL
            OR id_atendimento IS NULL
            OR cd_procedimento IS NULL
            OR id_medico_executante IS NULL
        )

    FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens


    UNION ALL


    SELECT
        'DQ_STG_008',
        'validade_vl_item_stg_procedimentos_itens',
        'VALIDADE',

        COUNT_IF(
            vl_item IS NULL
        )

    FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens


    UNION ALL


    SELECT
        'DQ_STG_009',
        'unicidade_id_item_stg_procedimentos_itens',
        'UNICIDADE',

        COUNT(*)

    FROM (

        SELECT
            id_item
        FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens
        GROUP BY
            id_item
        HAVING COUNT(*) > 1

    )


    UNION ALL


    SELECT
        'DQ_STG_010',
        'completude_campos_criticos_stg_cadastro_pacientes',
        'COMPLETUDE',

        COUNT_IF(
               id_paciente IS NULL
            OR ds_nome IS NULL
            OR ds_plano_saude IS NULL
            OR ds_cidade IS NULL
            OR dt_atualizacao IS NULL
        )

    FROM engenharia_analytics_saude_dev.staging.stg_cadastro_pacientes


    UNION ALL


    SELECT
        'DQ_STG_011',
        'unicidade_versao_stg_cadastro_pacientes',
        'UNICIDADE',

        COUNT(*)

    FROM (

        SELECT
            id_paciente,
            dt_atualizacao
        FROM engenharia_analytics_saude_dev.staging.stg_cadastro_pacientes
        GROUP BY
            id_paciente,
            dt_atualizacao
        HAVING COUNT(*) > 1

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