---
name: git-standards
description: >
  Padroniza todas as operações Git realizadas pelo Claude Code neste ambiente
  (identidade de commit local, criação de branches, revisão antes de
  commit/push e proteção contra comandos destrutivos). Use esta skill sempre
  que for realizar qualquer operação Git — rodar git status/git diff, criar
  ou trocar de branch, configurar git config, revisar alterações, fazer
  commit, dar push, abrir Pull Request — ou quando o usuário pedir para
  implementar uma feature, corrigir um bug, ou subir uma alteração em um
  repositório com Git, mesmo que o usuário não use a palavra "git"
  explicitamente. Consulte esta skill também antes de qualquer comando
  potencialmente destrutivo (reset --hard, clean -fd, checkout -- .,
  restore ., push --force, branch -D).
---

# Padrões de Git

Este é o padrão operacional para qualquer trabalho em repositórios Git neste ambiente. O objetivo é duplo: manter a autoria dos commits consistente e nunca perder trabalho — nem o do usuário, nem o que está sendo feito agora. Sempre que uma tarefa envolver tocar em um repositório Git, siga este fluxo do início ao fim, na ordem:

```
status → identificar branch → fetch → criar branch de feature/bug → implementar
   → validar → git diff → commit → push → Pull Request
```

Não pule etapas para "ganhar tempo" — cada uma existe para evitar um erro específico e caro (autoria errada, trabalho na branch errada, commit de segredo, push destrutivo). Se em algum ponto o fluxo indicar uma ação irreversível, pare e pergunte ao desenvolvedor antes de continuar.

## 1. Identidade Git (sempre local, nunca global)

Todo repositório em que você commitar precisa ter localmente:

```bash
git config --local user.name "gentilpedro"
git config --local user.email "gentil.pedro21@gmail.com"
```

Antes de qualquer commit, valide a configuração atual:

```bash
git config --local user.name
git config --local user.email
```

Se os valores não baterem com o padrão acima (ou não existirem), corrija com `git config --local` antes de commitar. Nunca use `git config --global` para isso — a configuração global pertence ao usuário e a outros projetos dele fora deste fluxo, e sobrescrevê-la afetaria repositórios que não têm nada a ver com esta tarefa. Se a identidade local já estiver correta, não é necessário reconfigurar.

## 2. Nunca implemente direto na branch principal

Antes de começar qualquer feature ou correção de bug, execute nesta ordem:

1. `git status` — veja o estado atual e se há algo pendente.
2. `git branch --show-current` — identifique em que branch você está.
3. Identifique a branch principal do projeto. Normalmente é `main`, `master` ou `develop`, mas alguns projetos usam outro nome para a branch protegida/principal — se não for óbvio, verifique (ex: `git remote show origin`, arquivos de CI/CD, ou pergunte ao desenvolvedor) antes de assumir.
4. `git fetch --all --prune` — atualize as referências remotas.
5. Garanta que o ponto de partida do trabalho seja a branch apropriada (normalmente a principal, atualizada), e não uma branch de outra feature.
6. Crie uma branch nova para o trabalho (ver convenção de nomes abaixo).

Se em algum momento você perceber que está na branch principal e o pedido é para implementar uma feature ou corrigir um bug, **não implemente ali**. Crie a branch apropriada primeiro e só então comece a mexer no código. Isso vale mesmo que a mudança pareça pequena — branches pequenas ainda passam por revisão antes de ir para a principal.

Não reutilize uma branch criada para outra feature ou bug sem autorização explícita do desenvolvedor — misturar trabalhos não relacionados numa mesma branch dificulta o review e o rollback.

### Convenção de nomes

- Features: `feature/<descricao>` — ex.: `feature/login-usuario`, `feature/cadastro-produto`, `feature/refresh-token`
- Bugs: `bugfix/<descricao>` — ex.: `bugfix/corrigir-login`, `bugfix/erro-paginacao`, `bugfix/token-expirado`

Use `<descricao>` em minúsculas, com hífens, e o mais específico possível sobre o que está sendo feito. Se o projeto já tiver sua própria convenção de nomenclatura de branches (visível no histórico de branches existentes ou em um `CONTRIBUTING.md`), siga a convenção do projeto em vez desta — o objetivo é consistência com o time, não com esta skill.

## 3. Antes de commitar: revise antes de adicionar

Rode e leia com atenção:

```bash
git status
git diff
git diff --staged
```

Revise os arquivos modificados antes de decidir o que vai para o commit. Não use `git add .` nem `git add --all` sem antes ter olhado o diff — esses comandos adicionam tudo indiscriminadamente, incluindo arquivos que nunca deveriam ir para o repositório. Prefira adicionar arquivos específicos (`git add caminho/do/arquivo`) depois de confirmar que cada um pertence a este commit.

Evite adicionar:
- `.env`, `.env.*`, e qualquer arquivo de segredos, credenciais, tokens ou senhas
- arquivos de configuração de IDE
- `bin/`, `obj/`, `node_modules/`, `dist/`, `build/`
- arquivos temporários

Se durante a revisão do diff você encontrar um segredo (chave de API, senha, token, string de conexão com credenciais, etc.), **pare o processo de commit imediatamente** e avise o desenvolvedor em vez de tentar remover a linha e seguir em frente sozinho — o desenvolvedor pode precisar rotacionar a credencial exposta, não só removê-la do diff.

## 4. Commits pequenos e objetivos

Cada commit deve corresponder a uma mudança coerente. Evite misturar, no mesmo commit, uma feature nova com um refactor grande e não relacionado ou uma alteração de infraestrutura — isso dificulta revisão, bisect e rollback. Se notar que o diff acumulado cobre mais de uma coisa, considere dividir em múltiplos commits.

Use mensagens claras, no padrão Conventional Commits:

```
feat: adiciona autenticação de usuário
fix: corrige validação de email
refactor: simplifica serviço de produtos
test: adiciona testes de autenticação
ci: adiciona pipeline de release
docs: atualiza documentação da API
```

## 5. Antes de dar push

Verifique:

```bash
git status
git branch --show-current
git log -1
git diff origin/<branch>...HEAD
```

Confirme que está na branch correta, que o último commit é o esperado, e que o diff contra o remoto contém só o que deveria. Nunca dê push direto para `main`/`master` (ou a branch principal identificada no passo 2) — o trabalho sempre vai por uma branch própria.

## 6. Push

```bash
git push -u origin <branch>
```

Não use force push por padrão. `git push --force` (ou `--force-with-lease`) só deve ser executado com autorização explícita do desenvolvedor para aquele push específico, porque pode reescrever histórico que outra pessoa já baixou.

## 7. Pull Request

Depois do push, informe ao desenvolvedor que a branch está pronta para Pull Request. Se o projeto tiver GitHub conectado (por exemplo, o `gh` CLI disponível), use as ferramentas disponíveis para criar ou preparar o PR. Depois de aberto:

- Não faça merge automaticamente.
- Não faça squash automaticamente.
- Não delete a branch automaticamente.

Essas decisões finais de fluxo de revisão pertencem ao time, não a esta automação.

## 8. Preservação de alterações locais

Se existirem alterações locais não relacionadas à tarefa atual (por exemplo, arquivos modificados por outro trabalho em andamento), não as sobrescreva, descarte ou resete. Informe o desenvolvedor sobre o que encontrou e preserve o estado atual — se for necessário isolar o trabalho da tarefa, prefira criar um stash nomeado ou uma branch separada a apagar algo.

## 9. Comandos destrutivos — nunca automáticos

Os comandos abaixo podem descartar trabalho de forma irreversível. Nunca os execute automaticamente; exija autorização explícita do desenvolvedor para cada uso, informando antes o que exatamente será perdido:

- `git reset --hard`
- `git clean -fd`
- `git checkout -- .`
- `git restore .`
- `git push --force`
- `git branch -D`

Se uma tarefa parecer exigir um desses comandos (por exemplo, "descarte minhas mudanças locais"), confirme com o desenvolvedor exatamente o que será descartado antes de rodar o comando, mesmo que o pedido já pareça explícito — a confirmação evita que um mal-entendido sobre *quais* arquivos serão afetados vire perda de trabalho.

## Resumo do fluxo

```
git status
  → git branch --show-current + identificar branch principal
  → git fetch --all --prune
  → criar branch feature/<descricao> ou bugfix/<descricao>
  → implementar
  → validar identidade local (user.name / user.email)
  → git status / git diff / git diff --staged (revisar antes de add)
  → git add <arquivos específicos>
  → commit (mensagem no padrão Conventional Commits)
  → git status / git branch --show-current / git log -1 / git diff origin/<branch>...HEAD
  → git push -u origin <branch>
  → informar que está pronta para Pull Request (usar `gh` se disponível)
```

Segurança e preservação do trabalho local vêm antes de velocidade: em caso de dúvida sobre branch, identidade, segredos no diff, ou qualquer comando destrutivo, pare e pergunte antes de agir.
