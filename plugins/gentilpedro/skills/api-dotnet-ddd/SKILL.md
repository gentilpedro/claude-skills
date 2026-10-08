---
name: api-dotnet-ddd
description: >
  Especializada em desenvolvimento e manutenção de APIs ASP.NET Core .NET 10
  que seguem a arquitetura DDD do template GentilPedro.Templates.ApiDdd
  (camadas API/Application/Domain/Infrastructure, CQRS leve sem MediatR, EF
  Core + PostgreSQL, FluentValidation, AutoMapper, JWT, Serilog, Scalar).
  Use sempre que for implementar feature, corrigir bug, revisar
  arquitetura, criar entidades/commands/queries/handlers/DTOs/validators/
  repositories/controllers, mexer em migrations do EF Core, ou decidir
  design dentro de um projeto .NET já criado a partir desse template —
  mesmo sem o usuário dizer "DDD", bastando "adiciona um endpoint de X" ou
  "corrige esse bug na API". NÃO usar para criar projeto novo
  (`template-standards`), Git (`git-standards`), CI/CD (`github-cicd`), ou
  release (`release-standards`) — foco exclusivo em implementação e
  arquitetura dentro do código da API DDD.
---

# API .NET DDD (template GentilPedro.Templates.ApiDdd)

Esta skill assume que o projeto já existe e foi criado a partir do template `GentilPedro.Templates.ApiDdd` (package `GentilPedro.Templates.ApiDdd`, template `api-ddd`, fonte em `github.com/gentilpedro/template-dotnet-api-ddd`). Ela não cria projetos novos — isso é `template-standards`. A partir do momento em que o projeto existe, esta skill governa as decisões de implementação, arquitetura, qualidade e validação específicas dele.

O template deve ser tratado como a referência arquitetural, mas não como algo para clonar, copiar manualmente ou reconstruir de memória — se em algum momento for necessário consultar o template diretamente (não só o projeto atual), siga o mecanismo descrito em `template-standards` (scaffold de referência descartável), nunca `git clone`.

## Arquitetura

O projeto usa DDD tático, separado em quatro camadas: **API → Application → Domain**, com **Infrastructure** implementando as abstrações que o Domain e a Application definem. A direção das dependências é a regra mais importante desta skill:

```
API
 ↓
Application
 ↓
Domain

Infrastructure implementa abstrações definidas pelo Domain/Application
```

O Domain nunca depende de nada fora dele mesmo: nem da API, nem da Infrastructure, nem de Entity Framework Core, PostgreSQL, HTTP, ASP.NET Core, ou qualquer outro detalhe de infraestrutura ou mecanismo de persistência. Essa independência é o que torna as regras de negócio testáveis e estáveis mesmo que a infraestrutura mude por baixo. Antes de adicionar um `using` no Domain, pergunte-se: isso é uma regra de negócio ou um detalhe técnico? Detalhes técnicos vão para Infrastructure, sempre.

## Domain — regras de negócio

O Domain existe para: Entities, Aggregates, Value Objects, Domain Events, invariantes, e as interfaces de Repository que pertencem ao domínio (as implementações concretas ficam na Infrastructure).

Regra de negócio nunca vai em Controllers, nunca diretamente em Infrastructure, nunca em DTOs, nunca em classes de configuração — se está decidindo algo sobre o negócio (o que é um pedido válido, quando um valor pode mudar, o que acontece quando X acontece), isso pertence ao Domain, não importa o quão conveniente seja colocar ali onde você já está mexendo.

**Entities**: têm identidade e comportamento quando há regra de negócio associada a elas. Não crie entidades anêmicas (só getters/setters, sem comportamento) por padrão — se a entidade só guarda dados sem nenhuma regra, questione se ela precisa ser uma Entity ou se um Value Object/DTO simples resolve.

**Aggregates**: respeite os limites do Aggregate. Nenhuma parte da aplicação deve alterar diretamente objetos internos de um Aggregate sem passar pelas regras que o próprio Aggregate Root expõe — se você está tentado a expor um setter público num objeto interno só para "facilitar" uma alteração de fora, é sinal de que a regra deveria estar num método do Aggregate.

**Value Objects**: use quando um conceito do domínio tem identidade definida pelo seu valor e comportamento próprio (ex.: `Email`, `Money`, `CPF`). Não crie Value Objects só para aumentar a contagem de classes — se o conceito não tem comportamento nem validação própria, um tipo primitivo ou uma propriedade simples resolve.

**Domain Events**: use quando uma mudança relevante no domínio precisa ser comunicada a outras partes do sistema. Não transforme toda alteração simples em Domain Event — isso é ruído, não comunicação.

## Application — casos de uso (CQRS leve, sem MediatR)

Application representa os casos de uso: **Commands** (operações que alteram estado — `CreateOrderCommand`, `UpdateOrderCommand`, `DeleteOrderCommand`), **Queries** (consultas — `GetOrderQuery`, `ListOrdersQuery`), **Handlers** (orquestram o caso de uso), e **DTOs**.

O template usa CQRS leve e **não depende de MediatR**. Não introduza MediatR automaticamente só porque "CQRS normalmente usa MediatR" — isso adicionaria uma dependência e uma camada de indireção que o template deliberadamente não tem. Se o usuário pedir explicitamente para adotar MediatR, é uma decisão dele para tomar conscientemente, não algo para você assumir.

Handlers orquestram: recebem o Command/Query, chamam o Domain e a Infrastructure na ordem certa, e devolvem o resultado. Regra de negócio complexa não fica no Handler — se uma decisão pertence ao negócio, ela mora no Domain, e o Handler só a invoca.

## DTOs

Use DTOs para entrada e saída da API. Não exponha entidades de domínio diretamente como contrato HTTP sem uma justificativa explícita — os contratos HTTP devem ficar desacoplados do modelo de domínio, para que um não force mudanças no outro. Siga o padrão de DTOs já existente no projeto (nomenclatura, localização, convenções de serialização).

## AutoMapper

O template usa AutoMapper. Respeite as configurações existentes; não escreva mapeamentos manuais repetitivos quando o padrão de mapeamento já configurado resolve o caso. Ao mesmo tempo, não use o AutoMapper para esconder regra de negócio dentro de um `Profile` — mapeamento deve continuar simples e previsível: DTO ↔ modelo, sem lógica de decisão escondida ali.

## Validação (FluentValidation)

O template usa `FluentValidation` e `FluentValidation.AspNetCore`. Validações de entrada seguem o padrão de Validators já existente. Diferencie dois tipos de regra: **validação de entrada** (o payload está bem formado? campos obrigatórios preenchidos? formato correto?) é FluentValidation; **invariante de domínio** (essa transição de estado é permitida pelo negócio?) é Domain. Não jogue regra de negócio complexa só no DTO/Validator porque é mais rápido de escrever ali — uma requisição inválida deve ser rejeitada antes de executar qualquer operação desnecessária, mas "inválida" aqui significa malformada, não "viola uma regra de negócio".

## Infrastructure

Infrastructure implementa os detalhes concretos: Entity Framework Core, Npgsql/PostgreSQL, Repositories, autenticação, integrações externas. Nada específico de EF Core pode vazar para o Domain — sem `DbSet`, sem atributos de mapeamento do EF, sem `DbContext` nas classes de domínio. O `DbContext` nunca é usado diretamente em Controllers nem em regras de domínio; ele fica confinado à Infrastructure, acessado através das abstrações que o Domain define.

### Repositories

As interfaces de Repository seguem a localização definida pelo template (tipicamente no Domain); as implementações concretas ficam na Infrastructure. Não crie um Repository para cada entidade automaticamente só porque "é o padrão" — quando uma operação pode ser resolvida de forma simples reutilizando uma abstração já existente, reutilize-a em vez de criar mais uma interface. Abstrações artificiais (interfaces com uma única implementação que nunca muda, criadas "por precaução") custam mais do que ajudam.

## API / Controllers

Controllers são finos: recebem a requisição HTTP, encaminham/validam a entrada, chamam o caso de uso (Command/Query + Handler), e devolvem a resposta HTTP. Eles não contêm regra de negócio, queries complexas, acesso direto ao `DbContext` ou ao banco, lógica de persistência, ou lógica complexa de transformação de dados. Um Controller que está crescendo é sinal de que lógica que deveria estar na Application ou no Domain ficou no lugar errado — não "resolva" isso com um Controller maior, mova a lógica para a camada certa.

## Exception Handling

O template tem um middleware global de tratamento de exceções — use-o. Não crie `try/catch` genérico espalhado em todos os Controllers:

```csharp
try
{
    ...
}
catch (Exception ex)
{
    return BadRequest(...);
}
```

Esse padrão engole informação sobre o que realmente deu errado e duplica uma responsabilidade que já tem um lugar central. Trate exceções de acordo com o mecanismo já existente; não esconda erros inesperados atrás de um catch genérico que os transforma silenciosamente numa resposta 400.

## Autenticação e segurança

O template usa JWT e `BCrypt.Net-Next`. Respeite a implementação existente — não troque o mecanismo de autenticação sem necessidade explícita do usuário. Regras que nunca têm exceção:

- nunca coloque secrets diretamente no código;
- nunca commite JWT secrets, senhas, ou connection strings com credenciais (isso também é regra da `git-standards` — se encontrar um segredo num diff, pare e avise, não remova e siga em frente sozinho);
- nunca exponha tokens em logs;
- nunca retorne senhas (nem hasheadas) em DTOs de resposta.

Secrets ficam em configuração segura (variáveis de ambiente, secret manager, `appsettings` fora do controle de versão), nunca hardcoded. Ao criar endpoints protegidos, use o padrão de autorização já existente no projeto (mesmos atributos, mesma configuração de política).

## Logging

O template usa Serilog, com sinks de Console e File — preserve os dois; não troque o mecanismo de logging por outro sem que o usuário peça isso explicitamente. Nunca registre em log: senhas, JWTs, connection strings, secrets, tokens, ou dados sensíveis desnecessários. Um log deve dar contexto suficiente para diagnosticar um problema depois — nem tão genérico que não ajuda em nada, nem tão detalhado que vaza dado sensível.

## OpenAPI

O template documenta a API com Scalar. Não substitua Scalar por Swagger UI sem pedido explícito do usuário. Ao criar endpoints: use os verbos HTTP corretos, os status codes apropriados para cada resultado, documente o contrato quando fizer sentido, e mantenha consistência com os endpoints já existentes (mesmo estilo de rota, mesmo padrão de resposta de erro).

## Async

Operações de I/O usam `async`/`await`. Evite `.Result`, `.Wait()`, e `.GetAwaiter().GetResult()` — esses padrões bloqueiam threads desnecessariamente e podem causar deadlocks em contextos ASP.NET Core. Use `CancellationToken` quando aplicável (especialmente em endpoints que podem ser cancelados pelo cliente). Não adicione `async` artificialmente em métodos que não têm nenhuma operação assíncrona de verdade — isso só adiciona overhead sem benefício.

## EF Core — performance e segurança

Ao trabalhar com Entity Framework Core: evite N+1 queries, evite carregar dados desnecessários, use projeções quando fizer sentido, use `AsNoTracking()` em consultas somente leitura, não materialize grandes volumes de dados sem necessidade, use paginação quando o volume puder crescer, e respeite transações quando houver operações que precisam de atomicidade.

Não execute SQL bruto sem necessidade. Quando SQL bruto for realmente necessário, use sempre mecanismos parametrizados — nunca concatene entrada do usuário diretamente numa string SQL (isso é injeção de SQL, não uma otimização).

## Database / Migrations

Ao alterar uma entidade persistida, siga esta ordem: avalie a alteração do modelo → verifique o `DbContext` → verifique as configurações do EF Core (mapeamentos, `Fluent API`) → crie a migration quando necessário → **revise a migration gerada antes de aplicá-la** (o EF Core às vezes infere algo diferente do que você esperava) → execute testes/build.

Nunca execute uma migration destrutiva silenciosamente. Nunca rode `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, ou um `DELETE` massivo como parte automática de uma implementação. Se uma migration puder causar perda de dados (remoção de coluna com dados, mudança de tipo incompatível, etc.), informe isso explicitamente ao desenvolvedor antes de aplicá-la — essa é uma decisão dele, não sua.

## Testes

Toda funcionalidade nova relevante tem testes. Prioridade de cobertura: regras de negócio primeiro, depois casos de uso, depois validações, depois comportamento crítico da API.

Ao corrigir um bug, siga esta ordem: reproduza o comportamento → crie um teste que reproduza o bug (deve falhar antes da correção) → implemente a correção → confirme que o teste passa. Isso garante que o bug não volta silenciosamente depois. Nunca remova um teste só para fazer a suíte passar — se um teste está falhando, ou o código está errado, ou o teste está desatualizado; das duas uma precisa ser corrigida, nenhuma das duas deve ser simplesmente apagada para destravar.

## Quality Gate

Antes de considerar qualquer implementação concluída, verifique nesta ordem: arquitetura → Domain → Application → Infrastructure → API → DTOs → validações → segurança → logging → migrations (quando aplicável). Depois execute:

```bash
dotnet restore
dotnet build
dotnet test
```

(O script `scripts/quality_gate.sh` desta skill automatiza essas três etapas — restore, build, test — parando no primeiro erro e reportando warnings relevantes; use-o para não pular etapa por pressa.)

Confirme que todos os testes passam, revise warnings relevantes do build, e revise o `git diff` antes de finalizar. **Se build ou testes falharem, a tarefa não está concluída** — não ignore a falha, e não desabilite um teste só para conseguir ver tudo verde. Uma implementação "funcionando" que não passa no quality gate não está pronta, está pendente.

## Regra de conservadorismo

Antes de criar uma nova abstração (interface, camada, padrão), pergunte: essa abstração é necessária para o requisito, ou é complexidade que está sendo adicionada porque parece "mais arquitetural"? Prefira sempre código simples, com responsabilidade clara, consistente com a arquitetura já existente, em vez de empilhar padrões, interfaces e frameworks sem necessidade real comprovada pelo requisito em mãos.

## Fluxo de implementação

**Feature nova:**

1. Entender o requisito.
2. Identificar o Aggregate/Domain afetado.
3. Identificar o caso de uso.
4. Criar/alterar o Command ou Query.
5. Criar/alterar o Handler.
6. Criar/alterar o DTO.
7. Criar/alterar o Validator.
8. Alterar o Domain quando houver regra de negócio envolvida.
9. Alterar o Repository quando necessário.
10. Alterar a Infrastructure quando necessário.
11. Criar/alterar o Controller.
12. Criar os testes.
13. `dotnet restore`.
14. `dotnet build`.
15. `dotnet test`.
16. Revisar segurança.
17. Revisar arquitetura (a implementação ainda respeita a direção de dependências e os limites de camada?).
18. Revisar o `git diff`.
19. Seguir `git-standards` para commit/push (branch `feature/<descricao>`, nunca direto na principal).

**Correção de bug:**

1. Reproduzir o problema.
2. Identificar a camada responsável.
3. Criar um teste de regressão.
4. Corrigir na camada correta (não na camada onde é mais fácil, na camada onde a responsabilidade realmente mora).
5. Executar os testes.
6. Executar o build.
7. Executar os testes de novo.
8. Revisar arquitetura.
9. Seguir `git-standards` (branch `bugfix/<descricao>`).

## Limites de escopo do agente

Não faça alterações fora do que foi pedido. Não faça refatorações grandes durante uma feature simples ("já que estou aqui, vou reorganizar isso tudo" não é uma decisão sua para tomar sozinho). Não atualize todas as dependências do projeto sem solicitação. Não troque bibliotecas por preferência pessoal. Não altere a arquitetura existente sem necessidade real. "Está funcionando" não é o critério de conclusão — o critério é: requisito implementado, arquitetura respeitada, testes passando, build passando, segurança validada, template respeitado, e Git tratado conforme `git-standards`.

## O que esta skill NÃO faz — e quem faz

- **Criar o projeto**: `template-standards` — nunca clone o repositório do template nem reconstrua a arquitetura manualmente aqui.
- **Operações de Git** (identidade, branches, commits, push, comandos destrutivos): `git-standards`. Esta skill não duplica essas regras — só reforça que features vão em `feature/<descricao>` e bugs em `bugfix/<descricao>`, nunca direto na branch principal.
- **CI/CD**: `github-cicd`. Esta skill garante que a API passe pelo pipeline definido (mínimo esperado: `restore → build → test → publish → release quando aplicável`), mas não reimplementa a pipeline aqui.
- **Versionamento e GitHub Release**: `release-standards`. Não crie releases manualmente ignorando essa skill.

## Não transforme esta API em outra coisa

O projeto deve continuar reconhecível como uma API criada pelo template DDD do GentilPedro. Não transforme esta arquitetura em Clean Architecture genérica, Onion Architecture, Hexagonal Architecture, Vertical Slice, CQRS pesado com MediatR, ou na arquitetura SOLID do outro template (`GentilPedro.Templates.ApiSolid`) — a menos que o usuário peça isso explicitamente, sabendo que é uma migração arquitetural, não um ajuste incremental.
