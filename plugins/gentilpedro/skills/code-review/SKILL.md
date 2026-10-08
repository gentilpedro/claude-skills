---
name: code-review
description: >
  Revisão técnica completa e transversal de código antes de considerar
  uma feature, bugfix ou alteração pronta para PR — complementa as skills
  específicas de stack (`api-dotnet-ddd`, `api-dotnet-solid`,
  `blazor-dotnet10`, `frontend-react-vite`, `python-cli`) sem
  substituí-las. Use sempre que o usuário pedir para revisar código,
  perguntar "tá pronto pra PR?"/"pode abrir o PR?", pedir uma segunda
  opinião antes de commitar/subir, ou depois de terminar qualquer feature
  ou bugfix — mesmo sem pedido explícito de "code review", encare a
  conclusão de uma implementação como o gatilho natural para esta skill
  antes de declarar a tarefa pronta. Consulte também antes de aprovar
  qualquer PR, migration, ou alteração que mexa em autenticação,
  autorização, secrets, ou banco de dados.
---

# Code Review

Esta skill é transversal: ela não substitui `api-dotnet-ddd`, `api-dotnet-solid`, `blazor-dotnet10`, `frontend-react-vite` ou `python-cli` — ela identifica qual dessas se aplica ao projeto e usa as regras dela como referência arquitetural durante a revisão. Também consulta `git-standards`, `github-cicd`, `release-standards` e `template-standards` para os aspectos que pertencem a cada uma, sem duplicar as regras delas aqui.

## Princípio

Uma implementação não está pronta só porque compila, funciona quando testada manualmente, ou os testes passam. Este é o erro mais comum que uma revisão existe para pegar: código que "funciona" mas tem um requisito mal entendido, uma regressão silenciosa, um buraco de segurança, ou uma dívida técnica que ninguém vai notar até doer. A revisão avalia, nesta amplitude: requisito, arquitetura, qualidade, segurança, testes, performance, manutenção, dependências, documentação, Git, CI/CD e release.

## Antes de revisar

1. Identificar a stack do projeto.
2. Identificar o template utilizado.
3. Identificar a branch atual.
4. Identificar a branch base.
5. Verificar o estado do Git.
6. Rodar `git status`, `git diff`, `git diff --stat`.
7. Identificar os arquivos alterados.
8. Identificar os arquivos novos.
9. Verificar commits recentes quando necessário para entender a sequência de mudanças.
10. Ler contexto suficiente do projeto para entender a alteração — não revise o diff isoladamente quando o comportamento só faz sentido à luz do código ao redor dele.

(`scripts/scan_diff.sh` automatiza uma primeira varredura do diff por secrets aparentes e sobras de debug — ver seção "Revisão de diff" abaixo. Ele é um filtro rápido, não substitui a leitura do diff.)

## O que a revisão precisa responder

1. O código atende ao requisito?
2. A implementação está na camada correta?
3. A arquitetura existente foi respeitada?
4. Há código desnecessário?
5. Há regressões possíveis?
6. Há vulnerabilidades?
7. Há testes suficientes?
8. O build passa?
9. O lint passa quando aplicável?
10. A pipeline está adequada?
11. A alteração está pronta para PR?

## Severidade

- **CRITICAL** — comprometimento de segurança, perda de dados, exposição de secret, execução remota, corrupção grave, ou quebra generalizada da aplicação.
- **HIGH** — deve ser corrigido antes do PR: falha de autorização, bug funcional relevante, SQL Injection, XSS, vazamento de dado, regressão importante.
- **MEDIUM** — relevante mas pode não impedir o merge imediatamente: tratamento de erro incompleto, teste ausente num fluxo relevante, problema de arquitetura localizado, performance potencialmente ruim.
- **LOW** — melhoria de qualidade: naming, duplicação pequena, simplificação, documentação, legibilidade.
- **INFO** — sugestão ou observação sem necessidade de alteração.

Classifique com essa régua consistentemente — um `TODO` esquecido não é HIGH, e um endpoint sem checagem de autorização não é LOW. A severidade é o que orienta o desenvolvedor sobre o que resolver antes do PR e o que pode esperar.

## Segurança

Sempre revise segurança, verificando conforme a stack: autenticação, autorização, IDOR, SQL Injection, XSS, CSRF quando aplicável, SSRF quando aplicável, command injection, path traversal, upload/download de arquivo, exposição de dado, secrets, tokens, senhas, logs, CORS, redirects, validação de entrada. **Nunca considere validação de frontend suficiente** — se a única barreira para uma operação sensível é uma checagem no cliente, isso é HIGH no mínimo, independente de qual stack.

### Secrets

Procure nas alterações por senha, token, API key, chave privada, connection string, secret, credential — não só no código: também em arquivos de configuração, `.env`, workflows, scripts, logs, e documentação. Se houver um secret real commitado, classifique como CRITICAL ou HIGH conforme o impacto, e **não trate como resolvido só porque foi removido do arquivo** — considere que ele pode já ter sido exposto (histórico de commits, logs de CI, forks) e diga isso explicitamente no finding; a remoção do arquivo sozinha não desfaz a exposição.

## Dependências

Para cada dependência nova: entenda por que foi adicionada, verifique se já existe solução equivalente no projeto, verifique se é realmente necessária, avalie manutenção do pacote, avalie superfície de ataque, verifique o lockfile, verifique se a versão é adequada. Não recomende biblioteca por preferência pessoal.

## Arquitetura por stack

Verifique se a implementação respeita a arquitetura do projeto — usando a skill específica da stack como referência, não uma opinião genérica de "boa arquitetura":

| Stack | O que checar | Skill de referência |
|---|---|---|
| API .NET DDD | Domain/Application/Infrastructure/API, CQRS leve, Aggregates, Value Objects, Domain Events | `api-dotnet-ddd` |
| API .NET SOLID | Domain/Services/Repositories/API, abstrações justificadas | `api-dotnet-solid` |
| Blazor | componentes, pages, layouts, render modes, `.Client`, services, lifecycle | `blazor-dotnet10` |
| React | components, pages, hooks, services, estado, routing | `frontend-react-vite` |
| Python CLI | CLI, application, services, domain, infrastructure | `python-cli` |

Não imponha a arquitetura de uma stack a outra — um finding de "isso deveria ter Aggregates" não faz sentido num projeto SOLID, e vice-versa.

## Overengineering

Identifique: abstração sem necessidade, interface artificial, classe desnecessária, framework desnecessário, dependência desnecessária, pattern aplicado sem problema real, mecanismo duplicado quando um já existe. Não recomende refatoração gigantesca para um problema pequeno — o remédio desproporcional ao problema também é um finding, não só o problema original.

## Duplicação

Identifique duplicação relevante, mas diferencie duplicação aceitável de duplicação que cria risco real de manutenção (a mesma regra de negócio implementada duas vezes, que pode divergir silenciosamente, é diferente de duas linhas de UI parecidas). Não recomende criar uma abstração só porque duas linhas se parecem.

## Complexidade

Avalie método grande, classe grande, condicional excessivo, nesting excessivo, múltiplas responsabilidades numa unidade só, código difícil de testar. Priorize os problemas que realmente afetam manutenção — não toda função com mais de N linhas é um problema.

## Tratamento de erro

Verifique: exceção ignorada, catch genérico, mensagem de erro incorreta ou pouco útil, stack trace exposto ao usuário final, erro transformado incorretamente (perdendo informação no caminho), exit code incorreto em CLI, resposta HTTP incorreta, estado de erro ausente no frontend.

## Validação nos limites externos

Verifique validação em todo limite externo — API (`Request → Validation → Application`), frontend (`User input → Frontend validation → API → Backend validation`), CLI (`Arguments → Validation → Application`). Nunca considere validação só do lado cliente como suficiente — isso vale tanto para a seção de Segurança quanto aqui.

## Banco de dados / migrations

Quando houver alteração de banco, verifique: migration, índices, constraints, relacionamentos, performance, queries, N+1, paginação, dados já existentes, e possibilidade de perda de dado. Classifique migration destrutiva como HIGH ou CRITICAL conforme o impacto real (uma coluna vazia removida é diferente de uma coluna com dados de produção removida).

## Performance

Identifique problemas reais: N+1, chamada duplicada, loop desnecessário, query grande, falta de paginação, carregamento excessivo, processamento síncrono de I/O que deveria ser assíncrono, renderização excessiva, memory leak. Não recomende otimização prematura sem evidência de que é um problema de verdade.

## Testes

Verifique: testes existentes, testes adicionados, cobertura do comportamento alterado, casos de erro, regressões, edge cases. A pergunta que separa um teste útil de um teste decorativo: **"esse teste falharia se a implementação estivesse quebrada?"** Se a resposta for não, o teste provavelmente está testando a implementação (o "como") em vez do comportamento (o "o quê"), e isso é um finding em si. Para bugfix, espere um teste de regressão quando tecnicamente aplicável — sua ausência é pelo menos MEDIUM.

## Build e lint — sempre pela configuração do projeto

Execute os comandos adequados à stack, sempre a partir da configuração real do projeto — nunca invente comando:

- **.NET** (DDD/SOLID/Blazor): `dotnet restore`, `dotnet build`, `dotnet test` (os scripts `scripts/quality_gate.sh` de `api-dotnet-ddd`/`api-dotnet-solid`/`blazor-dotnet10` fazem exatamente isso).
- **React**: os scripts que já existem no `package.json` (`lint`, `test`, `build`) — o script `scripts/quality_gate.sh` de `frontend-react-vite` os detecta e roda na ordem certa.
- **Python**: as ferramentas configuradas no `pyproject.toml` (lint, test, build/package) — o script `scripts/quality_gate.sh` de `python-cli` faz essa detecção.

Não altere regra de lint só para o pipeline passar. Se uma exceção for realmente necessária, ela precisa estar documentada com justificativa no próprio código (comentário explicando o motivo), não apenas silenciada.

## Git, CI/CD, Release e Template

Estas quatro áreas têm skill própria — esta revisão consulta cada uma, sem duplicar as regras:

- **Git** (`git-standards`): branch correta, `user.name`/`user.email` locais, qualidade dos commits, arquivos não intencionais no diff, secrets, mudanças fora do escopo da tarefa.
- **CI/CD** (`github-cicd`): o workflow existe e está adequado, o trigger é o correto, build/test/lint/publish/release estão cobertos. Não altere a pipeline sem necessidade.
- **Release** (`release-standards`): a alteração exige incremento de versão? Muda comportamento público, API, ou CLI? Exige migration ou release note? — nunca crie uma release automaticamente durante a revisão, apenas sinalize se uma será necessária.
- **Template** (`template-standards`): o projeto continua aderente ao template oficial da sua stack? Não deixe passar uma feature simples que silenciosamente alterou a arquitetura base do template sem justificativa.

## Escopo

Identifique alterações fora do escopo da tarefa. Exemplo: a tarefa era "adicionar endpoint de clientes", mas o diff também inclui atualização de dezenas de dependências, troca de framework, alteração de autenticação, refatoração global, mudança completa de UI, ou alteração de pipeline sem necessidade — sinalize essas alterações mesmo que individualmente não tenham bug, porque misturado num PR de escopo pequeno elas dificultam revisão e rollback.

## Documentação

Verifique se a alteração exige atualizar README, documentação de API, OpenAPI, help da CLI, documentação de configuração, notas de migration, ou release notes. Não exija documentação para uma alteração trivial sem benefício real de fazê-lo.

## Revisão de diff

Revise o `git diff` arquivo por arquivo, procurando: código morto, comentário temporário, `TODO` esquecido, código de debug (`console.log`, `print`, breakpoint), secret, código duplicado, import não utilizado, arquivo temporário, e alteração que parece acidental (um arquivo tocado sem relação aparente com a tarefa).

`scripts/scan_diff.sh` automatiza a parte determinística disso: roda contra o diff atual (ou um range especificado) e sinaliza padrões de secret conhecidos, chaves de nuvem com prefixo identificável, blocos de chave privada, `console.log`/`print`/`Console.WriteLine`, `debugger`/`breakpoint()`/`pdb.set_trace()`, e `TODO`/`FIXME`/`XXX`. Um match não é automaticamente um problema real (pode ser um TODO antigo, ou uma string que só parece uma chave) — mas cada um merece confirmação explícita antes de aprovar.

## Formato de saída

Ao final da revisão, produza sempre neste formato exato:

```markdown
## Code Review

### Status
APPROVED | CHANGES_REQUIRED | BLOCKED

### Resumo
Resumo objetivo da alteração.

### Findings
Para cada problema encontrado:
- severidade
- arquivo
- linha quando possível
- problema
- impacto
- correção recomendada

Exemplo:

HIGH
`UserController.cs:42`
O endpoint permite consultar usuário sem verificar autorização.
Impacto: qualquer usuário autenticado pode acessar dados de outro usuário.
Correção: validar autorização sobre o recurso antes de retornar os dados.

### Quality Checks
- Build: PASS/FAIL
- Tests: PASS/FAIL
- Lint: PASS/FAIL/N/A
- Security: PASS/FAIL
- Architecture: PASS/FAIL
- Git: PASS/FAIL
- CI/CD: PASS/FAIL
- Release: PASS/FAIL/N/A

### Recommendation
Conclusão objetiva.
```

## Regras de comportamento

Não elogie código sem necessidade — um review não é o lugar para validação social. Não gere review genérico nem liste "boas práticas" sem relação com o código revisado de verdade. Todo finding precisa estar amarrado a uma alteração ou comportamento real do diff em questão, nunca a um princípio abstrato solto. Não invente problema para parecer que a revisão foi profunda — se não encontrar nada de bloqueante, diga claramente **"No blocking issues found."** em vez de forçar findings de baixo valor só para preencher a seção.

## Princípio final

A revisão prioriza, nesta ordem: segurança, correção, regressão, arquitetura, testes, performance, manutenção, estilo. Uma revisão excelente não é a que encontra mais problemas — é a que encontra os problemas que realmente importam, na ordem certa de importância.
