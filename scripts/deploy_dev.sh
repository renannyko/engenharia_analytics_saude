#!/usr/bin/env bash

# ========================================================================================
# PROJETO: engenharia_analytics_saude
# ARQUIVO: deploy_dev.sh
# AMBIENTE: dev
#
# OBJETIVO:
#   Executar sequencialmente os scripts SQL definidos no manifesto de deployment
#   do ambiente DEV.
#
# RESPONSABILIDADES:
#   - ler o arquivo deploy/dev_manifest.txt;
#   - ignorar comentários e linhas vazias;
#   - validar a existência de cada script;
#   - executar os scripts na ordem definida;
#   - interromper imediatamente em caso de falha;
#   - fornecer rastreabilidade no log do GitHub Actions.
#
# PRE-REQUISITOS:
#   - Snowflake CLI instalada;
#   - autenticação OIDC configurada;
#   - variáveis SNOWFLAKE_* disponíveis no ambiente;
#   - manifesto deploy/dev_manifest.txt disponível.
#
# OBSERVAÇÃO:
#   Este script não executa ingestão de arquivos CSV locais.
# ========================================================================================


set -euo pipefail


# ========================================================================================
# 1. CONFIGURAÇÃO
# ========================================================================================

MANIFEST_FILE="deploy/dev_manifest.txt"


# ========================================================================================
# 2. VALIDAR MANIFESTO
# ========================================================================================

echo "============================================================"
echo "DEPLOY SNOWFLAKE - DEV"
echo "============================================================"
echo

echo "Validando manifesto de deploy..."

if [[ ! -f "${MANIFEST_FILE}" ]]; then
    echo "ERRO: manifesto não encontrado: ${MANIFEST_FILE}"
    exit 1
fi

echo "Manifesto encontrado: ${MANIFEST_FILE}"
echo


# ========================================================================================
# 3. EXECUTAR SCRIPTS
# ========================================================================================

QT_EXECUTADOS=0

while IFS= read -r SCRIPT_SQL || [[ -n "${SCRIPT_SQL}" ]]
do

    # Remove espaços no início e no final.
    SCRIPT_SQL="$(echo "${SCRIPT_SQL}" | xargs)"

    # Ignora linhas vazias.
    if [[ -z "${SCRIPT_SQL}" ]]; then
        continue
    fi

    # Ignora comentários do manifesto.
    if [[ "${SCRIPT_SQL}" == \#* ]]; then
        continue
    fi

    echo "------------------------------------------------------------"
    echo "Executando:"
    echo "${SCRIPT_SQL}"
    echo "------------------------------------------------------------"

    if [[ ! -f "${SCRIPT_SQL}" ]]; then
        echo "ERRO: arquivo SQL não encontrado."
        echo "Arquivo: ${SCRIPT_SQL}"
        exit 1
    fi

    snow sql \
        -f "${SCRIPT_SQL}" \
        -x

    QT_EXECUTADOS=$((QT_EXECUTADOS + 1))

    echo
    echo "Script concluído com sucesso: ${SCRIPT_SQL}"
    echo

done < "${MANIFEST_FILE}"


# ========================================================================================
# 4. VALIDAR QUANTIDADE EXECUTADA
# ========================================================================================

if [[ "${QT_EXECUTADOS}" -eq 0 ]]; then
    echo "ERRO: nenhum script foi executado."
    exit 1
fi


# ========================================================================================
# 5. RESULTADO
# ========================================================================================

echo "============================================================"
echo "DEPLOY DEV CONCLUÍDO"
echo "============================================================"
echo "Scripts executados: ${QT_EXECUTADOS}"
echo "Status: SUCESSO"
echo "============================================================"