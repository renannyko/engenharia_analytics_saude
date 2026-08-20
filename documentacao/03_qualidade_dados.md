# Qualidade de Dados

## 1. Visão Geral

O projeto `engenharia_analytics_saude` implementa uma estratégia formal de Data Quality
ao longo das camadas Raw, Staging, Business e Information.

A abordagem segue os princípios da metodologia VDAE, segundo os quais qualidade de
dados deve ser tratada como parte integrante do produto de dados e não apenas como
uma validação manual executada ao final do desenvolvimento.

Os controles foram implementados como objetos consultáveis no Snowflake, permitindo
execução recorrente, observabilidade e futura integração com processos automatizados.


## 2. Objetivos

A estratégia de Data Quality possui os seguintes objetivos:

- detectar problemas próximos da camada onde são introduzidos;
- validar granularidade e unicidade;
- identificar ausência de dados obrigatórios;
- validar conversões e domínios;
- preservar integridade referencial;
- validar regras de negócio;
- garantir consistência temporal do SCD Tipo 2;
- reconciliar métricas financeiras;
- validar produtos da camada Information;
- disponibilizar uma visão consolidada da qualidade.


## 3. Princípios Aplicados

Os controles seguem os seguintes princípios:

1. cada teste possui objetivo explícito;
2. cada teste possui identificador único;
3. resultados são mensuráveis;
4. o critério de aprovação é determinístico;
5. os testes não alteram os dados avaliados;
6. os controles são reproduzíveis;
7. regras são aplicadas na camada adequada;
8. exceções de negócio conhecidas são tratadas explicitamente;
9. os resultados podem ser consumidos por processos automatizados.


## 4. Dimensões de Qualidade

Os controles implementados cobrem principalmente as seguintes dimensões:

### Completude

Avalia se dados obrigatórios estão presentes.

Exemplos:

- campos críticos não nulos;
- existência de registros;
- existência de versão atual de uma dimensão histórica.


### Unicidade

Avalia se registros que deveriam ser únicos não possuem duplicidades.

Exemplos:

- `id_item`;
- Surrogate Keys;
- chaves naturais;
- combinação de paciente e início de vigência.


### Validade

Avalia se os valores estão de acordo com regras técnicas ou funcionais esperadas.

Exemplos:

- conversões de tipos;
- intervalos de vigência válidos;
- valores monetários corretamente tipados.


### Consistência

Avalia coerência entre registros, tabelas ou camadas.

Exemplos:

- Raw versus Staging;
- fato versus dimensões;
- continuidade do SCD Tipo 2;
- Business versus Information.


### Acurácia

Avalia se valores calculados representam corretamente os valores esperados.

O principal exemplo no projeto é a reconciliação financeira.


### Integridade Referencial

Avalia se as chaves dimensionais existentes na fato possuem correspondência válida
nas respectivas dimensões.


## 5. Arquitetura dos Controles

Os controles estão centralizados no schema:

`qualidade_dados`

Foram implementadas as seguintes Views:

- `dq_raw`;
- `dq_staging`;
- `dq_business_dimensoes`;
- `dq_business_scd2`;
- `dq_business_fato`;
- `dq_reconciliacao_financeira`;
- `dq_information`;
- `dq_resumo_qualidade`.

A arquitetura pode ser representada como:

Raw ----------------------→ dq_raw

Staging ------------------→ dq_staging

Business / Dimensões -----→ dq_business_dimensoes

Business / SCD2 ----------→ dq_business_scd2

Business / Fato ----------→ dq_business_fato

Business / Financeiro ----→ dq_reconciliacao_financeira

Information --------------→ dq_information

                               ↓

                       dq_resumo_qualidade


## 6. Estrutura Padronizada dos Resultados

Os controles individuais retornam uma estrutura padronizada:

- `id_teste`;
- `ds_teste`;
- `ds_dimensao_dq`;
- `qt_erros`;
- `ds_status`.

Exemplo conceitual:

| id_teste | ds_teste | ds_dimensao_dq | qt_erros | ds_status |
|---|---|---|---:|---|
| DQ_FCT_001 | unicidade_id_item_fct_procedimentos | UNICIDADE | 0 | APROVADO |


## 7. Critério de Aprovação

O critério geral utilizado é:

`qt_erros = 0 → APROVADO`

`qt_erros > 0 → REPROVADO`

Essa padronização permite interpretar diferentes tipos de teste por meio de uma
mesma interface.


## 8. Data Quality — Raw

A View:

`dq_raw`

possui:

**6 controles**

O objetivo da Raw é estabelecer uma linha de base dos dados ingeridos.

Os controles verificam principalmente:

- presença dos dados;
- volumetria dos atendimentos;
- volumetria dos procedimentos e itens;
- volumetria do cadastro histórico de pacientes.

A Raw não possui controles de regras de negócio, pois sua responsabilidade é
preservar os dados recebidos.


## 9. Data Quality — Staging

A View:

`dq_staging`

possui:

**11 controles**

A Staging é validada quanto à preparação técnica dos dados.

Os controles verificam:

- reconciliação de volumetria entre Raw e Staging;
- completude de campos críticos;
- validade dos campos convertidos;
- unicidade de `id_atendimento`;
- unicidade de `id_item`;
- unicidade das versões cadastrais de pacientes.

Esses testes ajudam a detectar problemas de tipagem ou preparação antes que os dados
entrem na camada Business.


## 10. Data Quality — Dimensões Business

A View:

`dq_business_dimensoes`

possui:

**19 controles**

Os testes verificam:

- unicidade das Surrogate Keys;
- completude das Surrogate Keys;
- unicidade das chaves naturais quando aplicável;
- existência de exatamente um Default Member.

As dimensões avaliadas são:

- `dim_paciente`;
- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`.


## 11. Particularidade da `dim_paciente`

A chave natural `id_paciente` não deve ser testada como globalmente única.

Isso ocorre porque a dimensão utiliza SCD Tipo 2.

Um paciente pode possuir:

`id_paciente = PAC_001`

em múltiplas linhas, desde que cada linha represente uma versão histórica válida.

Por isso, os controles de histórico foram separados em um conjunto específico.


## 12. Data Quality — SCD Tipo 2

A View:

`dq_business_scd2`

possui:

**10 controles**

Os controles verificam:

- no máximo uma versão atual por paciente;
- existência de exatamente uma versão atual;
- validade dos intervalos de vigência;
- continuidade temporal;
- ausência de sobreposição;
- coerência de `lg_atual` nas versões históricas;
- coerência de `lg_atual` na versão vigente;
- data final da versão atual;
- data final das versões históricas;
- unicidade da combinação paciente e início de vigência.


## 13. Continuidade Temporal

Uma das validações mais importantes do SCD Tipo 2 verifica a continuidade entre
versões.

Conceitualmente:

versão 1
dt_inicio = T1
dt_fim    = T2

versão 2
dt_inicio = T2
dt_fim    = T3

O término de uma versão deve ser coerente com o início da versão seguinte.


## 14. Sobreposição Temporal

Também é verificado se duas versões do mesmo paciente possuem vigências simultâneas
indevidas.

Exemplo inválido:

versão 1
T1 ---------------- T3

versão 2
        T2 ---------------- T4

onde:

T2 < T3

Esse cenário produziria ambiguidade ao determinar qual versão deveria ser utilizada
por um evento ocorrido entre T2 e T3.


## 15. Data Quality — Fato

A View:

`dq_business_fato`

possui:

**16 controles**

Os testes verificam:

- unicidade de `id_item`;
- unicidade da Surrogate Key da fato;
- completude da Surrogate Key;
- completude das chaves dimensionais;
- integridade referencial com `dim_paciente`;
- integridade referencial com `dim_procedimento`;
- integridade referencial com `dim_unidade`;
- integridade referencial com `dim_medico`;
- integridade referencial com `dim_data`;
- completude de campos críticos;
- coerência financeira no nível do item;
- tratamento de Late Arriving Dimension;
- uso inesperado dos demais Default Members.


## 16. Integridade Referencial

A fato é validada contra todas as dimensões.

O princípio utilizado é:

fato
    ↓
Surrogate Key
    ↓
registro correspondente na dimensão

Uma chave dimensional sem correspondência representa falha de integridade
referencial.


## 17. Default Members e Qualidade

Default Member não é automaticamente classificado como erro.

A interpretação depende da regra de negócio.

### Paciente

O dataset possui 10 atendimentos classificados como Late Arriving Dimension.

Nesses casos, o Default Member é esperado.

Portanto, o controle verifica se o comportamento conhecido está sendo preservado.

### Procedimento, unidade, médico e data

No dataset atual não são esperados registros sem correspondência nessas dimensões.

Por isso, a utilização dos respectivos Default Members é tratada como erro.


## 18. Data Quality — Reconciliação Financeira

A View:

`dq_reconciliacao_financeira`

possui:

**7 controles**

São avaliados:

- valor bruto por atendimento;
- desconto por atendimento;
- valor líquido por atendimento;
- atendimentos sem itens na fato;
- valor bruto global;
- desconto global;
- valor líquido global.


## 19. Tolerância Financeira

Para comparações monetárias foi adotada tolerância de:

`0,01`

A tolerância evita reprovação indevida causada exclusivamente por diferenças
mínimas de representação ou arredondamento.


## 20. Reconciliação por Atendimento

Para cada atendimento, são comparados os valores da origem com a soma dos itens
existentes na fato.

Conceitualmente:

Atendimento
vl_bruto
vl_desconto
vl_liquido

        ↕

SUM dos itens da fato
vl_item_bruto
vl_desconto_item
vl_item_liquido


## 21. Reconciliação Global

Além da comparação por atendimento, os totais globais também são reconciliados.

Valores validados no dataset:

| Métrica | Valor |
|---|---:|
| Valor bruto | 41.285,00 |
| Desconto | 2.767,25 |
| Valor líquido | 38.517,75 |

A reconciliação foi concluída sem divergências acima da tolerância definida.


## 22. Data Quality — Information

A View:

`dq_information`

possui:

**11 controles**

Os testes verificam:

- volumetria da fato versus View detalhada;
- unicidade de `id_item`;
- completude dos campos críticos;
- preservação dos Late Arriving Dimensions;
- reconciliação do valor bruto;
- reconciliação do desconto;
- reconciliação do valor líquido;
- reconciliação do valor bruto agregado;
- reconciliação do desconto agregado;
- reconciliação do valor líquido agregado;
- reconciliação da quantidade de atendimentos.


## 23. Validação Ponta a Ponta

A camada Information representa o ponto mais próximo do consumidor analítico.

Por isso, os testes dessa camada verificam se as propriedades importantes dos dados
continuam válidas após todas as transformações.

O fluxo de reconciliação é:

Raw
 ↓
Staging
 ↓
Business
 ↓
Information
 ↓
resultado analítico

A qualidade não é validada somente na origem ou somente no destino.

Ela é verificada ao longo do pipeline.


## 24. Resumo Consolidado

A View:

`dq_resumo_qualidade`

consolida os resultados das Views de qualidade.

Ela apresenta por escopo:

- quantidade de testes;
- quantidade de aprovados;
- quantidade de reprovados;
- quantidade de erros;
- status consolidado.


## 25. Distribuição dos Testes

| Escopo | Quantidade |
|---|---:|
| Raw | 6 |
| Staging | 11 |
| Business — Dimensões | 19 |
| Business — SCD Tipo 2 | 10 |
| Business — Fato | 16 |
| Reconciliação Financeira | 7 |
| Information | 11 |
| **Total** | **80** |


## 26. Resultado Final

Após a implementação e execução dos controles:

| Indicador | Resultado |
|---|---:|
| Testes executados | 80 |
| Testes aprovados | 80 |
| Testes reprovados | 0 |
| Taxa de aprovação | 100% |

Resultado:

`80 / 80 APROVADOS`


## 27. Observabilidade

Inicialmente, os testes foram executados como consultas SQL individuais.

Posteriormente, os controles foram promovidos para Views persistentes no schema
`qualidade_dados`.

Essa evolução transformou os testes de:

validação manual
    ↓
resultado temporário

para:

objetos de qualidade
    ↓
consulta recorrente
    ↓
resumo consolidado
    ↓
observabilidade


## 28. Benefícios da Persistência em Views

A utilização de Views `dq_` permite:

- consultar a qualidade a qualquer momento;
- centralizar resultados;
- evitar duplicação da lógica dos testes;
- alimentar dashboards;
- suportar processos de CI/CD;
- implementar alertas futuramente;
- disponibilizar evidências de qualidade.


## 29. Possível Quality Gate de CI/CD

A arquitetura atual permite uma evolução natural para Quality Gates.

Um pipeline automatizado poderia executar:

deploy
    ↓
execução dos objetos
    ↓
consulta de dq_resumo_qualidade
    ↓
existem testes REPROVADOS?
       ↓              ↓
      SIM            NÃO
       ↓              ↓
bloquear promoção   continuar pipeline

Dessa forma, Data Quality passa a fazer parte do processo de entrega.


## 30. Severidade dos Testes

No exercício atual, todos os controles utilizam o mesmo critério geral de aprovação.

Em um cenário corporativo, os testes poderiam receber níveis de severidade, por
exemplo:

- crítico;
- alto;
- médio;
- informativo.

Isso permitiria diferenciar:

falhas que bloqueiam o pipeline

de

anomalias que apenas geram alertas.


## 31. Histórico de Execuções

As Views atuais apresentam o estado dos dados no momento da consulta.

Uma evolução possível seria persistir os resultados em uma tabela histórica.

Exemplo conceitual:

`fct_execucao_qualidade`

com informações como:

- identificador da execução;
- data e hora;
- ambiente;
- teste;
- quantidade de erros;
- status;
- versão do código.

Isso permitiria analisar tendências de qualidade ao longo do tempo.


## 32. Alertas

Outra evolução possível seria criar alertas para situações como:

- teste crítico reprovado;
- crescimento inesperado de nulos;
- quebra de integridade referencial;
- divergência financeira;
- aumento de Late Arriving Dimensions;
- alteração inesperada de volumetria.


## 33. Relação com Observabilidade

Data Quality representa uma parte da observabilidade do produto.

Em uma arquitetura corporativa mais ampla, poderia ser combinada com métricas de:

- duração dos pipelines;
- falhas de execução;
- volume processado;
- freshness;
- consumo de créditos;
- performance de queries;
- disponibilidade dos produtos analíticos.


## 34. Decisões Principais

As principais decisões relacionadas a Data Quality foram:

1. implementar qualidade desde as primeiras camadas;
2. separar testes por responsabilidade;
3. utilizar identificadores únicos para os testes;
4. padronizar o resultado dos controles;
5. medir erros em vez de retornar apenas booleanos;
6. validar SCD Tipo 2 separadamente;
7. tratar Late Arriving Dimension como regra conhecida;
8. não considerar Default Member automaticamente como erro;
9. reconciliar métricas financeiras;
10. validar também a camada Information;
11. persistir os controles como Views `dq_`;
12. criar uma visão consolidada de qualidade.


## 35. Conclusão

A estratégia de Data Quality implementada permite validar o pipeline desde a ingestão
até os produtos analíticos.

Os 80 controles cobrem aspectos técnicos, dimensionais, temporais, referenciais e
financeiros.

O resultado final de 80 testes aprovados e nenhum teste reprovado fornece uma
evidência objetiva da consistência do dataset no estado atual.

Além da validação do exercício, a arquitetura criada estabelece uma base para futura
automação de Quality Gates, dashboards de observabilidade, alertas e histórico de
execuções.