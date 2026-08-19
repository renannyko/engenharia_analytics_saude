/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 02_criacao_tabelas_raw.sql
CAMADA: raw
OBJETIVO: criar as tabelas da camada Raw para preservacao dos dados de origem
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

PRINCIPIOS:

1. As colunas provenientes dos arquivos CSV serao armazenadas inicialmente como VARCHAR.
2. Nenhuma regra de negocio sera aplicada na camada Raw.
3. Nenhuma padronizacao de valores sera aplicada na camada Raw.
4. Metadados tecnicos serao adicionados para garantir rastreabilidade da ingestao.
5. A coluna dt_insercao sera sempre a ultima coluna da tabela, conforme padrao VDAE.

GRANULARIDADE:

raw_atendimentos
    1 linha = 1 atendimento recebido da origem.

raw_procedimentos_itens
    1 linha = 1 procedimento/item recebido da origem.

raw_cadastro_pacientes
    1 linha = 1 versao cadastral de paciente recebida da origem.

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
-- 2. RAW ATENDIMENTOS
-- ========================================================================================

CREATE TABLE IF NOT EXISTS raw_atendimentos (

    id_atendimento          VARCHAR,
    id_paciente             VARCHAR,
    data_hora_atendimento   VARCHAR,
    tipo_atendimento        VARCHAR,
    id_unidade              VARCHAR,
    status                  VARCHAR,
    valor_bruto             VARCHAR,
    desconto                VARCHAR,
    valor_liquido           VARCHAR,

    -- Metadados tecnicos de rastreabilidade
    ds_arquivo_origem       VARCHAR,
    nr_linha_origem         NUMBER,

    -- Conforme padrao VDAE, dt_insercao deve ser a ultima coluna
    dt_insercao             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()

)
COMMENT = 'Dados brutos de atendimentos preservados conforme recebidos da origem.';


-- ========================================================================================
-- 3. RAW PROCEDIMENTOS ITENS
-- ========================================================================================

CREATE TABLE IF NOT EXISTS raw_procedimentos_itens (

    id_item                 VARCHAR,
    id_atendimento          VARCHAR,
    codigo_procedimento     VARCHAR,
    nome_procedimento       VARCHAR,
    id_medico_executante    VARCHAR,
    valor_item              VARCHAR,

    -- Metadados tecnicos de rastreabilidade
    ds_arquivo_origem       VARCHAR,
    nr_linha_origem         NUMBER,

    -- Conforme padrao VDAE, dt_insercao deve ser a ultima coluna
    dt_insercao             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()

)
COMMENT = 'Dados brutos dos procedimentos realizados nos atendimentos.';


-- ========================================================================================
-- 4. RAW CADASTRO PACIENTES
-- ========================================================================================

CREATE TABLE IF NOT EXISTS raw_cadastro_pacientes (

    id_paciente             VARCHAR,
    nome                    VARCHAR,
    plano_saude             VARCHAR,
    cidade                  VARCHAR,
    data_atualizacao        VARCHAR,

    -- Metadados tecnicos de rastreabilidade
    ds_arquivo_origem       VARCHAR,
    nr_linha_origem         NUMBER,

    -- Conforme padrao VDAE, dt_insercao deve ser a ultima coluna
    dt_insercao             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()

)
COMMENT = 'Historico bruto de cadastros e atualizacoes dos pacientes.';


-- ========================================================================================
-- 5. VALIDACAO
-- ========================================================================================

SHOW TABLES IN SCHEMA engenharia_analytics_saude_dev.raw;
