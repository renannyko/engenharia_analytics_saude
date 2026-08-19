/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 06_criacao_fct_procedimentos.sql
CAMADA: business
OBJETO: fct_procedimentos
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Criar a estrutura fisica da fato de procedimentos utilizada pela camada Business.

GRANULARIDADE:

1 linha = 1 procedimento/item realizado dentro de 1 atendimento.

CHAVE DO GRAO:

id_item

REGRAS DE IMPLEMENTACAO:

1. A estrutura fisica da fato e provisionada separadamente da carga incremental.
2. A Surrogate Key da fato sera deterministica e baseada em MD5(id_item).
3. As chaves dimensionais serao armazenadas como STRING.
4. Valores financeiros utilizam NUMBER(18,2).
5. dt_insercao representa o momento de insercao fisica do registro na fato.
6. dt_insercao permanece como ultima coluna conforme o padrao VDAE.

DECISAO DE ARQUITETURA:

A criacao da estrutura foi separada da carga incremental para manter responsabilidade
unica por script, facilitar CI/CD, rastreabilidade, operacao e troubleshooting.

A carga recorrente sera implementada no arquivo:
07_carga_fct_procedimentos.sql
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
-- 2. CRIACAO DA FATO DE PROCEDIMENTOS
-- ========================================================================================

CREATE TABLE IF NOT EXISTS fct_procedimentos (

    id_sk_fato_procedimento VARCHAR,
    id_item VARCHAR,
    id_atendimento VARCHAR,

    id_sk_paciente VARCHAR,
    id_sk_procedimento VARCHAR,
    id_sk_unidade VARCHAR,
    id_sk_medico VARCHAR,
    id_sk_data VARCHAR,

    dt_atendimento TIMESTAMP_NTZ,

    ds_tipo_atendimento VARCHAR,
    ds_status VARCHAR,

    vl_item_bruto NUMBER(18,2),
    vl_desconto_item NUMBER(18,2),
    vl_item_liquido NUMBER(18,2),

    dt_insercao TIMESTAMP_NTZ

)
COMMENT = 'Fato incremental de procedimentos realizados por atendimento.';