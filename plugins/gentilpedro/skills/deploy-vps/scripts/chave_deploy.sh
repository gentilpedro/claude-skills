#!/bin/bash
# Cria (ou troca) a chave de deploy de uma app e cadastra os secrets do GitHub Actions.
#   - gera um par ed25519 numa pasta temporária, apagada no fim;
#   - na VPS, troca a linha "deploy-<app>@github-actions" em ~deploy/.ssh/authorized_keys por
#     uma presa ao forced command "sudo -n /usr/local/bin/app-deploy <app>";
#   - testa a chave com "status";
#   - grava VPS_HOST, VPS_SSH_KEY e VPS_KNOWN_HOSTS no repositório atual (gh secret set).
# A chave privada nunca é impressa. Rode da raiz do repositório do projeto, com o gh autenticado:
#   bash chave_deploy.sh <app>
set -euo pipefail
HOST="${VPS:-vps}"
APP="${1:?uso: chave_deploy.sh <app>}"
[[ "$APP" =~ ^[a-z][a-z0-9-]{1,30}$ ]] || { echo "nome de app inválido: '$APP'" >&2; exit 2; }

gh auth status >/dev/null 2>&1 || { echo "gh não autenticado: peça ao usuário para rodar '! gh auth login'" >&2; exit 2; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
IP=$(ssh -G "$HOST" | awk '/^hostname /{print $2}')
ssh -o BatchMode=yes "$HOST" "test -f /opt/$APP/deploy.conf && test -x /usr/local/bin/app-deploy" \
  || { echo "rode instalar_vps.sh e preparar_app.sh antes" >&2; exit 2; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
COMENTARIO="deploy-$APP@github-actions"
ssh-keygen -q -t ed25519 -N "" -C "$COMENTARIO" -f "$TMP/chave"
LINHA="command=\"sudo -n /usr/local/bin/app-deploy $APP\",restrict $(cat "$TMP/chave.pub")"

ssh -o BatchMode=yes "$HOST" "COMENTARIO='$COMENTARIO' bash -s" <<EOF
set -euo pipefail
AK=/home/deploy/.ssh/authorized_keys
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
touch "\$AK"
grep -v " \$COMENTARIO\$" "\$AK" > "\$AK.novo" || true
echo '$LINHA' >> "\$AK.novo"
chown deploy:deploy "\$AK.novo"; chmod 600 "\$AK.novo"; mv "\$AK.novo" "\$AK"
restorecon -R /home/deploy/.ssh
EOF

KNOWN="$IP $(ssh -o BatchMode=yes "$HOST" 'cut -d" " -f1,2 /etc/ssh/ssh_host_ed25519_key.pub')"
echo "$KNOWN" > "$TMP/known_hosts"
echo "== teste da chave (deve mostrar o status de $APP)"
ssh -o BatchMode=yes -o IdentitiesOnly=yes -o UserKnownHostsFile="$TMP/known_hosts" \
  -i "$TMP/chave" "deploy@$IP" status

gh secret set VPS_HOST --repo "$REPO" --body "$IP"
gh secret set VPS_KNOWN_HOSTS --repo "$REPO" < "$TMP/known_hosts"
gh secret set VPS_SSH_KEY --repo "$REPO" < "$TMP/chave"
echo "ok: chave de $APP instalada e secrets VPS_HOST, VPS_KNOWN_HOSTS e VPS_SSH_KEY gravados em $REPO"
