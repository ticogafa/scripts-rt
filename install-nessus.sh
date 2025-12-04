#!/bin/bash
#
# Install_Nessus.sh - Executa a instalação Docker/Nessus.
#
# Site:     https://github.com.br/newe-x
# Autor:    Pedro Ewen <pedrohenriquewen@gmail.com>
# Manutenção: Pedro Ewen <pedrohenriquewen@gmail.com>
#
# --------------------------------------------------------
#
# O programa executa a instalação do Docker usando o repositório oficial
# e realiza a instalação da imagem oficial do Tenable Nessus disponível
# no Docker Hub.
#
# Exemplo de uso:
#   $ sudo ./Install_Nessus.sh
#
# Ordem de requisições externas:
# 1. http://br.archive.ubuntu.com
# 2. https://download.docker.com
# 3. https://hub.docker.com/r/tenable/nessus
#
# --------------------------------------------------------
#
# Histórico:
#   v1.0 10-10-2024, Pedro Ewen:
#        - Versão inicial.
#   v1.1 21-11-2025, Pedro Ewen:
#        - Reconstrução da lógica e construção da documentação.
# --------------------------------------------------------

# Remoção de versões antigas do Docker, caso existam.
sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1) 2>/dev/null

# Atualização dos pacotes.
sudo apt update && sudo apt upgrade -y

# Instalação de certificados e curl.
sudo apt install -y ca-certificates curl gnupg

# Criação do diretório de keyrings.
sudo install -m 0755 -d /etc/apt/keyrings

# Baixar a chave GPG.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Inserção do repositório Docker.
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualização do ambiente APT.
sudo apt update && sudo apt upgrade -y

# Instalação dos pacotes Docker.
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Validação da instalação.
sudo docker run hello-world
sudo systemctl status docker

# Download da imagem do Nessus.
sudo docker pull tenable/nessus:latest-ubuntu

# Execução do container Nessus.
sudo docker run -d --name nessus -p 8834:8834 tenable/nessus:latest-ubuntu
