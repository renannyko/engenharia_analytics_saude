# Modelo Dimensional

## 1. Visão Geral

A camada Business do projeto `engenharia_analytics_saude` utiliza modelagem dimensional
para representar os dados de atendimentos e procedimentos de saúde em estruturas
adequadas para análise.

O modelo foi construído seguindo os princípios da metodologia VDAE, com definição
explícita de:

- grão da fato;
- dimensões;
- chaves naturais;
- Surrogate Keys;
- relacionamento fato-dimensão;
- tratamento histórico;
- Default Members;
- Late Arriving Dimensions;
- métricas financeiras.

O modelo principal segue uma estrutura Star Schema.


## 2. Star Schema

A tabela fato central é:

`fct_procedimentos`

Ela se relaciona com cinco dimensões:

- `dim_paciente`;
- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`.

Representação lógica:

                         dim_paciente
                              |
                              |
dim_procedimento ---- fct_procedimentos ---- dim_unidade
                              |
                              |
                         dim_medico
                              |
                              |
                           dim_data


## 3. Definição do Grão

O grão da tabela fato é:

**1 linha por item de procedimento (`id_item`).**

Essa definição foi estabelecida antes da implementação da fato.

Um atendimento pode possuir múltiplos procedimentos e, consequentemente, múltiplos
itens.

Portanto:

1 atendimento
    ↓
N itens de procedimento
    ↓
N registros na fct_procedimentos

A chave `id_atendimento` não representa o grão da fato.

A chave natural utilizada para identificar cada evento no nível definido é:

`id_item`


## 4. Tabela Fato

### `fct_procedimentos`

A `fct_procedimentos` centraliza os eventos analíticos relacionados aos procedimentos
executados nos atendimentos.

Principais grupos de atributos:

### Identificação

- Surrogate Key da fato;
- `id_item`;
- `id_atendimento`.

### Relacionamentos dimensionais

- SK de paciente;
- SK de procedimento;
- SK de unidade;
- SK de médico;
- SK de data.

### Informações temporais

- data do atendimento.

### Métricas

- valor bruto do item;
- desconto atribuído ao item;
- valor líquido do item.


## 5. Surrogate Key da Fato

A fato possui uma Surrogate Key própria e determinística.

A utilização dessa chave permite manter uma identificação técnica independente das
chaves provenientes da origem.

Entretanto, a validação do grão continua sendo realizada por `id_item`.

Portanto, existem duas responsabilidades distintas:

`id_item`

representa o grão natural do evento.

A Surrogate Key

representa a identificação técnica do registro dentro do modelo dimensional.


## 6. Dimensão Paciente

### `dim_paciente`

A dimensão de pacientes representa os atributos cadastrais associados aos pacientes.

Diferentemente das demais dimensões, essa estrutura possui histórico.

Principais conceitos:

- chave natural: `id_paciente`;
- Surrogate Key: `id_sk_paciente`;
- histórico: SCD Tipo 2;
- indicador de versão atual: `lg_atual`;
- início de vigência: `dt_inicio_vigencia`;
- fim de vigência: `dt_fim_vigencia`.

A mesma chave natural pode aparecer múltiplas vezes na dimensão.

Exemplo conceitual:

id_paciente | cidade       | inicio     | fim        | atual
------------|--------------|------------|------------|------
PAC_001     | Santo André  | período 1  | período 2  | FALSE
PAC_001     | São Paulo    | período 2  | 9999-12-31 | TRUE

Isso não representa duplicidade.

Representa duas versões históricas válidas do mesmo paciente.


## 7. SCD Tipo 2

Foi adotada a estratégia Slowly Changing Dimension Tipo 2 para preservar alterações
históricas nos dados cadastrais dos pacientes.

Quando atributos relevantes mudam, o registro anterior não é sobrescrito.

Em vez disso:

versão anterior
    ↓
encerramento da vigência
    ↓
nova versão
    ↓
nova Surrogate Key

Essa estratégia permite responder perguntas históricas considerando o estado do
cadastro existente no momento do evento.


## 8. Vigência Temporal

Cada versão válida da `dim_paciente` possui:

`dt_inicio_vigencia`

e

`dt_fim_vigencia`

A versão atual utiliza como limite futuro:

`9999-12-31`

e:

`lg_atual = TRUE`

Versões encerradas possuem:

`lg_atual = FALSE`

Os controles de Data Quality verificam a consistência dessas regras.


## 9. Relacionamento Temporal com a Fato

O relacionamento entre um evento e a `dim_paciente` deve considerar não apenas a
chave natural do paciente, mas também a vigência da versão dimensional.

Conceitualmente:

id_paciente do atendimento
        +
dt_atendimento
        ↓
versão da dim_paciente válida naquele instante
        ↓
id_sk_paciente

Esse comportamento preserva corretamente o contexto histórico do evento.


## 10. Late Arriving Dimension

Durante o profiling dos dados foi identificado um cenário de Late Arriving Dimension.

Existem atendimentos válidos cujos pacientes ainda não possuem correspondência no
cadastro disponível.

Foram identificados:

**10 atendimentos**

nessa situação.

Excluir esses registros da fato produziria perda de eventos válidos.

Por isso, a estratégia adotada foi:

paciente não encontrado
        ↓
Default Member
        ↓
id_sk_paciente correspondente ao registro desconhecido
        ↓
evento preservado na fato

Assim, a ausência temporária da dimensão não elimina o evento transacional.


## 11. Dimensão Procedimento

### `dim_procedimento`

Representa os procedimentos existentes no modelo.

Principais conceitos:

- chave natural: `cd_procedimento`;
- Surrogate Key: `id_sk_procedimento`.

A chave natural deve ser única para os registros reais da dimensão.

Essa dimensão não utiliza histórico SCD Tipo 2 no escopo atual do projeto.


## 12. Dimensão Unidade

### `dim_unidade`

Representa as unidades relacionadas aos atendimentos.

Principais conceitos:

- chave natural: `id_unidade`;
- Surrogate Key: `id_sk_unidade`.

Cada unidade possui uma identificação técnica independente da chave recebida da
origem.


## 13. Dimensão Médico

### `dim_medico`

Representa os médicos associados à execução dos procedimentos.

Principais conceitos:

- chave natural: `id_medico`;
- Surrogate Key: `id_sk_medico`.

No escopo atual, a dimensão não possui versionamento histórico.


## 14. Dimensão Data

### `dim_data`

Representa a dimensão temporal utilizada para análise dos procedimentos.

Principais conceitos:

- data de calendário: `dt_data`;
- Surrogate Key: `id_sk_data`.

A utilização de uma dimensão dedicada permite separar atributos temporais do evento
transacional e facilita análises por períodos.


## 15. Default Members

Todas as dimensões possuem um Default Member.

A chave natural reservada utilizada é:

`-1`

A Surrogate Key correspondente é gerada de forma determinística.

O objetivo é disponibilizar uma referência dimensional válida quando a dimensão
correspondente não puder ser encontrada.


## 16. Default Member não significa erro automaticamente

A presença de um Default Member deve ser interpretada conforme a regra de negócio.

No caso da `dim_paciente`, seu uso é esperado para os 10 atendimentos classificados
como Late Arriving Dimension.

Portanto:

Default Member de paciente
+
cenário Late Arriving conhecido
=
comportamento válido

Por outro lado, no dataset atual não são esperados Default Members para:

- procedimento;
- unidade;
- médico;
- data.

Por isso, os controles de Data Quality tratam essas ocorrências de forma diferente.


## 17. Integridade Referencial

A fato deve possuir correspondência válida nas dimensões por meio das Surrogate Keys.

Os relacionamentos principais são:

fct_procedimentos.id_sk_paciente
    → dim_paciente.id_sk_paciente

fct_procedimentos.id_sk_procedimento
    → dim_procedimento.id_sk_procedimento

fct_procedimentos.id_sk_unidade
    → dim_unidade.id_sk_unidade

fct_procedimentos.id_sk_medico
    → dim_medico.id_sk_medico

fct_procedimentos.id_sk_data
    → dim_data.id_sk_data

Os Default Members fazem parte dessa estratégia de integridade.


## 18. Métricas Financeiras

A origem possui valores financeiros no nível do atendimento, enquanto o grão da fato
é o item de procedimento.

Foi necessário distribuir os valores para compatibilizar:

grão financeiro da origem
        ↓
regra de distribuição
        ↓
grão da fato

A fato disponibiliza:

- `vl_item_bruto`;
- `vl_desconto_item`;
- `vl_item_liquido`.


## 19. Regra de Valor Líquido

No nível do item, deve ser preservada a relação:

`vl_item_bruto - vl_desconto_item = vl_item_liquido`

Essa regra é formalmente validada pelos controles de Data Quality.


## 20. Reconciliação Financeira

A distribuição das métricas para o nível do item não pode alterar o resultado
financeiro original.

Por isso, os valores são reconciliados novamente no nível do atendimento.

Para cada atendimento:

SUM(vl_item_bruto)
    ↔
vl_bruto do atendimento

SUM(vl_desconto_item)
    ↔
vl_desconto do atendimento

SUM(vl_item_liquido)
    ↔
vl_liquido do atendimento

Também existe reconciliação dos totais globais.

A tolerância adotada para diferenças monetárias é de:

`0,01`


## 21. Resultado da Reconciliação

A reconciliação financeira foi validada sem divergências acima da tolerância
estabelecida.

Totais do dataset:

| Métrica | Valor |
|---|---:|
| Valor bruto | 41.285,00 |
| Desconto | 2.767,25 |
| Valor líquido | 38.517,75 |

Esses valores permanecem reconciliados entre os níveis analisados.


## 22. Incrementalidade da Fato

A criação da estrutura da fato foi separada da lógica de carga incremental.

Essa separação estabelece duas responsabilidades:

### Estrutura

Responsável pela existência e definição física da tabela.

### Processamento

Responsável por inserir ou atualizar os registros necessários.

Essa decisão facilita manutenção, automação e evolução para pipelines de CI/CD.


## 23. Controle de Duplicidade

A carga incremental deve preservar o grão definido.

Portanto:

`id_item`

não pode gerar múltiplos registros válidos na fato.

Essa regra também é validada formalmente na camada de Data Quality.


## 24. Camada Information

O modelo dimensional da Business é utilizado como base para os produtos analíticos
da camada Information.

Foram disponibilizados dois tipos principais de produto.


### `vw_analise_procedimentos`

Produto detalhado que preserva:

**1 linha por `id_item`.**

A View disponibiliza atributos dimensionais e métricas de forma conveniente para
consumo analítico.


### `agg_faturamento_mensal_unidade`

Produto agregado destinado à análise mensal de faturamento por unidade.

A agregação reduz a granularidade conforme a finalidade analítica do produto.

Os totais financeiros da agregação são reconciliados com a camada detalhada.


## 25. Data Quality do Modelo Dimensional

O modelo possui controles específicos para:

### Dimensões

- unicidade das Surrogate Keys;
- completude das SKs;
- unicidade das chaves naturais quando aplicável;
- existência dos Default Members.

### SCD Tipo 2

- uma única versão atual por paciente;
- existência de versão atual;
- validade dos intervalos;
- continuidade temporal;
- ausência de sobreposição;
- coerência de `lg_atual`;
- coerência da data final;
- unicidade de paciente e início de vigência.

### Fato

- unicidade do grão;
- unicidade da SK;
- completude das FKs;
- integridade referencial;
- completude de campos críticos;
- coerência financeira;
- uso esperado ou inesperado de Default Members.

### Reconciliação

- valor bruto;
- desconto;
- valor líquido;
- nível do atendimento;
- nível consolidado.


## 26. Resumo do Modelo

O modelo pode ser resumido da seguinte forma:

                            dim_paciente
                            [SCD Tipo 2]
                                 |
                                 |
dim_procedimento ---- fct_procedimentos ---- dim_unidade
                         1 linha/id_item
                                 |
                                 |
                            dim_medico
                                 |
                                 |
                              dim_data

Características principais:

- Star Schema;
- fato no grão de item;
- cinco dimensões;
- Surrogate Keys determinísticas;
- SCD Tipo 2 para paciente;
- Default Members;
- Late Arriving Dimension;
- integridade referencial;
- métricas financeiras no grão da fato;
- reconciliação financeira;
- carga incremental.


## 27. Decisões de Modelagem

As principais decisões tomadas foram:

1. definir o grão antes da construção da fato;
2. utilizar `id_item` como grão natural;
3. utilizar Surrogate Keys nas dimensões;
4. preservar histórico de pacientes com SCD Tipo 2;
5. utilizar vigência temporal no relacionamento histórico;
6. implementar Default Members;
7. preservar eventos com Late Arriving Dimension;
8. não considerar todo Default Member automaticamente como erro;
9. distribuir métricas financeiras para o grão da fato;
10. reconciliar os valores após a distribuição;
11. separar criação física da carga incremental;
12. validar formalmente o modelo com controles de Data Quality.


## 28. Conclusão

O modelo dimensional foi construído para preservar simultaneamente:

- granularidade;
- histórico;
- integridade;
- eventos sem dimensão disponível;
- consistência financeira;
- facilidade de consumo analítico.

A definição explícita do grão, combinada com Surrogate Keys, SCD Tipo 2, Default
Members e controles de reconciliação, permite que a camada Business funcione como
fonte semântica confiável para os produtos da camada Information.