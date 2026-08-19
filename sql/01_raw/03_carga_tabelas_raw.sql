/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 03_carga_tabelas_raw.sql
CAMADA: raw
OBJETIVO: carregar os arquivos CSV do Internal Stage para as tabelas Raw
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

PRINCIPIOS:

1. Os dados recebidos da origem nao serao transformados nesta etapa.
2. As colunas dos arquivos permanecerao como VARCHAR na camada Raw.
3. Metadados do Snowflake serao utilizados para garantir rastreabilidade:
   - arquivo de origem;
   - numero da linha de origem;
   - timestamp de insercao.
4. A tipagem e padronizacao dos dados ocorrerao somente na camada Staging.

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
-- 2. CARGA RAW ATENDIMENTOS
-- ========================================================================================

COPY INTO raw_atendimentos (
    id_atendimento,
    id_paciente,
    data_hora_atendimento,
    tipo_atendimento,
    id_unidade,
    status,
    valor_bruto,
    desconto,
    valor_liquido,
    ds_arquivo_origem,
    nr_linha_origem,
    dt_insercao
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP()
    FROM @stg_arquivos_saude/raw_atendimentos.csv
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_saude)
ON_ERROR = 'ABORT_STATEMENT';


-- ========================================================================================
-- 3. CARGA RAW PROCEDIMENTOS ITENS
-- ========================================================================================

COPY INTO raw_procedimentos_itens (
    id_item,
    id_atendimento,
    codigo_procedimento,
    nome_procedimento,
    id_medico_executante,
    valor_item,
    ds_arquivo_origem,
    nr_linha_origem,
    dt_insercao
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP()
    FROM @stg_arquivos_saude/raw_procedimentos_itens.csv
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_saude)
ON_ERROR = 'ABORT_STATEMENT';


-- ========================================================================================
-- 4. CARGA RAW CADASTRO PACIENTES
-- ========================================================================================

COPY INTO raw_cadastro_pacientes (
    id_paciente,
    nome,
    plano_saude,
    cidade,
    data_atualizacao,
    ds_arquivo_origem,
    nr_linha_origem,
    dt_insercao
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP()
    FROM @stg_arquivos_saude/raw_cadastro_pacientes.csv
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_saude)
ON_ERROR = 'ABORT_STATEMENT';


-- ========================================================================================
-- 5. VALIDACAO DE VOLUMETRIA
-- ========================================================================================

SELECT
    'raw_atendimentos' AS ds_tabela,
    COUNT(*) AS qt_registros
FROM raw_atendimentos

UNION ALL

SELECT
    'raw_procedimentos_itens' AS ds_tabela,
    COUNT(*) AS qt_registros
FROM raw_procedimentos_itens

UNION ALL

SELECT
    'raw_cadastro_pacientes' AS ds_tabela,
    COUNT(*) AS qt_registros
FROM raw_cadastro_pacientes
;


-- ========================================================================================
-- 6. VALIDACAO DE RASTREABILIDADE
-- ========================================================================================

SELECT
    ds_arquivo_origem,
    MIN(nr_linha_origem) AS nr_primeira_linha,
    MAX(nr_linha_origem) AS nr_ultima_linha,
    COUNT(*) AS qt_registros,
    MIN(dt_insercao) AS dt_primeira_insercao,
    MAX(dt_insercao) AS dt_ultima_insercao
FROM raw_atendimentos
GROUP BY
    ds_arquivo_origem
;