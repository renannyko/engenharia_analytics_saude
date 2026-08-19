/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 04_dim_data.sql
CAMADA: business
OBJETO: dim_data
TIPO: table
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Criar a dimensao de datas utilizada para analises temporais dos procedimentos
e atendimentos.

GRANULARIDADE:

1 linha = 1 dia do calendario.

REGRAS DE IMPLEMENTACAO:

1. A dimensao utiliza Surrogate Key deterministica em formato MD5 STRING.
2. O calendario e gerado entre a menor e a maior data de atendimento existente.
3. E criado Default Member para tratamento de referencias nao mapeadas.
4. Sao disponibilizados atributos de calendario relevantes ao consumo analitico.
5. Nenhuma regra de negocio transacional e aplicada nesta dimensao.
6. dt_insercao permanece como ultima coluna conforme o padrao VDAE.

DECISOES DE ARQUITETURA:

1. A dimensao e materializada como tabela na camada Business.
2. O calendario e continuo, incluindo dias sem ocorrencia de atendimentos.
3. A geracao inicial utiliza GENERATOR com limite tecnico superior ao intervalo
   atualmente necessario para o projeto.
4. A CTE calendario_base calcula a data apenas uma vez, evitando repeticao da
   expressao DATEADD e melhorando a legibilidade do codigo.
5. O filtro do intervalo utiliza WHERE, pois nao existe funcao de janela nesta etapa.
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
-- 2. DIMENSAO DE DATAS
-- ========================================================================================

CREATE OR REPLACE TABLE dim_data AS

WITH limites AS (

    SELECT
        MIN(dt_atendimento::DATE) AS dt_minima,
        MAX(dt_atendimento::DATE) AS dt_maxima
    FROM engenharia_analytics_saude_dev.staging.stg_atendimentos
    WHERE dt_atendimento IS NOT NULL

),

calendario_base AS (

    SELECT
        DATEADD(
            DAY,
            SEQ4(),
            limites.dt_minima
        )::DATE AS dt_data,

        limites.dt_maxima

    FROM limites,
         TABLE(GENERATOR(ROWCOUNT => 10000))

),

calendario AS (

    SELECT
        dt_data
    FROM calendario_base
    WHERE dt_data <= dt_maxima

),

default_member AS (

    SELECT
        MD5('-1') AS id_sk_data,
        NULL::DATE AS dt_data,
        -1 AS nr_ano,
        -1 AS nr_semestre,
        -1 AS nr_trimestre,
        -1 AS nr_mes,
        'NÃO INFORMADO' AS ds_mes,
        -1 AS nr_dia_mes,
        -1 AS nr_dia_semana,
        'NÃO INFORMADO' AS ds_dia_semana,
        FALSE AS lg_fim_semana

),

registros_validos AS (

    SELECT
        MD5(
            TO_VARCHAR(
                dt_data,
                'YYYY-MM-DD'
            )
        ) AS id_sk_data,

        dt_data,

        YEAR(dt_data) AS nr_ano,

        CASE
            WHEN MONTH(dt_data) <= 6 THEN 1
            ELSE 2
        END AS nr_semestre,

        QUARTER(dt_data) AS nr_trimestre,

        MONTH(dt_data) AS nr_mes,

        CASE MONTH(dt_data)
            WHEN 1 THEN 'JANEIRO'
            WHEN 2 THEN 'FEVEREIRO'
            WHEN 3 THEN 'MARÇO'
            WHEN 4 THEN 'ABRIL'
            WHEN 5 THEN 'MAIO'
            WHEN 6 THEN 'JUNHO'
            WHEN 7 THEN 'JULHO'
            WHEN 8 THEN 'AGOSTO'
            WHEN 9 THEN 'SETEMBRO'
            WHEN 10 THEN 'OUTUBRO'
            WHEN 11 THEN 'NOVEMBRO'
            WHEN 12 THEN 'DEZEMBRO'
        END AS ds_mes,

        DAY(dt_data) AS nr_dia_mes,

        DAYOFWEEKISO(dt_data) AS nr_dia_semana,

        CASE DAYOFWEEKISO(dt_data)
            WHEN 1 THEN 'SEGUNDA-FEIRA'
            WHEN 2 THEN 'TERÇA-FEIRA'
            WHEN 3 THEN 'QUARTA-FEIRA'
            WHEN 4 THEN 'QUINTA-FEIRA'
            WHEN 5 THEN 'SEXTA-FEIRA'
            WHEN 6 THEN 'SÁBADO'
            WHEN 7 THEN 'DOMINGO'
        END AS ds_dia_semana,

        CASE
            WHEN DAYOFWEEKISO(dt_data) IN (6, 7) THEN TRUE
            ELSE FALSE
        END AS lg_fim_semana

    FROM calendario

)

SELECT
    id_sk_data,
    dt_data,
    nr_ano,
    nr_semestre,
    nr_trimestre,
    nr_mes,
    ds_mes,
    nr_dia_mes,
    nr_dia_semana,
    ds_dia_semana,
    lg_fim_semana,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM default_member

UNION ALL

SELECT
    id_sk_data,
    dt_data,
    nr_ano,
    nr_semestre,
    nr_trimestre,
    nr_mes,
    ds_mes,
    nr_dia_mes,
    nr_dia_semana,
    ds_dia_semana,
    lg_fim_semana,
    CURRENT_TIMESTAMP() AS dt_insercao
FROM registros_validos
;