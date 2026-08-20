/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 04_dq_business_scd2.sql
CAMADA: qualidade_dados
OBJETO: dq_business_scd2
ESCOPO: business - dim_paciente - SCD Tipo 2
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para validar a consistencia temporal da
dim_paciente, garantindo a correta aplicacao da estrategia Slowly Changing Dimension
Tipo 2 (SCD2).

DIMENSOES DE QUALIDADE AVALIADAS:

1. Consistencia.
2. Unicidade.
3. Validade.
4. Completude.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. Cada paciente pode possuir varias versoes historicas.
2. Deve existir exatamente uma versao atual por paciente.
3. Toda vigencia deve possuir inicio anterior ao fim.
4. Periodos historicos nao podem se sobrepor.
5. O fim de uma versao historica deve coincidir com o inicio da proxima versao.
6. A versao atual deve possuir lg_atual = TRUE.
7. Versoes encerradas devem possuir lg_atual = FALSE.
8. O Default Member nao participa dos controles historicos do paciente.
9. Os controles nao alteram os dados avaliados.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - SCD TIPO 2
-- ========================================================================================

CREATE OR REPLACE VIEW dq_business_scd2 AS

WITH pacientes_validos AS (

    SELECT
        id_sk_paciente,
        id_paciente,
        ds_nome,
        ds_plano_saude,
        ds_cidade,
        dt_inicio_vigencia,
        dt_fim_vigencia,
        lg_atual
    FROM engenharia_analytics_saude_dev.business.dim_paciente
    WHERE id_paciente <> '-1'

),

historico_ordenado AS (

    SELECT
        id_sk_paciente,
        id_paciente,
        dt_inicio_vigencia,
        dt_fim_vigencia,
        lg_atual,

        LEAD(dt_inicio_vigencia) OVER (
            PARTITION BY id_paciente
            ORDER BY dt_inicio_vigencia
        ) AS dt_proximo_inicio

    FROM pacientes_validos

),

controles AS (

    SELECT
        'DQ_SCD_001' AS id_teste,
        'unicidade_versao_atual_por_paciente' AS ds_teste,
        'UNICIDADE' AS ds_dimensao_dq,
        COUNT(*) AS qt_erros
    FROM (
        SELECT
            id_paciente
        FROM pacientes_validos
        WHERE lg_atual = TRUE
        GROUP BY id_paciente
        HAVING COUNT(*) > 1
    )


    UNION ALL


    SELECT
        'DQ_SCD_002',
        'existencia_versao_atual_por_paciente',
        'COMPLETUDE',
        COUNT(*)
    FROM (
        SELECT
            id_paciente
        FROM pacientes_validos
        GROUP BY id_paciente
        HAVING COUNT_IF(lg_atual = TRUE) <> 1
    )


    UNION ALL


    SELECT
        'DQ_SCD_003',
        'validade_intervalo_vigencia',
        'VALIDADE',
        COUNT_IF(
            dt_fim_vigencia <= dt_inicio_vigencia
        )
    FROM pacientes_validos


    UNION ALL


    SELECT
        'DQ_SCD_004',
        'continuidade_vigencias_scd2',
        'CONSISTENCIA',
        COUNT_IF(
               dt_proximo_inicio IS NOT NULL
           AND dt_fim_vigencia <> dt_proximo_inicio
        )
    FROM historico_ordenado


    UNION ALL


    SELECT
        'DQ_SCD_005',
        'ausencia_sobreposicao_vigencias',
        'CONSISTENCIA',
        COUNT_IF(
               dt_proximo_inicio IS NOT NULL
           AND dt_fim_vigencia > dt_proximo_inicio
        )
    FROM historico_ordenado


    UNION ALL


    SELECT
        'DQ_SCD_006',
        'lg_atual_versoes_historicas',
        'CONSISTENCIA',
        COUNT_IF(
               dt_proximo_inicio IS NOT NULL
           AND lg_atual = TRUE
        )
    FROM historico_ordenado


    UNION ALL


    SELECT
        'DQ_SCD_007',
        'lg_atual_ultima_versao',
        'CONSISTENCIA',
        COUNT_IF(
               dt_proximo_inicio IS NULL
           AND lg_atual = FALSE
        )
    FROM historico_ordenado


    UNION ALL


    SELECT
        'DQ_SCD_008',
        'dt_fim_versao_atual',
        'CONSISTENCIA',
        COUNT_IF(
               lg_atual = TRUE
           AND dt_fim_vigencia <> '9999-12-31 00:00:00'::TIMESTAMP_NTZ
        )
    FROM pacientes_validos


    UNION ALL


    SELECT
        'DQ_SCD_009',
        'dt_fim_versoes_historicas',
        'CONSISTENCIA',
        COUNT_IF(
               lg_atual = FALSE
           AND dt_fim_vigencia = '9999-12-31 00:00:00'::TIMESTAMP_NTZ
        )
    FROM pacientes_validos


    UNION ALL


    SELECT
        'DQ_SCD_010',
        'unicidade_paciente_inicio_vigencia',
        'UNICIDADE',
        COUNT(*)
    FROM (
        SELECT
            id_paciente,
            dt_inicio_vigencia
        FROM pacientes_validos
        GROUP BY
            id_paciente,
            dt_inicio_vigencia
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