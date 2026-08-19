/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 02_dim_unidade.sql
CAMADA: business
OBJETO: dim_unidade
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Criar a dimensao de unidades a partir dos identificadores disponiveis na camada
Staging, permitindo relacionamento dimensional da fato sem criar atributos
inexistentes nas fontes disponibilizadas.

GRANULARIDADE:

1 linha = 1 unidade de atendimento.

REGRAS DE IMPLEMENTACAO:

1. A dimensao utiliza Surrogate Key deterministica em formato MD5 STRING.
2. A chave natural da unidade e preservada.
3. E criado Default Member para tratamento de referencias nao mapeadas.
4. Nenhum atributo inexistente na origem e artificialmente criado.
5. A dimensao permanece preparada para enriquecimento futuro por fonte mestre.
6. dt_insercao permanece como ultima coluna conforme o padrao VDAE.
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
-- 2. DIMENSAO DE UNIDADES
-- ========================================================================================

CREATE OR REPLACE TABLE dim_unidade AS

WITH unidades AS (

    SELECT DISTINCT
        id_unidade
    FROM engenharia_analytics_saude_dev.staging.stg_atendimentos
    WHERE id_unidade IS NOT NULL

),

default_member AS (

    SELECT
        MD5('-1') AS id_sk_unidade,
        '-1' AS id_unidade

),

registros_validos AS (

    SELECT
        MD5(id_unidade) AS id_sk_unidade,
        id_unidade
    FROM unidades

)

SELECT
    id_sk_unidade,
    id_unidade,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM default_member

UNION ALL

SELECT
    id_sk_unidade,
    id_unidade,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM registros_validos
;