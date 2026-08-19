# Engenharia de Analytics em Saúde

## Visão Geral

Este projeto implementa uma arquitetura de Analytics Engineering para uma rede integrada de saúde e medicina diagnóstica utilizando Snowflake como Cloud Data Warehouse.

O objetivo é transformar dados brutos provenientes de sistemas de atendimento, procedimentos e cadastro de pacientes em estruturas analíticas governadas, confiáveis e eficientes para consumo por áreas de negócio e ferramentas de Business Intelligence.

O desenvolvimento segue os princípios da metodologia **VDAE (Value-Driven Analytics Engineering)**, com práticas de modelagem dimensional, qualidade de dados, governança, FinOps e CI/CD.

## Arquitetura

O fluxo principal de dados segue a arquitetura:

`arquivos csv → raw → staging → business → information`

A camada `qualidade_dados` é responsável pelos controles de qualidade aplicados ao pipeline.

### Raw

Preservação dos dados provenientes dos arquivos de origem.

### Staging

Limpeza técnica, tipagem, padronização e tratamento dos dados antes da aplicação das regras de negócio.

### Business

Aplicação das regras corporativas e construção do modelo dimensional, incluindo dimensões, fatos, surrogate keys e histórico de alterações cadastrais.

### Information

Disponibilização de estruturas orientadas ao consumo analítico e ferramentas de BI.

### Qualidade de Dados

Implementação de controles de qualidade baseados nas dimensões de Data Quality definidas pelo DAMA e adotadas pela metodologia VDAE.

## Tecnologias

* Snowflake
* SQL
* Git
* GitHub
* Visual Studio Code
* GitHub Actions

## Estrutura do Projeto

```text
engenharia_analytics_saude/
├── .github/
│   └── workflows/
├── changes/
├── dados/
├── documentacao/
├── scripts/
├── tmp_changes/
├── sql/
│   ├── 00_configuracao/
│   ├── 01_raw/
│   ├── 02_staging/
│   ├── 03_business/
│   ├── 04_information/
│   └── 05_qualidade_dados/
├── .gitignore
└── README.md
```

## Ambientes Snowflake

Database de desenvolvimento:

`engenharia_analytics_saude_dev`

Virtual Warehouses:

* `wh_transformacao_dev` — ingestão e transformação dos dados.
* `wh_bi_dev` — consultas analíticas e consumo de BI.

Os warehouses utilizam inicialmente tamanho `X-Small`, `AUTO_SUSPEND = 60` e `AUTO_RESUME = TRUE`, permitindo isolamento das cargas de trabalho e controle de custos.

## Governança

O projeto utiliza uma role específica:

`role_engenharia_analytics`

A utilização cotidiana de roles administrativas como `ACCOUNTADMIN` é evitada, seguindo o princípio de menor privilégio.

Alterações estruturais são documentadas previamente em `tmp_changes/` e, após implementação e validação, promovidas para `changes/`.

## Status

🚧 Projeto em desenvolvimento.
