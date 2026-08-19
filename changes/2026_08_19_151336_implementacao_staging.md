# Implementação — Camada Staging

## 1. Objetivo

Implementar a camada `staging` do projeto `engenharia_analytics_saude`, responsável pela padronização técnica dos dados provenientes da camada `raw`.

A Staging deverá produzir dados tecnicamente consistentes e preparados para aplicação posterior das regras de negócio e construção do modelo dimensional.

## 2. Origem

As fontes da camada Staging serão exclusivamente as tabelas da camada Raw:

- `raw.raw_atendimentos`
- `raw.raw_procedimentos_itens`
- `raw.raw_cadastro_pacientes`

Nenhum arquivo CSV será acessado diretamente pela Staging.

## 3. Responsabilidade da camada

A Staging será responsável por:

- conversão segura de tipos;
- padronização de strings;
- remoção de espaços desnecessários;
- padronização de nomenclatura conforme VDAE;
- preservação dos identificadores de negócio;
- manutenção da rastreabilidade técnica;
- identificação de conversões inválidas;
- preparação dos dados para a camada Business.

A Staging não deverá aplicar regras de negócio.

## 4. Conversão segura de tipos

Como a camada Raw preserva os campos provenientes da origem como `VARCHAR`, a Staging será responsável pela tipagem.

Serão utilizadas funções seguras do Snowflake, principalmente:

- `TRY_TO_TIMESTAMP`
- `TRY_TO_DECIMAL`
- `TRY_TO_NUMBER`

Conversões inválidas deverão resultar em `NULL`, permitindo posterior identificação por controles de qualidade sem interromper o pipeline.

## 5. Padronização textual

Campos descritivos deverão seguir a convenção VDAE:

`UPPER(TRIM(campo))`

Exemplos:

- tipo de atendimento;
- status;
- nome do paciente;
- plano de saúde;
- cidade;
- nome do procedimento.

A camada Raw permanecerá inalterada.

## 6. Padronização de nomenclatura

A Staging adotará nomenclatura semântica conforme o VDAE.

Exemplos:

- `data_hora_atendimento` → `dt_atendimento`
- `tipo_atendimento` → `ds_tipo_atendimento`
- `status` → `ds_status`
- `valor_bruto` → `vl_bruto`
- `desconto` → `vl_desconto`
- `valor_liquido` → `vl_liquido`
- `codigo_procedimento` → `cd_procedimento`
- `nome_procedimento` → `ds_procedimento`
- `valor_item` → `vl_item`
- `nome` → `ds_nome`
- `plano_saude` → `ds_plano_saude`
- `cidade` → `ds_cidade`
- `data_atualizacao` → `dt_atualizacao`

## 7. Granularidade

### stg_atendimentos

`1 linha = 1 atendimento recebido e tecnicamente tratado`

### stg_procedimentos_itens

`1 linha = 1 procedimento/item recebido e tecnicamente tratado`

### stg_cadastro_pacientes

`1 linha = 1 versão cadastral de paciente tecnicamente tratada`

Nenhuma agregação será realizada na Staging.

## 8. Regras que não pertencem à Staging

Não serão implementados nesta camada:

- SCD Tipo 2;
- geração das Surrogate Keys dimensionais;
- Default Member;
- rateio proporcional de desconto;
- definição de faturamento por status;
- agregações analíticas;
- regras específicas de negócio;
- construção das tabelas fato e dimensão.

Essas responsabilidades pertencem à camada Business.

## 9. Rastreabilidade

Os metadados provenientes da Raw serão preservados quando necessários:

- `ds_arquivo_origem`
- `nr_linha_origem`

A coluna `dt_insercao` será gerada para representar o momento de materialização do registro na Staging e permanecerá como última coluna, conforme o padrão VDAE.

## 10. Qualidade de Dados

A Staging permitirá detectar problemas como:

- timestamps inválidos;
- valores monetários inválidos;
- identificadores ausentes;
- valores textuais vazios ou inconsistentes;
- falhas de conversão.

Os testes formais e evidências de Data Quality serão implementados na estrutura `05_qualidade_dados`.

## 11. Objetos previstos

Serão criadas como `VIEW` no schema `staging`:

- `stg_atendimentos`
- `stg_procedimentos_itens`
- `stg_cadastro_pacientes`

A utilização de Views foi escolhida porque a camada Staging realizará transformações técnicas leves, sem agregações ou regras de negócio complexas.

Essa abordagem evita armazenamento adicional e processos de atualização desnecessários, mantendo os dados da Staging sincronizados com a camada Raw no momento da consulta.

Foram avaliadas as alternativas de tabelas físicas e Dynamic Tables. A materialização não foi adotada nesta etapa por não existir requisito de performance ou volume que justifique seu custo e complexidade operacional.

Caso o volume de dados, a complexidade das transformações ou os requisitos de latência aumentem, a utilização de Dynamic Tables poderá ser reavaliada.

## 12. Critérios de validação

A implementação será considerada válida quando:

- as três estruturas Staging forem criadas;
- a volumetria for reconciliada com a Raw;
- os tipos de dados estiverem corretamente convertidos;
- os textos estiverem padronizados;
- os metadados de rastreabilidade estiverem disponíveis;
- nenhuma regra de negócio tiver sido aplicada;
- conversões inválidas puderem ser identificadas;
- `dt_insercao` estiver presente como última coluna;
- os scripts estiverem versionados no Git.

## 13. Alinhamento VDAE

A implementação segue os princípios do VDAE para a camada Staging:

- tipagem segura;
- padronização textual;
- nomenclatura semântica;
- separação entre transformação técnica e regra de negócio;
- granularidade explicitamente documentada;
- rastreabilidade;
- qualidade de dados incorporada ao pipeline;
- documentação da mudança antes da implementação.

## 14. Resultado da Implementação

A implementação da camada Staging foi concluída e validada com sucesso no ambiente `dev`.

### Objetos implementados

Foram criadas como `VIEW` no schema `staging`:

- `stg_atendimentos`;
- `stg_procedimentos_itens`;
- `stg_cadastro_pacientes`.

### Estratégia de materialização

As estruturas foram implementadas como Views.

A decisão considerou que as transformações realizadas nesta camada são predominantemente técnicas e de baixa complexidade, incluindo:

- conversão segura de tipos;
- padronização textual;
- renomeação semântica;
- preservação de chaves naturais;
- preservação de metadados de rastreabilidade.

Não foi identificada necessidade de materialização física nesta etapa.

Tabelas físicas e Dynamic Tables foram avaliadas, mas não adotadas por adicionarem armazenamento, processamento ou complexidade operacional sem benefício comprovado para o cenário atual.

Essa decisão poderá ser reavaliada caso o volume, a complexidade das transformações ou os requisitos de latência aumentem.

### Reconciliação de volumetria

A volumetria entre Raw e Staging foi reconciliada:

| Objeto | Raw | Staging |
|---|---:|---:|
| atendimentos | 60 | 60 |
| procedimentos_itens | 155 | 155 |
| cadastro_pacientes | 13 | 13 |

Nenhum registro foi eliminado ou agregado durante o tratamento técnico.

### Validação das conversões

As conversões técnicas foram realizadas utilizando funções seguras `TRY_TO_*`.

As validações executadas não identificaram valores inválidos nos campos críticos avaliados.

A estratégia permite que eventuais erros futuros de conversão sejam representados como `NULL` e posteriormente identificados pelos controles formais de Data Quality, sem provocar falha completa do pipeline.

### Histórico cadastral

O histórico cadastral dos pacientes foi preservado integralmente na Staging.

Foram identificados pacientes com múltiplas versões:

| Paciente | Quantidade de versões |
|---|---:|
| PAC_001 | 2 |
| PAC_002 | 2 |
| PAC_006 | 2 |

Nenhuma deduplicação ou regra de vigência foi aplicada nesta camada.

Essas versões serão utilizadas posteriormente pela camada Business para implementação da dimensão de pacientes utilizando SCD Tipo 2.

### Separação de responsabilidades

A Staging permaneceu restrita às transformações técnicas.

Não foram implementados nesta camada:

- SCD Tipo 2;
- Surrogate Keys;
- Default Members;
- rateio de desconto;
- regras de faturamento;
- agregações;
- regras de negócio.

Essas responsabilidades permanecem destinadas à camada Business.

### Status

Camada Staging implementada, reconciliada e validada em ambiente `dev`.