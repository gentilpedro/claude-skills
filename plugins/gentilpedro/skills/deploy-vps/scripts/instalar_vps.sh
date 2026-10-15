#!/bin/bash
# Instala/atualiza na VPS os scripts app-deploy, app-backup e app-import desta skill e o sudoers
# que deixa o usuário "deploy" rodar o app-deploy. Idempotente.
#   bash instalar_vps.sh             mostra o que mudaria (diff), não altera nada
#   bash instalar_vps.sh --aplicar   instala
set -euo pipefail
HOST="${VPS:-vps}"
SERVER_DIR="$(cd "$(dirname "$0")/../server" && pwd)"

for f in app-deploy app-backup app-import; do
  echo "=== $f"
  if ssh -o BatchMode=yes "$HOST" "cat /usr/local/bin/$f 2>/dev/null || true" | diff -u - "$SERVER_DIR/$f"; then
    echo "(igual)"
  fi
done

if [ "${1:-}" != "--aplicar" ]; then
  echo; echo "Nada alterado. Rode com --aplicar para instalar."
  exit 0
fi

ssh -o BatchMode=yes "$HOST" 'rm -rf /root/.deploy-vps-inst && mkdir -m 700 /root/.deploy-vps-inst'
scp -q "$SERVER_DIR/app-deploy" "$SERVER_DIR/app-backup" "$SERVER_DIR/app-import" "$HOST:/root/.deploy-vps-inst/"

ssh -o BatchMode=yes "$HOST" 'bash -s' <<'EOF'
set -euo pipefail
T=/root/.deploy-vps-inst
trap 'rm -rf "$T"' EXIT
for f in app-deploy app-backup app-import; do
  install -m 750 -o root -g root "$T/$f" "/usr/local/bin/$f"
  restorecon "/usr/local/bin/$f"
done
cat > "$T/sudoers" <<'S'
# skill deploy-vps: cada chave só chega aqui pelo forced command em ~deploy/.ssh/authorized_keys
Defaults:deploy env_keep += "SSH_ORIGINAL_COMMAND"
deploy ALL=(root) NOPASSWD: /usr/local/bin/app-deploy
S
visudo -cqf "$T/sudoers"
install -m 440 -o root -g root "$T/sudoers" /etc/sudoers.d/app-deploy
restorecon /etc/sudoers.d/app-deploy
id deploy >/dev/null
echo "ok: app-deploy, app-backup, app-import e sudoers instalados"
EOF
