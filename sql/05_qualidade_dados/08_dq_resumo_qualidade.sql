/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 08_dq_resumo_qualidade.sql
CAMADA: qualidade_dados
OBJETO: dq_resumo_qualidade
TIPO: view
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Consolidar os resultados dos controles formais de Data Quality implementados ao
longo das camadas Raw, Staging, Business e Information.

A View permite acompanhar de forma centralizada a quantidade de testes executados,
aprovados e reprovados por escopo de qualidade.

REGRAS DE IMPLEMENTACAO:

1. Os resultados sao obtidos exclusivamente das Views dq_ ja implementadas.
2. Nenhuma regra de qualidade e recalculada nesta estrutura.
3. A View funciona como camada consolidada de observabilidade de Data Quality.
4. O status geral do escopo sera APROVADO somente quando nao houver testes reprovados.
5. dt_insercao permanece como ultima coluna conforme o padrao VDAE.
==========================================================================================
*/


-- ========================================================================================
-- 1. CONTEXTO DE EXECUCAO
-- ========================================================================================

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA qualidade_dados;


-- ========================================================================================
-- 2. RESUMO CONSOLIDADO DE QUALIDADE
-- ========================================================================================

CREATE OR REPLACE VIEW dq_resumo_qualidade AS

WITH resultados AS (

    SELECT
        'RAW' AS ds_escopo,
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_raw

    UNION ALL

    SELECT
        'STAGING',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_staging

    UNION ALL

    SELECT
        'BUSINESS_DIMENSOES',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_business_dimensoes

    UNION ALL

    SELECT
        'BUSINESS_SCD2',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_business_scd2

    UNION ALL

    SELECT
        'BUSINESS_FATO',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_business_fato

    UNION ALL

    SELECT
        'RECONCILIACAO_FINANCEIRA',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_reconciliacao_financeira

    UNION ALL

    SELECT
        'INFORMATION',
        id_teste,
        ds_teste,
        ds_dimensao_dq,
        qt_erros,
        ds_status
    FROM dq_information

)

SELECT
    ds_escopo,

    COUNT(*) AS qt_testes,

    COUNT_IF(
        ds_status = 'APROVADO'
    ) AS qt_aprovados,

    COUNT_IF(
        ds_status = 'REPROVADO'
    ) AS qt_reprovados,

    SUM(qt_erros) AS qt_erros,

    IFF(
        COUNT_IF(ds_status = 'REPROVADO') = 0,
        'APROVADO',
        'REPROVADO'
    ) AS ds_status,

    CURRENT_TIMESTAMP() AS dt_insercao

FROM resultados

GROUP BY
    ds_escopo
;