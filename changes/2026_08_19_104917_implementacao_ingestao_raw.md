# Implementação — Ingestão da Camada Raw

## 1. Objetivo

Implementar a ingestão dos arquivos CSV fornecidos para o desafio, preservando os dados de origem na camada `raw` do Snowflake antes da aplicação de transformações técnicas ou regras de negócio.

A implementação seguirá os princípios da metodologia VDAE, com adaptações específicas para os recursos disponíveis no Snowflake.

## 2. Arquivos de origem

Serão ingeridos os seguintes arquivos:

* `raw_atendimentos.csv`
* `raw_procedimentos_itens.csv`
* `raw_cadastro_pacientes.csv`

Os arquivos permanecerão armazenados localmente e não serão versionados no Git.

## 3. Granularidade identificada

### raw_atendimentos

Granularidade:

`1 linha = 1 atendimento`

Chave natural identificada:

`id_atendimento`

### raw_procedimentos_itens

Granularidade:

`1 linha = 1 procedimento realizado dentro de um atendimento`

Chave natural identificada:

`id_item`

Relacionamento com atendimento:

`id_atendimento`

### raw_cadastro_pacientes

Granularidade:

`1 linha = 1 versão cadastral de um paciente em determinado momento`

Chave natural de negócio:

`id_paciente`

Como o mesmo paciente pode possuir múltiplas versões cadastrais, `id_paciente` não é único neste arquivo.

A coluna `data_atualizacao` representa o momento da versão cadastral e será utilizada posteriormente na implementação do SCD Tipo 2.

## 4. Profiling inicial

O profiling dos arquivos identificou que os dados possuem boa integridade técnica básica, sem necessidade de alteração manual dos arquivos de origem.

Foram identificados, entretanto, cenários relevantes para tratamento nas camadas posteriores.

### Histórico cadastral anterior incompleto

Existem atendimentos cuja data é anterior à primeira versão cadastral disponível do respectivo paciente.

Foram identificados 10 atendimentos nessa condição.

Esse cenário será tratado posteriormente na camada `business`, considerando a estratégia de Default Member prevista pelo VDAE para fatos que não possuem correspondência dimensional válida.

### Atendimentos não concluídos com valores financeiros

Existem atendimentos com status `Cancelado` e `Em Andamento` que possuem valores financeiros preenchidos.

A existência desses valores não será considerada automaticamente um erro, pois o dataset não fornece uma regra de negócio determinando quais status devem ou não compor faturamento.

Nenhuma regra será criada sem evidência de negócio.

### Histórico cadastral

Existem pacientes com múltiplos registros cadastrais e alterações de atributos como plano de saúde e cidade.

Esse histórico será utilizado posteriormente na implementação da dimensão de pacientes com SCD Tipo 2.

## 5. Estratégia de ingestão

O fluxo será:

`arquivo csv local → internal stage → tabela raw`

Será criado um `FILE FORMAT` específico para os arquivos CSV e um `INTERNAL STAGE` para recebimento dos arquivos locais.

Os arquivos não serão alterados antes da ingestão.

## 6. Estratégia de tipagem da Raw

As tabelas da camada `raw` utilizarão uma estratégia permissiva de ingestão.

Os campos provenientes dos arquivos serão inicialmente armazenados como `VARCHAR`, preservando o conteúdo recebido da origem.

A conversão para tipos de dados de negócio será realizada posteriormente na camada `staging`.

Essa abordagem permite que valores inesperados ou inválidos sejam capturados na camada Raw sem interromper desnecessariamente a ingestão.

## 7. Tratamento na Staging

A camada `staging` será responsável posteriormente por:

* conversão segura de tipos;
* padronização de strings;
* tratamento de espaços;
* aplicação da nomenclatura VDAE;
* identificação de valores inválidos;
* preparação dos dados para aplicação das regras de negócio.

No Snowflake, funções da família `TRY_TO_*` serão utilizadas como equivalente conceitual ao `SAFE_CAST` previsto pelo VDAE.

Exemplos:

* `TRY_TO_DECIMAL`
* `TRY_TO_NUMBER`
* `TRY_TO_TIMESTAMP`

Valores textuais deverão seguir a padronização definida pelo VDAE, incluindo `UPPER(TRIM(...))` quando aplicável.

## 8. Objetos previstos

### File Format

Será criado um objeto para leitura padronizada dos arquivos CSV.

Nome previsto:

`ff_csv_saude`

### Internal Stage

Será criado um stage interno para recebimento dos arquivos.

Nome previsto:

`stg_arquivos_saude`

### Tabelas Raw

Serão criadas:

* `raw_atendimentos`
* `raw_procedimentos_itens`
* `raw_cadastro_pacientes`

Todos os objetos de ingestão serão criados no schema:

`engenharia_analytics_saude_dev.raw`

## 9. Rastreabilidade

Além das colunas provenientes da origem, será avaliada a inclusão de metadados técnicos de ingestão que permitam identificar a procedência e o momento de carga dos registros.

Esses campos deverão ser técnicos e não deverão alterar o conteúdo original recebido.

## 10. Critérios de validação

A implementação será considerada válida quando:

* o File Format estiver criado;
* o Internal Stage estiver criado;
* os três arquivos estiverem disponíveis no stage;
* as três tabelas Raw estiverem criadas;
* todos os registros dos arquivos forem carregados;
* a quantidade de registros carregados for reconciliada com os arquivos de origem;
* os dados originais permanecerem preservados;
* nenhuma correção manual tiver sido realizada nos CSVs;
* problemas de qualidade identificados permanecerem rastreáveis para tratamento posterior;
* os scripts SQL estiverem versionados no Git.

## 11. Alinhamento VDAE

A implementação preserva os seguintes princípios da metodologia VDAE:

* preservação da origem;
* separação entre ingestão e transformação;
* tratamento técnico na Staging;
* rastreabilidade;
* granularidade explicitamente documentada;
* qualidade de dados como parte da arquitetura;
* mudanças documentadas antes da implementação;
* código versionado em Git.

### Adaptação para Snowflake

No VDAE original, fontes externas são declaradas na camada `0_sources`.

Neste projeto, os arquivos CSV serão fisicamente carregados no Snowflake e preservados em tabelas no schema `raw`.

Dessa forma, a camada `raw` funciona como a representação persistida das fontes dentro da arquitetura Snowflake.


## 12. Resultado da Implementação

A implementação da camada Raw foi concluída e validada com sucesso.

### Objetos criados

Foram criados no schema `raw`:

- `ff_csv_saude` — File Format para leitura dos arquivos CSV;
- `stg_arquivos_saude` — Internal Stage para recebimento dos arquivos locais;
- `raw_atendimentos`;
- `raw_procedimentos_itens`;
- `raw_cadastro_pacientes`.

### Volumetria validada

A reconciliação entre os arquivos de origem e as tabelas Raw apresentou:

| Tabela | Registros |
|---|---:|
| raw_atendimentos | 60 |
| raw_procedimentos_itens | 155 |
| raw_cadastro_pacientes | 13 |

Todos os registros esperados foram carregados.

### Rastreabilidade

Foram adicionados às tabelas Raw os seguintes metadados técnicos:

- `ds_arquivo_origem`;
- `nr_linha_origem`;
- `dt_insercao`.

A validação confirmou que os registros podem ser rastreados até seus respectivos arquivos de origem.

O comportamento observado do `METADATA$FILE_ROW_NUMBER` para os arquivos utilizados resultou na numeração dos registros de dados iniciando em `1` após a aplicação do `SKIP_HEADER = 1`.

### Ocorrência identificada durante a implementação

Durante a primeira tentativa de leitura, os arquivos carregados no Internal Stage possuíam o sufixo ` 1` em seus nomes físicos.

Exemplo:

`raw_atendimentos 1.csv`

Enquanto o pipeline esperava:

`raw_atendimentos.csv`

As validações intermediárias permitiram identificar que:

- o Internal Stage estava acessível;
- os arquivos estavam presentes;
- as tabelas Raw estavam vazias;
- o caminho utilizado pelo pipeline não correspondia ao nome físico armazenado no stage.

Os arquivos foram padronizados para nomenclatura `lowercase` e `snake_case`, sem espaços, e reenviados ao stage.

Após a correção, a carga foi executada e reconciliada com sucesso.

### Status

Implementação concluída e validada em ambiente `dev`.