/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 05_dim_paciente.sql
CAMADA: business
OBJETO: dim_paciente
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
ESTRATEGIA: SCD Tipo 2
==========================================================================================

OBJETIVO:

Criar a dimensao historica de pacientes utilizando Slowly Changing Dimension
Tipo 2 (SCD2), preservando as alteracoes cadastrais disponibilizadas pela origem.

A dimensao devera permitir que cada procedimento seja relacionado a versao do
paciente vigente no momento em que o atendimento ocorreu.

GRANULARIDADE:

1 linha = 1 versao historica de 1 paciente.

REGRAS DE IMPLEMENTACAO:

1. A dimensao utiliza SCD Tipo 2.
2. A chave natural id_paciente e preservada.
3. Cada versao historica recebe uma Surrogate Key MD5 deterministica.
4. A data de atualizacao da origem define o inicio da vigencia da versao.
5. LEAD identifica o inicio da proxima versao do mesmo paciente.
6. O fim da vigencia e exclusivo.
7. A versao atual recebe data fim futura e lg_atual = TRUE.
8. Versoes historicas recebem lg_atual = FALSE.
9. E criado Default Member para tratamento de Late Arriving Dimensions.
10. Nenhuma vigencia historica inexistente na origem e artificialmente criada.
11. dt_insercao permanece como ultima coluna conforme o padrao VDAE.

REGRA TEMPORAL PARA RELACIONAMENTO COM A FATO:

dt_atendimento >= dt_inicio_vigencia
AND dt_atendimento < dt_fim_vigencia

LATE ARRIVING DIMENSION:

Atendimentos anteriores a primeira versao conhecida do paciente nao serao
artificialmente associados a essa primeira versao.

Nesses casos, a fato devera utilizar o Default Member da dim_paciente.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA business;


-- ========================================================================================
-- 2. DIMENSAO HISTORICA DE PACIENTES - SCD TIPO 2
-- ========================================================================================

CREATE OR REPLACE TABLE dim_paciente AS

WITH pacientes_origem AS (

    SELECT
        id_paciente,
        ds_nome,
        ds_plano_saude,
        ds_cidade,
        dt_atualizacao
    FROM engenharia_analytics_saude_dev.staging.stg_cadastro_pacientes
    WHERE id_paciente IS NOT NULL
      AND dt_atualizacao IS NOT NULL

),

vigencias AS (

    SELECT
        id_paciente,
        ds_nome,
        ds_plano_saude,
        ds_cidade,
        dt_atualizacao AS dt_inicio_vigencia,

        LEAD(dt_atualizacao) OVER (
            PARTITION BY id_paciente
            ORDER BY dt_atualizacao
        ) AS dt_proxima_vigencia

    FROM pacientes_origem

),

registros_validos AS (

    SELECT
        MD5(
            id_paciente
            || '|'
            || TO_VARCHAR(
                dt_inicio_vigencia,
                'YYYY-MM-DD HH24:MI:SS.FF9'
            )
        ) AS id_sk_paciente,

        id_paciente,
        ds_nome,
        ds_plano_saude,
        ds_cidade,
        dt_inicio_vigencia,

        COALESCE(
            dt_proxima_vigencia,
            '9999-12-31 00:00:00'::TIMESTAMP_NTZ
        ) AS dt_fim_vigencia,

        IFF(
            dt_proxima_vigencia IS NULL,
            TRUE,
            FALSE
        ) AS lg_atual

    FROM vigencias

),

default_member AS (

    SELECT
        MD5('-1') AS id_sk_paciente,
        '-1' AS id_paciente,
        'NÃO INFORMADO' AS ds_nome,
        'NÃO INFORMADO' AS ds_plano_saude,
        'NÃO INFORMADO' AS ds_cidade,
        '1900-01-01 00:00:00'::TIMESTAMP_NTZ AS dt_inicio_vigencia,
        '9999-12-31 00:00:00'::TIMESTAMP_NTZ AS dt_fim_vigencia,
        TRUE AS lg_atual

)

SELECT
    id_sk_paciente,
    id_paciente,
    ds_nome,
    ds_plano_saude,
    ds_cidade,
    dt_inicio_vigencia,
    dt_fim_vigencia,
    lg_atual,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM default_member

UNION ALL

SELECT
    id_sk_paciente,
    id_paciente,
    ds_nome,
    ds_plano_saude,
    ds_cidade,
    dt_inicio_vigencia,
    dt_fim_vigencia,
    lg_atual,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM registros_validos
;