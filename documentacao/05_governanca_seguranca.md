# Governança e Segurança

## 1. Visão Geral

O projeto `engenharia_analytics_saude` considera governança e segurança como
responsabilidades integrantes da arquitetura de dados.

A implementação foi desenvolvida em um ambiente pessoal de desenvolvimento no
Snowflake, mas foram aplicados princípios que permitem evolução para um cenário
corporativo.

Os principais conceitos considerados foram:

- Role-Based Access Control (RBAC);
- princípio de menor privilégio;
- separação entre administração e execução;
- organização por databases e schemas;
- segregação de responsabilidades;
- rastreabilidade por código versionado;
- documentação das decisões arquiteturais.

Recursos corporativos adicionais, como classificação de dados, Tags, Masking
Policies e Row Access Policies, são tratados neste documento como possíveis
evoluções e não como funcionalidades já implementadas.


## 2. Princípio de Menor Privilégio

O princípio de menor privilégio estabelece que usuários e processos devem possuir
somente os privilégios necessários para executar suas responsabilidades.

Conceitualmente:

usuário ou processo
        ↓
responsabilidade
        ↓
privilégios necessários
        ↓
nenhum privilégio adicional sem justificativa

Essa abordagem reduz exposição desnecessária e melhora a governança do ambiente.


## 3. Role-Based Access Control

O Snowflake utiliza um modelo de controle de acesso baseado em roles.

No projeto, foi utilizada uma role específica para as atividades regulares de
engenharia:

`role_engenharia_analytics`

Essa role representa a responsabilidade operacional do processo de engenharia e
analytics.


## 4. Uso de ACCOUNTADMIN

Durante o setup inicial, determinadas atividades administrativas exigiram
privilégios elevados.

Nesses casos foi utilizado:

`ACCOUNTADMIN`

Entretanto, `ACCOUNTADMIN` não foi adotado como contexto padrão para o
desenvolvimento cotidiano.

A estratégia utilizada foi:

setup administrativo
        ↓
ACCOUNTADMIN

execução normal
        ↓
role_engenharia_analytics

Essa separação evita utilizar uma role administrativa para atividades que não
necessitam desse nível de privilégio.


## 5. Separação entre Administração e Execução

A arquitetura diferencia duas responsabilidades principais.

### Administração

Relacionada a atividades como:

- criação inicial de determinados objetos;
- configuração de privilégios;
- configuração estrutural do ambiente.

Essas operações podem exigir roles administrativas.


### Execução

Relacionada a atividades como:

- ingestão;
- transformação;
- modelagem;
- Data Quality;
- manutenção dos objetos do pipeline.

Essas operações utilizam:

`role_engenharia_analytics`

A separação melhora controle e reduz dependência de privilégios administrativos.


## 6. Contexto de Execução

Os scripts do projeto definem explicitamente o contexto necessário para execução.

Exemplo conceitual:

`USE ROLE role_engenharia_analytics;`

`USE WAREHOUSE wh_transformacao_dev;`

`USE DATABASE engenharia_analytics_saude_dev;`

`USE SCHEMA ...;`

Essa prática reduz dependência do estado anterior da sessão e torna o comportamento
dos scripts mais previsível.


## 7. Organização por Database

O ambiente de desenvolvimento utiliza:

`engenharia_analytics_saude_dev`

O nome identifica:

- o projeto;
- o domínio;
- o ambiente.

Essa convenção facilita evolução futura para ambientes como:

`engenharia_analytics_saude_dev`

`engenharia_analytics_saude_qa`

`engenharia_analytics_saude_prod`

A separação física ou lógica entre ambientes deve ser definida conforme os padrões
da organização.


## 8. Organização por Schemas

As responsabilidades são separadas por schemas.

Entre os principais estão:

- `raw`;
- `staging`;
- `business`;
- `information`;
- `qualidade_dados`.

Essa organização não representa apenas uma convenção de nomes.

Cada schema possui uma responsabilidade arquitetural distinta.


## 9. Raw

O schema:

`raw`

representa a persistência inicial dos dados ingeridos.

Sua responsabilidade é preservar os dados recebidos com o mínimo possível de
transformação.

Em um cenário corporativo, o acesso direto à Raw pode ser mais restritivo, pois
essa camada não representa necessariamente uma interface de consumo para usuários
de negócio.


## 10. Staging

O schema:

`staging`

representa a preparação técnica.

Ele contém estruturas utilizadas internamente pelo pipeline.

A Staging não deve ser considerada, por padrão, uma camada destinada ao consumo
analítico final.


## 11. Business

O schema:

`business`

representa o núcleo semântico da solução.

Ele contém:

- dimensões;
- fato;
- regras de negócio;
- histórico;
- relacionamentos dimensionais.

Em uma arquitetura corporativa, o acesso a essa camada pode ser concedido a
perfis técnicos e analíticos específicos conforme a necessidade.


## 12. Information

O schema:

`information`

representa a interface principal de consumo analítico.

Ele contém produtos preparados para consumidores como:

- analistas;
- dashboards;
- ferramentas de BI;
- aplicações analíticas.

Essa separação reduz a necessidade de consumidores acessarem diretamente estruturas
internas do pipeline.


## 13. Qualidade de Dados

O schema:

`qualidade_dados`

centraliza os objetos de Data Quality.

Foram criadas as Views:

- `dq_raw`;
- `dq_staging`;
- `dq_business_dimensoes`;
- `dq_business_scd2`;
- `dq_business_fato`;
- `dq_reconciliacao_financeira`;
- `dq_information`;
- `dq_resumo_qualidade`.

Essa separação torna os controles de qualidade identificáveis e consultáveis sem
misturá-los com as estruturas de negócio.


## 14. Separação de Compute

A arquitetura utiliza:

`wh_transformacao_dev`

e:

`wh_bi_dev`

A separação possui benefícios de performance e FinOps, mas também contribui para
governança operacional.

Conceitualmente:

engenharia
    ↓
wh_transformacao_dev

consumo analítico
    ↓
wh_bi_dev

Em um cenário corporativo, privilégios de `USAGE` podem ser atribuídos de forma
diferente conforme o perfil de acesso.


## 15. Segregação de Responsabilidades

A arquitetura permite separar responsabilidades entre diferentes tipos de usuário.

Exemplo conceitual:

Administrador
    ↓
configuração e segurança

Engenharia
    ↓
Raw / Staging / Business / Data Quality

Analytics / BI
    ↓
Information

Consumidor
    ↓
produtos analíticos autorizados

O exercício atual não implementa toda essa matriz de roles, mas a organização dos
objetos permite essa evolução.


## 16. Segurança por Camadas

Nem todos os usuários precisam acessar todas as camadas.

Uma estratégia corporativa poderia utilizar:

Raw
    ↓
acesso técnico restrito

Staging
    ↓
engenharia

Business
    ↓
engenharia + analytics autorizado

Information
    ↓
consumidores analíticos

Qualidade
    ↓
engenharia + observabilidade

Esse modelo reduz exposição desnecessária das estruturas internas.


## 17. Governança do Código

Governança não se limita aos objetos dentro do Snowflake.

O código do projeto é mantido fora da plataforma e versionado com Git.

Isso permite:

- histórico de alterações;
- rastreabilidade;
- comparação entre versões;
- reversão;
- revisão;
- colaboração;
- futura automação de CI/CD.


## 18. Git como Registro Técnico

Cada alteração relevante é registrada por meio de commits.

O fluxo adotado durante o exercício é:

alteração
    ↓
validação
    ↓
documentação
    ↓
git add
    ↓
git commit
    ↓
git push

Esse processo cria uma trilha técnica das mudanças realizadas.


## 19. VDAE e Registro de Mudanças

O projeto também utiliza:

`tmp_changes`

e:

`changes`

para documentar decisões e alterações relevantes.

O fluxo utilizado é:

mudança em desenvolvimento
        ↓
tmp_changes
        ↓
implementação
        ↓
validação
        ↓
promoção
        ↓
changes

Essa estratégia complementa o histórico do Git com contexto técnico sobre as
decisões realizadas.


## 20. Governança de Nomenclatura

O projeto utiliza uma convenção padronizada baseada em:

`snake_case`

Exemplos:

`engenharia_analytics_saude_dev`

`wh_transformacao_dev`

`fct_procedimentos`

`dim_paciente`

`dq_business_fato`

A padronização reduz ambiguidades e melhora legibilidade e manutenção.


## 21. Prefixos Semânticos

Também foram utilizados prefixos para indicar a responsabilidade dos objetos.

Exemplos:

`raw_` → dados da camada Raw

`stg_` → estruturas de Staging

`dim_` → dimensões

`fct_` → fatos

`vw_` → Views de consumo

`agg_` → estruturas agregadas

`dq_` → controles de Data Quality

Essa convenção ajuda a identificar rapidamente o papel de cada objeto.


## 22. Dados Sensíveis

O domínio de saúde pode envolver dados sensíveis.

O dataset utilizado no exercício possui finalidade de desenvolvimento e aprendizado,
mas uma implementação corporativa real exigiria análise específica sobre:

- dados pessoais;
- dados sensíveis;
- necessidade de acesso;
- finalidade do tratamento;
- retenção;
- exposição em ambientes não produtivos.

Essas decisões devem seguir as políticas de segurança, privacidade e compliance da
organização.


## 23. Classificação de Dados — Evolução

A classificação de dados não foi implementada no escopo atual.

Em um ambiente corporativo, uma evolução recomendada seria identificar e classificar
colunas conforme sua sensibilidade.

Exemplos conceituais:

- público;
- interno;
- confidencial;
- dado pessoal;
- dado sensível.

A classificação pode servir como base para políticas posteriores de proteção.


## 24. Tags — Evolução

Tags também podem ser utilizadas como mecanismo de governança.

Exemplos de informações que poderiam ser representadas:

- domínio;
- ambiente;
- proprietário;
- criticidade;
- classificação;
- centro de custo;
- produto de dados.

Exemplo conceitual:

objeto
    ↓
tag: dominio = saude
tag: ambiente = prod
tag: classificacao = confidencial

Essa estratégia pode facilitar inventário, governança e atribuição de responsabilidades.


## 25. Masking Policies — Evolução

Masking Policies não foram implementadas no exercício.

Em um cenário corporativo, poderiam ser avaliadas para proteger atributos sensíveis.

Conceitualmente:

usuário autorizado
        ↓
valor real

usuário não autorizado
        ↓
valor mascarado

A política adequada dependeria da classificação do dado e das regras de acesso da
organização.


## 26. Row Access Policies — Evolução

Row Access Policies também não foram implementadas no escopo atual.

Elas poderiam ser utilizadas quando diferentes usuários precisam visualizar
subconjuntos diferentes das mesmas tabelas ou Views.

Exemplo conceitual:

usuário A
    ↓
unidades autorizadas A

usuário B
    ↓
unidades autorizadas B

A necessidade dessa estratégia depende das regras de segurança do negócio.


## 27. Secure Views — Evolução

Em cenários onde a exposição da lógica interna ou dos dados precisa de controles
adicionais, Secure Views podem ser avaliadas.

Essa decisão deve ser orientada pelos requisitos de segurança e pelo modelo de
consumo da organização.

O projeto atual utiliza Views convencionais.


## 28. Governança dos Default Members

Os Default Members fazem parte do modelo dimensional e também precisam possuir
significado governado.

No projeto, a chave natural reservada é:

`-1`

Ela representa um membro padrão utilizado quando não existe correspondência
dimensional válida.

O significado desse valor deve permanecer consistente entre:

- implementação;
- documentação;
- Data Quality;
- consumo analítico.


## 29. Governança do Late Arriving Dimension

O cenário de Late Arriving Dimension de paciente é tratado explicitamente.

Foram identificados 10 atendimentos nessa situação.

A decisão foi:

não excluir o evento
        ↓
utilizar Default Member
        ↓
preservar a fato
        ↓
sinalizar no consumo
        ↓
monitorar por Data Quality

Essa abordagem torna a exceção conhecida e observável.


## 30. Governança da Qualidade

Os testes de qualidade são identificados individualmente.

Exemplos:

`DQ_RAW_001`

`DQ_STG_001`

`DQ_DIM_001`

`DQ_SCD_001`

`DQ_FCT_001`

`DQ_FIN_001`

`DQ_INF_001`

Essa identificação facilita:

- rastreamento;
- investigação;
- documentação;
- automação;
- comunicação de falhas.


## 31. Evidência de Qualidade

A View:

`dq_resumo_qualidade`

fornece uma interface consolidada para acompanhamento.

No estado validado do projeto:

- 80 testes executados;
- 80 aprovados;
- 0 reprovados;
- 100% de aprovação.

Isso fornece uma evidência técnica objetiva do estado atual dos dados.


## 32. CI/CD e Segurança

Uma evolução do projeto será integrar versionamento e deploy automatizado.

Em um cenário corporativo, o processo de CI/CD deve utilizar uma identidade técnica
com privilégios controlados.

Essa identidade não deve utilizar uma role administrativa ampla sem necessidade.

Conceitualmente:

pipeline
    ↓
service identity
    ↓
role específica
    ↓
privilégios necessários para deploy

Isso aplica o mesmo princípio de menor privilégio utilizado pelos usuários.


## 33. Separação de Ambientes

Uma arquitetura corporativa deve evitar misturar desenvolvimento e produção.

Uma possível organização seria:

DEV
    ↓
desenvolvimento e testes

QA
    ↓
validação e homologação

PROD
    ↓
consumo produtivo

Cada ambiente pode possuir:

- databases próprios;
- Warehouses próprios;
- roles próprias;
- políticas próprias;
- credenciais próprias.


## 34. Promoção entre Ambientes

Mudanças não deveriam ser implementadas manualmente diretamente em produção.

O fluxo recomendado é:

Git
 ↓
DEV
 ↓
testes
 ↓
QA
 ↓
validação
 ↓
aprovação
 ↓
PROD

A automação desse fluxo reduz alterações não rastreadas.


## 35. Auditoria

Em um cenário corporativo, recursos de histórico e auditoria podem ser utilizados
para investigar:

- quem executou determinada operação;
- quando ocorreu;
- quais objetos foram acessados;
- quais queries foram executadas;
- quais recursos foram utilizados.

Auditoria complementa RBAC e políticas preventivas.


## 36. Ownership

A propriedade dos objetos deve ser definida de forma controlada.

Em ambientes maiores, deve-se evitar depender permanentemente da propriedade pessoal
de um desenvolvedor.

O modelo ideal deve considerar ownership por roles adequadas à responsabilidade do
objeto.

Isso reduz dependência de indivíduos específicos.


## 37. Gestão de Privilégios

Em um ambiente corporativo, privilégios devem ser concedidos preferencialmente a
roles, e usuários devem receber roles apropriadas.

Conceitualmente:

privilégios
    ↓
roles
    ↓
usuários

em vez de:

privilégios
    ↓
usuários individualmente

Essa abordagem facilita manutenção e auditoria.


## 38. Privilégios Futuros

Ao automatizar a criação de novos objetos, também deve ser considerada a governança
dos privilégios futuros.

Novas tabelas ou Views não devem depender de concessões manuais esquecidas após cada
deploy.

A estratégia precisa ser definida de acordo com o modelo de segurança da organização.


## 39. Governança e FinOps

Governança e FinOps também se relacionam.

Separar Warehouses permite controlar quem pode utilizar determinados recursos de
compute.

Exemplo:

role de engenharia
    ↓
wh_transformacao

role de BI
    ↓
wh_bi

Em um ambiente corporativo, isso pode contribuir para:

- controle de consumo;
- atribuição de custos;
- investigação de utilização;
- isolamento operacional.


## 40. Governança e Data Quality

Qualidade também é uma forma de governança.

Um dado não deve ser considerado confiável apenas porque está tecnicamente disponível.

O projeto adiciona evidências objetivas por meio de:

- testes;
- reconciliações;
- validação de histórico;
- integridade referencial;
- resumo consolidado.

Assim, governança inclui não apenas **quem pode acessar**, mas também **qual é o estado
de confiabilidade do produto**.


## 41. Estado Atual versus Evoluções

### Implementado no projeto

- organização por camadas;
- database de desenvolvimento;
- schemas por responsabilidade;
- role específica de engenharia;
- uso controlado de `ACCOUNTADMIN`;
- separação de Warehouses;
- Git;
- documentação de mudanças;
- nomenclatura padronizada;
- Data Quality observável.


### Evoluções corporativas

- matriz completa de roles;
- roles específicas por consumidor;
- classificação de dados;
- Tags;
- Masking Policies;
- Row Access Policies;
- Secure Views quando justificadas;
- service identities para CI/CD;
- segregação completa DEV / QA / PROD;
- auditoria operacional;
- ownership institucional;
- automação de grants;
- políticas específicas para dados sensíveis.


## 42. Princípios de Governança Aplicados

As principais decisões podem ser resumidas em:

1. evitar utilização cotidiana de roles administrativas;
2. utilizar role específica para execução;
3. separar responsabilidades por schema;
4. separar workloads por Warehouse;
5. versionar código;
6. documentar mudanças;
7. padronizar nomenclatura;
8. tornar exceções conhecidas e observáveis;
9. tratar Data Quality como parte da governança;
10. preparar a arquitetura para políticas corporativas futuras.


## 43. Conclusão

A estratégia de governança e segurança do projeto foi adequada ao contexto de um
ambiente pessoal de desenvolvimento, sem simular controles corporativos que não foram
efetivamente necessários ou implementados.

Ao mesmo tempo, a arquitetura foi organizada de forma a permitir evolução para um
modelo corporativo com maior segregação de responsabilidades, proteção de dados,
controle de acesso, automação e auditoria.

A principal diretriz adotada é:

**conceder somente o acesso necessário, separar responsabilidades e manter mudanças
rastreáveis.**