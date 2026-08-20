# Arquitetura da Solução

## 1. Visão Geral

O projeto `engenharia_analytics_saude` implementa uma arquitetura analítica em Snowflake para ingestão, transformação, modelagem dimensional, disponibilização analítica e controle de qualidade de dados relacionados a atendimentos de saúde.

A arquitetura foi desenvolvida seguindo os princípios da metodologia VDAE, adaptados às características e recursos nativos do Snowflake.

O fluxo principal da solução é:

CSV Local
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

Paralelamente, a solução possui uma camada dedicada de Qualidade de Dados, responsável por validar os dados ao longo das diferentes etapas da arquitetura.


## 2. Arquitetura Lógica

A arquitetura é organizada nas seguintes responsabilidades:

| Componente | Responsabilidade |
|---|---|
| Fonte | Arquivos CSV utilizados como origem dos dados |
| Internal Stage | Armazenamento temporário dos arquivos para ingestão |
| Raw | Preservação dos dados recebidos |
| Staging | Tipagem, padronização e preparação técnica |
| Business | Aplicação das regras de negócio e modelagem dimensional |
| Information | Produtos analíticos preparados para consumo |
| Qualidade de Dados | Controles de qualidade e reconciliação |
| BI | Consumo dos produtos analíticos |


## 3. Fonte de Dados

O exercício utiliza arquivos CSV locais como fontes.

Os arquivos representam três conjuntos principais de dados:

- atendimentos;
- procedimentos e itens;
- cadastro histórico de pacientes.

Os arquivos são carregados para um Internal Stage do Snowflake antes da ingestão na camada Raw.

Essa abordagem separa:

origem física do arquivo

de

armazenamento estruturado dos dados.


## 4. Internal Stage

O Internal Stage funciona como ponto de entrada dos arquivos no Snowflake.

O fluxo de ingestão utilizado é:

CSV Local
    ↓
Internal Stage
    ↓
COPY INTO
    ↓
Raw

O Stage não possui responsabilidade de transformação ou aplicação de regras de negócio.

Sua função é permitir que os arquivos estejam disponíveis para o processo de ingestão executado pelo Snowflake.


## 5. Camada Raw

A camada Raw representa a primeira persistência estruturada dos dados.

Seu objetivo é preservar o conteúdo recebido da fonte com o mínimo possível de transformação.

Principais características:

- preservação dos dados recebidos;
- ausência de regras de negócio;
- estrutura próxima à origem;
- possibilidade de rastrear problemas até o dado originalmente ingerido.

A Raw funciona como linha de base para as etapas posteriores do pipeline.


## 6. Camada Staging

A camada Staging é responsável pela preparação técnica dos dados.

Nessa camada são realizadas operações como:

- conversão de tipos;
- padronização técnica;
- tratamento seguro de campos;
- preparação das estruturas para aplicação das regras de negócio.

A Staging deve preservar a granularidade da Raw.

Portanto:

Raw
    ↓
transformação técnica
    ↓
Staging

não deve introduzir agregações ou alterações de granularidade.


## 7. Camada Business

A camada Business representa o núcleo semântico da solução.

É nessa camada que são implementadas:

- regras de negócio;
- modelagem dimensional;
- Surrogate Keys;
- dimensões;
- fato;
- SCD Tipo 2;
- Default Members;
- tratamento de Late Arriving Dimensions;
- lógica financeira;
- carga incremental.

O modelo dimensional principal é composto por:

dim_paciente
dim_procedimento
dim_unidade
dim_medico
dim_data
        ↓
fct_procedimentos


## 8. Surrogate Keys

As dimensões utilizam Surrogate Keys independentes das chaves naturais provenientes das fontes.

As SKs são geradas de forma determinística.

Essa estratégia permite:

- desacoplamento das chaves da origem;
- estabilidade dos relacionamentos;
- suporte a histórico;
- tratamento consistente de registros desconhecidos;
- repetibilidade entre execuções.

A dimensão histórica de pacientes utiliza a combinação da chave natural e da versão temporal para representar corretamente diferentes estados do mesmo paciente.


## 9. SCD Tipo 2

A `dim_paciente` implementa Slowly Changing Dimension Tipo 2.

O objetivo é preservar alterações históricas nos atributos cadastrais do paciente.

Cada versão possui informações de vigência que permitem determinar qual registro era válido em determinado momento.

A estrutura utiliza conceitos como:

- `dt_inicio_vigencia`;
- `dt_fim_vigencia`;
- `lg_atual`.

Dessa forma, alterações cadastrais não sobrescrevem simplesmente o histórico anterior.


## 10. Default Members

As dimensões possuem Default Members.

O Default Member permite preservar registros da fato quando uma correspondência dimensional válida não está disponível.

A chave natural reservada utilizada é:

`-1`

e sua respectiva Surrogate Key determinística é utilizada nos relacionamentos da fato.

Essa estratégia evita a perda de registros durante o processamento.


## 11. Late Arriving Dimension

O dataset contém um cenário realista de Late Arriving Dimension relacionado ao cadastro de pacientes.

Existem atendimentos cujo paciente ainda não possui correspondência dimensional disponível.

Nesses casos:

atendimento
    ↓
paciente não encontrado
    ↓
Default Member
    ↓
registro preservado na fato

Foram identificados 10 atendimentos nessa condição.

A decisão arquitetural foi preservar esses registros em vez de eliminá-los por meio de `INNER JOIN`.

Essa abordagem garante que eventos válidos não sejam perdidos apenas porque a dimensão correspondente ainda não chegou.


## 12. Fato de Procedimentos

A principal tabela fato da solução é:

`fct_procedimentos`

O grão definido é:

**1 linha por item de procedimento (`id_item`).**

Essa definição é fundamental para evitar duplicações e ambiguidades nas métricas.

A fato contém relacionamentos com:

- paciente;
- procedimento;
- unidade;
- médico;
- data.

Também contém métricas financeiras no nível do item.


## 13. Regra Financeira

Os valores financeiros do atendimento são distribuídos para o nível do item.

A solução preserva e reconcilia:

- valor bruto;
- desconto;
- valor líquido.

O rateio permite analisar valores financeiros no mesmo grão da fato sem perder a capacidade de reconciliar os totais com o atendimento original.

Foram implementados controles específicos de Data Quality para garantir essa reconciliação.


## 14. Incrementalidade

A arquitetura separa:

criação da estrutura

de

processamento incremental.

Essa decisão evita misturar DDL e processamento recorrente em uma única responsabilidade.

A carga incremental utiliza operações adequadas para manter a fato sem duplicar registros já processados.

Essa separação facilita:

- manutenção;
- automação;
- reprocessamento;
- CI/CD;
- compreensão operacional.


## 15. Camada Information

A camada Information disponibiliza produtos preparados para consumo analítico.

Foram implementados produtos com diferentes granularidades.

### Visão detalhada

`vw_analise_procedimentos`

Mantém granularidade detalhada no nível do item e reúne informações necessárias para análises de procedimentos.

### Visão agregada

`agg_faturamento_mensal_unidade`

Disponibiliza métricas financeiras agregadas por período e unidade.

Essa separação permite atender diferentes necessidades de consumo sem obrigar ferramentas de BI a reconstruírem repetidamente regras existentes na camada Business.


## 16. Qualidade de Dados

A solução possui um schema dedicado:

`qualidade_dados`

Os controles foram organizados em Views:

- `dq_raw`;
- `dq_staging`;
- `dq_business_dimensoes`;
- `dq_business_scd2`;
- `dq_business_fato`;
- `dq_reconciliacao_financeira`;
- `dq_information`;
- `dq_resumo_qualidade`.

Os testes cobrem principalmente:

- unicidade;
- completude;
- consistência;
- validade;
- acurácia;
- integridade referencial.

Foram implementados 80 controles formais.

Resultado da validação:

- 80 testes executados;
- 80 testes aprovados;
- 0 testes reprovados;
- 100% de aprovação.


## 17. Observabilidade de Qualidade

A persistência dos controles como Views `dq_` permite que o estado da qualidade seja consultado a qualquer momento.

A View:

`dq_resumo_qualidade`

consolida os resultados por escopo.

Essa arquitetura permite evolução futura para:

- dashboards de qualidade;
- alertas;
- execução automatizada;
- gates de CI/CD;
- monitoramento operacional.


## 18. Estratégia de Compute

A solução utiliza dois Virtual Warehouses independentes:

`wh_transformacao_dev`

e

`wh_bi_dev`

Ambos foram configurados inicialmente como:

- tamanho X-Small;
- `AUTO_SUSPEND = 60`;
- `AUTO_RESUME = TRUE`.

### `wh_transformacao_dev`

Responsável pelas cargas, transformações, modelagem e controles de qualidade.

### `wh_bi_dev`

Reservado para workloads de consulta e consumo analítico.

A separação permite isolamento entre processamento e consumo.


## 19. Decisão de Sizing

Foi adotado X-Small como tamanho inicial para os dois Warehouses.

A decisão segue uma estratégia conservadora de FinOps:

**começar pequeno, medir e escalar com base em evidências.**

O tamanho do Warehouse não deve ser aumentado preventivamente sem evidências de necessidade.

O Snowflake permite alterar o tamanho posteriormente sem necessidade de redesenhar a arquitetura.


## 20. Multi-cluster

Multi-cluster Warehouse não foi habilitado no ambiente pessoal utilizado no exercício.

A decisão foi tomada principalmente por custo e pelo baixo nível de concorrência existente no ambiente.

Em um cenário corporativo com múltiplos usuários ou alta concorrência, multi-cluster poderia ser avaliado para melhorar capacidade de atendimento simultâneo.

Portanto, a decisão não representa uma limitação arquitetural, mas uma escolha adequada ao contexto do ambiente.


## 21. Segurança e RBAC

O setup inicial de objetos administrativos exigiu privilégios elevados.

`ACCOUNTADMIN` foi utilizado apenas quando necessário para configuração inicial.

A execução normal do pipeline utiliza uma role específica:

`role_engenharia_analytics`

Essa separação segue o princípio de menor privilégio.

O objetivo é evitar o uso permanente de roles administrativas para workloads cotidianos.


## 22. Separação de Responsabilidades

A arquitetura final pode ser resumida como:

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
BI

Qualidade de Dados
    ↕
Raw / Staging / Business / Information

Compute
    ├── wh_transformacao_dev
    └── wh_bi_dev

Segurança
    ├── ACCOUNTADMIN → setup administrativo
    └── role_engenharia_analytics → execução normal


## 23. Princípios Arquiteturais Aplicados

As principais decisões arquiteturais do projeto foram:

1. separação clara entre camadas;
2. preservação da Raw;
3. transformação técnica isolada na Staging;
4. regras de negócio centralizadas na Business;
5. grão explicitamente definido para a fato;
6. utilização de Surrogate Keys;
7. implementação de SCD Tipo 2;
8. utilização de Default Members;
9. tratamento explícito de Late Arriving Dimensions;
10. reconciliação financeira;
11. separação entre criação e carga incremental;
12. produtos analíticos dedicados na Information;
13. Data Quality observável e reproduzível;
14. separação de compute entre transformação e BI;
15. sizing conservador orientado a FinOps;
16. RBAC e princípio de menor privilégio;
17. versionamento de código e documentação.


## 24. Evoluções Possíveis

Em um ambiente corporativo, a arquitetura pode evoluir para incluir:

- ambientes separados de desenvolvimento, homologação e produção;
- CI/CD automatizado;
- execução automatizada dos controles de Data Quality;
- bloqueio de promoção quando testes críticos falharem;
- alertas de qualidade;
- monitoramento de custos;
- Resource Monitors;
- tagging e classificação de dados;
- masking policies para informações sensíveis;
- Row Access Policies quando aplicável;
- observabilidade operacional;
- multi-cluster para workloads com alta concorrência;
- integração com ferramentas corporativas de BI e governança.


## 25. Conclusão

A arquitetura implementada busca separar claramente ingestão, preparação técnica, regras de negócio, consumo analítico e qualidade de dados.

As decisões foram adaptadas ao contexto de um ambiente Snowflake de desenvolvimento pessoal, mantendo princípios que permitem evolução para cenários corporativos.

O resultado é uma solução modular, reproduzível, governável e preparada para evolução por meio de automação e CI/CD.