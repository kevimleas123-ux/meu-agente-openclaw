#!/usr/bin/env bash
# Instala Docker e o OpenClaw na VPS (Ubuntu 22.04 / Debian 12).
# Uso:  bash install-vps.sh
set -euo pipefail

echo ">> Atualizando o sistema..."
sudo apt-get update -y && sudo apt-get upgrade -y

if ! command -v docker >/dev/null 2>&1; then
  echo ">> Instalando Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo ">> Docker instalado. SAIA e ENTRE de novo no SSH antes de continuar."
fi

echo ">> Baixando o OpenClaw..."
cd "$HOME"
[ -d openclaw ] || git clone https://github.com/openclaw/openclaw.git
cd openclaw

echo ">> Pronto. Proximo passo: copiar seu .env e subir os containers."
echo "   cp ~/meu-agente-openclaw/.env.example .env && nano .env"
echo "   docker compose up -d"
