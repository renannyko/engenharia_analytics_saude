/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_configuracao_inicial.sql
CAMADA: configuracao
OBJETIVO: criar a fundacao inicial do ambiente Snowflake para o projeto
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

DECISOES DE ARQUITETURA:

1. A role ACCOUNTADMIN sera utilizada apenas para a configuracao administrativa inicial.

2. O desenvolvimento cotidiano sera realizado com a role:
   role_engenharia_analytics

3. Serao utilizados dois Virtual Warehouses independentes:
   - wh_transformacao_dev: ingestao e transformacoes.
   - wh_bi_dev: consultas analiticas e consumo de BI.

4. Ambos os warehouses iniciarao como X-Small, com AUTO_SUSPEND de 60 segundos,
   seguindo uma estrategia conservadora de FinOps.

5. Multi-cluster nao sera utilizado neste ambiente devido ao baixo volume e baixa
   concorrencia esperados. Em producao, podera ser avaliado para cargas de BI com
   alta concorrencia.

6. A arquitetura logica seguira as camadas:
   raw -> staging -> business -> information

7. O schema qualidade_dados sera utilizado para controles de Data Quality seguindo
   as dimensoes definidas pelo DAMA e pela metodologia VDAE.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONFIGURACAO ADMINISTRATIVA
-- ========================================================================================

USE ROLE ACCOUNTADMIN;


-- ========================================================================================
-- 2. ROLE DO PROJETO
-- ========================================================================================

CREATE ROLE IF NOT EXISTS role_engenharia_analytics
    COMMENT = 'Role utilizada no projeto engenharia_analytics_saude.';


-- A role do projeto passa a fazer parte da hierarquia do SYSADMIN.
GRANT ROLE role_engenharia_analytics TO ROLE SYSADMIN;


-- Concede a role ao usuario responsavel pelo desenvolvimento.
GRANT ROLE role_engenharia_analytics TO USER RENANNYKO;


-- ========================================================================================
-- 3. WAREHOUSE DE TRANSFORMACAO
-- ========================================================================================

CREATE WAREHOUSE IF NOT EXISTS wh_transformacao_dev
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse destinado a ingestao e transformacoes do projeto engenharia_analytics_saude.';


-- ========================================================================================
-- 4. WAREHOUSE DE BI
-- ========================================================================================

CREATE WAREHOUSE IF NOT EXISTS wh_bi_dev
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse destinado a consultas analiticas e consumo de BI.';


-- ========================================================================================
-- 5. DATABASE DO PROJETO
-- ========================================================================================

CREATE DATABASE IF NOT EXISTS engenharia_analytics_saude_dev
    COMMENT = 'Database de desenvolvimento do projeto engenharia_analytics_saude.';


-- ========================================================================================
-- 6. SCHEMAS
-- ========================================================================================

CREATE SCHEMA IF NOT EXISTS engenharia_analytics_saude_dev.raw
    COMMENT = 'Camada de dados brutos preservados conforme recebidos da origem.';

CREATE SCHEMA IF NOT EXISTS engenharia_analytics_saude_dev.staging
    COMMENT = 'Camada de tratamento tecnico, tipagem e padronizacao dos dados.';

CREATE SCHEMA IF NOT EXISTS engenharia_analytics_saude_dev.business
    COMMENT = 'Camada corporativa de regras de negocio e modelagem dimensional.';

CREATE SCHEMA IF NOT EXISTS engenharia_analytics_saude_dev.information
    COMMENT = 'Camada destinada ao consumo analitico e ferramentas de BI.';

CREATE SCHEMA IF NOT EXISTS engenharia_analytics_saude_dev.qualidade_dados
    COMMENT = 'Camada destinada aos controles e validacoes de qualidade de dados.';


-- ========================================================================================
-- 7. PRIVILEGIOS DA ROLE DO PROJETO
-- ========================================================================================

GRANT USAGE ON WAREHOUSE wh_transformacao_dev
TO ROLE role_engenharia_analytics;

GRANT USAGE ON WAREHOUSE wh_bi_dev
TO ROLE role_engenharia_analytics;


GRANT USAGE ON DATABASE engenharia_analytics_saude_dev
TO ROLE role_engenharia_analytics;


GRANT USAGE ON ALL SCHEMAS IN DATABASE engenharia_analytics_saude_dev
TO ROLE role_engenharia_analytics;


-- Permissoes para criacao de objetos dentro dos schemas do projeto.

GRANT CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT
ON SCHEMA engenharia_analytics_saude_dev.raw
TO ROLE role_engenharia_analytics;


GRANT CREATE TABLE, CREATE VIEW
ON SCHEMA engenharia_analytics_saude_dev.staging
TO ROLE role_engenharia_analytics;


GRANT CREATE TABLE, CREATE VIEW
ON SCHEMA engenharia_analytics_saude_dev.business
TO ROLE role_engenharia_analytics;


GRANT CREATE TABLE, CREATE VIEW
ON SCHEMA engenharia_analytics_saude_dev.information
TO ROLE role_engenharia_analytics;


GRANT CREATE TABLE, CREATE VIEW
ON SCHEMA engenharia_analytics_saude_dev.qualidade_dados
TO ROLE role_engenharia_analytics;


-- ========================================================================================
-- 8. VALIDACAO DO CONTEXTO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA raw;


SELECT
    CURRENT_USER()      AS usuario_atual,
    CURRENT_ROLE()      AS role_atual,
    CURRENT_WAREHOUSE() AS warehouse_atual,
    CURRENT_DATABASE()  AS database_atual,
    CURRENT_SCHEMA()    AS schema_atual;