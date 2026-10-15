---
name: deploy-vps
description: Coloca no ar, na VPS aamora.com.br, uma aplicação que ainda não está publicada ou que roda em outro lugar (Vercel, Netlify, Render, Railway, Heroku, Fly, MonsterASP, Azure, Neon, Supabase…). Monta Docker + Nginx + deploy por GitHub Actions com rollback automático e migra os dados. Use sempre que o usuário pedir para "fazer o deploy", "subir pra VPS", "colocar no ar", "publicar em <algo>.aamora.com.br", "migrar do <host> pra minha VPS" ou "tirar do <host>", mesmo sem falar em Docker ou Nginx. Use também para rollback, status ou troca da chave de deploy de uma app que já usa o app-deploy. NÃO usar para criar o CI do zero (`github-cicd`) nem para decidir versão ou tag (`release-standards`).
---

# Deploy na VPS aamora.com.br

## Primeira pergunta, sempre: a URL

Antes de qualquer outra coisa (inspecionar, escrever arquivo, tocar no servidor), **pergunte ao
usuário como vai ficar a URL do serviço novo**. Use o AskUserQuestion com sugestões tiradas do nome
do projeto, por exemplo `https://<projeto>.aamora.com.br` (recomendada), uma variação mais curta e
"outra". Nunca assuma a URL, nem quando ela parecer óbvia. Se o pedido já trouxer a URL, confirme
a que entendeu.

Com a resposta, confira:

- **`<nome>.aamora.com.br` (um nível)** já funciona: o DNS curinga do Cloudflare e o certificado de
  origem `*.aamora.com.br` cobrem.
- **`aamora.com.br` / `www`** já estão em uso (site principal em `/var/www/aamora`). Avise e pergunte.
- **Dois níveis (`api.app.aamora.com.br`) ou outro domínio**: o curinga não cobre. Precisa de
  registro DNS no Cloudflare e de outro certificado de origem. Explique e combine com o usuário
  antes de seguir, porque ele é que mexe no painel do Cloudflare.
- O domínio não pode estar no `server_name` de outra app (o `vps_info.sh` lista).

O nome da app (`<app>`: pasta `/opt/<app>`, imagem, projeto do Compose) sai do subdomínio:
minúsculas, números e hífen.

## Como a VPS está montada

```
navegador → Cloudflare (proxy, WAF) → Nginx do host :443 → 127.0.0.1:<porta> → container web
                                                                              └→ container db (Postgres 18)
```

- Rocky Linux 10 com SELinux, 3,6 GB de RAM para tudo. Alias SSH `vps` (root) no `~/.ssh/config`.
- O firewalld só aceita 80/443 vindos dos IPs do Cloudflare; o resto bate no `00-default.conf` (444).
- Cada app tem **um** `/opt/<app>/` com `docker-compose.yml`, `deploy.conf`, `.env` (senha do
  Postgres, gerada no servidor e que só existe lá), `secrets.env` (escrito pelo deploy),
  `.version` e `backups/`. O Nginx fica em `/etc/nginx/conf.d/<app>.conf` com
  `include snippets/aamora-ssl.conf`.
- O deploy roda pelo GitHub Actions na tag `vX.Y.Z`: `docker save | ssh deploy@VPS`. A chave de
  cada repositório só consegue rodar `app-deploy <app>` (forced command), então não abre shell, não
  lê arquivo e não alcança outra app.
- `app-deploy <app> up <versão>` sobe a versão, confere `http://127.0.0.1:<porta><HEALTH_PATH>` e
  **volta sozinho para a versão anterior** se ela não responder. Guarda as 3 últimas imagens.
- `app-backup <app>` faz o backup diário (banco + volumes) com retenção de 7 dias. `app-import`
  importa dados de outro host e é só para o root.
- **Nexus e PreçoBaixo são legados**: o Nexus tem o `nexus-deploy` próprio e o PreçoBaixo é manual.
  Não mexa neles por esta skill sem o usuário pedir.

Scripts desta skill (rode com o Bash do Git):

```bash
S="${CLAUDE_SKILL_DIR}/scripts"
bash $S/vps_info.sh                       # só leitura: RAM, portas, sub-redes, domínios, scripts instalados
bash $S/instalar_vps.sh [--aplicar]       # instala/atualiza app-deploy, app-backup, app-import e o sudoers
bash $S/preparar_app.sh <app> [--aplicar] # da raiz do projeto: /opt/<app>, .env, nginx, cron de backup
bash $S/chave_deploy.sh <app>             # da raiz do projeto: chave de deploy + secrets VPS_* no GitHub
```

Sem `--aplicar`, os scripts só mostram o diff do que mudaria. **Tudo que escreve na VPS é produção:**
mostre o diff ao usuário e espere o "pode" antes de rodar com `--aplicar`. A autorização vale para
aquele passo, não para os seguintes.

## 1. Diagnóstico (só leitura)

1. **URL**: veja a seção acima.
2. **Onde a app está hoje**: em nenhum lugar, ou em qual host. Leia o que der no repositório
   (`vercel.json`, `netlify.toml`, `render.yaml`, `fly.toml`, `Procfile`, `railway.json`,
   `.github/workflows/*` com FTP/Azure etc.) e pergunte o que não estiver lá.
3. **Stack**: .NET API/Blazor, React/Vite (SPA estática), Node, Python web… Se já tem `Dockerfile`,
   aproveite. Python CLI não é serviço web: esta skill não serve para ele.
4. **Dados**: usa banco? Qual (Postgres, SQL Server, MySQL, SQLite)? Tem arquivos de usuário
   (uploads)? Tem segredos (API keys, SMTP)? Lembre que o banco novo é **Postgres 18**, e que vir de
   outro motor é uma migração de dados à parte: combine com o usuário.
5. **Health check**: qual rota responde 2xx com o app pronto? .NET sem rota:
   `builder.Services.AddHealthChecks()` + `app.MapHealthChecks("/health")`. A SPA usa o `/health`
   do `spa.conf`.
6. `bash $S/vps_info.sh`: escolha a **próxima porta livre a partir de 5101** e a **próxima sub-rede
   livre `172.30.N.0/24`** (o Nexus usa a `172.30.0`). Some o `mem_limit` novo ao total e compare
   com a RAM. Se apertar, diga isso ao usuário antes (baixar limites, app sem banco próprio…). Se
   os scripts `app-*` aparecerem como ausentes ou desatualizados, o passo 3 instala.

Apresente o plano numa mensagem curta: URL, `<app>`, porta, sub-rede, `mem_limit`, banco sim/não,
segredos, migração de dados sim/não. Siga só depois do ok.

## 2. Arquivos no repositório

Siga a `fluxo-issue-mr` (issue + branch) e a `git-standards`. Crie `deploy/vps/` a partir de
`${CLAUDE_SKILL_DIR}/assets/`, trocando os placeholders `__APP__`, `__DOMINIO__`, `__PORTA__`,
`__SUBREDE__` (ex.: `172.30.1`) e `__PROJETO__`:

| Asset | Vai para | Observação |
|---|---|---|
| `Dockerfile.dotnet` / `Dockerfile.react-vite` | `deploy/vps/Dockerfile` | Se o projeto já tem Dockerfile, adapte o dele: a imagem precisa escutar em **8080** |
| `spa.conf` | `deploy/vps/spa.conf` | Só para SPA |
| `docker-compose.yml` | `deploy/vps/docker-compose.yml` | Tire o que não é do stack; sem banco, tire o `db` |
| `deploy.conf` | `deploy/vps/deploy.conf` | `HEALTH_PATH`, `SECRETS`, `BACKUP_VOLUMES` |
| `nginx.conf` | `deploy/vps/nginx.conf` | Blazor Server/SignalR: timeouts de 1h |
| `dockerignore` | `.dockerignore` na raiz | Mescle se já existir |
| `deploy-job.yml` | job `deploy-vps` em `.github/workflows/ci-cd.yml` | Se não houver CI, crie primeiro pela `github-cicd` |

Pontos que costumam quebrar:

- **Migrations (.NET/EF)**: o app precisa aplicar as migrations na subida ou o deploy precisa
  rodá-las. Confira como o projeto faz hoje.
- **Proxy**: o app está atrás de proxy (HTTPS termina no Nginx). No .NET, `UseForwardedHeaders`
  com `KnownProxies` = gateway da sub-rede (`PROXY_GATEWAY`); no Express, `trust proxy`.
  Sem isso, redirects e cookies `Secure` saem errados.
- **CORS e URLs absolutas**: o front e a API precisam conhecer a URL nova.
- **Uploads**: precisam de volume nomeado (`volumes:` no compose) e permissão do usuário do
  container (.NET: uid 1654).
- **SPA**: `VITE_*` entra no bundle na hora do build. Vai como **variável** do GitHub
  (`vars.`), nunca como segredo.

Se houver Docker local, rode `docker build -f deploy/vps/Dockerfile .` para validar. Valide o YAML
do workflow como manda a `github-cicd`.

## 3. Servidor (com confirmação a cada passo)

1. `bash $S/instalar_vps.sh` → mostre o diff → ok → `--aplicar`. Só na primeira vez, ou quando o
   `vps_info.sh` acusar os scripts como desatualizados.
2. Da raiz do projeto: `bash $S/preparar_app.sh <app>` → mostre o diff → ok → `--aplicar`. Ele
   recusa porta ou domínio que já pertençam a outra app e desfaz a conf do Nginx se o `nginx -t`
   falhar. Depois disso a URL responde 502 até o primeiro deploy, o que é esperado.
3. `bash $S/chave_deploy.sh <app>`: cria a chave, testa com `status` e grava `VPS_HOST`,
   `VPS_SSH_KEY` e `VPS_KNOWN_HOSTS` no repositório. Precisa do `gh` autenticado; se não estiver,
   peça `! gh auth login`.
4. **Segredos da app**: o próprio usuário cadastra em *Settings → Secrets and variables → Actions*
   (ou com `gh secret set NOME`). **Nunca peça nem aceite valor de segredo no chat**. Os nomes
   precisam estar no `SECRETS` do `deploy.conf` e no passo "Enviar os segredos" do workflow.

## 4. Primeiro deploy

Commit, PR e merge pelo fluxo normal. Depois a tag pela `release-standards`, que dispara o
`deploy-vps`. Acompanhe com `gh run watch`. Se falhar:

```bash
gh run view --log-failed
ssh vps 'app-deploy <app> status; cd /opt/<app> && APP_VERSION=$(cat .version) docker compose logs --tail 100'
```

Para ver a resposta pública: `curl -sI https://<dominio>/`.

## 5. Migrar os dados (se a app vem de outro host)

Faça depois do primeiro deploy, quando o banco e os volumes já existem.

1. Peça ao usuário um **snapshot da VPS** no painel da Locaweb.
2. Combine a janela: deixe a app antiga só leitura ou em manutenção, para nada novo ser gravado lá
   durante a cópia.
3. **Banco Postgres de origem** (Neon, Supabase, Render, Railway…): peça ao usuário para salvar
   `ORIGEM_URL=postgres://...` (sem aspas) num arquivo local, por exemplo
   `~/.aamora/<app>-origem.env`, sem colar no chat. Depois:

   ```bash
   scp ~/.aamora/<app>-origem.env vps:/root/<app>-origem.env      # nunca dê cat nesse arquivo
   ssh vps 'docker run --rm --env-file /root/<app>-origem.env postgres:18-alpine \
              sh -c "pg_dump \"\$ORIGEM_URL\" -Fc --no-owner --no-privileges" > /var/tmp/<app>.dump \
            ; shred -u /root/<app>-origem.env'
   ssh vps 'app-import <app> db /var/tmp/<app>.dump && rm /var/tmp/<app>.dump'
   ```

   No Supabase, acrescente `-n public` ao `pg_dump`: os schemas `auth`/`storage` não existem aqui.
   O `app-import` guarda o banco atual em `backups/pre-import-*.dump`, recria o banco, restaura,
   mostra as tabelas com o número de linhas e sobe o web de novo. Confira essas contagens com o
   usuário.
4. **Arquivos** (uploads): traga para um `.tar.gz` local, mande com `scp` para `/var/tmp/` e rode
   `ssh vps 'app-import <app> volume <volume> /var/tmp/<arq>.tar.gz 1654'` (uid do usuário do
   container).
5. **Outro motor** (SQL Server, MySQL, SQLite): não tem atalho. Planeje com o usuário (ferramenta de
   conversão, exportar por CSV ou deixar o EF recriar o schema e copiar os dados).

## 6. Virada e depois

- Teste com o usuário na URL nova: login, fluxo principal, upload, e-mail.
- **Não apague nada no host antigo** (projeto na Vercel, banco no Neon, site no MonsterASP). Sugira
  um redirect ou aviso apontando para a URL nova e deixe a remoção para o usuário decidir.
- Monitoramento: o `aamora-healthcheck` só olha os containers do projeto `aamora`, e o backup só
  avisa o Healthchecks.io se `HC_<APP>_BACKUP_URL` estiver em `/etc/aamora/monitor.env`. Pergunte se
  o usuário quer incluir a app nova.
- Escreva em `deploy/vps/README.md` (curto) a URL, a porta, o que mora em `/opt/<app>` e como fazer
  rollback. Os arquivos de `deploy/vps/` não vão sozinhos para o servidor: mudou compose,
  `deploy.conf` ou nginx, rode o `preparar_app.sh` de novo.

## Operação do dia a dia

```bash
ssh vps 'app-deploy <app> status'               # versão no ar, imagens guardadas, containers
ssh vps 'app-deploy <app> up 1.4.2'             # rollback para uma imagem guardada
ssh vps 'app-backup <app>'                      # backup na hora
bash $S/chave_deploy.sh <app>                   # troca a chave de deploy (vazou, rotação)
```

## Nunca

- Escrever na VPS sem mostrar o diff e ter o ok; mexer em Nexus, PreçoBaixo, aamora ou nos
  `aamora-*` sem pedido explícito.
- Imprimir `.env`, `secrets.env`, a chave privada ou a URL do banco de origem; pedir segredo no chat.
- Publicar porta fora de `127.0.0.1`, abrir porta no firewalld ou desligar o Cloudflare na frente.
- Usar a chave root (`vps`) no GitHub Actions; lá, só a chave presa ao `app-deploy <app>`.
- Apagar volume, banco ou backup, ou rodar `docker system prune`/`volume prune` na VPS.
- Assumir a URL sem perguntar.
