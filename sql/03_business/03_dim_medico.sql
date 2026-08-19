/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 03_dim_medico.sql
CAMADA: business
OBJETO: dim_medico
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Criar a dimensao de medicos a partir dos identificadores dos profissionais
executantes disponiveis na camada Staging.

GRANULARIDADE:

1 linha = 1 medico/profissional executante.

REGRAS DE IMPLEMENTACAO:

1. A dimensao utiliza Surrogate Key deterministica em formato MD5 STRING.
2. A chave natural do medico e preservada.
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
-- 2. DIMENSAO DE MEDICOS
-- ========================================================================================

CREATE OR REPLACE TABLE dim_medico AS

WITH medicos AS (

    SELECT DISTINCT
        id_medico_executante AS id_medico
    FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens
    WHERE id_medico_executante IS NOT NULL

),

default_member AS (

    SELECT
        MD5('-1') AS id_sk_medico,
        '-1' AS id_medico

),

registros_validos AS (

    SELECT
        MD5(id_medico) AS id_sk_medico,
        id_medico
    FROM medicos

)

SELECT
    id_sk_medico,
    id_medico,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM default_member

UNION ALL

SELECT
    id_sk_medico,
    id_medico,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM registros_validos
;