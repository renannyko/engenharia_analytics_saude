/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 03_stg_cadastro_pacientes.sql
CAMADA: staging
OBJETO: stg_cadastro_pacientes
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Realizar o tratamento tecnico do historico cadastral de pacientes proveniente da
camada Raw, aplicando tipagem segura, padronizacao textual e nomenclatura conforme
o padrao VDAE.

GRANULARIDADE:

1 linha = 1 versao cadastral de paciente recebida da camada Raw.

REGRAS DE IMPLEMENTACAO:

1. Nenhuma regra de SCD Tipo 2 e aplicada nesta camada.
2. Todas as versoes cadastrais recebidas da origem sao preservadas.
3. A chave natural id_paciente e preservada.
4. Campos descritivos sao padronizados com UPPER(TRIM(...)).
5. A data de atualizacao e convertida de forma segura com TRY_TO_TIMESTAMP_NTZ.
6. Metadados da origem sao preservados para rastreabilidade.
7. dt_insercao representa o momento de processamento da Staging e permanece
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

CREATE OR REPLACE VIEW stg_cadastro_pacientes AS

SELECT
    TRIM(id_paciente) AS id_paciente,

    UPPER(
        TRIM(nome)
    ) AS ds_nome,

    UPPER(
        TRIM(plano_saude)
    ) AS ds_plano_saude,

    UPPER(
        TRIM(cidade)
    ) AS ds_cidade,

    TRY_TO_TIMESTAMP_NTZ(
        NULLIF(TRIM(data_atualizacao), '')
    ) AS dt_atualizacao,

    ds_arquivo_origem,
    nr_linha_origem,

    CURRENT_TIMESTAMP() AS dt_insercao

FROM engenharia_analytics_saude_dev.raw.raw_cadastro_pacientes
;