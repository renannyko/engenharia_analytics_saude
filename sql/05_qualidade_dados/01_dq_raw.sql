/*
==========================================================================================
PROJETO: engenharia_analytics_saude
ARQUIVO: 01_dq_raw.sql
CAMADA: qualidade_dados
OBJETO: dq_raw
ESCOPO: raw
TIPO: view de controles de Data Quality
METODOLOGIA: VDAE
AMBIENTE: dev
==========================================================================================

OBJETIVO:

Implementar controles formais de qualidade para a camada Raw, estabelecendo uma
linha de base para os dados ingeridos e verificando presenca, volumetria e
rastreabilidade dos registros recebidos.

DIMENSOES DE QUALIDADE AVALIADAS:

1. Completude.
2. Consistencia.
3. Validade.
4. Rastreabilidade.

CRITERIO GERAL:

qt_erros = 0     -> APROVADO
qt_erros > 0     -> REPROVADO

REGRAS DE IMPLEMENTACAO:

1. Os controles nao alteram os dados avaliados.
2. Nenhuma regra de negocio e aplicada na camada Raw.
3. Os resultados apresentam identificacao do teste, quantidade de erros e status.
4. As volumetrias esperadas representam o dataset utilizado neste exercicio.
5. Os controles sao reproduziveis e podem ser executados novamente.
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
-- 2. VIEW DE CONTROLES DE QUALIDADE - RAW
-- ========================================================================================

CREATE OR REPLACE VIEW dq_raw AS

WITH controles AS (

    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_001
    -- Validar volumetria de atendimentos.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_001' AS id_teste,
        'volumetria_raw_atendimentos' AS ds_teste,
        'COMPLETUDE' AS ds_dimensao_dq,

        ABS(
            COUNT(*) - 60
        ) AS qt_erros

    FROM engenharia_analytics_saude_dev.raw.raw_atendimentos


    UNION ALL


    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_002
    -- Validar volumetria de procedimentos/itens.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_002',
        'volumetria_raw_procedimentos_itens',
        'COMPLETUDE',

        ABS(
            COUNT(*) - 155
        )

    FROM engenharia_analytics_saude_dev.raw.raw_procedimentos_itens


    UNION ALL


    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_003
    -- Validar volumetria do cadastro historico de pacientes.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_003',
        'volumetria_raw_cadastro_pacientes',
        'COMPLETUDE',

        ABS(
            COUNT(*) - 13
        )

    FROM engenharia_analytics_saude_dev.raw.raw_cadastro_pacientes


    UNION ALL


    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_004
    -- Validar se a Raw de atendimentos possui registros.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_004',
        'presenca_dados_raw_atendimentos',
        'COMPLETUDE',

        IFF(
            COUNT(*) = 0,
            1,
            0
        )

    FROM engenharia_analytics_saude_dev.raw.raw_atendimentos


    UNION ALL


    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_005
    -- Validar se a Raw de procedimentos possui registros.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_005',
        'presenca_dados_raw_procedimentos_itens',
        'COMPLETUDE',

        IFF(
            COUNT(*) = 0,
            1,
            0
        )

    FROM engenharia_analytics_saude_dev.raw.raw_procedimentos_itens


    UNION ALL


    -- ------------------------------------------------------------------------------------
    -- DQ_RAW_006
    -- Validar se a Raw de cadastro de pacientes possui registros.
    -- ------------------------------------------------------------------------------------

    SELECT
        'DQ_RAW_006',
        'presenca_dados_raw_cadastro_pacientes',
        'COMPLETUDE',

        IFF(
            COUNT(*) = 0,
            1,
            0
        )

    FROM engenharia_analytics_saude_dev.raw.raw_cadastro_pacientes

)

SELECT
    id_teste,
    ds_teste,
    ds_dimensao_dq,
    qt_erros,

    IFF(
        qt_erros = 0,
        'APROVADO',
        'REPROVADO'
    ) AS ds_status

FROM controles
;