# Execução do Projeto

## 1. Objetivo

Este documento apresenta a sequência operacional do projeto
`engenharia_analytics_saude`.

Seu objetivo é permitir que um desenvolvedor compreenda:

- os pré-requisitos;
- a arquitetura de execução;
- a ordem dos scripts;
- as dependências entre as camadas;
- os Warehouses utilizados;
- os pontos de validação;
- a execução dos controles de Data Quality.

A execução segue a arquitetura:

Fonte
    ↓
Internal Stage
    ↓
Raw
    ↓
Staging
    ↓
Business
    ↓
Information
    ↓
Consumo Analítico

com controles de Data Quality aplicados ao longo do pipeline.


## 2. Pré-requisitos

Para executar o projeto são necessários:

- acesso a uma conta Snowflake;
- privilégios para criação e utilização dos objetos necessários;
- acesso à role utilizada pelo projeto;
- arquivos CSV utilizados como fonte;
- repositório do projeto disponível localmente;
- Git para versionamento;
- cliente SQL compatível com Snowflake ou interface Snowsight.

O projeto foi desenvolvido utilizando:

- Snowflake;
- SQL;
- Git;
- GitHub;
- VSCode.


## 3. Ambiente

O ambiente principal de desenvolvimento utiliza o database:

`engenharia_analytics_saude_dev`

Os objetos são organizados por schemas conforme suas responsabilidades.


## 4. Schemas

A arquitetura utiliza principalmente:

`raw`

Responsável pela persistência inicial dos dados.

`staging`

Responsável pela preparação técnica.

`business`

Responsável pelas regras de negócio e modelo dimensional.

`information`

Responsável pelos produtos de dados destinados ao consumo analítico.

`qualidade_dados`

Responsável pelos controles formais de Data Quality.


## 5. Warehouses

O projeto utiliza dois Virtual Warehouses.

### Transformação

`wh_transformacao_dev`

Utilizado para:

- ingestão;
- transformação;
- modelagem;
- processamento incremental;
- Data Quality.


### BI

`wh_bi_dev`

Utilizado para:

- consultas analíticas;
- consumo da camada Information;
- workloads de BI.

Ambos foram configurados inicialmente como X-Small, com suspensão e retomada
automáticas.


## 6. Role

A execução regular utiliza:

`role_engenharia_analytics`

Atividades administrativas de setup podem exigir uma role administrativa apropriada.

`ACCOUNTADMIN` foi utilizado durante o desenvolvimento apenas quando necessário
para atividades administrativas.

A execução cotidiana não deve depender de `ACCOUNTADMIN`.


## 7. Contexto dos Scripts

Os scripts devem estabelecer explicitamente o contexto necessário para execução.

Exemplo conceitual:

USE ROLE role_engenharia_analytics;

USE WAREHOUSE wh_transformacao_dev;

USE DATABASE engenharia_analytics_saude_dev;

USE SCHEMA <schema>;

Isso reduz dependência do estado anterior da sessão.


## 8. Estrutura Geral do Repositório

O projeto está organizado conceitualmente em:

sql/
documentacao/
changes/
tmp_changes/

### `sql`

Contém os scripts responsáveis pela implementação técnica.

### `documentacao`

Contém a documentação arquitetural e operacional.

### `changes`

Contém registros de mudanças concluídas e validadas.

### `tmp_changes`

Contém registros de mudanças ainda em desenvolvimento.


## 9. Ordem Geral de Execução

A execução deve respeitar as dependências entre as camadas.

Ordem lógica:

1. Setup
2. Ingestão
3. Staging
4. Business
5. Information
6. Data Quality

Representação:

Setup
  ↓
Ingestão
  ↓
Raw
  ↓
Staging
  ↓
Business
  ↓
Information
  ↓
Data Quality Consolidado


## 10. Etapa 1 — Setup

A primeira etapa prepara a infraestrutura necessária para o projeto.

Entre os objetos configurados estão:

- database;
- schemas;
- Warehouses;
- Internal Stage;
- roles e privilégios necessários.

O setup deve ser executado antes dos scripts que dependem desses objetos.


## 11. Validação do Setup

Antes de continuar, deve ser confirmado que:

- o database existe;
- os schemas existem;
- os Warehouses existem;
- o Internal Stage está disponível;
- a role possui os privilégios necessários.

Falhas nessa etapa devem ser resolvidas antes da ingestão.


## 12. Etapa 2 — Disponibilização dos Arquivos

Os arquivos CSV utilizados como origem devem ser disponibilizados no Internal Stage.

Fluxo:

CSV local
    ↓
upload
    ↓
Internal Stage

A presença dos arquivos deve ser confirmada antes da execução do `COPY INTO`.


## 13. Etapa 3 — Raw

Após a disponibilização dos arquivos, os dados são ingeridos para a camada Raw.

Fluxo:

Internal Stage
    ↓
COPY INTO
    ↓
tabelas Raw

A Raw deve preservar os dados recebidos com o mínimo possível de transformação.


## 14. Validação da Raw

Após a ingestão, devem ser verificadas:

- existência dos registros;
- volumetria das fontes;
- disponibilidade das três estruturas esperadas.

A Raw estabelece a linha de base utilizada pelas etapas seguintes.


## 15. Etapa 4 — Staging

A Staging prepara tecnicamente os dados da Raw.

Entre as responsabilidades estão:

- conversão de tipos;
- padronização;
- tratamento técnico;
- preparação para regras de negócio.

A Staging deve preservar a granularidade correspondente da Raw.


## 16. Validação da Staging

Após a criação das estruturas, devem ser verificadas:

- volumetria Raw versus Staging;
- tipos convertidos;
- campos críticos;
- unicidade das chaves esperadas;
- preservação do histórico cadastral.

As validações exploratórias utilizadas durante o desenvolvimento não precisam fazer
parte dos scripts finais de criação dos objetos.


## 17. Etapa 5 — Business

A Business implementa o modelo dimensional e as regras de negócio.

Os principais objetos são:

- `dim_paciente`;
- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`;
- `fct_procedimentos`.


## 18. Ordem das Dimensões

As dimensões devem existir antes da carga da fato.

Ordem conceitual:

Staging
    ↓
Dimensões
    ↓
Fato

Isso ocorre porque a fato depende das Surrogate Keys dimensionais.


## 19. `dim_paciente`

A `dim_paciente` utiliza SCD Tipo 2.

A execução deve preservar:

- versões históricas;
- início de vigência;
- fim de vigência;
- indicador de versão atual;
- Surrogate Keys independentes por versão.

O relacionamento histórico depende da data do atendimento.


## 20. Demais Dimensões

Também são construídas:

- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`.

Essas dimensões utilizam Surrogate Keys e possuem Default Members.


## 21. Default Members

Os Default Members devem estar disponíveis antes do processamento da fato.

A chave natural reservada é:

`-1`

Sua finalidade é permitir uma referência dimensional controlada quando não existe
correspondência válida para determinado evento.


## 22. Criação da Fato

A estrutura da:

`fct_procedimentos`

é criada separadamente da lógica de processamento incremental.

Essa separação é intencional.

A criação física representa uma responsabilidade de estrutura.

A carga representa uma responsabilidade operacional recorrente.


## 23. Grão da Fato

Antes de qualquer carga deve ser preservada a definição:

**1 linha por `id_item`.**

`id_atendimento` não representa o grão da fato.

Um atendimento pode possuir vários itens.


## 24. Carga Incremental

Após a existência da estrutura da fato, a lógica incremental pode ser executada.

O processamento deve:

- identificar os registros da origem;
- resolver as Surrogate Keys;
- considerar a vigência da `dim_paciente`;
- tratar Default Members;
- preservar Late Arriving Dimensions;
- calcular métricas no nível do item;
- evitar duplicação do grão.


## 25. Late Arriving Dimension

O dataset contém 10 atendimentos cujo paciente não possui correspondência dimensional
disponível.

Nesses casos:

paciente não encontrado
    ↓
Default Member
    ↓
registro preservado

Esses registros não devem ser eliminados do processamento.


## 26. Métricas Financeiras

A fato possui métricas financeiras no nível do item.

Entre elas:

- `vl_item_bruto`;
- `vl_desconto_item`;
- `vl_item_liquido`.

A regra fundamental é:

`vl_item_bruto - vl_desconto_item = vl_item_liquido`

Os valores distribuídos devem continuar reconciliados com os valores originais do
atendimento.


## 27. Validação da Business

Após o processamento, devem ser validados:

- dimensões;
- Surrogate Keys;
- SCD Tipo 2;
- Default Members;
- grão da fato;
- integridade referencial;
- Late Arriving Dimensions;
- métricas financeiras;
- reconciliação.


## 28. Etapa 6 — Information

Após a Business estar válida, são disponibilizados os produtos analíticos da camada
Information.

Foram implementados:

`vw_analise_procedimentos`

e:

`agg_faturamento_mensal_unidade`


## 29. `vw_analise_procedimentos`

A View detalhada preserva o grão:

**1 linha por `id_item`.**

Ela combina atributos dimensionais e métricas para facilitar consumo analítico.

Sua volumetria deve permanecer reconciliada com a fato.


## 30. `agg_faturamento_mensal_unidade`

Esse produto possui granularidade agregada.

Seu objetivo é disponibilizar métricas mensais por unidade.

As métricas financeiras agregadas devem permanecer reconciliadas com a camada
Business.


## 31. Etapa 7 — Data Quality

Após a implementação das camadas, devem ser criados os objetos formais de Data
Quality.

Os scripts estão organizados em:

`sql/05_qualidade_dados/`

A ordem é:

1. `01_dq_raw.sql`
2. `02_dq_staging.sql`
3. `03_dq_business_dimensoes.sql`
4. `04_dq_business_scd2.sql`
5. `05_dq_business_fato.sql`
6. `06_dq_reconciliacao_financeira.sql`
7. `07_dq_information.sql`
8. `08_dq_resumo_qualidade.sql`


## 32. Dependência dos Objetos de Data Quality

Os sete primeiros objetos validam diferentes partes da arquitetura.

O:

`08_dq_resumo_qualidade.sql`

depende dos objetos anteriores.

Portanto, deve ser executado por último.


## 33. Consulta Consolidada

Após a criação dos objetos, o resultado consolidado pode ser consultado por:

SELECT *
FROM engenharia_analytics_saude_dev.qualidade_dados.dq_resumo_qualidade
ORDER BY ds_escopo;


## 34. Resultado Esperado

O estado validado do projeto possui:

| Escopo | Testes |
|---|---:|
| Raw | 6 |
| Staging | 11 |
| Business — Dimensões | 19 |
| Business — SCD Tipo 2 | 10 |
| Business — Fato | 16 |
| Reconciliação Financeira | 7 |
| Information | 11 |
| **Total** | **80** |

Resultado esperado:

- 80 testes executados;
- 80 aprovados;
- 0 reprovados.


## 35. Critério de Aceite

A execução pode ser considerada tecnicamente válida quando:

- os objetos esperados existem;
- as camadas foram processadas na ordem correta;
- o grão da fato está preservado;
- a integridade referencial está válida;
- o histórico SCD Tipo 2 está consistente;
- as métricas financeiras estão reconciliadas;
- a camada Information está reconciliada;
- os 80 controles de Data Quality estão aprovados.


## 36. Tratamento de Falhas

Caso algum teste apresente:

`REPROVADO`

a recomendação é não alterar imediatamente o teste.

Primeiro deve ser identificado:

1. qual `id_teste` falhou;
2. qual dimensão de qualidade foi afetada;
3. qual camada originou o problema;
4. quais registros contribuíram para `qt_erros`;
5. se existe uma regra de negócio conhecida que explique o resultado.


## 37. Investigação pela Camada

A arquitetura facilita localizar a origem de problemas.

Exemplo:

erro em Raw
    ↓
investigar ingestão ou fonte

erro em Staging
    ↓
investigar preparação técnica

erro em dimensão
    ↓
investigar modelagem

erro em SCD2
    ↓
investigar histórico

erro em fato
    ↓
investigar relacionamentos ou grão

erro financeiro
    ↓
investigar distribuição ou reconciliação

erro em Information
    ↓
investigar produto analítico


## 38. Reexecução

Os scripts devem ser executados respeitando suas responsabilidades.

Nem todo objeto deve necessariamente ser recriado para corrigir um problema em uma
etapa posterior.

A separação entre estrutura e processamento facilita reexecuções controladas.


## 39. Versionamento

Após uma alteração validada:

git status

git add .

git commit -m "<descricao_da_alteracao>"

git push

O commit deve representar uma unidade lógica compreensível de mudança.


## 40. Fluxo VDAE de Mudanças

Durante o desenvolvimento, alterações relevantes são registradas inicialmente em:

`tmp_changes`

Após implementação e validação, o registro correspondente é promovido para:

`changes`

Fluxo:

necessidade
    ↓
tmp_changes
    ↓
implementação
    ↓
validação
    ↓
changes
    ↓
commit


## 41. Ordem Resumida

A execução completa pode ser resumida como:

1. preparar infraestrutura;
2. validar database, schemas, roles e Warehouses;
3. disponibilizar CSVs no Internal Stage;
4. executar ingestão Raw;
5. validar Raw;
6. criar Staging;
7. validar Staging;
8. criar e carregar dimensões;
9. validar dimensões;
10. criar estrutura da fato;
11. executar carga incremental;
12. validar fato e reconciliação;
13. criar produtos Information;
14. validar produtos analíticos;
15. criar Views de Data Quality;
16. criar resumo consolidado;
17. validar 80/80 testes;
18. registrar mudança;
19. promover documentação;
20. realizar commit e push.


## 42. Dependências Resumidas

A relação entre os principais componentes é:

Arquivos CSV
     ↓
Internal Stage
     ↓
Raw
     ↓
Staging
     ↓
Dimensões
     ↓
Fato
     ↓
Information

Raw ──────────────→ DQ Raw
Staging ──────────→ DQ Staging
Dimensões ────────→ DQ Dimensões
dim_paciente ─────→ DQ SCD2
Fato ─────────────→ DQ Fato
Financeiro ───────→ DQ Reconciliação
Information ──────→ DQ Information

Todos
     ↓
dq_resumo_qualidade


## 43. Checklist Operacional

Antes de considerar a execução concluída, verificar:

- [ ] database disponível;
- [ ] schemas disponíveis;
- [ ] Warehouses disponíveis;
- [ ] role configurada;
- [ ] Internal Stage disponível;
- [ ] arquivos carregados;
- [ ] Raw populada;
- [ ] Staging validada;
- [ ] dimensões criadas;
- [ ] Default Members disponíveis;
- [ ] SCD Tipo 2 válido;
- [ ] fato criada;
- [ ] carga incremental executada;
- [ ] `id_item` único;
- [ ] integridade referencial válida;
- [ ] 10 Late Arriving Dimensions preservados;
- [ ] métricas financeiras reconciliadas;
- [ ] Information disponível;
- [ ] objetos `dq_` criados;
- [ ] `dq_resumo_qualidade` disponível;
- [ ] 80 testes aprovados;
- [ ] documentação atualizada;
- [ ] alteração registrada em `changes`;
- [ ] código versionado no Git.


## 44. Evolução para Automação

O processo atual permite evolução para um pipeline automatizado.

Conceitualmente:

Git
 ↓
CI
 ↓
validação SQL
 ↓
deploy DEV
 ↓
Data Quality
 ↓
Quality Gate
 ↓
promoção
 ↓
QA / PROD

A automação deve preservar as mesmas dependências documentadas neste runbook.


## 45. Princípio de Reprodutibilidade

Uma execução reproduzível não depende apenas da existência dos arquivos SQL.

Também exige:

- ordem conhecida;
- dependências documentadas;
- contexto explícito;
- parâmetros conhecidos;
- validações objetivas;
- versionamento;
- critérios de aceite.

Por isso, código, documentação e Data Quality são tratados como partes do mesmo
produto de dados.


## 46. Conclusão

O projeto foi estruturado para permitir execução progressiva e validável desde a
ingestão até o consumo analítico.

A separação entre camadas, a definição explícita das dependências, a distinção entre
criação e processamento incremental e os controles formais de Data Quality tornam a
solução mais reproduzível e preparada para automação futura.

O estado final validado do projeto possui:

`80 / 80 testes de Data Quality aprovados`.