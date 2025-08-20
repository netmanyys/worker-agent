#!/bin/sh
set -e

# Ensure HOME is set (should be for non-root user, but just in case)
: "${HOME:=/home/${USERNAME:-agent}}"

# Ensure SSH dir exists for the non-root user
mkdir -p "$HOME/.ssh" 2>/dev/null || true
chmod 700 "$HOME/.ssh" 2>/dev/null || true

# Try to use an explicit private key if provided; otherwise default to id_ed25519
if [ -n "${ANSIBLE_PRIVATE_KEY:-}" ] && [ -f "$ANSIBLE_PRIVATE_KEY" ]; then
  chmod 600 "$ANSIBLE_PRIVATE_KEY" 2>/dev/null || true   # ignore RO bind errors
elif [ -f "$HOME/.ssh/id_ed25519" ]; then
  export ANSIBLE_PRIVATE_KEY="$HOME/.ssh/id_ed25519"
  chmod 600 "$ANSIBLE_PRIVATE_KEY" 2>/dev/null || true
fi

# Optional defaults
: "${ANsIBLE_CONFIG:=/opt/ansible/ansible.cfg}"
: "${ANSIBLE_INVENTORY:=/opt/ansible/inventories/hosts.ini}"
: "${ANSIBLE_STDOUT_CALLBACK:=default}"                 # avoid yaml callback conflicts
: "${ANSIBLE_PYTHON_INTERPRETER:=/usr/local/bin/python}"
: "${ANSIBLE_HOST_KEY_CHECKING:=False}"

export ANSIBLE_CONFIG ANSIBLE_INVENTORY ANSIBLE_STDOUT_CALLBACK \
       ANSIBLE_PYTHON_INTERPRETER ANSIBLE_HOST_KEY_CHECKING ANSIBLE_PRIVATE_KEY

echo "== Worker Agent Environment =="
echo "ANSIBLE_CONFIG=$ANSIBLE_CONFIG"
echo "ANSIBLE_INVENTORY=$ANSIBLE_INVENTORY"
echo "ANSIBLE_PRIVATE_KEY=${ANSIBLE_PRIVATE_KEY:-<unset>}"
ansible --version || true
python --version || true
go version || true
echo "=========================="

exec "$@"
