---
name: blazor-dotnet10
description: >
  Especializada em desenvolvimento e manutenção de aplicações Blazor Web
  App em .NET 10 do template GentilPedro.Templates.Blazor10 (projeto
  principal + `.Client`, InteractiveAuto, Bootstrap, tema claro/escuro).
  Use sempre que for criar/alterar componentes Razor, páginas, layouts,
  formulários, decidir render mode, mexer em ciclo de vida (OnInitialized/
  OnAfterRender/Dispose), usar JS Interop, tratar estado, consumir APIs,
  ou corrigir bugs de renderização/navegação num projeto Blazor já criado
  a partir desse template — mesmo sem o usuário dizer "Blazor" ou "render
  mode", bastando "cria uma página de X" ou "esse componente não está
  atualizando". NÃO usar para criar projeto novo (`template-standards`),
  Git (`git-standards`), CI/CD (`github-cicd`), release
  (`release-standards`), ou APIs .NET (`api-dotnet-ddd`/`api-dotnet-solid`)
  — foco exclusivo em Blazor.
---

# Blazor Web App .NET 10 (template GentilPedro.Templates.Blazor10)

Esta skill assume que o projeto já existe, criado a partir do template `GentilPedro.Templates.Blazor10` (package `GentilPedro.Templates.Blazor10`, template `blazor10`, fonte em `github.com/gentilpedro/template-dotnet-blazor10`). Ela não cria projetos novos — isso é `template-standards`; o template nunca deve ser clonado, copiado manualmente ou reconstruído de memória. Depois que o projeto existe, a estrutura local é a fonte de verdade, e esta skill governa as decisões de implementação e arquitetura Blazor dentro dela.

## Arquitetura

O projeto tem um projeto principal e um projeto `.Client`, organizados em Components, Layout e Pages. Respeite essa separação — não mova componentes entre o projeto principal e o `.Client` sem entender o impacto no render mode e no modelo de execução (código no lugar errado pode simplesmente parar de funcionar, ou funcionar só às vezes, dependendo de onde ele acaba rodando). Não introduza MVC, Razor Pages, Angular, React ou Vue para resolver um problema que pertence ao Blazor — se algo parece difícil no Blazor, o caminho é entender o modelo de execução dele melhor, não trazer outro framework para dentro do projeto.

## Render modes

O template usa `InteractiveAuto` como padrão. Antes de definir ou mudar um render mode, entenda: onde o componente vai executar, quando ele terá interatividade, se pode rodar no servidor, se pode rodar no cliente, quais dependências estão disponíveis em cada lugar, se vai precisar de JS Interop, se vai precisar de APIs do browser. Não aplique `InteractiveAuto` (ou qualquer render mode) indiscriminadamente, e **não altere o render mode global para resolver um problema de um componente específico** — isso troca um bug localizado por um problema de performance/comportamento espalhado pelo app inteiro. Quando um componente precisa de interatividade específica, defina o render mode no nível dele, não no nível da aplicação.

### SSR vs. interatividade

Diferencie server-side rendering de interactive rendering. Não assuma que todo código Razor vai executar no browser, e não assuma que todo código pode acessar APIs JavaScript durante a renderização inicial — no SSR e durante o prerendering, essas APIs simplesmente não existem ainda. Operações que dependem do browser precisam esperar o momento certo do lifecycle (ver seção abaixo).

## Projeto `.Client`

Antes de colocar código no `.Client`, avalie se ele realmente precisa executar no cliente. Não mova classes para lá só para "organizar" — isso é uma decisão de execução, não de arrumação de pastas. Não crie dependências circulares entre os dois projetos, e não deixe o projeto principal depender de componentes que só podem existir no cliente.

## Componentes Razor

Componentes têm responsabilidade clara; evite componentes gigantes. Se um componente está acumulando markup, chamadas HTTP, regra de negócio, validação, estado, JS Interop e processamento complexo tudo junto, isso é sinal para extrair responsabilidades em componentes menores e serviços — prefira sempre componentes pequenos e reutilizáveis a um componente que faz tudo.

### Code-behind

Use `Component.razor` + `Component.razor.cs` quando a lógica do componente está complexa o suficiente para que a separação melhore a legibilidade. Não crie code-behind para componentes triviais só por hábito ou "porque é o padrão" — o objetivo é legibilidade, não uma regra mecânica.

## Ciclo de vida

Conheça e respeite `OnInitialized`/`OnInitializedAsync`, `OnParametersSet`/`OnParametersSetAsync`, `OnAfterRender`/`OnAfterRenderAsync`, `Dispose`/`IAsyncDisposable`. Nunca execute lógica que depende do browser numa fase em que o browser ainda não está disponível (SSR/prerendering) — JS Interop dependente do DOM precisa esperar o lifecycle apropriado (tipicamente `OnAfterRenderAsync`). Ao usar `OnAfterRenderAsync`, controle o parâmetro `firstRender` quando for o caso, para não repetir uma inicialização a cada render.

Evite o loop clássico `OnAfterRenderAsync → StateHasChanged → OnAfterRenderAsync → StateHasChanged → ...`. Não chame `StateHasChanged` indiscriminadamente — cada chamada desnecessária é um re-render desnecessário.

## JS Interop

Use JS Interop só quando necessário — antes de escrever JavaScript, verifique se o Blazor/.NET já resolve o problema nativamente. Não transforme o projeto numa aplicação JavaScript com Razor só como container em volta.

Ao usar JS Interop: respeite o lifecycle, evite chamadas repetitivas, trate o caso do componente ser destruído no meio de uma chamada, libere recursos quando necessário, considere o prerendering/SSR (não assuma que `window`/`document` estarão disponíveis durante toda a renderização). Nunca insira JavaScript inline sem necessidade — prefira arquivos `.js` organizados a strings de JS espalhadas no código C#.

## Estado

Dê ao estado o escopo apropriado: local do componente, compartilhado, de sessão, ou persistente — não crie estado global para tudo por padrão. Evite guardar informação sensível no estado do cliente, e nunca confie no estado do frontend como mecanismo de segurança — esconder algo na UI não é autorização; a autorização real sempre é validada no backend.

## Services

Componentes não concentram lógica de acesso a APIs externas. Quando há comunicação com o backend, prefira um service dedicado: `Component → Service → API`. Não coloque `HttpClient` + tratamento de erro + mapeamento + regra de negócio repetidos em cada componente — reutilize services existentes. E, como nas skills de API, não crie uma interface para cada service automaticamente; só quando houver necessidade real de abstração.

## HTTP / API

Ao consumir APIs: trate os status HTTP, trate erros, evite chamadas duplicadas e chamadas a cada renderização, use `CancellationToken` quando apropriado. Nunca exponha secrets no cliente — nunca coloque connection strings, senhas, API secrets, JWT secrets ou chaves privadas no projeto `.Client` (ou em qualquer código que rode no browser). Trate qualquer configuração que chegue ao cliente como pública, porque ela é: tudo que roda no browser pode ser inspecionado pelo usuário.

## Formulários e validação

Use os mecanismos de formulário do Blazor: `EditForm`, `EditContext`, `DataAnnotationsValidator`, `ValidationMessage`, `ValidationSummary`. Não implemente validação manual repetitiva campo a campo quando esses mecanismos já resolvem.

Frontend e backend têm responsabilidades diferentes: o frontend dá feedback rápido e cuida de UX; o backend cuida de segurança, regra de negócio, e é a validação definitiva. **A validação do Blazor nunca substitui a validação do backend** — nunca confie somente nela, porque um usuário pode chamar a API diretamente, sem passar pelo formulário.

## Autenticação e autorização

Respeite o mecanismo de autenticação já existente no projeto; não implemente um mecanismo paralelo. Não armazene secrets no frontend. Esconder um elemento da UI não é autorização — é só UX; a autorização real acontece no backend, sempre. Ao criar páginas protegidas, use os mecanismos oficiais do Blazor para isso (atributos de autorização, `AuthorizeView`, etc.), consistentes com o que o projeto já usa.

## Navegação

Use o sistema de routing do Blazor: `@page`, `NavigationManager`, `RouteView`, layouts, autorização de rota. Não implemente navegação manual via JavaScript quando o router do Blazor já resolve. Não espalhe URLs hardcoded pelo código — centralize rotas de forma que mudar uma URL não signifique caçar strings pelo projeto inteiro.

## Layout

Respeite os layouts existentes no template. Não duplique header, menu, sidebar ou footer em cada página — componentes de layout existem justamente para isso; mantenha-os reutilizáveis.

## CSS

O template usa Bootstrap — preserve o padrão visual existente, prefira as classes Bootstrap já disponíveis, e **não introduza Tailwind CSS nem outro framework de UI sem solicitação explícita**. Evite CSS duplicado. Ao criar CSS específico de um componente, use o escopo adequado (CSS isolation do Blazor: `Component.razor.css`), evite estilos globais desnecessários, e não quebre componentes existentes.

## Tema claro/escuro

O template já suporta tema claro/escuro — preserve o mecanismo existente; não crie um segundo sistema de tema em paralelo. Ao adicionar componentes, verifique compatibilidade com os dois temas e evite cores hardcoded que quebrem um deles (uma cor de texto fixa que fica ilegível no modo escuro é o erro mais comum aqui).

## Acessibilidade

Sempre que aplicável: labels associados aos inputs, navegação por teclado funcionando, foco visível, elementos semânticos (não `div` para tudo), `aria-label` quando necessário, contraste adequado, mensagens de erro acessíveis (não só uma borda vermelha). Não use só cor para comunicar estado (erro, sucesso, aviso) — sempre acompanhe de texto ou ícone, para quem não distingue as cores.

## Performance

Evite renderizações desnecessárias: chamadas HTTP repetidas, carregamento de grandes volumes de dados de uma vez, loops de renderização, `StateHasChanged` desnecessário, componentes excessivamente complexos, processamento pesado dentro do render. Use paginação quando o volume de dados puder crescer — não carregue tudo de uma vez só para preencher um componente quando o backend já pode paginar/filtrar. Ao mesmo tempo, não otimize prematuramente: meça antes de assumir que algo é um problema de performance.

## Disposal

Componentes que usam timers, subscriptions, eventos, streams ou recursos JS precisam liberar esses recursos corretamente — implemente `IDisposable`/`IAsyncDisposable` quando necessário. Uma subscription não removida é um memory leak silencioso que só aparece depois de muita navegação entre páginas.

## Segurança

Ao implementar qualquer funcionalidade, avalie: autenticação, autorização, XSS, dados sensíveis, exposição de informação, manipulação de HTML, JS Interop, URLs externas, uploads, downloads. Evite renderizar HTML arbitrário; não use `MarkupString` (ou equivalente) para conteúdo não confiável sem sanitização apropriada — isso é a porta de entrada mais comum para XSS em Blazor. Nunca confie em dados enviados pelo cliente: eles podem ter sido manipulados antes de chegar ao backend.

## Criando um componente reutilizável

Nesta ordem: defina a responsabilidade → defina os parâmetros → defina os eventos → defina o estado → avalie reutilização → avalie acessibilidade → avalie render mode → avalie lifecycle. Parâmetros têm nomes claros; eventos seguem os padrões do Blazor (`EventCallback<T>`); não use callbacks genéricos sem necessidade.

## Criando uma página nova

Nesta ordem: identifique a rota → identifique o layout → identifique o render mode → identifique os services necessários → crie os estados de UI (loading, error, empty, success) → implemente a UI → implemente a validação → implemente as chamadas necessárias → valide responsividade → valide light/dark mode → valide acessibilidade.

## Tratamento de erros

Não ignore exceptions. Não use `catch { }` vazio sem tratamento adequado. A UI deve ter estados de erro compreensíveis para quem está usando — não mostre stack trace nem informação interna ao usuário; logs detalhados ficam no lado apropriado da aplicação (servidor), nunca expostos no cliente.

## Testes

Ao adicionar lógica importante, crie testes. Prioridade: regras de apresentação relevantes, comportamento de componentes, validações, services, fluxos críticos. Teste comportamento observável, não só implementação interna. Ao corrigir um bug: reproduza → crie teste de regressão quando apropriado → corrija → execute os testes.

## Build / Quality Gate

Antes de considerar qualquer implementação concluída, execute:

```bash
dotnet restore
dotnet build
dotnet test
```

(O script `scripts/quality_gate.sh` desta skill automatiza essas três etapas, parando no primeiro erro e reportando warnings.) Se o projeto tiver testes específicos para a mudança, rode-os também. **Se build ou testes falharem, a tarefa não está concluída** — não ignore warnings ou erros relevantes.

## Regra de conservadorismo

Não adicione bibliotecas sem necessidade. Não introduza frameworks JavaScript para resolver um problema que o Blazor já resolve nativamente. Não faça refatorações grandes durante uma feature simples. Não altere o render mode global para corrigir um componente específico. Não transforme componentes simples em arquiteturas complexas. Antes de adicionar uma abstração, verifique se existe necessidade real; antes de adicionar JavaScript, verifique se existe solução nativa do Blazor; antes de adicionar uma biblioteca de UI, verifique se o Bootstrap já resolve.

## Fluxo de implementação

**Feature nova:**

1. Entender o requisito.
2. Identificar a página/componente.
3. Identificar o render mode.
4. Identificar os services necessários.
5. Implementar o componente.
6. Separar code-behind quando necessário.
7. Implementar os estados de UI.
8. Implementar a validação.
9. Implementar a comunicação com API quando necessário.
10. Implementar acessibilidade.
11. Validar light/dark mode.
12. Verificar o lifecycle.
13. Verificar JS Interop quando aplicável.
14. Criar testes quando necessário.
15. `dotnet restore` / `dotnet build` / `dotnet test`.
16. Revisar segurança.
17. Revisar performance.
18. Revisar arquitetura.
19. Revisar o `git diff`.
20. Seguir `git-standards` (branch `feature/<descricao>`).

**Correção de bug:**

1. Reproduzir o bug.
2. Identificar se o problema é de renderização, lifecycle, estado, navegação, API, CSS, JS Interop, autenticação, ou autorização.
3. Criar teste de regressão quando apropriado.
4. Corrigir na camada correta.
5. Executar o build.
6. Executar os testes.
7. Verificar que não introduziu regressão.
8. Revisar segurança.
9. Revisar performance.
10. Seguir `git-standards` (branch `bugfix/<descricao>`).

## O que esta skill NÃO faz — e quem faz

- **Criar o projeto**: `template-standards` — nunca clone o repositório do template nem reconstrua a arquitetura manualmente aqui.
- **Operações de Git**: `git-standards`. Esta skill não duplica essas regras — só reforça `feature/<descricao>` e `bugfix/<descricao>`, nunca direto na branch principal.
- **CI/CD**: `github-cicd`. O mínimo esperado para a pipeline é `restore → build → test → publish → release quando aplicável`; não reimplementado aqui.
- **Versionamento e GitHub Release**: `release-standards`.
- **APIs .NET**: `api-dotnet-ddd` ou `api-dotnet-solid`, conforme o template da API consumida por este front-end — não confunda as regras de uma com as da outra.

Não substitua Bootstrap por Tailwind, não substitua `InteractiveAuto` por outro modelo globalmente sem motivo real, e não reestruture o projeto por preferência pessoal.

## Critério de conclusão

Uma implementação só está concluída quando: o requisito foi implementado, a arquitetura do template foi preservada, o render mode é adequado ao componente, o lifecycle está correto, o estado está tratado com o escopo certo, a segurança foi revisada, a acessibilidade foi considerada, os testes aplicáveis estão passando, `dotnet build` e `dotnet test` passam, o `git diff` foi revisado, e o Git foi tratado conforme `git-standards`. "O código aparece na tela" não significa que a tarefa está concluída — a implementação precisa estar correta dentro do modelo de execução do Blazor (o render mode certo, no lifecycle certo, sem vazar estado ou segredo para o cliente), não só parecer certa numa primeira olhada no browser.
