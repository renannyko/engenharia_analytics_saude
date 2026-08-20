# Engenharia Analytics Saúde

Projeto de Analytics Engineering desenvolvido em Snowflake para implementar um pipeline analítico completo a partir de dados de atendimentos de saúde.

A solução cobre o ciclo desde a ingestão de arquivos CSV até a disponibilização de produtos analíticos, incluindo modelagem dimensional, processamento incremental, qualidade de dados, governança e práticas de FinOps.

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
- versionamento com Git.

---

## 2. Tecnologias

Principais tecnologias utilizadas:

- Snowflake;
- SQL;
- Git;
- GitHub;
- VSCode;
- PowerShell.

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
                              |
                              |
                         dim_medico
                              |
                              |
                           dim_data
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
- evolução para CI/CD.

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

Isso permite evolução futura para:

- dashboards de qualidade;
- alertas;
- histórico de execuções;
- monitoramento;
- Quality Gates de CI/CD.

---

## 17. FinOps

Foram utilizados dois Virtual Warehouses:

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

`ACCOUNTADMIN` foi utilizado somente quando necessário para atividades administrativas de setup.

A estratégia segue o princípio de menor privilégio.

O projeto também utiliza:

- separação por schemas;
- nomenclatura padronizada;
- Git;
- registro de mudanças;
- Data Quality observável.

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

---

## 20. Estrutura do Repositório

Estrutura conceitual:

```text
engenharia_analytics_saude/
│
├── sql/
│   ├── setup/
│   ├── ingestao/
│   ├── transformacao/
│   ├── modelagem/
│   └── 05_qualidade_dados/
│
├── documentacao/
│   ├── 01_arquitetura.md
│   ├── 02_modelo_dimensional.md
│   ├── 03_qualidade_dados.md
│   ├── 04_finops.md
│   ├── 05_governanca_seguranca.md
│   └── 06_execucao_projeto.md
│
├── changes/
├── tmp_changes/
└── README.md
```

> A estrutura exata das pastas SQL deve ser consultada no próprio repositório, pois representa os scripts efetivamente implementados no projeto.

---

## 21. Ordem de Execução

A ordem lógica do pipeline é:

```text
1. Setup
2. Ingestão
3. Raw
4. Staging
5. Dimensões
6. Fato
7. Carga incremental
8. Information
9. Data Quality
10. Validação consolidada
```

A documentação operacional completa está disponível em:

`documentacao/06_execucao_projeto.md`

---

## 22. Validação Final

O projeto pode ser considerado tecnicamente válido quando:

- o pipeline executa sem erros;
- o grão da fato está preservado;
- as Surrogate Keys estão consistentes;
- o SCD Tipo 2 está válido;
- a integridade referencial está preservada;
- os Late Arriving Dimensions conhecidos estão preservados;
- os valores financeiros estão reconciliados;
- os produtos Information estão reconciliados;
- os 80 controles de Data Quality estão aprovados.

---

## 23. Documentação

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

## 24. Principais Decisões Técnicas

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
18. versionamento e documentação das mudanças.

---

## 25. Evoluções Futuras

A arquitetura permite evolução para um cenário corporativo com:

- ambientes DEV, QA e PROD;
- CI/CD;
- Quality Gates;
- execução automatizada de Data Quality;
- histórico de resultados de qualidade;
- alertas;
- Resource Monitors;
- monitoramento de custos;
- classificação de dados;
- Tags;
- Masking Policies;
- Row Access Policies;
- service identities;
- automação de grants;
- observabilidade operacional;
- Multi-cluster quando houver necessidade de concorrência.

---

## 26. Status do Projeto

### Implementado

- [x] Setup Snowflake
- [x] Ingestão
- [x] Raw
- [x] Staging
- [x] Modelagem dimensional
- [x] SCD Tipo 2
- [x] Default Members
- [x] Late Arriving Dimension
- [x] Fato
- [x] Carga incremental
- [x] Reconciliação financeira
- [x] Camada Information
- [x] Data Quality
- [x] 80/80 testes aprovados
- [x] Documentação técnica

### Próximas evoluções

- [ ] CI/CD
- [ ] Quality Gate automatizado
- [ ] automação de deploy
- [ ] observabilidade histórica
- [ ] preparação para ambientes QA e PROD

---

## 27. Metodologia

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
- evolução controlada das mudanças.

---

## 28. Conclusão

O projeto `engenharia_analytics_saude` implementa uma solução de Analytics Engineering em Snowflake cobrindo desde a ingestão dos dados até a disponibilização de produtos analíticos validados.

A solução combina arquitetura em camadas, modelagem dimensional, processamento incremental, tratamento histórico, qualidade de dados, governança e FinOps.

O estado atual possui:

**80 de 80 controles de Data Quality aprovados.**

A próxima evolução arquitetural é incorporar CI/CD e transformar as validações já existentes em parte do processo automatizado de entrega.