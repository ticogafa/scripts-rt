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
#   v1.4 21-11-2024, Tiago Gurgel:
#        - Removida opção de desinstalar Docker, apenas remove Nessus
# --------------------------------------------------------

if [ "$EUID" -ne 0 ]; then 
    echo "ERRO: Este script precisa ser executado como root (use sudo)."
    exit 1
fi

echo "=== Iniciando desinstalação do Nessus ==="
echo ""
echo "ATENÇÃO: Este script irá:"
echo "  - Remover APENAS containers e imagens do Nessus"
echo "  - Docker permanecerá instalado no sistema"
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
        
        read -p "Deseja remover os containers do Nessus? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo "Operação cancelada pelo usuário."
            exit 0
        fi
    else
        echo "Nenhum container do Nessus encontrado."
    fi
    
    echo "Parando containers do Nessus..."
    if [ ! -z "$NESSUS_CONTAINERS" ]; then
        echo "$NESSUS_CONTAINERS" | xargs docker stop 2>/dev/null && echo "Containers parados com sucesso."
        echo "$NESSUS_CONTAINERS" | xargs docker rm 2>/dev/null && echo "Containers removidos com sucesso."
    else
        echo "Nenhum container do Nessus encontrado para parar."
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
    
else
    echo "Docker não está instalado no sistema."
    exit 1
fi

echo ""
echo "=== Desinstalação concluída ==="
echo "Containers e imagens do Nessus foram removidos."
echo "Docker permanece instalado no sistema."
echo "Verifique as mensagens acima para confirmar se todas as operações foram bem-sucedidas."
