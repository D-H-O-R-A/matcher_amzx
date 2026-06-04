#!/usr/bin/env bash

# Terminal Colors
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
BOLD='\e[1m'
NC='\e[0m' # No Color

clear
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}⚡  AMZX PRIVATE BLOCKCHAIN NETWORK & MATCHER BOOTSTRAP SYSTEM   ⚡${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "Este script configura, automatiza e inicializa uma rede privada isolada"
echo -e "de forma totalmente interativa e customizada.\n"

# 1. Check for Java 17
if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
fi

JAVA_VER=$(java -version 2>&1 | head -n 1)
if [[ ! "$JAVA_VER" == *"17.0"* ]]; then
    echo -e "${RED}[AVISO] OpenJDK 17 não detectado como versão padrão de execução.${NC}"
    echo -e "Tentando carregar o caminho padrão homologado..."
    export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
    export PATH=$JAVA_HOME/bin:$PATH
    JAVA_VER=$(java -version 2>&1 | head -n 1)
    if [[ ! "$JAVA_VER" == *"17.0"* ]]; then
        echo -e "${RED}[ERRO] Por favor, instale o OpenJDK 17 para continuar.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}[OK]¹ Java 17 Detectado com sucesso:${NC} $JAVA_VER"

# 2. Collect custom parameters
echo -e "\n${CYAN}--- PASSO 1: CONFIGURAÇÃO DE PARÂMETROS DA REDE ---${NC}"
read -p "Letra do Chain ID (padrão 'D'): " CHAIN_ID
CHAIN_ID=${CHAIN_ID:-D}
CHAIN_ID=$(echo "$CHAIN_ID" | tr '[:lower:]' '[:upper:]' | cut -c1)

read -p "Suprimento Inicial de Moedas (padrão '100000000'): " SUPPLY
SUPPLY=${SUPPLY:-100000000}

read -p "Tempo Médio entre Blocos (padrão '10' segundos): " BLOCK_DELAY
BLOCK_DELAY=${BLOCK_DELAY:-10}

read -p "API-Key Password das REST APIs (padrão 'ridethewaves!'): " API_KEY
API_KEY=${API_KEY:-ridethewaves!}

read -p "Senha de Segurança da Wallet Admin (padrão 'amzblockchainpassword123!'): " WALLET_PWD
WALLET_PWD=${WALLET_PWD:-amzblockchainpassword123!}

# Target Directories
WAVES_DIR="/home/diegooris/Documentos/amzblockchain/waves"
MATCHER_DIR="/home/diegooris/Documentos/amzblockchain/matcher"
OUTPUT_DIR="/home/diegooris/Documentos/amzblockchain/custom-network/active-network"

echo -e "\n${CYAN}--- PASSO 2: GERANDO CONFIGURAÇÕES CRIPTOGRÁFICAS E GÊNESIS ---${NC}"
echo -e "Compilando e executando o gerador customizado..."

cd "$WAVES_DIR" || exit 1
sbt "node/runMain com.wavesplatform.utils.generator.CustomNetworkGenerator $CHAIN_ID $SUPPLY $BLOCK_DELAY $API_KEY $WALLET_PWD $OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERRO] Falha ao executar o gerador CustomNetworkGenerator.${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Configurações de rede geradas em:${NC} $OUTPUT_DIR"

# 3. Compile extension jar if missing
EXT_JAR="$MATCHER_DIR/waves-ext/target/waves-ext-2.4.21-DIRTY.jar"
if [ ! -f "$EXT_JAR" ]; then
    echo -e "\n${CYAN}--- PASSO 3: COMPILANDO EXTENSÃO gRPC DO MATCHER ---${NC}"
    cd "$MATCHER_DIR" || exit 1
    sbt "project waves-ext" packageBin
fi

# Copy dynamic extension to loadable node directory
mkdir -p "$OUTPUT_DIR/lib"
cp "$MATCHER_DIR/waves-ext/target/waves-ext-2.4.21-DIRTY.jar" "$OUTPUT_DIR/lib/"
echo -e "${GREEN}[OK] Extensão gRPC copiada com sucesso para a pasta de execução.${NC}"

# 4. Interactive Start Option
echo -e "\n${CYAN}--- PASSO 4: INICIALIZAÇÃO DA REDE ---${NC}"
read -p "Deseja inicializar o Nó Blockchain e o Matcher DEX agora mesmo? (S/n): " RUN_NOW
RUN_NOW=${RUN_NOW:-S}

if [[ "$RUN_NOW" =~ ^[Ss]$ ]]; then
    # Kill any old running nodes
    echo -e "Finalizando processos anteriores do nó e do matcher (se houver)..."
    pkill -f "com.wavesplatform.Application" > /dev/null 2>&1
    pkill -f "com.wavesplatform.dex.Matcher" > /dev/null 2>&1
    sleep 1

    echo -e "\n${GREEN}🚀 Iniciando o Nó Blockchain em segundo plano...${NC}"
    cd "$WAVES_DIR" || exit 1
    
    java \
      --add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
      --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \
      -cp "node/target/waves-all-1.6.3-DIRTY.jar:$OUTPUT_DIR/lib/*" \
      com.wavesplatform.Application "$OUTPUT_DIR/custom-blockchain.conf" > "$OUTPUT_DIR/node.log" 2>&1 &
    
    NODE_PID=$!
    echo -e "${GREEN}[INFO] Nó Blockchain rodando com PID $NODE_PID (Logs em node.log)${NC}"
    
    echo -e "Aguardando 5 segundos para aquecimento do Nó e abertura das portas gRPC..."
    sleep 5

    echo -e "\n${GREEN}🚀 Iniciando o Matcher DEX (via sbt) em segundo plano...${NC}"
    cd "$MATCHER_DIR" || exit 1
    sbt "project dex" "run $OUTPUT_DIR/custom-matcher.conf" > "$OUTPUT_DIR/matcher.log" 2>&1 &
    MATCHER_PID=$!
    echo -e "${GREEN}[INFO] Matcher DEX rodando com PID $MATCHER_PID (Logs em matcher.log)${NC}"

    echo -e "\n=================================================================="
    echo -e "${GREEN}🎉 TUDO PRONTO! SUAS REST APIs ESTÃO EXPOSTAS E FUNCIONANDO:${NC}"
    echo -e "=================================================================="
    echo -e "🌐 REST API do Nó:     ${CYAN}http://127.0.0.1:6869${NC} (Header: X-API-Key: $API_KEY)"
    echo -e "🌐 REST API do Matcher: ${CYAN}http://127.0.0.1:6886${NC}"
    echo -e "=================================================================="
    echo -e "Para parar todos os serviços a qualquer momento, execute:"
    echo -e "👉 ${YELLOW}pkill -f com.wavesplatform.Application && pkill -f com.wavesplatform.dex.Matcher${NC}\n"
else
    echo -e "\n${YELLOW}Configuração finalizada! Para rodar manualmente use as instruções do walkthrough.md.${NC}\n"
fi
