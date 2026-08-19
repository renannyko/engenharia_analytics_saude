# Implementação — Configuração Inicial Snowflake

## 1. Objetivo

Criar a fundação técnica do projeto `engenharia_analytics_saude` no Snowflake, estabelecendo a estrutura necessária para ingestão, transformação, modelagem dimensional, disponibilização de dados e controles de qualidade.

A implementação seguirá os princípios da metodologia VDAE, adaptando ao Snowflake os componentes originalmente definidos para Dataform e BigQuery.

## 2. Objetos previstos

### Database

* `engenharia_analytics_saude_dev`

### Schemas

* `raw`
* `staging`
* `business`
* `information`
* `qualidade_dados`

### Virtual Warehouses

* `wh_transformacao_dev`
* `wh_bi_dev`

### Objetos de ingestão

* file format para arquivos CSV
* internal stage para recebimento dos arquivos locais

## 3. Arquitetura de camadas

O fluxo de dados será:

`csv local → raw → staging → business → information`

A camada `qualidade_dados` será utilizada para implementação e execução de controles de qualidade sobre as diferentes camadas do pipeline.

### Raw

Preservação dos dados provenientes dos arquivos CSV com mínima interferência, permitindo rastreabilidade até a origem.

### Staging

Responsável pelas transformações técnicas, incluindo tipagem, padronização, tratamento de valores inválidos e preparação dos dados para aplicação das regras de negócio.

### Business

Responsável pela modelagem dimensional corporativa, incluindo dimensões, fatos, surrogate keys e implementação de SCD Tipo 2.

### Information

Responsável pela disponibilização de estruturas orientadas ao consumo analítico e ferramentas de BI.

### Qualidade de Dados

Responsável pelas validações de unicidade, completude, validade, acurácia, consistência e tempestividade definidas pela metodologia VDAE e pelo DAMA.

## 4. Estratégia de Compute

Serão utilizados warehouses independentes para isolamento das cargas de trabalho.

### `wh_transformacao_dev`

Destinado às operações de ingestão, transformação, construção das dimensões e fatos e execução dos pipelines de dados.

### `wh_bi_dev`

Destinado às consultas analíticas, exploração dos dados e consumo pelas ferramentas de BI.

A separação permite isolamento de workloads, controle independente de recursos e melhor gestão de custos.

## 5. Estratégia de ingestão

Os arquivos CSV permanecerão preservados localmente e não serão versionados no Git.

A ingestão seguirá o fluxo:

`arquivo csv local → internal stage → tabela raw`

Os dados da camada Raw deverão preservar os valores recebidos da origem sempre que possível.

Problemas de qualidade encontrados nos arquivos não deverão ser corrigidos diretamente nos arquivos de origem.

## 6. Segurança e governança

* Credenciais não poderão ser armazenadas no repositório.
* Arquivos `.env`, chaves e credenciais serão ignorados pelo Git.
* Os CSVs locais não serão enviados ao repositório.
* Alterações estruturais serão realizadas por scripts SQL versionados.
* As implementações deverão possuir rastreabilidade no Git.

## 7. Critérios de validação

A implementação será considerada válida quando:

* o database estiver criado;
* os cinco schemas estiverem disponíveis;
* os warehouses estiverem configurados;
* o file format estiver criado;
* o internal stage estiver criado;
* os objetos puderem ser consultados pelo usuário do projeto;
* os scripts SQL correspondentes estiverem versionados;
* nenhuma credencial ou arquivo de dados estiver exposto no repositório.

## 8. Alinhamento VDAE

A implementação preserva os princípios VDAE de:

* separação clara entre camadas;
* dados brutos preservados antes das transformações;
* transformações técnicas na Staging;
* regras de negócio e modelagem dimensional na Business;
* estruturas de consumo na Information;
* qualidade de dados tratada como componente explícito da arquitetura;
* código e alterações versionados;
* documentação das decisões de arquitetura;
* dados tratados como produto.

### Adaptações para Snowflake

A camada de origem do Dataform é representada por tabelas físicas no schema `raw`, necessárias para persistir os dados provenientes dos arquivos CSV.

Os recursos específicos de BigQuery/Dataform serão substituídos pelos recursos equivalentes do Snowflake, preservando os princípios arquiteturais definidos pelo VDAE.
