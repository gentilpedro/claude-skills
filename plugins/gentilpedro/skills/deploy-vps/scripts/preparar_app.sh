#!/bin/bash
# Prepara (ou atualiza) o lado do servidor de uma app, a partir da pasta deploy/vps/ do projeto:
#   /opt/<app>/docker-compose.yml e deploy.conf   cópias do repositório
#   /opt/<app>/.env                               senha do Postgres, gerada no servidor (só se não existir)
#   /opt/<app>/secrets.env                        vazio; o set-secrets do deploy preenche
#   /etc/nginx/conf.d/<app>.conf                  cópia de deploy/vps/nginx.conf (nginx -t antes do reload)
#   /etc/cron.d/<app>-backup                      app-backup diário, se houver banco ou BACKUP_VOLUMES
#
# Rode da raiz do repositório do projeto:
#   bash preparar_app.sh <app> [pasta=deploy/vps]             mostra o que mudaria, não altera nada
#   bash preparar_app.sh <app> [pasta=deploy/vps] --aplicar   aplica
# Nunca sobrescreve .env nem secrets.env que já existam.
set -euo pipefail
HOST="${VPS:-vps}"
APP="${1:?uso: preparar_app.sh <app> [pasta] [--aplicar]}"
PASTA="deploy/vps"; APLICAR=0
for a in "${@:2}"; do
  if [ "$a" = "--aplicar" ]; then APLICAR=1; else PASTA="$a"; fi
done

[[ "$APP" =~ ^[a-z][a-z0-9-]{1,30}$ ]] || { echo "nome de app inválido: '$APP' (minúsculas, números e hífen)" >&2; exit 2; }
for f in docker-compose.yml deploy.conf nginx.conf; do
  [ -f "$PASTA/$f" ] || { echo "falta $PASTA/$f" >&2; exit 2; }
done
if grep -qE '__[A-Z]+__' "$PASTA/docker-compose.yml" "$PASTA/deploy.conf" "$PASTA/nginx.conf"; then
  echo "ainda há placeholders __...__ em $PASTA:" >&2
  grep -nE '__[A-Z]+__' "$PASTA/docker-compose.yml" "$PASTA/deploy.conf" "$PASTA/nginx.conf" >&2
  exit 2
fi

R="/root/.deploy-vps-$APP"
ssh -o BatchMode=yes "$HOST" "rm -rf $R && mkdir -m 700 $R"
scp -q "$PASTA/docker-compose.yml" "$PASTA/deploy.conf" "$PASTA/nginx.conf" "$HOST:$R/"

ssh -o BatchMode=yes "$HOST" "APP='$APP' R='$R' APLICAR='$APLICAR' bash -s" <<'EOF'
set -euo pipefail
trap 'rm -rf "$R"' EXIT
DIR="/opt/$APP"; NGX="/etc/nginx/conf.d/$APP.conf"; CRON="/etc/cron.d/$APP-backup"

PORT=$(sed -n 's/^PORT=//p' "$R/deploy.conf" | tr -d '"')
DOMINIOS=$(grep -ho 'server_name [^;]*' "$R/nginx.conf" | sed 's/server_name //' | tr ' ' '\n' | sort -u)

# Conflitos com as outras apps: porta e domínio.
for f in /opt/*/docker-compose.yml; do
  [ "$f" = "$DIR/docker-compose.yml" ] && continue
  grep -q "127\.0\.0\.1:$PORT:" "$f" && { echo "porta $PORT já usada em $f" >&2; exit 2; }
done
for d in $DOMINIOS; do
  for f in /etc/nginx/conf.d/*.conf; do
    [ "$f" = "$NGX" ] && continue
    grep -qE "server_name.*[[:space:]]$d[[:space:];]" "$f" && { echo "domínio $d já configurado em $f" >&2; exit 2; }
  done
  [[ "$d" =~ ^[a-z0-9-]+\.aamora\.com\.br$ ]] || echo "AVISO: $d não é *.aamora.com.br — DNS e certificado não estão cobertos pelo curinga"
done

mostrar() { # destino origem
  if [ -f "$1" ]; then diff -u "$1" "$2" && echo "(igual) $1" || true
  else echo "(novo) $1"; fi
}
mostrar "$DIR/docker-compose.yml" "$R/docker-compose.yml"
mostrar "$DIR/deploy.conf" "$R/deploy.conf"
mostrar "$NGX" "$R/nginx.conf"
TEM_DB=0; grep -qE '^  db:' "$R/docker-compose.yml" && TEM_DB=1
VOLS=$(sed -n 's/^BACKUP_VOLUMES=//p' "$R/deploy.conf" | tr -d '"')
[ -f "$DIR/.env" ] && echo "(mantido) $DIR/.env" || echo "(novo) $DIR/.env$([ $TEM_DB = 1 ] && echo ' com senha do Postgres gerada aqui')"
if [ $TEM_DB = 1 ] || [ -n "$VOLS" ]; then
  [ -f "$CRON" ] && echo "(mantido) $CRON" || echo "(novo) $CRON"
fi

[ "$APLICAR" = 1 ] || { echo; echo "Nada alterado. Rode com --aplicar para aplicar."; exit 0; }

install -d -m 750 "$DIR"; install -d -m 700 "$DIR/backups"
install -m 640 "$R/docker-compose.yml" "$DIR/docker-compose.yml"
install -m 600 "$R/deploy.conf" "$DIR/deploy.conf"
if [ ! -f "$DIR/.env" ]; then
  if [ $TEM_DB = 1 ]; then
    NOME_DB=$(echo "$APP" | tr '-' '_')
    printf 'POSTGRES_DB=%s\nPOSTGRES_USER=%s\nPOSTGRES_PASSWORD=%s\n' "$NOME_DB" "$NOME_DB" "$(openssl rand -hex 24)" > "$DIR/.env"
  else
    : > "$DIR/.env"
  fi
  chmod 600 "$DIR/.env"
fi
[ -f "$DIR/secrets.env" ] || install -m 600 /dev/null "$DIR/secrets.env"

# Nginx: só fica a conf nova se o nginx -t aceitar.
[ -f "$NGX" ] && cp -p "$NGX" "$R/nginx.antigo"
install -m 644 "$R/nginx.conf" "$NGX"; restorecon "$NGX"
if ! nginx -tq; then
  if [ -f "$R/nginx.antigo" ]; then cp -p "$R/nginx.antigo" "$NGX"; else rm -f "$NGX"; fi
  echo "nginx -t falhou; conf de $APP desfeita" >&2; exit 1
fi
systemctl reload nginx

if { [ $TEM_DB = 1 ] || [ -n "$VOLS" ]; } && [ ! -f "$CRON" ]; then
  MIN=$(( $(echo "$APP" | cksum | cut -d' ' -f1) % 50 + 5 ))
  printf 'SHELL=/bin/bash\nPATH=/sbin:/bin:/usr/sbin:/usr/bin\n%d 4 * * * root /usr/local/bin/app-backup %s >/var/log/%s-backup.log 2>&1\n' "$MIN" "$APP" "$APP" > "$CRON"
  chmod 644 "$CRON"; restorecon "$CRON"
fi
echo "ok: $APP preparado em $DIR"
EOF
