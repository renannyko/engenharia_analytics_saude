# Implementação — Qualidade de Dados

## 1. Objetivo

Implementar controles formais, reproduzíveis e versionados de Data Quality para o projeto `engenharia_analytics_saude`.

Os controles deverão validar a integridade dos dados ao longo das camadas Raw, Staging, Business e Information.

## 2. Princípios

Os controles serão implementados seguindo os princípios de Data Quality definidos pela metodologia VDAE e pelas dimensões DAMA aplicáveis ao projeto.

Serão avaliadas principalmente:

- Unicidade;
- Completude;
- Consistência;
- Acurácia;
- Validade;
- Integridade Referencial.

## 3. Estratégia

Os testes serão implementados em SQL e versionados juntamente com o projeto.

Sempre que aplicável, cada teste deverá retornar:

- identificação do teste;
- quantidade de registros inválidos;
- status da validação.

O padrão esperado será:

`qt_erros = 0 → APROVADO`

`qt_erros > 0 → REPROVADO`

## 4. Escopo

Os controles serão organizados em:

- `01_dq_raw.sql`
- `02_dq_staging.sql`
- `03_dq_business_dimensoes.sql`
- `04_dq_business_scd2.sql`
- `05_dq_business_fato.sql`
- `06_dq_reconciliacao_financeira.sql`
- `07_dq_information.sql`

## 5. Raw

Serão avaliados controles relacionados principalmente a:

- volumetria;
- presença dos registros ingeridos;
- rastreabilidade da ingestão;
- preservação do dado recebido.

## 6. Staging

Serão avaliados:

- sucesso das conversões de tipos;
- completude de campos críticos;
- preservação da volumetria Raw → Staging;
- validade dos dados tecnicamente tratados.

## 7. Business — Dimensões

Serão avaliados:

- unicidade das Surrogate Keys;
- ausência de SKs nulas;
- unicidade das chaves naturais quando aplicável;
- existência controlada de Default Members.

## 8. Business — SCD Tipo 2

A `dim_paciente` terá controles específicos para:

- unicidade das versões;
- existência de no máximo uma versão atual por paciente;
- continuidade das vigências;
- ausência de sobreposição temporal;
- consistência entre `lg_atual` e as datas de vigência.

## 9. Business — Fato

A `fct_procedimentos` será validada quanto a:

- unicidade do grão `id_item`;
- unicidade da Surrogate Key da fato;
- ausência de chaves dimensionais nulas;
- integridade referencial com todas as dimensões;
- utilização controlada do Default Member.

## 10. Reconciliação Financeira

Serão implementados controles de acurácia para validar:

- valor bruto;
- desconto;
- valor líquido.

A soma dos valores da fato deverá reconciliar com os valores existentes no nível do atendimento.

## 11. Information

Os produtos analíticos serão validados quanto a:

- preservação da granularidade esperada;
- reconciliação com a Business;
- consistência das métricas agregadas;
- preservação dos registros associados a Default Members.

## 12. Critério de Aprovação

Sempre que aplicável:

`0 registros inválidos = APROVADO`

`1 ou mais registros inválidos = REPROVADO`

Os controles deverão ser executáveis novamente sem alteração dos dados avaliados.

## 13. Resultado da Implementação

A implementação dos controles formais de Data Quality foi concluída e validada com sucesso no ambiente `dev`.

### Objetos implementados

Foram criadas no schema `qualidade_dados` as seguintes Views de controle:

- `dq_raw`;
- `dq_staging`;
- `dq_business_dimensoes`;
- `dq_business_scd2`;
- `dq_business_fato`;
- `dq_reconciliacao_financeira`;
- `dq_information`;
- `dq_resumo_qualidade`.

### Estrutura dos controles

Os testes foram padronizados com os campos:

- `id_teste`;
- `ds_teste`;
- `ds_dimensao_dq`;
- `qt_erros`;
- `ds_status`.

O critério geral adotado foi:

`qt_erros = 0 → APROVADO`

`qt_erros > 0 → REPROVADO`

### Resultado consolidado

Foram implementados e executados 80 controles formais de Data Quality.

Resultado final:

- 80 testes executados;
- 80 testes aprovados;
- 0 testes reprovados;
- 100% de aprovação.

### Distribuição por escopo

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

### Dimensões de Data Quality avaliadas

Os controles implementados cobrem principalmente:

- Unicidade;
- Completude;
- Validade;
- Acurácia;
- Consistência;
- Integridade Referencial.

### Raw

Foram validados:

- presença dos dados;
- volumetria esperada das três fontes.

### Staging

Foram validados:

- reconciliação de volumetria Raw versus Staging;
- completude de campos críticos;
- validade das conversões;
- unicidade das chaves de grão;
- preservação do histórico cadastral.

### Business — Dimensões

Foram validados:

- unicidade das Surrogate Keys;
- ausência de SKs nulas;
- unicidade das chaves naturais quando aplicável;
- existência controlada dos Default Members.

### Business — SCD Tipo 2

A `dim_paciente` foi validada quanto a:

- existência de exatamente uma versão atual por paciente;
- validade dos intervalos de vigência;
- continuidade temporal;
- ausência de sobreposição;
- coerência da flag `lg_atual`;
- unicidade de paciente e início de vigência.

### Business — Fato

A `fct_procedimentos` foi validada quanto a:

- unicidade do grão `id_item`;
- unicidade da Surrogate Key;
- completude das chaves dimensionais;
- integridade referencial;
- completude de campos críticos;
- coerência financeira no nível do item;
- utilização controlada dos Default Members;
- presença dos 10 atendimentos identificados como Late Arriving Dimension de paciente.

### Reconciliação Financeira

Foram formalizados controles de acurácia para reconciliar:

- valor bruto;
- desconto;
- valor líquido.

Os controles foram executados no nível de atendimento e também no total consolidado.

A reconciliação permaneceu integral, sem divergências acima da tolerância definida.

### Information

Foram validados:

- preservação da granularidade da View detalhada;
- unicidade de `id_item`;
- completude de campos de consumo;
- preservação dos Late Arriving Dimensions;
- reconciliação financeira entre Business e Information;
- reconciliação da agregação mensal;
- quantidade de atendimentos.

### Observabilidade de Data Quality

Os controles foram persistidos como Views `dq_`, permitindo consulta recorrente e consumo por processos de CI/CD, monitoramento ou dashboards.

A View:

`dq_resumo_qualidade`

consolida os resultados por escopo e apresenta:

- quantidade de testes;
- quantidade de aprovados;
- quantidade de reprovados;
- quantidade de erros;
- status consolidado.

### Status

Fase de Data Quality concluída e validada com sucesso.

Resultado final:

`80 / 80 testes aprovados`