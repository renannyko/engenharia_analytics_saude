/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 03_dq_business_dimensoes.sql
CAMADA: qualidade_dados
OBJETO: dq_business_dimensoes
ESCOPO: business - dimensoes
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para as dimensoes da camada Business,
validando unicidade das Surrogate Keys, completude, consistencia das chaves naturais
e existencia controlada dos Default Members.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Unicidade.
2. Completude.
3. Consistencia.
4. Validade.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. Toda dimensao deve possuir Surrogate Key preenchida.
2. Toda Surrogate Key deve ser unica dentro da respectiva dimensao.
3. Dimensoes simples devem possuir chave natural unica.
4. A dim_paciente e historica e sera validada separadamente no controle de SCD Tipo 2.
5. Cada dimensao deve possuir exatamente um Default Member.
6. O Default Member utiliza a chave natural reservada '-1'.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - DIMENSOES BUSINESS
-- ========================================================================================

CREATE OR REPLACE VIEW dq_business_dimensoes AS

WITH controles AS (

    SELECT
        'DQ_DIM_001' AS id_teste,
        'unicidade_id_sk_procedimento' AS ds_teste,
        'UNICIDADE' AS ds_dimensao_dq,
        COUNT(*) AS qt_erros
    FROM (
        SELECT id_sk_procedimento
        FROM engenharia_analytics_saude_dev.business.dim_procedimento
        GROUP BY id_sk_procedimento
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_002',
        'completude_id_sk_procedimento',
        'COMPLETUDE',
        COUNT_IF(id_sk_procedimento IS NULL)
    FROM engenharia_analytics_saude_dev.business.dim_procedimento


    UNION ALL


    SELECT
        'DQ_DIM_003',
        'unicidade_cd_procedimento',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT cd_procedimento
        FROM engenharia_analytics_saude_dev.business.dim_procedimento
        GROUP BY cd_procedimento
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_004',
        'default_member_dim_procedimento',
        'CONSISTENCIA',
        ABS(COUNT_IF(cd_procedimento = '-1') - 1)
    FROM engenharia_analytics_saude_dev.business.dim_procedimento


    UNION ALL


    SELECT
        'DQ_DIM_005',
        'unicidade_id_sk_unidade',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_sk_unidade
        FROM engenharia_analytics_saude_dev.business.dim_unidade
        GROUP BY id_sk_unidade
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_006',
        'completude_id_sk_unidade',
        'COMPLETUDE',
        COUNT_IF(id_sk_unidade IS NULL)
    FROM engenharia_analytics_saude_dev.business.dim_unidade


    UNION ALL


    SELECT
        'DQ_DIM_007',
        'unicidade_id_unidade',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_unidade
        FROM engenharia_analytics_saude_dev.business.dim_unidade
        GROUP BY id_unidade
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_008',
        'default_member_dim_unidade',
        'CONSISTENCIA',
        ABS(COUNT_IF(id_unidade = '-1') - 1)
    FROM engenharia_analytics_saude_dev.business.dim_unidade


    UNION ALL


    SELECT
        'DQ_DIM_009',
        'unicidade_id_sk_medico',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_sk_medico
        FROM engenharia_analytics_saude_dev.business.dim_medico
        GROUP BY id_sk_medico
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_010',
        'completude_id_sk_medico',
        'COMPLETUDE',
        COUNT_IF(id_sk_medico IS NULL)
    FROM engenharia_analytics_saude_dev.business.dim_medico


    UNION ALL


    SELECT
        'DQ_DIM_011',
        'unicidade_id_medico',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_medico
        FROM engenharia_analytics_saude_dev.business.dim_medico
        GROUP BY id_medico
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_012',
        'default_member_dim_medico',
        'CONSISTENCIA',
        ABS(COUNT_IF(id_medico = '-1') - 1)
    FROM engenharia_analytics_saude_dev.business.dim_medico


    UNION ALL


    SELECT
        'DQ_DIM_013',
        'unicidade_id_sk_data',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_sk_data
        FROM engenharia_analytics_saude_dev.business.dim_data
        GROUP BY id_sk_data
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_014',
        'completude_id_sk_data',
        'COMPLETUDE',
        COUNT_IF(id_sk_data IS NULL)
    FROM engenharia_analytics_saude_dev.business.dim_data


    UNION ALL


    SELECT
        'DQ_DIM_015',
        'unicidade_dt_data',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT dt_data
        FROM engenharia_analytics_saude_dev.business.dim_data
        WHERE dt_data IS NOT NULL
        GROUP BY dt_data
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_016',
        'default_member_dim_data',
        'CONSISTENCIA',
        ABS(
            COUNT_IF(id_sk_data = MD5('-1')) - 1
        )
    FROM engenharia_analytics_saude_dev.business.dim_data


    UNION ALL


    SELECT
        'DQ_DIM_017',
        'unicidade_id_sk_paciente',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT id_sk_paciente
        FROM engenharia_analytics_saude_dev.business.dim_paciente
        GROUP BY id_sk_paciente
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_DIM_018',
        'completude_id_sk_paciente',
        'COMPLETUDE',
        COUNT_IF(id_sk_paciente IS NULL)
    FROM engenharia_analytics_saude_dev.business.dim_paciente


    UNION ALL


    SELECT
        'DQ_DIM_019',
        'default_member_dim_paciente',
        'CONSISTENCIA',
        ABS(COUNT_IF(id_paciente = '-1') - 1)
    FROM engenharia_analytics_saude_dev.business.dim_paciente

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