/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_vw_analise_procedimentos.sql
CAMADA: information
OBJETO: vw_analise_procedimentos
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Disponibilizar um produto analitico certificado para consumo dos dados de
procedimentos, reunindo as metricas consolidadas na fato com os respectivos
atributos dimensionais.

GRANULARIDADE:

1 linha = 1 procedimento/item realizado dentro de 1 atendimento.

REGRAS DE IMPLEMENTACAO:

1. A View utiliza exclusivamente objetos da camada Business.
2. Nenhuma regra de negocio financeira e recalculada nesta camada.
3. As Surrogate Keys permanecem encapsuladas no modelo dimensional.
4. O consumidor recebe chaves naturais, atributos descritivos e metricas de negocio.
5. Registros associados ao Default Member de paciente sao identificados por flag.
6. Os relacionamentos dimensionais utilizam as Surrogate Keys materializadas na fato.
7. dt_insercao representa o momento de processamento logico da Information e
   permanece como ultima coluna conforme o padrao VDAE.

DECISOES DE ARQUITETURA:

1. A estrutura e implementada inicialmente como VIEW.
2. Nao existe evidencia atual que justifique materializacao adicional.
3. A camada Information reduz a complexidade de consumo do modelo dimensional.
4. Regras consolidadas na Business sao reutilizadas e nao duplicadas.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA information;


-- ========================================================================================
-- 2. VIEW ANALITICA DE PROCEDIMENTOS
-- ========================================================================================

CREATE OR REPLACE VIEW vw_analise_procedimentos AS

SELECT

    -- ------------------------------------------------------------------------------------
    -- IDENTIFICACAO
    -- ------------------------------------------------------------------------------------

    f.id_item,
    f.id_atendimento,


    -- ------------------------------------------------------------------------------------
    -- TEMPO
    -- ------------------------------------------------------------------------------------

    f.dt_atendimento,
    d.dt_data,
    d.nr_ano,
    d.nr_trimestre,
    d.nr_mes,
    d.ds_mes,
    d.ds_dia_semana,
    d.lg_fim_semana,


    -- ------------------------------------------------------------------------------------
    -- ATENDIMENTO
    -- ------------------------------------------------------------------------------------

    f.ds_tipo_atendimento,
    f.ds_status,


    -- ------------------------------------------------------------------------------------
    -- PACIENTE
    -- ------------------------------------------------------------------------------------

    p.id_paciente,

    p.ds_nome AS ds_nome_paciente,

    p.ds_plano_saude,

    p.ds_cidade AS ds_cidade_paciente,

    IFF(
        p.id_paciente = '-1',
        TRUE,
        FALSE
    ) AS lg_paciente_nao_identificado,


    -- ------------------------------------------------------------------------------------
    -- PROCEDIMENTO
    -- ------------------------------------------------------------------------------------

    pr.cd_procedimento,
    pr.ds_procedimento,


    -- ------------------------------------------------------------------------------------
    -- UNIDADE
    -- ------------------------------------------------------------------------------------

    u.id_unidade,


    -- ------------------------------------------------------------------------------------
    -- MEDICO
    -- ------------------------------------------------------------------------------------

    m.id_medico,


    -- ------------------------------------------------------------------------------------
    -- METRICAS
    -- ------------------------------------------------------------------------------------

    f.vl_item_bruto,
    f.vl_desconto_item,
    f.vl_item_liquido,


    -- ------------------------------------------------------------------------------------
    -- AUDITORIA
    -- ------------------------------------------------------------------------------------

    CURRENT_TIMESTAMP() AS dt_insercao

FROM engenharia_analytics_saude_dev.business.fct_procedimentos AS f

INNER JOIN engenharia_analytics_saude_dev.business.dim_paciente AS p
    ON f.id_sk_paciente = p.id_sk_paciente

INNER JOIN engenharia_analytics_saude_dev.business.dim_procedimento AS pr
    ON f.id_sk_procedimento = pr.id_sk_procedimento

INNER JOIN engenharia_analytics_saude_dev.business.dim_unidade AS u
    ON f.id_sk_unidade = u.id_sk_unidade

INNER JOIN engenharia_analytics_saude_dev.business.dim_medico AS m
    ON f.id_sk_medico = m.id_sk_medico

INNER JOIN engenharia_analytics_saude_dev.business.dim_data AS d
    ON f.id_sk_data = d.id_sk_data
;