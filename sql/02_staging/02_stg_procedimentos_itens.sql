/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 02_stg_procedimentos_itens.sql
CAMADA: staging
OBJETO: stg_procedimentos_itens
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Realizar o tratamento tecnico dos dados de procedimentos provenientes da camada Raw,
aplicando tipagem segura, padronizacao textual e nomenclatura conforme o padrao VDAE.

GRANULARIDADE:

1 linha = 1 procedimento/item recebido da camada Raw.

REGRAS DE IMPLEMENTACAO:

1. Nenhuma regra de negocio e aplicada nesta camada.
2. As chaves naturais sao preservadas.
3. Campos descritivos sao padronizados com UPPER(TRIM(...)).
4. Conversoes utilizam funcoes TRY_TO_* para evitar falhas do pipeline.
5. Metadados da origem sao preservados para rastreabilidade.
6. dt_insercao representa o momento de processamento da Staging e permanece
   como ultima coluna conforme padrao VDAE.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA staging;


-- ========================================================================================
-- 2. VIEW STAGING
-- ========================================================================================

CREATE OR REPLACE VIEW stg_procedimentos_itens AS

SELECT
    TRIM(id_item) AS id_item,

    TRIM(id_atendimento) AS id_atendimento,

    TRIM(codigo_procedimento) AS cd_procedimento,

    UPPER(
        TRIM(nome_procedimento)
    ) AS ds_procedimento,

    TRIM(id_medico_executante) AS id_medico_executante,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(valor_item), ''),
        18,
        2
    ) AS vl_item,

    ds_arquivo_origem,
    nr_linha_origem,

    CURRENT_TIMESTAMP() AS dt_insercao

FROM engenharia_analytics_saude_dev.raw.raw_procedimentos_itens
;