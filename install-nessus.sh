#!/bin/bash
#
# Install_Nessus.sh - Executa a instalação Docker/Nessus; 
#
# Site:     https://github.com.br/newe-x
# Autor:    Pedro Ewen <pedrohenriquewen@gmail.com>
# Manutenção: Pedro Ewen <pedrohenriquewen@gmail.com>
#
# --------------------------------------------------------
#
#   O programa executa a instalação do docker usando o respositório padrão e desempenha a instalação da imagem do Tenable Nessus Oficial disponível no docker hub.

#   Exemplo de uso:
#   $ sudo ./Install_Nessus.sh 

# Ordem de requisições externas:
# 1. http://br.archive.ubuntu.com
# 2. https://download.docker.com
# 3. https://hub.docker.com/r/tenable/nessus

# --------------------------------------------------------
#
# Histórico:
#   v1.0 10-10-2024, Pedro Ewen:
#        - Versão Inicial
#   v1.1 21-11-2025, Pedro Ewen:
#        - Reconstrução da lógica e construção da documentação
# --------------------------------------------------------

# É necessário remover as versões antigas do docker, caso esteja instalado.
apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Atualizar pacotes para evitar problemas de versão
apt update && apt upgrade -yy

# Instalação dos certificados e o curl
apt install ca-certificates curl

install -m 0755 -d /etc/apt/keyrings

Inserção do respositório docker ao ambiente
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

Adicionar respositório apt
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Atualizar pacotes para evitar problemas de versão
apt update && apt upgrade -yy

# Instalação dos pacotes Docker
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Validação de instalação e execução
docker run hello-world
systemctl status docker

# Instalação do docker


