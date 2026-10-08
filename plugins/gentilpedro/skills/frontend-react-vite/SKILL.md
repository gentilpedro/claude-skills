---
name: frontend-react-vite
description: >
  Especializada em desenvolvimento e manutenção de frontends React +
  TypeScript + Vite + Tailwind do template create-gentilpedro-react. Use
  sempre que for criar/alterar páginas, componentes, hooks, services,
  formulários, estado, routing, ou integração com API num projeto já
  criado a partir desse template — mesmo sem o usuário dizer "React" ou
  "frontend", bastando "cria uma tela de X" ou "esse componente não
  atualiza". Consulte também antes de instalar qualquer dependência nova
  (Redux, Zustand, React Query, Axios, etc.), usar `any`/`as any`,
  `dangerouslySetInnerHTML`, ou colocar algo em variável `VITE_*`. NÃO usar
  para criar projeto novo (`template-standards`), Git (`git-standards`),
  CI/CD (`github-cicd`), release (`release-standards`), ou APIs backend
  (`api-dotnet-ddd`/`api-dotnet-solid`) — foco exclusivo no frontend React.
---

# Frontend React + TypeScript + Vite + Tailwind (template create-gentilpedro-react)

Esta skill assume que o projeto já existe, criado a partir do template `create-gentilpedro-react` (`npm create gentilpedro-react@latest <nome>`, fonte em `github.com/gentilpedro/template-react-vite`). Ela não cria projetos novos — isso é `template-standards`; nunca clone o repositório, copie arquivos manualmente, ou reconstrua o template. Depois que o projeto existe, a estrutura local é a fonte de verdade, e esta skill governa as decisões de implementação dentro dela.

## Stack e dependências

Stack: React, TypeScript, Vite, Tailwind CSS. Respeite as versões e dependências já presentes no projeto. Antes de adicionar qualquer biblioteca: verifique o `package.json` → verifique se o projeto já tem solução equivalente → verifique se React/TypeScript/o próprio browser já resolvem → avalie a necessidade real → avalie manutenção do pacote → só então adicione. Não instale Axios, Redux, Zustand, React Query, React Hook Form, Zod, Lodash, ou qualquer outra biblioteca só porque é popular — se o projeto já usa uma dessas, respeite o padrão existente; se não usa, a pergunta não é "qual é boa", é "isso é realmente necessário aqui". Não instale por preferência pessoal.

## React

Componentes funcionais — não escreva class components em código novo. Prefira composição a herança/abstração. Evite componentes gigantes: se um componente acumula UI, chamada HTTP, regra de negócio, estado complexo, transformação de dados e validação tudo junto, é hora de separar responsabilidades. Não crie abstrações prematuramente — a separação vem quando a complexidade já apareceu, não antes.

## TypeScript

Use tipagem estrita. Evite `any` quando existir alternativa razoável, e nunca use `as any` só para calar o compilador — isso não resolve o erro, esconde ele. Evite casts desnecessários. Prefira interfaces, types, generics, union types e type guards quando eles realmente agregam clareza (não porque "é mais TypeScript"). Os tipos devem representar corretamente o domínio da aplicação — um tipo errado que só engana o compilador é pior que nenhum tipo.

## Componentes

Componentes reutilizáveis (`Button`, `Modal`, `Input`, `Select`, `Table`, `Card`, `Loading`, `ErrorState`, `EmptyState`...) se justificam quando há reuso real — não transforme cada elemento HTML num componente sem necessidade. Um componente reutilizável não deve conhecer detalhes de uma página específica sem necessidade real (isso quebra a reutilização que era o motivo dele existir).

## Páginas

Páginas orquestram componentes e o fluxo da tela — evite colocar toda a lógica da aplicação direto nelas. Toda página que consome dados trata adequadamente loading, success, empty e error; não renderize simplesmente "Carregando..." sem considerar o que acontece quando a chamada falha ou volta vazia.

## Hooks

Hooks customizados (`useAuth`, `useDebounce`, `useFetch`, `usePagination`...) se justificam quando há lógica reutilizável ou complexa — não crie um hook customizado para todo `useState`. Siga as Rules of Hooks: nunca chame hooks dentro de `if`, dentro de loops, ou dentro de função condicional.

## useEffect

Não use `useEffect` como solução genérica para qualquer lógica. Antes de usá-lo, verifique se o valor pode ser derivado diretamente durante o render — se pode, não precisa de efeito. Evite efeitos redundantes e loops causados por array de dependências incorreto.

Ao buscar dados num efeito: controle loading, controle erro, evite chamadas duplicadas, considere cancelamento (`AbortController`) quando necessário, e evite race conditions (a resposta de uma requisição antiga chegando depois de uma mais nova e sobrescrevendo o estado com dado desatualizado). Não escreva `useEffect(() => { ... }, [])` de forma automática sem entender se aquele comportamento (rodar uma vez na montagem) é realmente o que o caso precisa.

## Estado

Diferencie estado local, estado derivado, estado compartilhado, estado remoto/server state, e estado de formulário — cada um tem o lugar certo. Não crie estado global sem necessidade. Antes de instalar Redux/Zustand/qualquer gerenciador de estado: verifique se `useState`/`useReducer`/Context já resolve → verifique se o projeto já tem uma solução → avalie a complexidade real do caso → só então considere uma biblioteca nova. Não duplique estado derivado — quando um valor pode ser calculado a partir de outro estado, calcule-o, não o guarde separadamente (evita os dois ficarem dessincronizados).

## Context

Use Context API quando há estado compartilhado que realmente se beneficia disso — não para qualquer estado. Evite um Context gigante contendo o estado da aplicação inteira; separe contexts quando as responsabilidades forem distintas (um `AuthContext` não precisa saber do estado de um carrinho de compras).

## Routing

Respeite o sistema de routing já existente no projeto. Não implemente navegação manual com `window.location` quando o router da aplicação resolve o problema. Rotas protegidas respeitam autenticação/autorização de verdade — esconder um link não é mecanismo de autorização, é só UX.

## Autenticação e autorização no frontend

O frontend nunca é a autoridade final de autorização — o backend valida as permissões de verdade. No frontend, você pode: controlar sessão, cuidar da UX, esconder opções sem permissão (por conveniência, não por segurança), redirecionar usuários, tratar sessão expirada. Mas nunca trate o frontend como mecanismo de segurança real — qualquer verificação feita só no cliente pode ser contornada por quem chama a API diretamente.

## Tokens e secrets

Nunca coloque segredo de backend no código frontend. Tudo que vai para o bundle é público — qualquer pessoa pode abrir o DevTools e ler. Nunca commite client secrets, private keys, senhas, API secrets, ou tokens permanentes no frontend. **Variáveis `VITE_*` devem ser tratadas como públicas** — não coloque segredo em `VITE_API_SECRET` ou equivalente; se algo precisa ser secreto, ele pertence ao backend, nunca a uma env var exposta ao Vite.

## API / Services

Não espalhe chamadas HTTP por dezenas de componentes — organize em services. Estrutura: `Component → Hook/Service → API`. Services concentram a comunicação com o backend e mantêm contratos tipados (`getUsers()`, `createUser()`, `updateUser()`, `deleteUser()`...). Não misture renderização com detalhe HTTP dentro do componente.

## HTTP

Ao consumir API: verifique o status HTTP, trate erros, trate timeout, trate sessão expirada, trate respostas inesperadas, evite chamadas duplicadas, cancele chamadas quando necessário. Não assuma que toda resposta é sucesso — não faça `response.json()` sem verificar antes se a resposta é apropriada, quando isso puder gerar um erro não tratado.

## Formulários

Um formulário tem estado, validação, loading, erro, sucesso, e feedback visual. Não permita múltiplos submits acidentais — o botão de submit tem um estado adequado durante o processamento (desabilitado ou com indicador de carregamento). Validação de frontend melhora a UX; **validação de backend é obrigatória para segurança** — a do frontend nunca substitui a do backend.

## XSS

Nunca renderize HTML fornecido pelo usuário diretamente. Evite `dangerouslySetInnerHTML`; se for absolutamente necessário, identifique a origem do conteúdo, sanitize, valide, e justifique explicitamente por que é necessário (não é uma decisão para tomar em silêncio). Não confie em conteúdo vindo da API como se fosse seguro por definição — ele pode ter sido escrito por outro usuário. Não insira strings vindas de fora diretamente em HTML.

## Tailwind

Use Tailwind conforme o padrão do template; evite CSS inline quando Tailwind resolve, e evite arquivos CSS globais desnecessários. **Não introduza Bootstrap, Material UI, Chakra ou Ant Design sem solicitação explícita** — não misture frameworks de UI sem necessidade real.

## Design system

Quando um padrão visual se repete, avalie criar um componente reutilizável (`Button`, `Input`, `Modal`, `Badge`, `Table`, `Card`...) em vez de duplicá-lo dezenas de vezes. Ao mesmo tempo, não crie um design system inteiro antes de existir necessidade real — comece com o componente que resolve o caso concreto, não com a biblioteca de componentes que você imagina que vai precisar.

## Responsividade

Toda interface nova considera desktop, tablet e mobile — não desenvolva assumindo só resolução desktop. Use os recursos responsivos do Tailwind (`sm:`, `md:`, `lg:`...); evite larguras, alturas e margens fixas que quebram em telas menores.

## Acessibilidade

Sempre que aplicável: labels associados aos inputs, `aria-label`, `aria-describedby`, foco visível, navegação por teclado, elementos semânticos, contraste adequado, mensagens de erro acessíveis. Não use só cor para indicar estado. Imagens têm `alt` apropriado quando necessário. Botões são `<button>`, links são `<a>` (ou o mecanismo de navegação do router) — não use `<div>` como botão só por facilidade, isso quebra teclado e leitor de tela.

## Loading / Error / Empty

Toda tela que consome dados considera os quatro estados: loading → success (com dado) → empty (sem registro) → error (mensagem + ação, como "tentar de novo"). Não deixe uma tela simplesmente vazia ou travada quando a API falha.

## Performance

Evite otimização prematura. Priorize componentes simples, renderização previsível, evitar estado e efeitos desnecessários, paginação, lazy loading quando necessário, imagens otimizadas. Use `useMemo`/`useCallback`/`memo` só quando há benefício real medido — não os adicione automaticamente em todo componente; cada um deles também tem custo (comparação de dependências a cada render), e usá-los sem necessidade pode até piorar a performance em vez de melhorar.

## Listas

Use keys estáveis ao renderizar listas — evite `key={index}` quando existir um identificador estável (`key={user.id}`). Uma key instável faz o React perder a identidade dos elementos entre renders, causando bugs de estado (ex.: input perdendo foco, animação errada) que parecem aleatórios.

## Imagens e datas

Imagens consideram dimensão, carregamento, `alt`, responsividade e formato apropriado — não carregue imagens gigantes sem necessidade. Datas: não manipule manualmente através de strings espalhadas pelo código; respeite timezone; antes de adicionar uma biblioteca de datas, verifique se o projeto já tem uma solução.

## Formatação

Formatação de moeda, número, data e percentual é centralizada/reutilizável quando há repetição — não espalhe a mesma regra de formatação (ex.: `toLocaleString` com as mesmas opções) em vários componentes.

## Error Boundaries

Use Error Boundaries quando aplicável, para impedir que uma falha isolada derrube a interface inteira. Não os use como substituto do tratamento normal de erro de API — Error Boundary é para erros de renderização inesperados, não para o caminho normal de "a API retornou 500".

## Testes

Toda funcionalidade relevante tem teste, testando comportamento observável, não implementação interna desnecessariamente. Prioridade: componentes críticos, formulários, autenticação, fluxos de negócio, hooks relevantes, tratamento de erro. Ao corrigir um bug: reproduza → crie teste de regressão quando apropriado → corrija → execute os testes.

## Lint, testes e build — sempre via `package.json`

Antes de considerar uma implementação concluída, rode o lint, os testes e o build **usando os scripts que o `package.json` do projeto já define** — não invente comando. Verifique primeiro o `package.json`: o comando de teste pode ser `npm test`, `npm run test`, `npm run test:run`, ou outro; o comando de build normalmente é `npm run build`, mas o que está configurado no projeto é a fonte de verdade, não a convenção mais comum.

(O script `scripts/quality_gate.sh` desta skill lê o `package.json` do projeto, roda `lint`/`test`/`build` só se esses scripts existirem — sem chutar nome de comando — e para no primeiro erro.)

Se o build falhar, a tarefa não está concluída: não ignore erro de TypeScript, e não remova tipo só para o build passar (trocar um tipo certo por `any` para "resolver" um erro de build é o mesmo problema disfarçado, não uma correção).

## Segurança

Ao implementar qualquer funcionalidade, avalie: XSS, CSRF quando aplicável, exposição de tokens, secrets, IDOR, autenticação, autorização, dados sensíveis, URLs externas, upload de arquivo, download de arquivo, open redirects. Não confie na validação de frontend para segurança. Não exponha informação sensível no bundle. Não armazene secret em variável `VITE_*`.

## Fluxo de implementação

**Feature nova:**

1. Entender o requisito.
2. Identificar a página.
3. Identificar componentes existentes reutilizáveis.
4. Identificar services existentes.
5. Identificar hooks existentes.
6. Implementar o mínimo necessário.
7. Adicionar os estados: loading, error, empty, success.
8. Implementar responsividade.
9. Implementar acessibilidade.
10. Validar segurança.
11. Criar testes quando necessário.
12. Executar o lint (script do `package.json`).
13. Executar os testes (script do `package.json`).
14. Executar o build (script do `package.json`).
15. Revisar TypeScript (sem `any`/`as any` desnecessário).
16. Revisar dependências adicionadas.
17. Revisar o `git diff`.
18. Seguir `git-standards` (branch `feature/<descricao>`).

**Correção de bug:**

1. Reproduzir o bug.
2. Identificar a camada: componente, hook, service, API, estado, routing, CSS, ou autenticação.
3. Criar teste de regressão quando apropriado.
4. Corrigir na camada correta.
5. Executar o lint.
6. Executar os testes.
7. Executar o build.
8. Verificar possíveis regressões.
9. Revisar segurança.
10. Seguir `git-standards` (branch `bugfix/<descricao>`).

## Quality Gate

Uma implementação não está concluída até: o requisito estar implementado, TypeScript sem erros, lint passando, testes passando quando aplicáveis, build passando, segurança revisada, responsividade revisada, acessibilidade considerada, os estados loading/error/empty tratados quando aplicável, dependências revisadas, `git diff` revisado, e Git tratado conforme `git-standards`. "O código aparece na tela" não significa que a tarefa está concluída.

## Regra de conservadorismo

Prefira React + TypeScript + Vite + Tailwind + as bibliotecas que já existem no projeto antes de adicionar qualquer dependência nova. Não transforme uma feature simples numa arquitetura complexa. Não crie hooks desnecessários, contexts desnecessários, stores globais desnecessárias, abstrações desnecessárias, componentes artificiais, ou bibliotecas novas sem justificativa real. O objetivo é código simples, tipado, testável, seguro e sustentável — não o mais "arquitetural" possível.

## O que esta skill NÃO faz — e quem faz

- **Criar o projeto**: `template-standards` — nunca clone o repositório do template nem reconstrua a estrutura manualmente aqui.
- **Operações de Git**: `git-standards`. Não duplicado aqui — só reforça `feature/<descricao>` e `bugfix/<descricao>`, nunca direto na branch principal.
- **CI/CD**: `github-cicd`. O mínimo esperado para a pipeline é `install → lint → test → build → release quando aplicável`; não reimplementado aqui.
- **Versionamento e GitHub Release**: `release-standards`.
- **APIs backend**: `api-dotnet-ddd` ou `api-dotnet-solid`, conforme o backend que este frontend consome.
