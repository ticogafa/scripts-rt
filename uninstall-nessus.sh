#!/bin/bash
#
# Uninstall_Nessus.sh - Executa a desinstalação Docker/Nessus; 
#
# Site:     https://github.com.br/ticogafa
# Autor:    Tiago Gurgel <tiago.gurgel2006@gmail.com>
# Manutenção: Tiago Gurgel <tiago.gurgel2006@gmail.com>
#
# --------------------------------------------------------
#
#   O programa remove completamente o Docker e suas dependências, incluindo containers, imagens e volumes do Tenable Nessus instalados pelo script install-nessus.sh.

#   Exemplo de uso:
#   $ sudo ./uninstall-nessus.sh 

# Ordem de operações:
# 1. Parar e remover containers do Nessus
# 2. Remover imagens do Nessus
# 3. Desinstalar pacotes Docker instalados
# 4. Limpar repositórios e configurações

# --------------------------------------------------------
#
# Histórico:
#   v1.0 21-11-2024, Tiago Gurgel:
#        - Versão Inicial
#   v1.1 21-11-2024, Tiago Gurgel:
#        - Ajuste para remover apenas itens instalados pelo script de instalação
#   v1.2 21-11-2024, Tiago Gurgel:
#        - Adicionada verificação de permissões e melhorias no tratamento de erros
#   v1.3 21-11-2024, Tiago Gurgel:
#        - Tornado seguro para ambientes com múltiplos containers Docker
# --------------------------------------------------------

if [ "$EUID" -ne 0 ]; then 
    echo "ERRO: Este script precisa ser executado como root (use sudo)."
    exit 1
fi

echo "=== Iniciando desinstalação do Docker e Nessus ==="
echo ""
echo "ATENÇÃO: Este script irá:"
echo "  - Remover APENAS containers e imagens do Nessus"
echo "  - Verificar se existem outros containers antes de remover Docker"
echo ""

if command -v docker &> /dev/null; then
    echo "Docker encontrado. Verificando containers..."
    
    # Contar todos os containers
    TOTAL_CONTAINERS=$(docker ps -a -q | wc -l)
    
    # Buscar containers do Nessus por imagem e por nome
    NESSUS_CONTAINERS_BY_IMAGE=$(docker ps -a --filter "ancestor=tenableofficial/nessus" -q)
    NESSUS_CONTAINERS_BY_NAME=$(docker ps -a --filter "name=nessus" -q)
    
    # Combinar e remover duplicatas
    NESSUS_CONTAINERS=$(echo -e "$NESSUS_CONTAINERS_BY_IMAGE\n$NESSUS_CONTAINERS_BY_NAME" | sort -u | grep -v '^$')
    NESSUS_CONTAINERS_COUNT=$(echo "$NESSUS_CONTAINERS" | grep -c .)
    
    OTHER_CONTAINERS=$((TOTAL_CONTAINERS - NESSUS_CONTAINERS_COUNT))
    
    echo "Containers encontrados:"
    echo "  - Total: $TOTAL_CONTAINERS"
    echo "  - Nessus: $NESSUS_CONTAINERS_COUNT"
    echo "  - Outros: $OTHER_CONTAINERS"
    echo ""
    
    # Mostrar detalhes dos containers do Nessus
    if [ $NESSUS_CONTAINERS_COUNT -gt 0 ]; then
        echo "Containers do Nessus identificados:"
        docker ps -a --filter "ancestor=tenableofficial/nessus" --format "  - {{.ID}} ({{.Image}}) - {{.Status}}"
        docker ps -a --filter "name=nessus" --format "  - {{.ID}} ({{.Image}}) - {{.Status}}" | grep -v "tenableofficial/nessus" 2>/dev/null
        echo ""
    fi
    
    if [ $OTHER_CONTAINERS -gt 0 ]; then
        echo "AVISO: Existem $OTHER_CONTAINERS container(s) além do Nessus!"
        echo "Este script irá remover APENAS os containers do Nessus."
        echo "O Docker e outros containers NÃO serão afetados."
        echo ""
        read -p "Deseja continuar apenas com a remoção do Nessus? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo "Operação cancelada pelo usuário."
            exit 0
        fi
        REMOVE_DOCKER=false
    else
        echo "Nenhum outro container encontrado além do Nessus."
        read -p "Deseja remover Docker completamente? (s/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            REMOVE_DOCKER=true
        else
            REMOVE_DOCKER=false
        fi
    fi
    
    echo "Parando containers do Nessus..."
    if [ ! -z "$NESSUS_CONTAINERS" ]; then
        echo "$NESSUS_CONTAINERS" | xargs docker stop 2>/dev/null && echo "Containers parados com sucesso."
        echo "$NESSUS_CONTAINERS" | xargs docker rm 2>/dev/null && echo "Containers removidos com sucesso."
    else
        echo "Nenhum container do Nessus encontrado."
    fi
    
    echo "Removendo imagens do Nessus..."
    NESSUS_IMAGES=$(docker images tenableofficial/nessus -q)
    if [ ! -z "$NESSUS_IMAGES" ]; then
        docker rmi -f $NESSUS_IMAGES 2>/dev/null && echo "Imagens do Nessus removidas com sucesso."
    else
        echo "Nenhuma imagem do Nessus encontrada."
    fi
    
    echo "Removendo imagem hello-world..."
    docker rmi hello-world 2>/dev/null && echo "Imagem hello-world removida." || echo "Imagem hello-world não encontrada."
    
    if [ "$REMOVE_DOCKER" = true ]; then
        echo ""
        echo "Parando serviço Docker..."
        systemctl stop docker.socket 2>/dev/null && echo "docker.socket parado."
        systemctl stop docker 2>/dev/null && echo "docker parado."
        
        echo "Desinstalando pacotes Docker..."
        if apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null; then
            echo "Pacotes Docker removidos com sucesso."
        else
            echo "Aviso: Alguns pacotes Docker não foram encontrados ou já foram removidos."
        fi
        
        echo "Removendo dependências não utilizadas..."
        apt autoremove -y && echo "Dependências removidas."
        
        echo "Removendo repositório Docker..."
        if [ -f /etc/apt/sources.list.d/docker.sources ]; then
            rm -f /etc/apt/sources.list.d/docker.sources && echo "Repositório Docker removido."
        else
            echo "Repositório Docker não encontrado."
        fi
        
        echo "Removendo chave GPG..."
        if [ -f /etc/apt/keyrings/docker.asc ]; then
            rm -f /etc/apt/keyrings/docker.asc && echo "Chave GPG removida."
        else
            echo "Chave GPG não encontrada."
        fi
        
        echo "Removendo diretórios do Docker..."
        [ -d /var/lib/docker ] && rm -rf /var/lib/docker && echo "Diretório /var/lib/docker removido."
        [ -d /var/lib/containerd ] && rm -rf /var/lib/containerd && echo "Diretório /var/lib/containerd removido."
        [ -d /etc/docker ] && rm -rf /etc/docker && echo "Diretório /etc/docker removido."
        
        echo "Atualizando lista de pacotes..."
        apt update -qq && echo "Lista de pacotes atualizada."
    else
        echo ""
        echo "Docker mantido no sistema (outros containers detectados)."
    fi
else
    echo "Docker não está instalado."
    REMOVE_DOCKER=false
fi

echo ""
echo "=== Desinstalação concluída ==="
if [ "$REMOVE_DOCKER" = true ]; then
    echo "Docker e Nessus foram completamente removidos do sistema."
else
    echo "Apenas containers e imagens do Nessus foram removidos."
    echo "Docker permanece instalado no sistema."
fi
echo "Verifique as mensagens acima para confirmar se todas as operações foram bem-sucedidas."
