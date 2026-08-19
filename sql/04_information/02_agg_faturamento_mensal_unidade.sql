/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 02_agg_faturamento_mensal_unidade.sql
CAMADA: information
OBJETO: agg_faturamento_mensal_unidade
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Disponibilizar uma visao analitica agregada para acompanhamento mensal dos
principais indicadores de volume e faturamento por unidade.

GRANULARIDADE:

1 linha = 1 mes + 1 unidade.

METRICAS DISPONIBILIZADAS:

1. Quantidade de atendimentos.
2. Quantidade de procedimentos.
3. Quantidade de pacientes identificados.
4. Valor bruto.
5. Valor de desconto.
6. Valor liquido.
7. Ticket medio por atendimento.
8. Ticket medio por procedimento.
9. Quantidade de atendimentos concluidos.
10. Quantidade de atendimentos cancelados.
11. Quantidade de atendimentos em andamento.

REGRAS DE IMPLEMENTACAO:

1. A estrutura utiliza exclusivamente o produto analitico detalhado da Information.
2. As metricas financeiras certificadas nao sao recalculadas.
3. Os valores financeiros sao apenas agregados no novo grao.
4. Atendimentos sao contabilizados de forma distinta para evitar duplicidade causada
   pela granularidade de procedimento da fonte.
5. Pacientes associados ao Default Member nao compoem a metrica de pacientes
   identificados.
6. Nenhum registro e excluido com base no status do atendimento.
7. As quantidades por status sao disponibilizadas separadamente para consumo.
8. dt_insercao permanece como ultima coluna conforme o padrao VDAE.

DECISOES DE ARQUITETURA:

1. A estrutura e implementada inicialmente como VIEW.
2. A agregacao representa um produto de consumo executivo.
3. O grao mensal por unidade reduz a complexidade para dashboards e indicadores.
4. Nenhuma nova regra de rateio financeiro e implementada nesta camada.
5. A materializacao podera ser reavaliada futuramente mediante necessidade
   comprovada de performance.
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
-- 2. AGREGACAO MENSAL DE FATURAMENTO POR UNIDADE
-- ========================================================================================

CREATE OR REPLACE VIEW agg_faturamento_mensal_unidade AS

SELECT
    nr_ano,
    nr_mes,
    ds_mes,
    id_unidade,

    COUNT(DISTINCT id_atendimento) AS qt_atendimentos,

    COUNT(DISTINCT id_item) AS qt_procedimentos,

    COUNT(
        DISTINCT CASE
            WHEN lg_paciente_nao_identificado = FALSE
                THEN id_paciente
        END
    ) AS qt_pacientes_identificados,

    SUM(vl_item_bruto)::NUMBER(18,2) AS vl_bruto,

    SUM(vl_desconto_item)::NUMBER(18,2) AS vl_desconto,

    SUM(vl_item_liquido)::NUMBER(18,2) AS vl_liquido,

    (
        SUM(vl_item_liquido)
        /
        NULLIF(
            COUNT(DISTINCT id_atendimento),
            0
        )
    )::NUMBER(18,2) AS vl_ticket_medio_atendimento,

    (
        SUM(vl_item_liquido)
        /
        NULLIF(
            COUNT(DISTINCT id_item),
            0
        )
    )::NUMBER(18,2) AS vl_ticket_medio_procedimento,

    COUNT(
        DISTINCT CASE
            WHEN ds_status = 'CONCLUÍDO'
                THEN id_atendimento
        END
    ) AS qt_atendimentos_concluidos,

    COUNT(
        DISTINCT CASE
            WHEN ds_status = 'CANCELADO'
                THEN id_atendimento
        END
    ) AS qt_atendimentos_cancelados,

    COUNT(
        DISTINCT CASE
            WHEN ds_status = 'EM ANDAMENTO'
                THEN id_atendimento
        END
    ) AS qt_atendimentos_em_andamento,

    CURRENT_TIMESTAMP() AS dt_insercao

FROM engenharia_analytics_saude_dev.information.vw_analise_procedimentos

GROUP BY
    nr_ano,
    nr_mes,
    ds_mes,
    id_unidade
;