# Implementação — Camada Information

## 1. Objetivo

Implementar a camada `information` do projeto `engenharia_analytics_saude`, disponibilizando um produto analítico certificado e orientado ao consumo a partir do modelo dimensional consolidado na camada Business.

## 2. Produto Analítico

Será implementada inicialmente a View:

`vw_analise_procedimentos`

Granularidade:

`1 linha = 1 procedimento realizado dentro de 1 atendimento, enriquecido com seu contexto dimensional`

## 3. Fontes

A camada Information utilizará exclusivamente objetos da camada Business:

- `business.fct_procedimentos`
- `business.dim_paciente`
- `business.dim_procedimento`
- `business.dim_unidade`
- `business.dim_medico`
- `business.dim_data`

Nenhum objeto das camadas Raw ou Staging será acessado diretamente.

## 4. Responsabilidade

A camada Information será responsável por:

- simplificar o consumo do modelo dimensional;
- disponibilizar atributos dimensionais junto às métricas da fato;
- utilizar nomenclatura orientada ao consumo analítico;
- disponibilizar métricas já consolidadas pela Business;
- reduzir a necessidade de joins pelo consumidor;
- expor de forma simples situações de Default Member relevantes ao consumo.

Nenhuma regra de negócio já consolidada na Business deverá ser recalculada nesta camada.

## 5. Estratégia de Materialização

O produto será inicialmente implementado como `VIEW`.

A escolha considera:

- baixo volume atual;
- ausência de requisito de materialização;
- ausência de evidência de gargalo de performance;
- simplicidade operacional;
- redução de armazenamento e processamento desnecessários.

Materialized Views ou outras estratégias de materialização poderão ser avaliadas futuramente caso existam requisitos comprovados de performance ou latência.

## 6. Late Arriving Dimension

Os registros associados ao Default Member da `dim_paciente` serão preservados.

A camada Information disponibilizará uma flag analítica que permita identificar esses registros sem exigir que o consumidor conheça a implementação técnica da Surrogate Key padrão.

## 7. Princípios VDAE

A implementação seguirá os princípios de:

- consumo orientado ao negócio;
- métricas certificadas;
- ausência de duplicação de regras;
- nomenclatura semântica;
- granularidade explícita;
- rastreabilidade;
- FinOps;
- documentação anterior à implementação.