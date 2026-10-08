---
name: api-dotnet-solid
description: >
  Especializada em desenvolvimento e manutenção de APIs ASP.NET Core .NET
  10 que seguem a arquitetura do template GentilPedro.Templates.ApiSolid
  (Controller → Service → Repository → Domain, princípios SOLID aplicados
  com pragmatismo, EF Core + PostgreSQL, FluentValidation, AutoMapper,
  JWT, BCrypt, Serilog, Scalar). Use sempre que for implementar feature,
  corrigir bug, revisar arquitetura, criar services/repositories/DTOs/
  validators/controllers, mexer em migrations do EF Core, decidir se algo
  precisa de interface/abstração, ou tomar qualquer decisão de design
  dentro de um projeto .NET já criado a partir desse template — mesmo sem
  o usuário dizer "SOLID", bastando "adiciona um endpoint de X" ou
  "corrige esse bug na API". NÃO usar para criar projeto novo
  (`template-standards`), Git (`git-standards`), CI/CD (`github-cicd`),
  release (`release-standards`), ou para o template DDD irmão
  (`api-dotnet-ddd`) — foco exclusivo em implementação e arquitetura
  dentro do código da API SOLID.
---

# API .NET SOLID (template GentilPedro.Templates.ApiSolid)

Esta skill assume que o projeto já existe e foi criado a partir do template `GentilPedro.Templates.ApiSolid` (package `GentilPedro.Templates.ApiSolid`, template `api-solid`, fonte em `github.com/gentilpedro/template-dotnet-api-solid`). Ela não cria projetos novos — isso é `template-standards`. A partir do momento em que o projeto existe, esta skill governa as decisões de implementação, arquitetura, qualidade e validação específicas dele.

O template é a referência arquitetural, não algo para clonar, copiar manualmente ou reconstruir de memória — se for preciso consultar o template diretamente (não só o projeto atual), siga o mecanismo de `template-standards` (scaffold de referência descartável), nunca `git clone`.

## Arquitetura

```
Controller
    ↓
Service
    ↓
Repository
    ↓
Database
```

Domain representa o modelo de negócio. A separação de responsabilidades entre essas camadas deve ser preservada — não introduza uma arquitetura diferente sem solicitação explícita do desenvolvedor, e em particular **não transforme automaticamente o projeto em DDD, Clean Architecture, Onion Architecture, Hexagonal Architecture, Vertical Slice, CQRS, ou MediatR**. O template SOLID é deliberadamente mais simples que o template DDD (`api-dotnet-ddd`) — essa simplicidade é uma escolha, não uma lacuna a "corrigir".

## Princípios SOLID — aplicados com pragmatismo

- **SRP** (Single Responsibility): cada classe tem uma responsabilidade clara.
- **OCP** (Open/Closed): prefira adicionar comportamento novo sem alterar comportamento existente desnecessariamente.
- **LSP** (Liskov Substitution): implementações respeitam o contrato definido pela abstração que implementam.
- **ISP** (Interface Segregation): interfaces específicas e pequenas, quando isso trouxer benefício real.
- **DIP** (Dependency Inversion): camadas de nível mais alto não dependem diretamente de implementações concretas quando uma abstração é realmente necessária.

**O ponto mais importante desta seção**: SOLID não significa criar uma interface para cada classe. Não crie abstrações artificiais só para "satisfazer uma regra" — evite o padrão `IUserService` + `UserService` quando a interface não traz nenhum benefício real além de duplicar a classe (nenhuma segunda implementação prevista, nenhum teste que precise fazer mock dela, nenhum ponto de substituição real). Uma abstração se justifica quando existe necessidade arquitetural, de testabilidade, de substituição, ou de desacoplamento — não porque "é a forma certa de fazer SOLID". Uma interface sem motivo é complexidade, não qualidade.

## Domain

O Domain representa o modelo de negócio — use entidades e objetos de domínio quando necessário. Regra de negócio fica no lugar apropriado: nunca em Controllers, nunca em Repositories. Services podem coordenar regras e operações de negócio quando esse for o padrão do projeto — mas não deixe Services virarem classes gigantes que fazem de tudo.

## Services

Services carregam a lógica de aplicação/negócio conforme o padrão do template: orquestração, aplicação de regras, validação de operações, coordenação entre Repository e Domain, transformação de dados necessária.

Services **não** recebem objetos HTTP diretamente, não conhecem detalhes de Controller, não retornam `ActionResult`, não manipulam a response HTTP, e não contêm código de infraestrutura desnecessário — essas são responsabilidades de outras camadas. Se existe um Repository para acessar dados, o Service usa o Repository; não acesse o banco diretamente de dentro de um Service quando o Repository já existe para isso.

## Repositories

Repositories cuidam do acesso a dados: consultas, persistência, atualização, remoção, operações relacionadas ao banco. Controllers não acessam Repository diretamente quando o padrão do projeto usa Services como intermediário. Repository não contém regra de negócio nem decisão HTTP, e não deve conter queries desnecessariamente complexas — se uma query está ficando complicada demais para um Repository, considere se parte dessa complexidade pertence ao Service.

## Controllers

Controllers são finos: recebem a requisição HTTP, validam/encaminham a entrada, chamam o Service, retornam a resposta HTTP. Eles não contêm regra de negócio, LINQ complexo, acesso direto ao `DbContext` ou ao banco, lógica extensa, autenticação implementada manualmente, ou transformação complexa de domínio. Um Controller crescendo demais é sinal de que lógica que pertence ao Service ficou no lugar errado.

## DTOs

Use DTOs para os contratos HTTP. Não exponha entidades de persistência diretamente quando isso acopla o contrato HTTP ao banco — DTOs de entrada e saída têm responsabilidades claras, sem regra de negócio complexa dentro deles. Nunca retorne, em resposta de API: senhas, hashes, tokens internos, secrets, ou qualquer informação sensível.

## AutoMapper

O template usa AutoMapper. Respeite os `Profiles` e padrões existentes; use-o para os mapeamentos apropriados, mas não para esconder regra de negócio dentro de um profile, e não crie mapeamentos excessivamente complexos — se o mapeamento está difícil de escrever declarativamente, provavelmente ele está fazendo mais do que mapear.

## Validação (FluentValidation)

O template usa FluentValidation. Validações de entrada seguem o padrão existente. Diferencie validação de entrada (payload bem formado, campos obrigatórios, formato) de regra de negócio (decisão do domínio) — FluentValidation não substitui invariantes fundamentais do domínio. Uma regra que precisa valer independentemente de como a requisição chegou (API, job em background, outro serviço interno) precisa estar protegida na camada apropriada, não só no validator do endpoint HTTP.

## Entity Framework Core

O template usa EF Core, Npgsql e PostgreSQL. Respeite a configuração existente. `DbContext` pertence à infraestrutura/persistência — nunca usado diretamente em Controllers, nunca no Domain.

Evite N+1 queries, evite carregar dados desnecessários, use projeções quando apropriado, use `AsNoTracking()` em consultas somente leitura, use paginação quando necessário, evite materializar grandes volumes de dados. Não use SQL bruto sem necessidade; quando for necessário, use sempre parâmetros — nunca concatene entrada do usuário em SQL.

## Async

Operações de I/O usam `async`/`await`. Evite `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` — bloqueiam threads desnecessariamente. Use `CancellationToken` quando apropriado. Não transforme métodos síncronos em `async` artificialmente quando não há nenhuma operação assíncrona real.

## Database / Migrations

Ao alterar a estrutura persistida: atualize o modelo → atualize as configurações do EF Core quando necessário → gere a migration → **revise a migration gerada** → execute build → execute testes.

Nunca execute operações destrutivas automaticamente. Nunca rode `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, ou um `DELETE` massivo sem autorização explícita. Se uma migration puder causar perda de dados: **pare** e informe o impacto ao desenvolvedor antes de prosseguir — essa decisão não é sua para tomar sozinho.

## Autenticação

O template usa JWT. Respeite o mecanismo existente; não o substitua sem solicitação explícita. Nunca coloque JWT secret, senha, token ou API key diretamente no código. Nunca commite secrets (se encontrar um num diff, siga `git-standards`: pare e avise, não remova e continue sozinho). Nunca registre tokens ou senhas em log. Endpoints protegidos usam o mecanismo de autorização já existente.

## BCrypt

O template usa `BCrypt.Net-Next`. Senhas são armazenadas com hashing seguro — nunca em texto puro, nunca retornadas em resposta de API, nunca registradas em log, e nunca comparadas manualmente de forma insegura (sempre pela função de verificação do próprio BCrypt). Não substitua BCrypt sem necessidade explícita.

## Logging

O template usa Serilog — preserve a configuração existente; não troque por outro framework sem solicitação. Logs devem ter contexto suficiente para diagnóstico, mas nunca registrar senhas, JWT, tokens, secrets, ou connection strings com credenciais.

## Exception Handling

Use o mecanismo global de tratamento de exceções já existente no template. Não adicione `try/catch` genérico em todos os Controllers — isso duplica uma responsabilidade centralizada e esconde exceções inesperadas. Nunca retorne stack traces em produção. Erros seguem o padrão de resposta HTTP já estabelecido no projeto.

## OpenAPI

O template usa Scalar/OpenAPI — preserve-o; não substitua por Swagger UI sem solicitação explícita. Ao adicionar endpoints: verbos HTTP corretos, status codes apropriados, contratos consistentes com o resto da API, documentação quando fizer sentido.

## Testes

Toda funcionalidade relevante tem testes. Ao corrigir um bug: reproduza o problema → crie um teste de regressão (deve falhar antes da correção) → implemente a correção → confirme que o teste passa. Nunca remova um teste só para fazer a pipeline passar. Testes validam comportamento observável, não detalhe de implementação interna desnecessariamente — testar demais o "como" em vez do "o quê" deixa a suíte frágil a refatorações inofensivas.

## Quality Gate

Antes de considerar uma implementação concluída, verifique nesta ordem: arquitetura → Controller → Service → Repository → Domain → DTOs → validações → autenticação/autorização → segurança → logging → migrations (quando aplicável). Depois execute:

```bash
dotnet restore
dotnet build
dotnet test
```

(O script `scripts/quality_gate.sh` desta skill automatiza essas três etapas, parando no primeiro erro e reportando warnings, para que nenhuma delas seja pulada por pressa.)

Confirme que os testes passam, revise warnings relevantes, e revise o `git diff`. **Se build ou testes falharem, a tarefa não está concluída** — não ignore o erro, não desabilite teste para conseguir ver tudo verde, e não reduza qualidade só para fechar um build verde.

## Template: não vire outra coisa

O template oficial é `GentilPedro.Templates.ApiSolid` — a arquitetura existente deve ser preservada. Não transforme a API SOLID numa API DDD. Não adicione automaticamente Aggregates, Value Objects, Domain Events, Commands, Queries, Handlers, MediatR, Unit of Work, ou CQRS quando esses elementos não fazem parte do padrão já existente no projeto. Se uma necessidade real justificar uma dessas técnicas, explique o motivo ao desenvolvedor antes de introduzir essa complexidade arquitetural — a decisão de adotá-la é dele, informada pela sua explicação, não uma iniciativa sua.

## Dependências

Não adicione bibliotecas sem necessidade. Antes de instalar um pacote novo: verifique se o projeto já resolve isso de outra forma → verifique se o próprio .NET ou uma biblioteca já existente resolve o problema → avalie o impacto da nova dependência → avalie segurança → avalie manutenção do pacote → só então adicione, se realmente necessário. Não atualize todas as dependências do projeto durante uma feature simples.

## Performance

Evite otimização prematura. Priorize: queries eficientes, paginação, uso correto de `async`, evitar N+1, evitar processamento e carregamento de dados desnecessário. Não introduza cache só por "boa prática" — cache existe quando há um requisito real ou um benefício mensurável, porque cache mal colocado troca um bug de performance por um bug de dado desatualizado.

## Segurança

Ao implementar qualquer endpoint, avalie explicitamente: autenticação, autorização, validação de entrada, exposição de dados, SQL Injection, mass assignment, IDOR (Insecure Direct Object Reference — um usuário conseguindo acessar/alterar recurso de outro só trocando um ID na URL), vazamento de informação, logging de dado sensível, CORS, rate limiting quando aplicável, e headers de segurança quando aplicável. Nunca confie exclusivamente na validação do frontend — toda entrada externa é não confiável até prova em contrário.

## Fluxo de implementação

**Feature nova:**

1. Entender o requisito.
2. Identificar o Controller.
3. Identificar o Service.
4. Identificar o Repository.
5. Identificar o Domain afetado.
6. Criar/alterar o DTO.
7. Criar/alterar o Validator.
8. Implementar a regra no local correto (Domain se for regra de negócio, Service se for orquestração).
9. Implementar persistência quando necessário.
10. Criar/alterar o endpoint.
11. Criar os testes.
12. `dotnet restore`.
13. `dotnet build`.
14. `dotnet test`.
15. Revisar segurança.
16. Revisar arquitetura.
17. Revisar o `git diff`.
18. Seguir `git-standards` (branch `feature/<descricao>`).

**Correção de bug:**

1. Reproduzir o bug.
2. Identificar a camada responsável.
3. Criar um teste de regressão.
4. Implementar a correção.
5. Executar os testes.
6. Executar o build.
7. Executar os testes de novo.
8. Revisar segurança.
9. Revisar arquitetura.
10. Seguir `git-standards` (branch `bugfix/<descricao>`).

## Regra de conservadorismo

Não faça refatorações grandes durante uma feature simples. Não altere a arquitetura existente sem necessidade. Não introduza um padrão só porque ele é popular. Não transforme SOLID em excesso de abstrações — SOLID mal aplicado vira mais complexo que o problema que resolve. Antes de cada decisão estrutural, responda a pergunta certa:

- Antes de criar uma interface: *existe uma necessidade real de abstração?*
- Antes de criar um Service: *existe responsabilidade de aplicação/negócio que justifica este Service?*
- Antes de criar um Repository: *existe necessidade real de abstrair ou encapsular o acesso a dados?*
- Antes de adicionar uma biblioteca: *ela resolve um problema real que o projeto tem agora?*

Se a resposta for "não" ou "não tenho certeza", não crie — o padrão consistente aqui é fazer menos, não mais.

## O que esta skill NÃO faz — e quem faz

- **Criar o projeto**: `template-standards` — nunca clone o repositório do template nem reconstrua a arquitetura manualmente aqui.
- **Operações de Git** (identidade, branches, commits, push, comandos destrutivos): `git-standards`. Esta skill não duplica essas regras — só reforça que features vão em `feature/<descricao>` e bugs em `bugfix/<descricao>`, nunca direto na branch principal.
- **CI/CD**: `github-cicd`. O mínimo esperado para a pipeline desta API é `restore → build → test → publish → release quando aplicável`; esta skill não reimplementa isso.
- **Versionamento e GitHub Release**: `release-standards`. Não crie releases manualmente ignorando essa skill.
- **Arquitetura DDD**: `api-dotnet-ddd`. Se o projeto em questão usa o template DDD, não esta skill.

## Critério de conclusão

Uma implementação só está concluída quando: o requisito foi implementado, a arquitetura do template foi preservada, SOLID foi aplicado com pragmatismo (não em excesso), a segurança foi revisada, testes foram implementados quando necessários, `dotnet build` e `dotnet test` estão passando, migrations foram revisadas quando aplicável, o `git diff` foi revisado, e o Git foi tratado conforme `git-standards`. Código funcionando não é sinônimo de tarefa concluída — qualidade, segurança, testes e aderência à arquitetura também fazem parte da definição de pronto.
