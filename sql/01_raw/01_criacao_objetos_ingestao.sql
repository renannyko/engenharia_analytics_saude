/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_criacao_objetos_ingestao.sql
CAMADA: raw
OBJETIVO: criar os objetos necessarios para ingestao dos arquivos CSV
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

RESPONSABILIDADES:

1. Criar o FILE FORMAT utilizado para leitura dos arquivos CSV.
2. Criar o INTERNAL STAGE utilizado para recebimento dos arquivos locais.
3. Nenhuma transformacao ou regra de negocio sera aplicada nesta etapa.

FLUXO:

arquivo csv local
        ↓
internal stage
        ↓
tabelas raw

==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA raw;


-- ========================================================================================
-- 2. FILE FORMAT CSV
-- ========================================================================================

CREATE FILE FORMAT IF NOT EXISTS ff_csv_saude
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = FALSE
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('NULL', 'null')
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    COMMENT = 'Formato padrao para ingestao dos arquivos CSV do projeto engenharia_analytics_saude.';


-- ========================================================================================
-- 3. INTERNAL STAGE
-- ========================================================================================

CREATE STAGE IF NOT EXISTS stg_arquivos_saude
    FILE_FORMAT = ff_csv_saude
    COMMENT = 'Stage interno para recebimento dos arquivos CSV do projeto engenharia_analytics_saude.';