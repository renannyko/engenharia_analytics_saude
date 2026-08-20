# Implementação — CI/CD

## 1. Objetivo

Implementar uma estratégia inicial de Continuous Integration e Continuous Delivery
para o projeto `engenharia_analytics_saude`.

A implementação deverá automatizar validações do repositório, deploy controlado no
ambiente Snowflake de desenvolvimento e execução dos controles de Data Quality como
Quality Gate.

## 2. Escopo Atual

O projeto possui atualmente apenas o ambiente:

`engenharia_analytics_saude_dev`

Portanto, a primeira versão do CI/CD realizará deploy somente em DEV.

Ambientes QA e PROD serão tratados como evoluções arquiteturais futuras e não serão
simulados artificialmente no exercício.

## 3. Continuous Integration

O processo de CI será associado principalmente a Pull Requests.

Seu objetivo será validar o código antes da promoção para a branch principal.

Entre as validações previstas estão:

- estrutura esperada do repositório;
- presença dos arquivos SQL;
- validação dos arquivos SQL;
- ausência de arquivos CSV indevidamente versionados;
- ausência de arquivos temporários;
- proteção contra credenciais ou configurações sensíveis no repositório.

Nenhum deploy produtivo será realizado durante essa etapa.

## 4. Continuous Delivery

O processo de CD será associado à promoção de alterações para a branch `main`.

Fluxo previsto:

`push main → autenticação Snowflake → deploy DEV → Data Quality → Quality Gate`

O deploy utilizará os recursos já existentes no ambiente de desenvolvimento.

## 5. Ordem de Dependência

A execução deverá respeitar a arquitetura do projeto.

Ordem lógica:

1. configuração necessária;
2. Raw;
3. Staging;
4. Business;
5. Information;
6. Qualidade de Dados.

A ordem não deverá depender apenas da descoberta automática dos arquivos.

As dependências arquiteturais devem permanecer explícitas.

## 6. Ingestão dos Arquivos Locais

Os arquivos CSV utilizados no exercício permanecem fora do Git.

Essa decisão é intencional.

Como a fonte atual está armazenada localmente, o pipeline de CI/CD não será
responsável por reproduzir automaticamente o upload desses arquivos.

O CI/CD será responsável principalmente pelo deploy dos objetos SQL e pela validação
do estado do produto no ambiente Snowflake.

Em uma arquitetura corporativa, a fonte poderia ser substituída por armazenamento
externo ou processo de ingestão automatizado.

## 7. Quality Gate

Após o deploy, os controles formais de Data Quality deverão ser avaliados.

A principal interface será:

`qualidade_dados.dq_resumo_qualidade`

Critério:

`qt_reprovados = 0 → Quality Gate aprovado`

`qt_reprovados > 0 → Quality Gate reprovado`

O pipeline deverá falhar quando existirem testes reprovados.

## 8. Estado Atual de Qualidade

O estado validado antes da implementação do CI/CD é:

- 80 testes executados;
- 80 aprovados;
- 0 reprovados;
- 100% de aprovação.

Esse conjunto de controles será utilizado como base para o Quality Gate.

## 9. Segurança

Nenhuma credencial Snowflake será armazenada diretamente no código versionado.

Informações sensíveis necessárias à execução automatizada deverão utilizar
mecanismos protegidos do GitHub Actions.

A autenticação deverá respeitar o princípio de menor privilégio.

O pipeline não deverá utilizar `ACCOUNTADMIN` para atividades operacionais que
possam ser executadas por uma role específica.

## 10. Role de Automação

A automação deverá utilizar uma role adequada aos privilégios necessários para o
deploy.

A utilização da role operacional existente ou a criação futura de uma role dedicada
ao CI/CD deverá considerar:

- menor privilégio;
- ownership dos objetos;
- necessidade de criação ou alteração;
- rastreabilidade;
- separação entre administração e deploy.

## 11. Branches

A estratégia inicial será simples.

Fluxo:

`desenvolvimento → Pull Request → main`

A branch `main` representa o código aprovado para deploy no ambiente DEV.

Branches adicionais de QA, release ou produção não serão criadas sem a existência
dos respectivos ambientes e requisitos operacionais.

## 12. Observabilidade

O pipeline deverá apresentar claramente:

- etapa executada;
- sucesso ou falha;
- resultado do deploy;
- resultado do Quality Gate.

Falhas de qualidade não deverão ser ocultadas.

## 13. Evolução para Ambientes Corporativos

Uma evolução futura poderá utilizar:

`DEV → QA → PROD`

com:

- GitHub Environments;
- approvals;
- credenciais separadas;
- databases separados;
- roles separadas;
- Quality Gates por ambiente;
- política de promoção;
- rollback;
- auditoria.

Esses recursos não fazem parte da primeira versão implementada.

## 14. Critérios de Aceite

A implementação inicial de CI/CD será considerada válida quando:

- existir workflow de CI versionado;
- existir workflow de CD para DEV versionado;
- credenciais não estiverem presentes no repositório;
- o pipeline respeitar as dependências principais;
- o deploy utilizar contexto Snowflake controlado;
- o Quality Gate consultar os controles formais;
- qualquer teste reprovado puder provocar falha do pipeline;
- o estado atual de 80/80 testes puder ser validado;
- a documentação estiver atualizada.

## 15. Alinhamento VDAE

A estratégia está alinhada aos princípios VDAE de:

- versionamento;
- rastreabilidade;
- separação de responsabilidades;
- promoção controlada;
- Data Quality como parte do produto;
- falhas bloqueantes impedindo promoção;
- governança;
- segurança;
- reprodutibilidade.