---
name: github-cicd
description: >
  Garante que todo projeto novo criado neste ambiente saia com CI/CD no
  GitHub Actions desde a primeira criação — não como algo adicionado depois.
  Use esta skill sempre que criar um projeto novo (.NET API, React/Vite,
  Blazor ou Python CLI), sempre que inicializar um repositório, fazer o
  scaffold inicial a partir de um template, ou quando o usuário pedir para
  "criar um projeto", "começar um novo repositório", "montar o esqueleto de
  uma API/app", ou pedir para adicionar/configurar CI, pipeline, workflow do
  GitHub Actions, ou releases automáticas — mesmo que o usuário não use as
  palavras "CI/CD" ou "GitHub Actions" explicitamente. Consulte também
  quando for revisar, corrigir ou estender um workflow existente em
  .github/workflows/, ou antes de publicar uma release/tag.
---

# CI/CD no GitHub Actions para todo projeto novo

Nenhum projeto criado neste ambiente deve existir sem pipeline. "Criar o projeto" e "criar o CI/CD" são a mesma tarefa, não duas tarefas separadas — o commit inicial de um projeto novo já deve incluir `.github/workflows/ci-cd.yml`. Se em algum momento você perceber que criou (ou está prestes a finalizar) um projeto sem workflow, pare e adicione o pipeline antes de considerar a tarefa concluída.

Esta skill assume que as operações Git em si (identidade, branches, commits, push) seguem a skill `git-standards` — use as duas juntas ao criar um projeto novo.

## Regra principal: 7 passos, nesta ordem

1. **Identifique a tecnologia** do projeto (.NET API, React/Vite, Blazor ou Python CLI — ver critérios abaixo).
2. **Identifique o template utilizado** (ex.: `dotnet new webapi`, `npm create vite@latest`, `dotnet new blazor`, cookiecutter, etc.), se houver um.
3. **Inspecione o template** — veja a estrutura de pastas gerada, o gerenciador de dependências, e se já existem scripts de lint/teste configurados. Isso evita gerar um workflow que assume algo que o projeto não tem.
4. **Crie o workflow GitHub Actions correspondente** em `.github/workflows/ci-cd.yml`, a partir do template certo (ver seção "Templates por tecnologia" abaixo). Nunca use um pipeline genérico para todas as linguagens — cada tecnologia tem etapas e ferramentas próprias.
5. **Valide o workflow**: confira que o YAML é sintaticamente válido (`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci-cd.yml'))"` funciona em qualquer ambiente com PyYAML; se o `actionlint` estiver disponível, rode-o também) e que os nomes de jobs/steps fazem sentido para o projeto.
6. **Execute localmente as etapas possíveis** antes de commitar — rode o restore/install, o build, e os testes na máquina local exatamente como o workflow vai rodar (`dotnet build`, `npm run build`, `pytest`, etc.). Isso pega erros óbvios antes de gastar um run de CI com eles.
7. **Faça commit do CI/CD junto com a criação inicial do projeto** — o workflow entra no mesmo commit/PR inicial, não em um commit separado "adicionando CI depois".

### Como identificar a tecnologia

- **.NET API**: existe um `.csproj` referenciando `Microsoft.AspNetCore.App` ou `Microsoft.NET.Sdk.Web`, sem componentes Razor/Blazor.
- **Blazor**: `.csproj` referenciando `Microsoft.AspNetCore.Components.WebAssembly` (Blazor WASM) ou um SDK Blazor Server — geralmente criado com `dotnet new blazor`.
- **React/Vite**: existe `package.json` com `vite` nas dependências (ou `devDependencies`) e um `vite.config.*`.
- **Python CLI**: existe `pyproject.toml` e/ou `setup.py`, tipicamente com um `console_scripts`/`entry_points` definindo o comando de linha de comando, sem framework web.

Se o projeto não se encaixar claramente em nenhuma dessas quatro categorias, adapte o template mais próximo (ex.: um projeto Python que é uma API usa o fluxo do Python CLI, trocando `pytest` por testes de API, mas mantendo o restante) e avise o desenvolvedor sobre a adaptação feita.

## Templates por tecnologia

Cada tecnologia tem um template pronto em `assets/` desta skill — copie o arquivo correspondente para `.github/workflows/ci-cd.yml` no projeto e ajuste os placeholders (versão da linguagem/runtime, caminho do projeto) para o caso real:

| Tecnologia | Template |
|---|---|
| .NET API | `assets/dotnet-api-ci-cd.yml` |
| React/Vite | `assets/react-vite-ci-cd.yml` |
| Blazor | `assets/blazor-ci-cd.yml` |
| Python CLI | `assets/python-ci-cd.yml` |

Os quatro seguem a mesma estrutura de dois jobs (`build-test` e `release`), mas cada um implementa o fluxo específico da sua tecnologia:

**.NET API** — `checkout → setup .NET → restore → build → test → publish → release`. Falha se restore, build, teste ou publish falharem.

**React/Vite** — `checkout → setup Node → npm ci → lint (se configurado) → test (se configurado) → build → release`. Falha se o build falhar. Lint e teste só rodam se o `package.json` declarar os scripts correspondentes (o template já verifica isso automaticamente), para não quebrar um projeto que ainda não os configurou.

**Blazor** — `restore → build → test → publish → release`, igual ao fluxo do .NET API (é a mesma plataforma por baixo).

**Python CLI** — `setup Python → install dependencies → lint quando configurado → pytest → build/package quando aplicável → release`. Lint só roda se houver config de `ruff`/`flake8` no projeto; empacotamento (`python -m build`) só roda se houver `[build-system]` no `pyproject.toml`.

Não copie um template de uma tecnologia para outra "só pra ter algo" — se a tecnologia do projeto não é nenhuma das quatro, adapte a mais próxima deliberadamente (ver seção acima) em vez de usar qualquer uma delas às cegas.

## Release e versionamento

O pipeline gera uma GitHub Release quando uma tag é publicada seguindo `vMAJOR.MINOR.PATCH` (ex.: `v1.0.0`, `v1.1.0`, `v1.1.1`) — é isso que o `on.push.tags: ["v*.*.*"]` nos templates captura. Não gere releases falsas ou incrementais sem motivo real (ou seja, não crie uma tag/release só para "testar o pipeline" em um repositório de verdade).

O job de release só roda depois que o job de build/test passou (`needs: build-test` + checagem de `result == 'success'`). Isso implementa a regra de nunca publicar uma release se o build falhou, os testes falharam, ou o artefato não foi gerado corretamente — se qualquer uma dessas etapas falhar, o job de release simplesmente não é acionado.

## Pull Request vs. branch principal vs. release

- **Pull Request**: aciona o job `build-test` (CI) para validar a mudança. Nunca cria release — os templates só disparam o job `release` quando o gatilho é uma tag `v*.*.*`, nunca em PR.
- **Push na branch principal**: aciona `build-test` para validar que a branch principal continua saudável. Também não gera release por si só.
- **Tag `vMAJOR.MINOR.PATCH`**: é o único gatilho que aciona o job de release/publicação.

Se o projeto usa uma branch principal diferente de `main` (ex.: `master`), ajuste `branches: [main]` nos templates para o nome correto antes de commitar o workflow.

## Segurança

Nunca coloque segredos diretamente no YAML do workflow. Use:
- **GitHub Secrets** para valores sensíveis (tokens, chaves de API, senhas).
- **GitHub Variables** para valores não sensíveis mas configuráveis (nomes, flags).
- **OIDC** quando a integração suportar (ex.: publicar em cloud providers sem armazenar credenciais de longa duração).

Nunca commite, nos templates ou em qualquer outro arquivo do projeto: tokens, senhas, PATs (Personal Access Tokens), API keys, ou connection strings contendo credenciais. Se ao inspecionar um template ou projeto você encontrar algum desses hardcoded, trate como a skill `git-standards` manda para segredos em diffs: pare e avise o desenvolvedor em vez de simplesmente remover e seguir.

## Permissões mínimas

Os templates já seguem esse padrão — mantenha-o ao editar:

```yaml
permissions:
  contents: read
```

no nível do workflow, e eleve para `contents: write` apenas dentro do job de release (é o único que precisa criar a GitHub Release). Não dê permissões de escrita ao job de build/test — ele só precisa ler o código para compilar e testar.

## Objetivo final

Todo projeto novo sai desta skill com quatro coisas, nunca menos: código, testes, CI, e CD/release. Se você entregar um projeto novo e um desses quatro estiver faltando — mesmo que o pedido original do usuário só tenha mencionado o código —, o trabalho não está completo.
