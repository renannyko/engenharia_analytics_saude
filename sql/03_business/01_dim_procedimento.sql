/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_dim_procedimento.sql
CAMADA: business
OBJETO: dim_procedimento
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Criar a dimensao de procedimentos a partir dos dados tecnicamente tratados na
camada Staging.

GRANULARIDADE:

1 linha = 1 procedimento de negocio.

REGRAS DE IMPLEMENTACAO:

1. A dimensao utiliza Surrogate Key deterministica em formato MD5 STRING.
2. A chave natural do procedimento e preservada.
3. E criado Default Member para tratamento de referencias nao mapeadas.
4. Nenhuma informacao inexistente na origem e artificialmente criada.
5. dt_insercao permanece como ultima coluna conforme o padrao VDAE.
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
-- 2. DIMENSAO DE PROCEDIMENTOS
-- ========================================================================================

CREATE OR REPLACE TABLE dim_procedimento AS

WITH procedimentos AS (

    SELECT DISTINCT
        cd_procedimento,
        ds_procedimento
    FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens
    WHERE cd_procedimento IS NOT NULL

),

default_member AS (

    SELECT
        MD5('-1') AS id_sk_procedimento,
        '-1' AS cd_procedimento,
        'NÃO INFORMADO' AS ds_procedimento

),

registros_validos AS (

    SELECT
        MD5(cd_procedimento) AS id_sk_procedimento,
        cd_procedimento,
        ds_procedimento
    FROM procedimentos

)

SELECT
    id_sk_procedimento,
    cd_procedimento,
    ds_procedimento,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM default_member

UNION ALL

SELECT
    id_sk_procedimento,
    cd_procedimento,
    ds_procedimento,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM registros_validos
;