/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_stg_atendimentos.sql
CAMADA: staging
OBJETO: stg_atendimentos
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Realizar o tratamento tecnico dos dados de atendimentos provenientes da camada Raw,
aplicando tipagem segura, padronizacao textual e nomenclatura conforme o padrao VDAE.

GRANULARIDADE:

1 linha = 1 atendimento recebido da camada Raw.

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

CREATE OR REPLACE VIEW stg_atendimentos AS

SELECT
    TRIM(id_atendimento) AS id_atendimento,
    TRIM(id_paciente) AS id_paciente,

    TRY_TO_TIMESTAMP_NTZ(
        NULLIF(TRIM(data_hora_atendimento), '')
    ) AS dt_atendimento,

    UPPER(
        TRIM(tipo_atendimento)
    ) AS ds_tipo_atendimento,

    TRIM(id_unidade) AS id_unidade,

    UPPER(
        TRIM(status)
    ) AS ds_status,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(valor_bruto), ''),
        18,
        2
    ) AS vl_bruto,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(desconto), ''),
        18,
        2
    ) AS vl_desconto,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(valor_liquido), ''),
        18,
        2
    ) AS vl_liquido,

    ds_arquivo_origem,
    nr_linha_origem,

    CURRENT_TIMESTAMP() AS dt_insercao

FROM engenharia_analytics_saude_dev.raw.raw_atendimentos
;