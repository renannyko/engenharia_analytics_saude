/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 07_carga_fct_procedimentos.sql
CAMADA: business
OBJETO: fct_procedimentos
TIPO: carga incremental
METODOLOGIA: VDAE
AMBIENTE: dev
ESTRATEGIA: MERGE incremental e idempotente
==========================================================================================

OBJETIVO:

Executar a carga incremental da fato de procedimentos utilizando MERGE, garantindo
idempotencia, integridade dimensional, preservacao historica do paciente e rateio
proporcional de descontos.

GRANULARIDADE:

1 linha = 1 procedimento/item realizado dentro de 1 atendimento.

CHAVE DO GRAO:

id_item

REGRAS DE NEGOCIO E ARQUITETURA:

1. A Surrogate Key da fato e deterministica e baseada em MD5(id_item).
2. O paciente e relacionado a versao dimensional vigente na data do atendimento.
3. Atendimentos anteriores ao primeiro cadastro conhecido utilizam Default Member.
4. Procedimentos, unidades, medicos e datas nao mapeados utilizam Default Member.
5. O desconto do atendimento e rateado proporcionalmente entre seus itens.
6. Nenhum atendimento e excluido por status, pois essa regra nao foi fornecida.
7. Novos registros sao inseridos.
8. Registros existentes sao atualizados somente quando houver alteracao relevante.
9. Reexecucoes sem mudanca na origem nao devem provocar UPDATE desnecessario.
10. dt_insercao representa a data de insercao fisica e nao e alterada em UPDATE.
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
-- 2. CARGA INCREMENTAL
-- ========================================================================================

MERGE INTO fct_procedimentos AS destino

USING (

    WITH base_procedimentos AS (

        SELECT
            p.id_item,
            p.id_atendimento,
            p.cd_procedimento,
            p.id_medico_executante,
            p.vl_item,

            a.id_paciente,
            a.id_unidade,
            a.dt_atendimento,
            a.ds_tipo_atendimento,
            a.ds_status,
            a.vl_desconto,

            SUM(p.vl_item) OVER (
                PARTITION BY p.id_atendimento
            ) AS vl_total_itens_atendimento

        FROM engenharia_analytics_saude_dev.staging.stg_procedimentos_itens AS p

        INNER JOIN engenharia_analytics_saude_dev.staging.stg_atendimentos AS a
            ON p.id_atendimento = a.id_atendimento

    ),

    base_rateio AS (

        SELECT
            id_item,
            id_atendimento,
            cd_procedimento,
            id_medico_executante,
            vl_item,

            id_paciente,
            id_unidade,
            dt_atendimento,
            ds_tipo_atendimento,
            ds_status,

            vl_desconto,
            vl_total_itens_atendimento,

            CASE
                WHEN vl_total_itens_atendimento = 0 THEN 0
                ELSE
                    vl_desconto
                    *
                    (
                        vl_item
                        /
                        NULLIF(vl_total_itens_atendimento, 0)
                    )
            END AS vl_desconto_item_calculado

        FROM base_procedimentos

    ),

    base_dimensional AS (

        SELECT
            MD5(b.id_item) AS id_sk_fato_procedimento,

            b.id_item,
            b.id_atendimento,

            COALESCE(
                dp.id_sk_paciente,
                MD5('-1')
            ) AS id_sk_paciente,

            COALESCE(
                dpr.id_sk_procedimento,
                MD5('-1')
            ) AS id_sk_procedimento,

            COALESCE(
                du.id_sk_unidade,
                MD5('-1')
            ) AS id_sk_unidade,

            COALESCE(
                dm.id_sk_medico,
                MD5('-1')
            ) AS id_sk_medico,

            COALESCE(
                dd.id_sk_data,
                MD5('-1')
            ) AS id_sk_data,

            b.dt_atendimento,
            b.ds_tipo_atendimento,
            b.ds_status,

            b.vl_item::NUMBER(18,2) AS vl_item_bruto,

            ROUND(
                b.vl_desconto_item_calculado,
                2
            )::NUMBER(18,2) AS vl_desconto_item,

            ROUND(
                b.vl_item - b.vl_desconto_item_calculado,
                2
            )::NUMBER(18,2) AS vl_item_liquido

        FROM base_rateio AS b

        LEFT JOIN engenharia_analytics_saude_dev.business.dim_paciente AS dp
            ON b.id_paciente = dp.id_paciente
           AND b.dt_atendimento >= dp.dt_inicio_vigencia
           AND b.dt_atendimento < dp.dt_fim_vigencia
           AND dp.id_paciente <> '-1'

        LEFT JOIN engenharia_analytics_saude_dev.business.dim_procedimento AS dpr
            ON b.cd_procedimento = dpr.cd_procedimento
           AND dpr.cd_procedimento <> '-1'

        LEFT JOIN engenharia_analytics_saude_dev.business.dim_unidade AS du
            ON b.id_unidade = du.id_unidade
           AND du.id_unidade <> '-1'

        LEFT JOIN engenharia_analytics_saude_dev.business.dim_medico AS dm
            ON b.id_medico_executante = dm.id_medico
           AND dm.id_medico <> '-1'

        LEFT JOIN engenharia_analytics_saude_dev.business.dim_data AS dd
            ON b.dt_atendimento::DATE = dd.dt_data
           AND dd.dt_data IS NOT NULL

    )

    SELECT
        id_sk_fato_procedimento,
        id_item,
        id_atendimento,

        id_sk_paciente,
        id_sk_procedimento,
        id_sk_unidade,
        id_sk_medico,
        id_sk_data,

        dt_atendimento,

        ds_tipo_atendimento,
        ds_status,

        vl_item_bruto,
        vl_desconto_item,
        vl_item_liquido

    FROM base_dimensional

) AS origem

ON destino.id_sk_fato_procedimento = origem.id_sk_fato_procedimento


-- ========================================================================================
-- 3. ATUALIZACAO SOMENTE QUANDO HOUVER ALTERACAO
-- ========================================================================================

WHEN MATCHED
AND (
       destino.id_item IS DISTINCT FROM origem.id_item
    OR destino.id_atendimento IS DISTINCT FROM origem.id_atendimento
    OR destino.id_sk_paciente IS DISTINCT FROM origem.id_sk_paciente
    OR destino.id_sk_procedimento IS DISTINCT FROM origem.id_sk_procedimento
    OR destino.id_sk_unidade IS DISTINCT FROM origem.id_sk_unidade
    OR destino.id_sk_medico IS DISTINCT FROM origem.id_sk_medico
    OR destino.id_sk_data IS DISTINCT FROM origem.id_sk_data
    OR destino.dt_atendimento IS DISTINCT FROM origem.dt_atendimento
    OR destino.ds_tipo_atendimento IS DISTINCT FROM origem.ds_tipo_atendimento
    OR destino.ds_status IS DISTINCT FROM origem.ds_status
    OR destino.vl_item_bruto IS DISTINCT FROM origem.vl_item_bruto
    OR destino.vl_desconto_item IS DISTINCT FROM origem.vl_desconto_item
    OR destino.vl_item_liquido IS DISTINCT FROM origem.vl_item_liquido
)
THEN UPDATE SET

    destino.id_item = origem.id_item,
    destino.id_atendimento = origem.id_atendimento,

    destino.id_sk_paciente = origem.id_sk_paciente,
    destino.id_sk_procedimento = origem.id_sk_procedimento,
    destino.id_sk_unidade = origem.id_sk_unidade,
    destino.id_sk_medico = origem.id_sk_medico,
    destino.id_sk_data = origem.id_sk_data,

    destino.dt_atendimento = origem.dt_atendimento,

    destino.ds_tipo_atendimento = origem.ds_tipo_atendimento,
    destino.ds_status = origem.ds_status,

    destino.vl_item_bruto = origem.vl_item_bruto,
    destino.vl_desconto_item = origem.vl_desconto_item,
    destino.vl_item_liquido = origem.vl_item_liquido


-- ========================================================================================
-- 4. INSERCAO DE NOVOS REGISTROS
-- ========================================================================================

WHEN NOT MATCHED THEN INSERT (

    id_sk_fato_procedimento,
    id_item,
    id_atendimento,

    id_sk_paciente,
    id_sk_procedimento,
    id_sk_unidade,
    id_sk_medico,
    id_sk_data,

    dt_atendimento,

    ds_tipo_atendimento,
    ds_status,

    vl_item_bruto,
    vl_desconto_item,
    vl_item_liquido,

    dt_insercao

)

VALUES (

    origem.id_sk_fato_procedimento,
    origem.id_item,
    origem.id_atendimento,

    origem.id_sk_paciente,
    origem.id_sk_procedimento,
    origem.id_sk_unidade,
    origem.id_sk_medico,
    origem.id_sk_data,

    origem.dt_atendimento,

    origem.ds_tipo_atendimento,
    origem.ds_status,

    origem.vl_item_bruto,
    origem.vl_desconto_item,
    origem.vl_item_liquido,

    CURRENT_TIMESTAMP()

);