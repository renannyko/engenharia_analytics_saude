# Engenharia Analytics Saúde

Projeto de Analytics Engineering desenvolvido em Snowflake para implementar um pipeline analítico completo a partir de dados de atendimentos de saúde.

A solução cobre o ciclo desde a ingestão de arquivos CSV até a disponibilização de produtos analíticos, incluindo modelagem dimensional, processamento incremental, qualidade de dados, governança, FinOps e CI/CD.

O projeto foi desenvolvido seguindo os princípios da metodologia VDAE, adaptados para uma arquitetura Snowflake.

---

## 1. Objetivo

O objetivo do projeto é construir uma solução analítica capaz de transformar dados operacionais de atendimentos de saúde em produtos de dados confiáveis e preparados para consumo analítico.

A implementação contempla:

- ingestão de arquivos CSV;
- arquitetura em camadas;
- preparação e padronização dos dados;
- modelagem dimensional;
- Slowly Changing Dimension Tipo 2;
- Surrogate Keys;
- Default Members;
- tratamento de Late Arriving Dimensions;
- processamento incremental;
- reconciliação financeira;
- produtos analíticos;
- controles formais de Data Quality;
- governança;
- FinOps;
- versionamento com Git;
- Continuous Integration;
- Continuous Deployment;
- autenticação passwordless via OIDC;
- deployment automatizado no Snowflake DEV;
- Quality Gate automatizado.

---

## 2. Tecnologias

Principais tecnologias utilizadas:

- Snowflake;
- SQL;
- Snowflake CLI;
- Git;
- GitHub;
- GitHub Actions;
- SQLFluff;
- VSCode;
- PowerShell;
- Bash.

---

## 3. Arquitetura

A solução utiliza uma arquitetura em camadas:

```text
Arquivos CSV
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
BI / Consumo Analítico
```

Paralelamente, uma camada dedicada de Data Quality valida os dados ao longo do pipeline:

```text
Raw ----------------------→ Data Quality
Staging ------------------→ Data Quality
Business -----------------→ Data Quality
Information --------------→ Data Quality
                               ↓
                      dq_resumo_qualidade
                               ↓
                         Quality Gate
```

### Responsabilidade das camadas

| Camada | Responsabilidade |
|---|---|
| Raw | Preservação dos dados recebidos |
| Staging | Tipagem e preparação técnica |
| Business | Regras de negócio e modelo dimensional |
| Information | Produtos preparados para consumo |
| Qualidade de Dados | Validações, reconciliações e observabilidade |

---

## 4. Modelo Dimensional

A camada Business utiliza um Star Schema.

A tabela fato central é:

`fct_procedimentos`

Dimensões:

- `dim_paciente`;
- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`.

Representação simplificada:

```text
                           dim_paciente
                           [SCD Tipo 2]
                                |
                                |
dim_procedimento ---- fct_procedimentos ---- dim_unidade
                          /             \
                         /               \
                  dim_medico           dim_data
```

---

## 5. Grão da Fato

O grão da `fct_procedimentos` é:

**1 linha por item de procedimento (`id_item`).**

Um atendimento pode possuir múltiplos itens.

Portanto:

```text
1 atendimento
      ↓
N itens de procedimento
      ↓
N registros na fato
```

A definição explícita do grão é utilizada como base para modelagem, incrementalidade e controles de qualidade.

---

## 6. SCD Tipo 2

A dimensão:

`dim_paciente`

utiliza Slowly Changing Dimension Tipo 2 para preservar alterações históricas nos dados cadastrais dos pacientes.

Cada versão possui:

- Surrogate Key própria;
- início de vigência;
- fim de vigência;
- indicador de versão atual.

O relacionamento com a fato considera a versão dimensional válida na data do atendimento.

---

## 7. Surrogate Keys

As dimensões utilizam Surrogate Keys independentes das chaves naturais provenientes das fontes.

As SKs são geradas de forma determinística.

Essa estratégia permite:

- desacoplamento das chaves da origem;
- estabilidade dos relacionamentos;
- suporte ao histórico;
- tratamento consistente de registros desconhecidos;
- repetibilidade entre execuções.

---

## 8. Default Members

As dimensões possuem Default Members para situações em que não existe uma correspondência dimensional válida.

A chave natural reservada utilizada é:

`-1`

Isso permite preservar eventos sem quebrar a integridade do modelo dimensional.

---

## 9. Late Arriving Dimension

Durante o profiling foi identificado um cenário de Late Arriving Dimension.

Existem:

**10 atendimentos**

cujos pacientes ainda não possuem correspondência dimensional disponível.

A estratégia adotada foi:

```text
evento válido
     ↓
paciente não encontrado
     ↓
Default Member
     ↓
evento preservado na fato
```

Dessa forma, eventos válidos não são eliminados devido à ausência temporária da dimensão.

---

## 10. Métricas Financeiras

A fato possui métricas financeiras no nível do item:

- `vl_item_bruto`;
- `vl_desconto_item`;
- `vl_item_liquido`.

A regra fundamental é:

```text
vl_item_bruto - vl_desconto_item = vl_item_liquido
```

Como os valores originais existem no nível do atendimento, foi implementada reconciliação para garantir que a distribuição para o nível do item não altere os totais financeiros.

---

## 11. Reconciliação Financeira

Os valores são reconciliados por atendimento e também no total consolidado.

Valores validados no dataset:

| Métrica | Valor |
|---|---:|
| Valor bruto | 41.285,00 |
| Desconto | 2.767,25 |
| Valor líquido | 38.517,75 |

A tolerância monetária utilizada nos controles é de:

`0,01`

---

## 12. Processamento Incremental

A criação física da `fct_procedimentos` foi separada da lógica de carga incremental.

Essa separação diferencia:

```text
DDL
 ↓
estrutura da tabela
```

de:

```text
DML
 ↓
processamento recorrente
```

A abordagem facilita:

- manutenção;
- reprocessamento;
- automação;
- execução por CI/CD.

---

## 13. Camada Information

A camada Information disponibiliza produtos preparados para consumo analítico.

### `vw_analise_procedimentos`

Visão detalhada no grão de:

**1 linha por `id_item`.**

### `agg_faturamento_mensal_unidade`

Produto agregado destinado à análise mensal de faturamento por unidade.

As duas estruturas possuem controles de reconciliação com a camada Business.

---

## 14. Data Quality

A solução possui um framework de qualidade implementado no schema:

`qualidade_dados`

Objetos:

```text
dq_raw
dq_staging
dq_business_dimensoes
dq_business_scd2
dq_business_fato
dq_reconciliacao_financeira
dq_information
dq_resumo_qualidade
```

Os controles cobrem principalmente:

- completude;
- unicidade;
- validade;
- consistência;
- acurácia;
- integridade referencial.

---

## 15. Resultado de Data Quality

Foram implementados:

**80 controles formais de Data Quality.**

Resultado final:

```text
80 testes executados
80 testes aprovados
0 testes reprovados
100% de aprovação
```

Distribuição:

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

---

## 16. Observabilidade

Os controles de qualidade foram persistidos como Views `dq_`.

A View:

`dq_resumo_qualidade`

consolida o estado dos testes por escopo.

Essa estrutura também é utilizada pelo pipeline de Continuous Deployment como fonte para o Quality Gate automatizado.

Isso permite evolução futura para:

- dashboards de qualidade;
- alertas;
- histórico de execuções;
- monitoramento operacional;
- observabilidade centralizada.

---

## 17. FinOps

Foram utilizados dois Virtual Warehouses.

### Transformação

`wh_transformacao_dev`

### Consumo analítico

`wh_bi_dev`

Configuração inicial:

```text
WAREHOUSE_SIZE = X-SMALL
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE
```

A estratégia segue o princípio:

**começar pequeno, medir e escalar com base em evidências.**

Multi-cluster não foi habilitado no ambiente pessoal devido ao baixo nível de concorrência e à preocupação com custos.

---

## 18. Segurança e Governança

A execução regular utiliza:

`role_engenharia_analytics`

As atividades automatizadas de CI/CD utilizam uma identidade dedicada e uma role específica para automação.

A autenticação entre GitHub Actions e Snowflake foi implementada utilizando OIDC / Workload Identity Federation.

Com isso, o pipeline não necessita armazenar:

- senha do usuário Snowflake;
- private key;
- credenciais permanentes no repositório.

O fluxo utiliza tokens temporários emitidos durante a execução do GitHub Actions.

A estratégia segue o princípio de menor privilégio.

`ACCOUNTADMIN` foi utilizado somente quando necessário para atividades administrativas de setup.

O projeto também utiliza:

- separação por schemas;
- nomenclatura padronizada;
- RBAC;
- service identity para automação;
- Git;
- Pull Requests;
- registro de mudanças;
- Data Quality observável;
- Quality Gate.

---

## 19. Organização dos Objetos

Principais schemas:

```text
engenharia_analytics_saude_dev
│
├── raw
├── staging
├── business
├── information
└── qualidade_dados
```

Compute:

```text
wh_transformacao_dev
wh_bi_dev
```

Role operacional:

```text
role_engenharia_analytics
```

A automação de CI/CD utiliza identidade e role dedicadas, separando a execução automatizada da utilização interativa do ambiente.

---

## 20. Estrutura do Repositório

Estrutura principal do projeto:

```text
engenharia_analytics_saude/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── cd_dev.yml
│       └── test_snowflake_oidc.yml
│
├── changes/
│
├── dados/
│
├── deploy/
│   └── dev_manifest.txt
│
├── documentacao/
│   ├── 01_arquitetura.md
│   ├── 02_modelo_dimensional.md
│   ├── 03_qualidade_dados.md
│   ├── 04_finops.md
│   ├── 05_governanca_seguranca.md
│   └── 06_execucao_projeto.md
│
├── scripts/
│   └── deploy_dev.sh
│
├── sql/
│   ├── 00_configuracao/
│   │   └── 01_configuracao_inicial.sql
│   │
│   ├── 01_raw/
│   │   ├── 01_criacao_objetos_ingestao.sql
│   │   ├── 02_criacao_tabelas_raw.sql
│   │   └── 03_carga_tabelas_raw.sql
│   │
│   ├── 02_staging/
│   │   ├── 01_stg_atendimentos.sql
│   │   ├── 02_stg_procedimentos_itens.sql
│   │   └── 03_stg_cadastro_pacientes.sql
│   │
│   ├── 03_business/
│   │   ├── 01_dim_procedimento.sql
│   │   ├── 02_dim_unidade.sql
│   │   ├── 03_dim_medico.sql
│   │   ├── 04_dim_data.sql
│   │   ├── 05_dim_paciente.sql
│   │   ├── 06_criacao_fct_procedimentos.sql
│   │   └── 07_carga_fct_procedimentos.sql
│   │
│   ├── 04_information/
│   │   ├── 01_vw_analise_procedimentos.sql
│   │   └── 02_agg_faturamento_mensal_unidade.sql
│   │
│   └── 05_qualidade_dados/
│       ├── 01_dq_raw.sql
│       ├── 02_dq_staging.sql
│       ├── 03_dq_business_dimensoes.sql
│       ├── 04_dq_business_scd2.sql
│       ├── 05_dq_business_fato.sql
│       ├── 06_dq_reconciliacao_financeira.sql
│       ├── 07_dq_information.sql
│       └── 08_dq_resumo_qualidade.sql
│
├── tmp_changes/
├── .gitignore
├── .sqlfluff
└── README.md
```

---

## 21. Ordem de Execução

A ordem lógica do pipeline de dados é:

```text
1. Configuração
2. Raw / Ingestão
3. Staging
4. Dimensões
5. Fato
6. Carga incremental
7. Information
8. Data Quality
9. Validação consolidada
```

A ordem automatizada utilizada pelo Continuous Deployment é controlada explicitamente pelo arquivo:

`deploy/dev_manifest.txt`

O manifesto funciona como contrato de deployment, determinando quais scripts SQL serão executados e em qual sequência.

A documentação operacional completa está disponível em:

`documentacao/06_execucao_projeto.md`

---

## 22. Continuous Integration

O projeto utiliza GitHub Actions para executar validações automáticas antes da integração de mudanças à branch principal.

O fluxo de desenvolvimento segue:

```text
Feature Branch
      ↓
Pull Request
      ↓
Continuous Integration
      ↓
Validações
      ↓
Merge permitido
```

Entre as validações implementadas estão:

- estrutura básica do repositório;
- existência dos arquivos SQL;
- bloqueio de arquivos CSV indevidamente versionados;
- detecção de arquivos temporários;
- verificações básicas contra possíveis credenciais;
- configuração automática do ambiente Python;
- instalação do SQLFluff;
- lint dos scripts SQL utilizando o dialeto Snowflake.

O CI atua como primeira barreira automática de qualidade antes do merge.

---

## 23. SQLFluff e Lint SQL

O projeto utiliza SQLFluff para análise estática dos scripts SQL.

O lint verifica padrões de código sem precisar executar os scripts no Snowflake.

Entre os controles estão aspectos relacionados a:

- formatação;
- indentação;
- consistência;
- estrutura;
- convenções SQL;
- compatibilidade com o dialeto Snowflake.

Esse controle reduz inconsistências antes que o código seja integrado à branch `main`.

---

## 24. Continuous Deployment

O projeto possui Continuous Deployment automatizado para o ambiente Snowflake DEV.

O workflow principal está localizado em:

`.github/workflows/cd_dev.yml`

O fluxo definitivo é:

```text
Feature Branch
      ↓
Pull Request
      ↓
CI
      ↓
Merge
      ↓
main
      ↓
CD Snowflake DEV
      ↓
Autenticação OIDC
      ↓
Validação do manifesto
      ↓
Validação dos scripts
      ↓
Deployment
      ↓
Data Quality
      ↓
Quality Gate
      ↓
Sucesso / Falha
```

O deployment automático ocorre após alterações integradas à branch:

`main`

Também existe suporte à execução manual por meio de `workflow_dispatch`.

---

## 25. Autenticação OIDC / Workload Identity Federation

A comunicação entre GitHub Actions e Snowflake utiliza autenticação baseada em OIDC / Workload Identity Federation.

Arquitetura simplificada:

```text
GitHub Actions
      ↓
OIDC Token temporário
      ↓
Snowflake
      ↓
Service Identity
      ↓
Role de CI/CD
      ↓
Role de Engenharia
      ↓
Objetos DEV
```

Essa abordagem evita o armazenamento de credenciais permanentes no GitHub.

O acesso foi validado por meio de um workflow específico:

`.github/workflows/test_snowflake_oidc.yml`

Esse workflow foi utilizado durante a implementação para validar:

- autenticação;
- identidade utilizada pelo GitHub Actions;
- acesso ao Snowflake;
- hierarquia de roles;
- capacidade da automação de assumir a role necessária para o deployment.

---

## 26. Manifesto de Deployment

O arquivo:

`deploy/dev_manifest.txt`

define explicitamente os scripts SQL que fazem parte do deployment do ambiente DEV.

O manifesto evita depender da descoberta automática de arquivos no repositório.

Isso permite controlar:

- quais scripts são executados;
- a ordem de execução;
- inclusão explícita de novos objetos;
- previsibilidade;
- rastreabilidade;
- reprodutibilidade do deployment.

---

## 27. Executor de Deployment

O arquivo:

`scripts/deploy_dev.sh`

é responsável pela execução automatizada dos scripts definidos no manifesto.

O executor:

1. lê o manifesto;
2. identifica os scripts SQL;
3. executa os scripts sequencialmente;
4. interrompe o processo em caso de erro;
5. reporta o resultado da execução ao GitHub Actions.

Essa abordagem transforma os scripts versionados no repositório em um processo reproduzível de deployment.

---

## 28. Quality Gate

Após o deployment, o pipeline executa automaticamente o Quality Gate.

O Quality Gate consulta os controles consolidados da camada:

`qualidade_dados`

utilizando como referência:

`dq_resumo_qualidade`

A regra conceitual é:

```text
Data Quality
      ↓
80 controles
      ↓
Existe teste REPROVADO?
      │
      ├── SIM → deployment reprovado
      │
      └── NÃO → deployment aprovado
```

Resultado validado durante a implementação:

```text
QUALITY_GATE_APROVADO

80 testes executados
80 testes aprovados
0 testes reprovados
```

Dessa forma, um deployment tecnicamente executável não é considerado automaticamente válido: ele também precisa atender aos critérios de qualidade dos dados.

---

## 29. Fluxo CI/CD Completo

A arquitetura final de entrega é:

```text
Desenvolvedor
     ↓
Feature Branch
     ↓
Pull Request
     ↓
┌───────────────────────────┐
│ Continuous Integration    │
│                           │
│ Estrutura do repositório  │
│ Arquivos SQL              │
│ Segurança básica          │
│ SQLFluff                  │
└─────────────┬─────────────┘
              ↓
            Merge
              ↓
             main
              ↓
┌───────────────────────────┐
│ Continuous Deployment     │
│                           │
│ OIDC / WIF                │
│ Snowflake CLI             │
│ Manifesto                 │
│ Executor SQL              │
└─────────────┬─────────────┘
              ↓
         Snowflake DEV
              ↓
         Data Quality
              ↓
┌───────────────────────────┐
│ Quality Gate              │
│                           │
│ 80 testes                 │
│ 80 aprovados              │
│ 0 reprovados              │
└─────────────┬─────────────┘
              ↓
       DEPLOY APROVADO
```

---

## 30. Validação Final

O projeto pode ser considerado tecnicamente válido quando:

- o pipeline executa sem erros;
- o grão da fato está preservado;
- as Surrogate Keys estão consistentes;
- o SCD Tipo 2 está válido;
- a integridade referencial está preservada;
- os Late Arriving Dimensions conhecidos estão preservados;
- os valores financeiros estão reconciliados;
- os produtos Information estão reconciliados;
- os 80 controles de Data Quality estão aprovados;
- o CI está aprovado;
- a autenticação OIDC está funcional;
- o deployment automatizado está funcional;
- o Quality Gate está aprovado.

Durante a validação final do projeto, o fluxo completo foi executado com sucesso a partir de um merge na branch `main`.

---

## 31. Documentação

A documentação detalhada está disponível em:

| Documento | Conteúdo |
|---|---|
| `01_arquitetura.md` | Arquitetura e decisões técnicas |
| `02_modelo_dimensional.md` | Star Schema, grão, SKs, SCD2 e fato |
| `03_qualidade_dados.md` | Estratégia e controles de Data Quality |
| `04_finops.md` | Compute, sizing, custos e escalabilidade |
| `05_governanca_seguranca.md` | RBAC, segurança e governança |
| `06_execucao_projeto.md` | Runbook e ordem de execução |

---

## 32. Principais Decisões Técnicas

Entre as principais decisões tomadas durante o projeto estão:

1. arquitetura em camadas;
2. preservação da Raw;
3. Staging dedicada à preparação técnica;
4. modelo dimensional em Star Schema;
5. definição explícita do grão da fato;
6. Surrogate Keys determinísticas;
7. SCD Tipo 2 para pacientes;
8. Default Members;
9. tratamento explícito de Late Arriving Dimensions;
10. preservação de eventos sem dimensão disponível;
11. distribuição e reconciliação financeira;
12. separação entre criação e carga incremental;
13. produtos analíticos dedicados;
14. 80 controles formais de Data Quality;
15. separação de compute entre transformação e BI;
16. sizing conservador orientado a FinOps;
17. RBAC e princípio de menor privilégio;
18. versionamento e documentação das mudanças;
19. desenvolvimento baseado em feature branches e Pull Requests;
20. Continuous Integration com GitHub Actions;
21. lint SQL automatizado com SQLFluff;
22. autenticação passwordless via OIDC / Workload Identity Federation;
23. identidade dedicada para automação;
24. manifesto explícito de deployment;
25. executor sequencial de scripts SQL;
26. Continuous Deployment para Snowflake DEV;
27. Quality Gate integrado ao deployment;
28. bloqueio automático do pipeline diante de falhas de qualidade.

---

## 33. Evoluções Futuras

A arquitetura permite evolução para um cenário corporativo com:

- ambientes QA e PROD;
- promoção controlada DEV → QA → PROD;
- aprovação manual para produção;
- histórico persistente dos resultados de Data Quality;
- alertas automáticos;
- dashboards de observabilidade;
- Resource Monitors;
- monitoramento detalhado de custos;
- classificação de dados;
- Tags;
- Masking Policies;
- Row Access Policies;
- automação adicional de grants;
- gestão centralizada de secrets quando necessária;
- testes automatizados adicionais;
- rollback automatizado;
- estratégias formais de versionamento de releases;
- Multi-cluster quando houver necessidade real de concorrência.

---

## 34. Status do Projeto

### Implementado

- [x] Setup Snowflake
- [x] Ingestão
- [x] Raw
- [x] Staging
- [x] Modelagem dimensional
- [x] SCD Tipo 2
- [x] Surrogate Keys
- [x] Default Members
- [x] Late Arriving Dimension
- [x] Fato
- [x] Carga incremental
- [x] Reconciliação financeira
- [x] Camada Information
- [x] Data Quality
- [x] 80/80 testes aprovados
- [x] Documentação técnica
- [x] Git e GitHub
- [x] Feature Branches
- [x] Pull Requests
- [x] Continuous Integration
- [x] SQLFluff
- [x] Continuous Deployment para DEV
- [x] Snowflake CLI
- [x] OIDC / Workload Identity Federation
- [x] identidade dedicada para CI/CD
- [x] manifesto de deployment
- [x] executor automatizado
- [x] Quality Gate automatizado
- [x] deployment validado a partir da `main`

### Próximas evoluções

- [ ] ambiente QA
- [ ] ambiente PROD
- [ ] promoção DEV → QA → PROD
- [ ] histórico de Data Quality
- [ ] observabilidade operacional
- [ ] alertas
- [ ] políticas avançadas de governança
- [ ] estratégia automatizada de rollback

---

## 35. Metodologia

O projeto foi desenvolvido seguindo princípios da metodologia VDAE, adaptados ao Snowflake.

Entre os princípios aplicados estão:

- separação clara de responsabilidades;
- definição explícita de granularidade;
- transformação por camadas;
- Data Quality ao longo do pipeline;
- governança;
- FinOps;
- documentação;
- rastreabilidade;
- reprodutibilidade;
- evolução controlada das mudanças;
- automação;
- validação antes da integração;
- validação após o deployment.

---

## 36. Conclusão

O projeto `engenharia_analytics_saude` implementa uma solução de Analytics Engineering em Snowflake cobrindo desde a ingestão dos dados até a disponibilização de produtos analíticos validados.

A solução combina arquitetura em camadas, modelagem dimensional, processamento incremental, tratamento histórico, qualidade de dados, governança, FinOps e práticas de engenharia de software aplicadas ao ciclo de entrega de dados.

O pipeline possui:

```text
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
Data Quality
```

O ciclo de desenvolvimento e entrega possui:

```text
Feature Branch
      ↓
Pull Request
      ↓
CI
      ↓
Merge
      ↓
main
      ↓
CD Snowflake DEV
      ↓
Quality Gate
```

O estado final validado possui:

**80 de 80 controles de Data Quality aprovados.**

Além disso, o Continuous Deployment foi validado com sucesso a partir de um merge na branch `main`, utilizando autenticação OIDC / Workload Identity Federation e executando automaticamente o deployment e o Quality Gate no Snowflake DEV.

O projeto encontra-se preparado para evoluções futuras envolvendo múltiplos ambientes, observabilidade operacional, governança avançada e estratégias de promoção para QA e PROD.