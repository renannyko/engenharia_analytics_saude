# Implementação — Modelo Dimensional Business

## 1. Objetivo

Implementar a camada `business` do projeto `engenharia_analytics_saude`, responsável pela aplicação das regras de negócio corporativas e pela construção do modelo dimensional utilizado pelas camadas analíticas posteriores.

A implementação seguirá os princípios da metodologia VDAE, com modelagem dimensional baseada em Kimball, utilização de Surrogate Keys, tratamento de dimensões históricas e construção de fato incremental.

## 2. Fontes

A camada Business utilizará exclusivamente objetos da camada Staging:

* `staging.stg_atendimentos`
* `staging.stg_procedimentos_itens`
* `staging.stg_cadastro_pacientes`

Nenhum objeto da camada Raw será referenciado diretamente pela Business.

## 3. Modelo dimensional proposto

O modelo será estruturado em torno da fato:

`fct_procedimentos`

Dimensões relacionadas:

* `dim_paciente`
* `dim_procedimento`
* `dim_unidade`
* `dim_medico`
* `dim_data`

Representação conceitual:

`dim_paciente → fct_procedimentos ← dim_procedimento`

`dim_data → fct_procedimentos ← dim_unidade`

`dim_medico → fct_procedimentos`

## 4. Granularidade da fato

A granularidade da `fct_procedimentos` será:

`1 linha = 1 procedimento/item realizado dentro de 1 atendimento`

O identificador natural `id_item` representa o grão transacional da fato.

Não será criada uma fato adicional de atendimentos, pois o identificador `id_atendimento` permanecerá disponível na `fct_procedimentos`, permitindo análises no nível de atendimento sem necessidade de duplicar estruturas fato.

## 5. Surrogate Keys

Conforme o padrão VDAE, as Surrogate Keys da camada Business serão materializadas como strings MD5 determinísticas.

### Procedimento

`id_sk_procedimento = MD5(cd_procedimento)`

### Unidade

`id_sk_unidade = MD5(id_unidade)`

### Médico

`id_sk_medico = MD5(id_medico)`

### Data

A chave substituta da dimensão de data será determinística a partir da própria data.

### Paciente

Como a dimensão de pacientes utilizará SCD Tipo 2, a Surrogate Key deverá identificar uma versão específica do paciente:

`id_sk_paciente = MD5(id_paciente || '|' || dt_inicio_vigencia)`

### Fato

A chave da fato será determinística a partir do identificador do item:

`id_sk_fato_procedimento = MD5(id_item)`

## 6. Default Member

As dimensões deverão possuir registro padrão para tratamento de chaves nulas, não mapeadas ou Late Arriving Dimensions.

Como as Surrogate Keys serão strings MD5, será utilizada uma chave padrão determinística gerada a partir do valor reservado `-1`.

Exemplo:

`MD5('-1')`

Os atributos de negócio do registro padrão utilizarão valores como:

* `-1`
* `NÃO INFORMADO`

A fato utilizará a chave padrão quando não houver correspondência dimensional válida.

## 7. Dimensão de Pacientes — SCD Tipo 2

A `dim_paciente` preservará o histórico completo das alterações cadastrais relevantes.

Estrutura prevista:

* `id_sk_paciente`
* `id_paciente`
* `ds_nome`
* `ds_plano_saude`
* `ds_cidade`
* `dt_inicio_vigencia`
* `dt_fim_vigencia`
* `lg_atual`
* `dt_insercao`

### Vigência

A coluna `dt_inicio_vigencia` utilizará o valor de `dt_atualizacao` recebido da Staging.

A próxima versão do mesmo paciente será identificada com função analítica `LEAD`.

A coluna `dt_fim_vigencia` utilizará o início da próxima versão como limite de vigência.

Para a versão atual será utilizado um limite aberto representado por timestamp futuro.

A coluna `lg_atual` será `TRUE` para a versão vigente e `FALSE` para versões históricas.

## 8. Late Arriving Dimensions

O profiling identificou 10 atendimentos cuja data é anterior à primeira versão cadastral conhecida do respectivo paciente.

Esses registros não serão artificialmente associados à primeira versão disponível.

Nesses casos, a `fct_procedimentos` deverá utilizar o Default Member da `dim_paciente`.

Essa decisão evita inventar informação histórica não disponível na origem e preserva a integridade temporal do modelo.

## 9. Dimensão de Procedimentos

A `dim_procedimento` terá granularidade:

`1 linha = 1 procedimento de negócio`

Estrutura prevista:

* `id_sk_procedimento`
* `cd_procedimento`
* `ds_procedimento`
* `dt_insercao`

## 10. Dimensão de Unidades

O conjunto de dados disponibilizado possui apenas o identificador da unidade.

A dimensão será inicialmente mínima:

* `id_sk_unidade`
* `id_unidade`
* `dt_insercao`

A arquitetura permanecerá preparada para enriquecimento futuro por fonte mestre de unidades.

## 11. Dimensão de Médicos

O conjunto de dados disponibilizado possui apenas o identificador do médico executante.

A dimensão será inicialmente mínima:

* `id_sk_medico`
* `id_medico`
* `dt_insercao`

A arquitetura permanecerá preparada para enriquecimento futuro por fonte mestre de profissionais.

## 12. Dimensão de Data

A `dim_data` será utilizada para análises temporais da fato.

A dimensão será derivada das datas disponíveis nos atendimentos e preparada para atributos de calendário relevantes ao consumo analítico.

## 13. Fato de Procedimentos

A `fct_procedimentos` deverá conter inicialmente:

* `id_sk_fato_procedimento`
* `id_item`
* `id_atendimento`
* `id_sk_paciente`
* `id_sk_procedimento`
* `id_sk_unidade`
* `id_sk_medico`
* `id_sk_data`
* `dt_atendimento`
* `ds_tipo_atendimento`
* `ds_status`
* `vl_item_bruto`
* `vl_desconto_item`
* `vl_item_liquido`
* `dt_insercao`

## 14. Rateio proporcional de desconto

O desconto concedido no atendimento será distribuído proporcionalmente entre os procedimentos.

Fórmula:

`vl_desconto_item = vl_desconto_atendimento * (vl_item / soma_vl_item_atendimento)`

O valor líquido do item será:

`vl_item_liquido = vl_item_bruto - vl_desconto_item`

A soma dos valores líquidos dos itens deverá reconciliar com o valor líquido do atendimento.

## 15. Regra de faturamento por status

O conjunto de dados apresenta atendimentos com status `CANCELADO` e `EM ANDAMENTO` contendo valores financeiros.

Como não foi fornecida uma regra de negócio determinando quais status devem ou não compor faturamento, nenhuma exclusão será aplicada nesta etapa.

Os registros serão preservados e o status permanecerá disponível para análise e definição futura de métricas específicas.

## 16. Estratégia incremental da fato

Conforme o padrão VDAE, a tabela `fct_` deverá ser incremental.

No Snowflake, a implementação utilizará `MERGE`.

A chave determinística da fato será baseada em `id_item`.

Comportamento esperado:

* novo `id_item` → `INSERT`;
* `id_item` já existente → `UPDATE`.

A implementação deverá ser idempotente e permitir reexecução sem geração de duplicidades.

## 17. Qualidade de Dados

A implementação deverá permitir controles posteriores relacionados a:

* unicidade das Surrogate Keys;
* completude das chaves;
* integridade referencial;
* existência de apenas uma versão atual por paciente;
* ausência de sobreposição de vigências SCD Tipo 2;
* consistência do rateio de descontos;
* reconciliação do valor líquido dos itens com o atendimento;
* utilização controlada do Default Member.

Os testes formais serão implementados em `05_qualidade_dados`.

## 18. Critérios de validação

A implementação será considerada válida quando:

* todas as dimensões previstas estiverem criadas;
* as Surrogate Keys forem determinísticas;
* os Default Members estiverem disponíveis;
* o histórico de pacientes estiver corretamente representado;
* existir no máximo uma versão atual por paciente;
* os 10 atendimentos anteriores ao primeiro cadastro utilizarem corretamente o Default Member;
* a fato respeitar a granularidade definida;
* o rateio de desconto reconciliar com os valores do atendimento;
* a fato puder ser reexecutada sem duplicidades;
* os objetos utilizarem nomenclatura conforme VDAE;
* `dt_insercao` permanecer como última coluna;
* os scripts estiverem versionados no Git.

## 19. Alinhamento VDAE

A implementação está alinhada aos princípios VDAE de:

* modelagem dimensional na camada Business;
* granularidade explicitamente definida;
* utilização de Surrogate Keys MD5;
* implementação de SCD Tipo 2 quando o histórico altera o contexto analítico;
* utilização de Default Member para Late Arriving Dimensions;
* fatos incrementais;
* separação entre regras de negócio e tratamento técnico;
* qualidade de dados incorporada à arquitetura;
* documentação antes da implementação.

## 20. Resultado da Implementação

A implementação da camada Business foi concluída e validada com sucesso no ambiente `dev`.

### Objetos implementados

Foram implementados no schema `business`:

- `dim_procedimento`;
- `dim_unidade`;
- `dim_medico`;
- `dim_data`;
- `dim_paciente`;
- `fct_procedimentos`.

A implementação da fato foi separada em dois scripts:

- `06_criacao_fct_procedimentos.sql` — provisionamento da estrutura física;
- `07_carga_fct_procedimentos.sql` — processamento incremental por meio de `MERGE`.

Essa separação mantém responsabilidade única por script e facilita operação, CI/CD, rastreabilidade e troubleshooting.

## 21. Validação das Dimensões

As dimensões foram validadas quanto à unicidade e preenchimento das Surrogate Keys.

As Surrogate Keys foram implementadas como strings MD5 determinísticas, conforme o padrão definido pelo VDAE.

Também foram implementados Default Members utilizando a chave determinística:

`MD5('-1')`

A utilização do Default Member permite que referências não mapeadas sejam representadas sem utilização de chaves estrangeiras nulas.

### Dimensões sem fonte mestre

As dimensões `dim_unidade` e `dim_medico` foram implementadas como dimensões mínimas.

As fontes disponibilizadas fornecem apenas seus respectivos identificadores.

Nenhum atributo inexistente na origem foi artificialmente criado.

A arquitetura permanece preparada para enriquecimento futuro por fontes mestre.

## 22. Validação da Dimensão de Pacientes

A `dim_paciente` foi implementada utilizando Slowly Changing Dimension Tipo 2.

A granularidade definida foi:

`1 linha = 1 versão histórica de 1 paciente`

Foram preservadas as diferentes versões cadastrais existentes na origem.

Os pacientes identificados com múltiplas versões foram:

| Paciente | Quantidade de versões |
|---|---:|
| PAC_001 | 2 |
| PAC_002 | 2 |
| PAC_006 | 2 |

As validações confirmaram que:

- cada versão possui Surrogate Key própria;
- a versão anterior possui `lg_atual = FALSE`;
- a versão mais recente possui `lg_atual = TRUE`;
- o fim da vigência anterior coincide com o início da próxima vigência;
- não foi necessário modificar artificialmente o histórico recebido.

A regra temporal utilizada para relacionamento com a fato é:

`dt_atendimento >= dt_inicio_vigencia`

e

`dt_atendimento < dt_fim_vigencia`

O limite final da vigência é, portanto, exclusivo.

## 23. Late Arriving Dimensions

A análise temporal confirmou a existência de 10 atendimentos ocorridos antes da primeira versão cadastral conhecida do respectivo paciente.

Esses registros não foram artificialmente associados à primeira versão disponível.

A `fct_procedimentos` utiliza o Default Member da `dim_paciente` nesses casos.

Essa estratégia representa explicitamente a ausência de informação histórica e evita atribuir ao passado atributos cadastrais que somente foram conhecidos posteriormente.

## 24. Validação da Fato

A `fct_procedimentos` foi implementada com granularidade:

`1 linha = 1 procedimento/item realizado dentro de 1 atendimento`

A chave natural de grão é:

`id_item`

A Surrogate Key da fato é determinística:

`MD5(id_item)`

A carga inicial apresentou:

- 155 registros;
- 155 `id_item` distintos;
- 155 Surrogate Keys distintas.

Não foram identificadas duplicidades no grão da fato.

## 25. Estratégia Incremental

A carga da `fct_procedimentos` foi implementada utilizando `MERGE`.

O comportamento definido é:

- registro inexistente → `INSERT`;
- registro existente com alteração relevante → `UPDATE`;
- registro existente sem alteração → nenhuma operação.

A condição de atualização compara os atributos relevantes utilizando `IS DISTINCT FROM`.

Essa estratégia evita atualizações desnecessárias e reduz processamento em reexecuções sem alteração dos dados.

A coluna `dt_insercao` representa o momento de inserção física do registro na fato e não é modificada durante `UPDATE`.

A reexecução da carga sem alteração das fontes foi validada e não modificou os valores existentes de `dt_insercao`.

A implementação demonstrou comportamento idempotente para o conjunto de dados validado.

## 26. Rateio Proporcional de Desconto

O desconto registrado no nível do atendimento foi distribuído proporcionalmente entre seus procedimentos.

A regra implementada foi:

`vl_desconto_item = vl_desconto_atendimento * (vl_item / soma_vl_item_atendimento)`

O valor líquido do procedimento foi calculado como:

`vl_item_liquido = vl_item_bruto - vl_desconto_item`

Foi implementada proteção contra divisão por zero utilizando `NULLIF`.

Os valores monetários finais foram materializados como `NUMBER(18,2)`.

## 27. Reconciliação Financeira

Foi realizada reconciliação financeira entre a camada Staging, no nível de atendimento, e a `fct_procedimentos`, após o rateio.

Foram avaliados os 60 atendimentos do conjunto de dados.

As validações confirmaram ausência de divergências para:

- valor bruto;
- desconto;
- valor líquido.

Resultado:

| Métrica | Origem | Fato | Diferença |
|---|---:|---:|---:|
| Valor bruto | 41.285,00 | 41.285,00 | 0,00 |
| Desconto | 2.767,25 | 2.767,25 | 0,00 |
| Valor líquido | 38.517,75 | 38.517,75 | 0,00 |

Os 60 atendimentos apresentaram diferença igual a `0,00` nas três métricas reconciliadas.

A regra de rateio apresentou, portanto, reconciliação integral para o conjunto de dados utilizado no exercício.

## 28. Decisões de Modelagem

Foi implementada uma única fato principal:

`fct_procedimentos`

Não foi criada uma `fct_atendimentos`.

Essa decisão evita duplicação desnecessária de estruturas, pois `id_atendimento` permanece disponível na fato de procedimentos e permite análises agregadas no nível do atendimento.

O modelo Business final é composto por:

- uma fato de procedimentos;
- dimensão de pacientes histórica;
- dimensão de procedimentos;
- dimensão de unidades;
- dimensão de médicos;
- dimensão de datas.

## 29. Qualidade de Dados

Durante a implementação foram realizadas validações técnicas relacionadas a:

- unicidade de Surrogate Keys;
- ausência de SKs nulas;
- existência controlada de Default Members;
- granularidade da fato;
- histórico SCD Tipo 2;
- vigência temporal;
- Late Arriving Dimensions;
- incrementalidade;
- idempotência;
- reconciliação financeira.

Essas verificações foram utilizadas como validações da implementação.

Os controles formais e permanentes serão posteriormente versionados em:

`sql/05_qualidade_dados`

## 30. Status

Camada Business implementada e validada com sucesso no ambiente `dev`.

A solução encontra-se preparada para construção da camada Information e posterior implementação dos controles formais de Data Quality.