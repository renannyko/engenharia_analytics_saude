# FinOps

## 1. Visão Geral

O projeto `engenharia_analytics_saude` considera FinOps como parte das decisões
arquiteturais da solução.

No Snowflake, os recursos de compute utilizados pelos Virtual Warehouses possuem
impacto direto no consumo de créditos.

Por isso, decisões relacionadas a:

- quantidade de Warehouses;
- tamanho;
- tempo de suspensão;
- retomada automática;
- concorrência;
- escalabilidade;
- separação de workloads;

devem considerar simultaneamente custo, performance e necessidade operacional.

A estratégia adotada no projeto segue o princípio:

**começar pequeno, medir e escalar com base em evidências.**


## 2. Estratégia de Compute

Foram definidos dois Virtual Warehouses:

- `wh_transformacao_dev`;
- `wh_bi_dev`.

A separação foi realizada de acordo com a natureza dos workloads.


## 3. Warehouse de Transformação

### `wh_transformacao_dev`

Responsável pelos workloads relacionados à engenharia e transformação dos dados.

Entre suas responsabilidades estão:

- ingestão;
- transformação;
- processamento da Staging;
- processamento da Business;
- cargas incrementais;
- execução de controles de Data Quality;
- operações de desenvolvimento relacionadas ao pipeline.


## 4. Warehouse de BI

### `wh_bi_dev`

Responsável pelos workloads relacionados ao consumo analítico.

Seu objetivo é atender principalmente:

- consultas analíticas;
- consumo da camada Information;
- ferramentas de BI;
- exploração dos produtos de dados.

Essa separação reduz a interferência entre processamento e consumo.


## 5. Isolamento de Workloads

A utilização de Warehouses independentes permite separar:

Transformação
    ↓
wh_transformacao_dev

Consumo
    ↓
wh_bi_dev

Como os Warehouses possuem recursos de compute independentes, consultas analíticas
não precisam competir diretamente pelos mesmos recursos utilizados pelas
transformações.

Essa arquitetura melhora o isolamento operacional.


## 6. Configuração Inicial

Os dois Warehouses foram configurados inicialmente como:

- tamanho: `X-SMALL`;
- `AUTO_SUSPEND = 60`;
- `AUTO_RESUME = TRUE`.

Representação:

wh_transformacao_dev
    ├── X-Small
    ├── AUTO_SUSPEND = 60
    └── AUTO_RESUME = TRUE

wh_bi_dev
    ├── X-Small
    ├── AUTO_SUSPEND = 60
    └── AUTO_RESUME = TRUE


## 7. Escolha do X-Small

O tamanho X-Small foi escolhido como ponto inicial para o ambiente de desenvolvimento.

A decisão evita superdimensionar o ambiente antes da existência de evidências que
justifiquem recursos adicionais.

O princípio utilizado é:

não escolher compute maior preventivamente
        ↓
começar com X-Small
        ↓
observar execução
        ↓
medir performance
        ↓
identificar gargalos
        ↓
redimensionar somente quando necessário


## 8. Escalabilidade Vertical

Caso o Warehouse se torne insuficiente para determinado workload, seu tamanho pode
ser aumentado.

Exemplo conceitual:

X-Small
   ↓
Small
   ↓
Medium
   ↓
Large

O aumento de tamanho disponibiliza mais recursos de compute, mas também altera o
consumo de créditos.

Portanto, aumentar o Warehouse deve ser uma decisão orientada por métricas.


## 9. Warehouse Maior não é Sempre a Primeira Solução

Uma query lenta não significa automaticamente que o Warehouse precisa ser aumentado.

Antes do scale-up, devem ser avaliados fatores como:

- volume processado;
- filtros utilizados;
- quantidade de dados lidos;
- joins;
- cardinalidade;
- agregações;
- lógica SQL;
- concorrência;
- frequência de execução;
- perfil da carga.

O processo recomendado é:

problema de performance
        ↓
investigar
        ↓
otimizar quando aplicável
        ↓
medir novamente
        ↓
avaliar scale-up


## 10. AUTO_SUSPEND

Foi configurado:

`AUTO_SUSPEND = 60`

Isso significa que um Warehouse ocioso pode ser suspenso automaticamente após o
período configurado.

O objetivo é evitar que compute permaneça ativo sem necessidade.

Conceitualmente:

query executada
    ↓
Warehouse ativo
    ↓
fim da atividade
    ↓
período de ociosidade
    ↓
AUTO_SUSPEND
    ↓
Warehouse suspenso


## 11. Importância do AUTO_SUSPEND para FinOps

Em ambientes de desenvolvimento, a utilização do Warehouse tende a ocorrer em
intervalos.

Sem suspensão automática, existe maior risco de manter compute ativo durante períodos
em que nenhum processamento está sendo realizado.

A suspensão automática reduz esse risco e é especialmente importante em ambientes
pessoais, de desenvolvimento e workloads intermitentes.


## 12. AUTO_RESUME

Também foi configurado:

`AUTO_RESUME = TRUE`

Essa opção permite que um Warehouse suspenso seja retomado automaticamente quando
uma nova operação precisar utilizá-lo.

O fluxo fica:

Warehouse suspenso
        ↓
nova query
        ↓
AUTO_RESUME
        ↓
Warehouse iniciado
        ↓
execução

Isso combina controle de custos com conveniência operacional.


## 13. Relação AUTO_SUSPEND e AUTO_RESUME

A combinação utilizada foi:

`AUTO_SUSPEND = 60`

+

`AUTO_RESUME = TRUE`

O objetivo é permitir:

uso quando necessário
        ↓
suspensão durante ociosidade
        ↓
retomada automática na próxima demanda

Essa configuração é adequada ao padrão de utilização do ambiente de desenvolvimento
deste projeto.


## 14. Separação entre Transformação e BI

A decisão de utilizar dois Warehouses também possui uma dimensão de FinOps.

Ela permite analisar separadamente o consumo associado a:

- engenharia e transformação;
- consumo analítico.

Conceitualmente:

wh_transformacao_dev
        ↓
custo do pipeline

wh_bi_dev
        ↓
custo de consumo

Em um ambiente corporativo, essa separação facilita atribuição, análise e otimização
dos custos por workload.


## 15. Trade-off da Separação

A separação de Warehouses não significa necessariamente que dois Warehouses devem
permanecer ativos simultaneamente.

Cada Warehouse possui seu próprio ciclo de:

ativação
    ↓
execução
    ↓
ociosidade
    ↓
suspensão

Com `AUTO_SUSPEND`, workloads independentes podem permanecer suspensos quando não
estão sendo utilizados.


## 16. Multi-cluster Warehouse

Multi-cluster Warehouse não foi habilitado no ambiente pessoal deste projeto.

A decisão foi intencional.

O ambiente possui:

- baixo volume;
- poucos usuários;
- baixa concorrência;
- finalidade educacional e de desenvolvimento.

Nesse cenário, adicionar capacidade para múltiplos clusters não apresentaria benefício
proporcional à complexidade e ao potencial consumo adicional.


## 17. Quando Avaliar Multi-cluster

Em um ambiente corporativo, Multi-cluster pode ser avaliado quando existe concorrência
significativa.

Exemplo:

Usuário A ─┐
Usuário B ─┤
Usuário C ─┼──→ Warehouse
Usuário D ─┤
Usuário E ─┘
            ↓
       alta concorrência

Nessa situação, o problema pode não ser uma única query pesada, mas muitas consultas
competindo simultaneamente por capacidade.


## 18. Scale-up versus Scale-out

Existem dois problemas diferentes que devem ser distinguidos.

### Scale-up

Aumentar o tamanho do Warehouse.

Mais relacionado a:

- queries individualmente pesadas;
- necessidade de maior capacidade computacional para determinado processamento.


### Scale-out

Aumentar capacidade para atender maior concorrência.

Mais relacionado a:

- múltiplas consultas simultâneas;
- filas;
- muitos consumidores concorrentes.

Multi-cluster está associado principalmente ao segundo cenário.

Portanto:

query pesada
    ≠
necessariamente problema de concorrência

e:

alta concorrência
    ≠
necessariamente necessidade de Warehouse individual maior


## 19. Monitoramento antes de Escalar

A estratégia recomendada para evolução do compute é:

1. iniciar com sizing conservador;
2. medir comportamento;
3. identificar gargalos;
4. distinguir performance de concorrência;
5. otimizar consultas quando aplicável;
6. avaliar scale-up;
7. avaliar scale-out quando houver concorrência;
8. medir novamente após a alteração.

Esse ciclo evita decisões baseadas apenas em percepção.


## 20. Armazenamento e Compute

Uma característica importante da arquitetura Snowflake é a separação entre
armazenamento e compute.

Isso permite que os mesmos dados sejam consultados por Warehouses diferentes sem
necessidade de duplicar fisicamente o dataset apenas para separar os workloads.

No projeto:

dados
   ↓
Snowflake Storage
   ↓
   ├── wh_transformacao_dev
   └── wh_bi_dev

Essa separação facilita isolamento e escalabilidade.


## 21. Desenvolvimento versus Produção

A configuração adotada é adequada ao contexto atual de desenvolvimento.

Um ambiente de produção deve ser dimensionado com base em características reais,
como:

- volume;
- frequência;
- SLA;
- concorrência;
- janelas de processamento;
- tempo máximo aceitável;
- quantidade de usuários;
- criticidade do workload.

Portanto, X-Small não deve ser interpretado como tamanho universal para todos os
ambientes.


## 22. Ambientes Separados

Em uma evolução corporativa, a solução pode utilizar ambientes independentes:

DEV
QA
PROD

Cada ambiente pode possuir:

- Warehouses próprios;
- sizing diferente;
- políticas diferentes;
- limites de consumo diferentes.

Exemplo:

DEV
    ↓
sizing conservador

QA
    ↓
capacidade compatível com testes

PROD
    ↓
dimensionamento baseado em SLA e workload


## 23. Resource Monitors

Uma evolução recomendada para ambientes corporativos é a utilização de mecanismos de
monitoramento e controle de consumo.

Resource Monitors podem fazer parte dessa estratégia para acompanhar utilização de
créditos e estabelecer ações ou notificações conforme limites definidos.

Isso adiciona uma camada preventiva de governança financeira.


## 24. Tags e Atribuição de Custos

Em ambientes maiores, objetos e recursos podem ser organizados de forma a facilitar
atribuição de custos.

Exemplos de dimensões úteis para análise:

- ambiente;
- domínio;
- equipe;
- produto de dados;
- centro de custo;
- tipo de workload.

Isso ajuda a responder perguntas como:

- qual ambiente consome mais?
- quanto custa transformação?
- quanto custa BI?
- qual produto possui maior custo computacional?


## 25. Query History e Análise de Consumo

A otimização de FinOps deve ser baseada em evidências operacionais.

Histórico de queries e métricas de utilização podem ajudar a identificar:

- consultas frequentes;
- consultas demoradas;
- períodos de maior utilização;
- Warehouses pouco utilizados;
- padrões de concorrência;
- oportunidades de otimização.


## 26. Custo versus Performance

FinOps não significa simplesmente minimizar o custo.

O objetivo é equilibrar:

CUSTO
   ↕
PERFORMANCE
   ↕
NECESSIDADE DE NEGÓCIO

Reduzir compute excessivamente pode comprometer SLAs.

Aumentar compute sem necessidade pode gerar desperdício.

A decisão adequada busca eficiência econômica sem comprometer o serviço esperado.


## 27. FinOps e Camada Information

A criação de produtos analíticos adequados também pode contribuir para eficiência.

A solução possui:

- uma View detalhada;
- uma estrutura agregada mensal.

Para determinados casos de uso, consumir uma estrutura já preparada e com
granularidade adequada pode evitar repetição desnecessária de transformações complexas
na ferramenta de BI.

A decisão deve considerar o padrão real de consumo.


## 28. FinOps e Data Quality

Controles de Data Quality também consomem compute.

Por isso, em ambientes maiores devem ser consideradas decisões como:

- frequência dos testes;
- criticidade;
- volume analisado;
- execução incremental;
- horário de execução;
- testes bloqueantes versus informativos.

Nem todo controle precisa necessariamente executar com a mesma frequência.


## 29. FinOps e CI/CD

Processos automatizados também devem considerar eficiência.

Um pipeline de CI/CD pode, por exemplo:

- executar somente objetos alterados quando apropriado;
- evitar recriações desnecessárias;
- utilizar Warehouses adequados ao workload;
- suspender recursos ociosos;
- executar controles críticos antes de promoção.

Automação sem governança pode apenas automatizar desperdício.


## 30. Estratégia FinOps do Projeto

A estratégia adotada pode ser resumida como:

                        WORKLOADS
                           |
             +-------------+-------------+
             |                           |
      Transformação                      BI
             |                           |
wh_transformacao_dev               wh_bi_dev
             |                           |
          X-Small                     X-Small
             |                           |
 AUTO_SUSPEND = 60             AUTO_SUSPEND = 60
 AUTO_RESUME = TRUE            AUTO_RESUME = TRUE

             ↓                           ↓

        medir consumo               medir consumo
             ↓                           ↓
       avaliar sizing              avaliar sizing


## 31. Decisões Implementadas

As principais decisões de FinOps implementadas no projeto foram:

1. separar compute de transformação e BI;
2. iniciar ambos os Warehouses em X-Small;
3. habilitar `AUTO_SUSPEND = 60`;
4. habilitar `AUTO_RESUME = TRUE`;
5. não habilitar Multi-cluster no ambiente pessoal;
6. evitar sizing preventivo;
7. manter possibilidade de scale-up conforme evidências;
8. considerar concorrência separadamente de performance individual.


## 32. Evoluções Recomendadas

Em um cenário corporativo, a estratégia poderia evoluir com:

- Resource Monitors;
- budgets e alertas;
- análise recorrente de consumo;
- atribuição de custos por domínio;
- tags para classificação;
- políticas por ambiente;
- monitoramento de Query History;
- análise de filas e concorrência;
- definição de SLAs;
- dimensionamento específico por workload;
- Multi-cluster quando justificado;
- otimização contínua baseada em métricas.


## 33. Conclusão

A estratégia de FinOps do projeto foi desenhada para equilibrar simplicidade,
performance e controle de custos.

A utilização de dois Warehouses independentes permite isolamento entre transformação
e consumo analítico, enquanto o sizing X-Small e a suspensão automática evitam
superdimensionamento no ambiente de desenvolvimento.

A principal diretriz adotada é:

**dimensionar com base em evidências, não em antecipação.**

Essa abordagem permite que a arquitetura cresça conforme a necessidade sem assumir
custos adicionais antes que eles sejam tecnicamente justificados.