#!/bin/bash
# Inventário da VPS, só leitura: RAM e mem_limit somados, disco, apps em /opt, portas e sub-redes
# já usadas, domínios no Nginx e se os scripts app-* instalados batem com os desta skill.
# Uso: bash vps_info.sh   (usa o alias "vps" do ~/.ssh/config)
set -euo pipefail
HOST="${VPS:-vps}"
SERVER_DIR="$(cd "$(dirname "$0")/../server" && pwd)"

# O sha256sum do Git Bash marca "*arquivo" (modo binário); o do Linux, não.
LOCAL_SHAS=$(cd "$SERVER_DIR" && sha256sum app-deploy app-backup app-import | sed 's/ \*/ /')

ssh -o BatchMode=yes "$HOST" "LOCAL_SHAS='$LOCAL_SHAS' bash -s" <<'EOF'
echo "## Memória"
free -m | awk 'NR==2{printf "total %d MB, disponível agora %d MB\n",$2,$7}'
docker ps -q | xargs -r docker inspect --format '{{.Name}} {{.HostConfig.Memory}}' \
  | awk '{s+=$2; printf "  %-28s mem_limit %5d MB\n",substr($1,2),$2/1048576} END{printf "  soma dos mem_limit: %d MB\n",s/1048576}'

echo; echo "## Disco"
df -h / | awk 'NR==2{print $3" usados de "$2" ("$5")"}'

echo; echo "## Apps em /opt"
for d in /opt/*/; do
  n=$(basename "$d"); [ "$n" = containerd ] && continue
  v=$(cat "$d/.version" 2>/dev/null || echo -)
  [ -f "$d/deploy.conf" ] && modo=app-deploy || modo="própria/manual"
  printf "  %-14s versão %-10s deploy: %s\n" "$n" "$v" "$modo"
done

echo; echo "## Portas em 127.0.0.1 (inclui as reservadas em comentário)"
grep -ho '127\.0\.0\.1:[0-9]\+' /opt/*/docker-compose.yml /etc/nginx/conf.d/*.conf 2>/dev/null \
  | cut -d: -f2 | sort -nu | tr '\n' ' '; echo

echo; echo "## Sub-redes Docker fixas"
grep -ho 'subnet: *[0-9./]\+' /opt/*/docker-compose.yml 2>/dev/null | awk '{print "  "$2}' | sort -u

echo; echo "## Domínios no Nginx"
grep -ho 'server_name [^;]*' /etc/nginx/conf.d/*.conf | sed 's/server_name //' | tr ' ' '\n' \
  | grep -v '^""$' | sort -u | sed 's/^/  /'

echo; echo "## Scripts app-* (skill deploy-vps)"
while read -r sha nome; do
  f=/usr/local/bin/$nome
  if [ ! -f "$f" ]; then st="ausente"
  elif [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$sha" ]; then st="atualizado"
  else st="DESATUALIZADO"; fi
  printf "  %-11s %s\n" "$nome" "$st"
done <<< "$LOCAL_SHAS"
[ -f /etc/sudoers.d/app-deploy ] && echo "  sudoers     ok" || echo "  sudoers     ausente"
EOF
