#!/usr/bin/env bash
# ==============================================================================
# AMZX BLOCKCHAIN & MATCHER DEX NETWORK INITIALIZATION WIZARD (PRO VERSION)
# ==============================================================================
# Fully automated setup script:
# 1. Verification and installation of dependencies (JDK 17, SBT, Git, bc, etc.)
# 2. GitHub repository cloning of Diego Antunes (amzx & matcher_amzx)
# 3. Complete compilation and assembly of both codebases
# 4. Interactive custom network creation (chainId, supply, ports, seeds, etc.)
# 5. Genesis block signing & configuration provisioning
# 6. One-click orchestrator startup scripts
# ==============================================================================

# ANSI Color Codes for beautiful terminal interface
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine script directories
WIZARD_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$WIZARD_DIR/.." && pwd )"

clear
echo -e "${CYAN}${BOLD}"
echo "=============================================================================="
echo "      🚀  AMZX PRIVATE BLOCKCHAIN & MATCHER DEX FULL SETUP WIZARD  🚀"
echo "=============================================================================="
echo -e "${NC}"
echo -e "Developer: Diego Antunes (diegoantunes2301@gmail.com)"
echo -e "WhatsApp: +55 (11) 97428-9097"
echo -e "GitHub: https://github.com/D-H-O-R-A"
echo "=============================================================================="
echo

# ------------------------------------------------------------------------------
# STEP 1: Verification and Installation of Dependencies
# ------------------------------------------------------------------------------
echo -e "${YELLOW}${BOLD}--- 🔍 STEP 1: VERIFYING SYSTEM DEPENDENCIES ---${NC}"

MISSING_DEPS=()

# Check Git
if ! command -v git &> /dev/null; then
  echo -e "❌ ${RED}git${NC} is not installed."
  MISSING_DEPS+=("git")
else
  echo -e "✅ ${GREEN}git${NC} is installed."
fi

# Check bc
if ! command -v bc &> /dev/null; then
  echo -e "❌ ${RED}bc${NC} (calculator utility) is not installed."
  MISSING_DEPS+=("bc")
else
  echo -e "✅ ${GREEN}bc${NC} is installed."
fi

# Check Java 17
JAVA_INSTALLED=false
if command -v java &> /dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | awk -F '.' '{print $1}')
  if [ "$JAVA_VERSION" -ge 17 ] 2>/dev/null; then
    echo -e "✅ ${GREEN}java${NC} is installed (Version: $(java -version 2>&1 | head -n 1))."
    JAVA_INSTALLED=true
  else
    echo -e "❌ ${RED}java${NC} is installed but version is older than 17. Requires Java 17+."
    MISSING_DEPS+=("openjdk-17-jdk")
  fi
else
  echo -e "❌ ${RED}java${NC} (JDK 17) is not installed."
  MISSING_DEPS+=("openjdk-17-jdk")
fi

# Check SBT
if ! command -v sbt &> /dev/null; then
  echo -e "❌ ${RED}sbt${NC} (Scala Build Tool) is not installed."
  MISSING_DEPS+=("sbt")
else
  echo -e "✅ ${GREEN}sbt${NC} is installed."
fi

# Install dependencies if missing
if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
  echo
  echo -e "${YELLOW}${BOLD}Warning: The following dependencies are missing/incomplete: ${MISSING_DEPS[*]}${NC}"
  read -p "Would you like to automatically install missing dependencies via apt? [S/n]: " INSTALL_DEPS
  INSTALL_DEPS=${INSTALL_DEPS:-S}
  
  if [[ "$INSTALL_DEPS" =~ ^[Ss]$ ]]; then
    echo -e "${CYAN}Running system dependency installation... (May require sudo password)${NC}"
    sudo apt-get update
    
    # Install git, bc, openjdk-17-jdk, curl, gnupg if listed
    for dep in "${MISSING_DEPS[@]}"; do
      if [ "$dep" == "git" ] || [ "$dep" == "bc" ] || [ "$dep" == "openjdk-17-jdk" ]; then
        echo -e "${CYAN}Installing $dep...${NC}"
        sudo apt-get install -y "$dep"
      fi
    done
    
    # Special handle for SBT installation on Ubuntu/Debian
    if [[ " ${MISSING_DEPS[*]} " =~ " sbt " ]]; then
      echo -e "${CYAN}Adding SBT Debian repository credentials...${NC}"
      sudo apt-get install -y apt-transport-https curl gnupg
      echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
      echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
      curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sbt-signatures.gpg
      sudo apt-get update
      sudo apt-get install -y sbt
    fi
    
    echo -e "${GREEN}${BOLD}Dependency installation completed!${NC}"
  else
    echo -e "${RED}${BOLD}Dependencies not met. The script might fail to clone or compile.${NC}"
  fi
else
  echo -e "${GREEN}${BOLD}All local dependencies are satisfied!${NC}"
fi

# ------------------------------------------------------------------------------
# STEP 2: Optional GitHub Repository Cloning
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}${BOLD}--- 🛸 STEP 2: SOURCE CODE ORIGINS ---${NC}"
echo -e "You can clone and build Diego's clean, rebranded repositories:"
echo -e "🔗 Blockchain Core: ${BLUE}https://github.com/D-H-O-R-A/amzx.git${NC}"
echo -e "🔗 Matcher DEX:     ${BLUE}https://github.com/D-H-O-R-A/matcher_amzx.git${NC}"
echo

read -p "Do you want to clone clean repositories from Diego's GitHub to a fresh folder? [s/N]: " CLONE_REPOS
COMPILE_PRE=${COMPILE_PRE:-N}
CLONE_REPOS=${CLONE_REPOS:-N}

WAVES_SRC_DIR="$PROJECT_ROOT/waves"
MATCHER_SRC_DIR="$PROJECT_ROOT/matcher"

# Auto-detect workspace folders if they are in the custom amzx-workspace directory (typically on VPS)
if [ ! -d "$WAVES_SRC_DIR" ] && [ -d "$WIZARD_DIR/amzx-workspace/amzx" ]; then
  WAVES_SRC_DIR="$WIZARD_DIR/amzx-workspace/amzx"
fi
if [ ! -d "$MATCHER_SRC_DIR" ] && [ -d "$WIZARD_DIR/amzx-workspace/matcher_amzx" ]; then
  MATCHER_SRC_DIR="$WIZARD_DIR/amzx-workspace/matcher_amzx"
fi

# Se o usuário não estiver rodando no root e estiver na pasta padrão de documentos, ajustamos automaticamente os caminhos se existirem
if [ ! -d "$WAVES_SRC_DIR" ] && [ -d "/home/diegooris/Documentos/amzblockchain/waves" ]; then
  WAVES_SRC_DIR="/home/diegooris/Documentos/amzblockchain/waves"
fi
if [ ! -d "$MATCHER_SRC_DIR" ] && [ -d "/home/diegooris/Documentos/amzblockchain/matcher" ]; then
  MATCHER_SRC_DIR="/home/diegooris/Documentos/amzblockchain/matcher"
fi

if [[ "$CLONE_REPOS" =~ ^[Ss]$ ]]; then
  read -p "Enter path/name for the new workspace folder [default: ./amzx-workspace]: " WORKSPACE_PATH
  WORKSPACE_PATH=${WORKSPACE_PATH:-./amzx-workspace}
  
  # Resolve to absolute path
  mkdir -p "$WORKSPACE_PATH"
  ABS_WORKSPACE="$(cd "$WORKSPACE_PATH" && pwd)"
  
  echo -e "${CYAN}Clonando repositórios no workspace: $ABS_WORKSPACE...${NC}"
  
  cd "$ABS_WORKSPACE"
  if [ ! -d "amzx" ]; then
    git clone https://github.com/D-H-O-R-A/amzx.git
  else
    echo -e "Directory ${GREEN}amzx${NC} already exists, skipping clone."
  fi
  
  if [ ! -d "matcher_amzx" ]; then
    git clone https://github.com/D-H-O-R-A/matcher_amzx.git
  else
    echo -e "Directory ${GREEN}matcher_amzx${NC} already exists, skipping clone."
  fi
  
  WAVES_SRC_DIR="$ABS_WORKSPACE/amzx"
  MATCHER_SRC_DIR="$ABS_WORKSPACE/matcher_amzx"
  
  # ------------------------------------------------------------------------------
  # STEP 3: Complete Compilation from Cloned Repositories
  # ------------------------------------------------------------------------------
  echo
  echo -e "${YELLOW}${BOLD}--- 🛠️ STEP 3: COMPILING SOURCE CODE (SBT ASSEMBLY) ---${NC}"
  echo -e "${YELLOW}Please wait. This can take several minutes to download libraries and compile Scala sources.${NC}"
  echo
  
  # Compile Blockchain
  echo -e "${CYAN}Building AMZX Node fat JAR...${NC}"
  cd "$WAVES_SRC_DIR"
  JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt node/assembly
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}[ERROR] Failed to compile AMZX Node.${NC}"
    exit 1
  fi
  
  # Compile Matcher & DEX Waves Extension
  echo -e "${CYAN}Compiling AMZX Matcher DEX & Waves gRPC Extension...${NC}"
  cd "$MATCHER_SRC_DIR"
  JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt "project dex" compile waves-ext/Universal/stage
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}[ERROR] Failed to compile AMZX Matcher.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}${BOLD}Compilation of cloned sources finished successfully!${NC}"
else
  echo -e "Proceeding with current pre-existing workspace folders: "
  echo -e "Blockchain Core: ${GREEN}$WAVES_SRC_DIR${NC}"
  echo -e "Matcher DEX:     ${GREEN}$MATCHER_SRC_DIR${NC}"
  echo
  
  read -p "Do you want to compile (SBT build) your current pre-existing folders now? [s/N]: " COMPILE_PRE
  COMPILE_PRE=${COMPILE_PRE:-N}
  if [[ "$COMPILE_PRE" =~ ^[Ss]$ ]]; then
    echo
    echo -e "${YELLOW}${BOLD}--- 🛠️ COMPILING SOURCE CODE (SBT ASSEMBLY) ---${NC}"
    
    # Compile Blockchain
    echo -e "${CYAN}Building AMZX Node fat JAR...${NC}"
    cd "$WAVES_SRC_DIR"
    JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt node/assembly
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}[ERROR] Failed to compile AMZX Node.${NC}"
      exit 1
    fi
    
    # Compile Matcher & DEX Waves Extension
    echo -e "${CYAN}Compiling AMZX Matcher DEX & Waves gRPC Extension...${NC}"
    cd "$MATCHER_SRC_DIR"
    JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt "project dex" compile waves-ext/Universal/stage
    if [ $? -ne 0 ]; then
      echo -e "${RED}${BOLD}[ERROR] Failed to compile AMZX Matcher.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}${BOLD}Compilation of pre-existing sources finished successfully!${NC}"
    cd "$WIZARD_DIR"
  fi
fi

# Ensure JVM parameters
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# ------------------------------------------------------------------------------
# STEP 4: Configure custom parameters
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}${BOLD}--- 🪙 STEP 4: CONFIGURE NETWORK PARAMETERS ---${NC}"

read -p "Enter Network Character (Chain ID) [default: D]: " CHAIN_ID
CHAIN_ID=${CHAIN_ID:-D}
CHAIN_ID=$(echo "$CHAIN_ID" | tr '[:lower:]' '[:upper:]' | cut -c1)

# Calcular formatos adicionais de Chain ID para compatibilidade com Ethereum/MetaMask
ETH_CHAIN_ID_DEC=$(printf '%d' "'$CHAIN_ID")
ETH_CHAIN_ID_HEX=$(printf '0x%02x' "$ETH_CHAIN_ID_DEC")

echo -e "Configurações geradas para o Chain ID informado:"
echo -e "👉 ${GREEN}Formato Waves (Caractere):${NC}       ${BOLD}$CHAIN_ID${NC}"
echo -e "👉 ${GREEN}Formato Ethereum (MetaMask):${NC}     ${BOLD}$ETH_CHAIN_ID_DEC${NC}"
echo -e "👉 ${GREEN}Formato Byte Ethereum (Hex):${NC}     ${BOLD}$ETH_CHAIN_ID_HEX${NC}"
echo

read -p "Enter Native Coin Name [default: AMZX]: " COIN_NAME
COIN_NAME=${COIN_NAME:-AMZX}

read -p "Enter Total Genesis Supply (Moedas inteiras) [default: 100000000]: " SUPPLY
SUPPLY=${SUPPLY:-100000000}
SUPPLY_SATOSHIS=$(echo "$SUPPLY * 100000000" | bc 2>/dev/null || expr "$SUPPLY" \* 100000000)

read -p "Enter Admin Genesis Seed Phrase [default: amzblockchain test private local network genesis seed wordlist]: " SEED
SEED=${SEED:-amzblockchain test private local network genesis seed wordlist}

echo
echo -e "${YELLOW}${BOLD}--- 🔌 STEP 5: CONFIGURE SERVICE PORTS ---${NC}"
read -p "Node REST API Port [default: 6869]: " REST_API_PORT
REST_API_PORT=${REST_API_PORT:-6869}

read -p "Node P2P Network Port [default: 6868]: " P2P_PORT
P2P_PORT=${P2P_PORT:-6868}

read -p "Node gRPC DEX Port [default: 6887]: " GRPC_PORT
GRPC_PORT=${GRPC_PORT:-6887}

read -p "Node gRPC Blockchain Updates Port [default: 6881]: " BLOCKCHAIN_UPDATES_PORT
BLOCKCHAIN_UPDATES_PORT=${BLOCKCHAIN_UPDATES_PORT:-6881}

read -p "Matcher DEX REST API Port [default: 6886]: " MATCHER_PORT
MATCHER_PORT=${MATCHER_PORT:-6886}

echo
echo -e "${YELLOW}${BOLD}--- 🛡️ STEP 5b: CONFIGURE REST API SECURITY ---${NC}"
echo -e "Você é obrigado a definir uma senha de acesso personalizada e segura para a REST API do Swagger (X-Api-Key)."
echo -e "Esta chave protege o acesso a endpoints altamente sensíveis do nó, como os que expõem a seed (semente) da carteira."
echo -e "${RED}${BOLD}IMPORTANTE:${NC} O uso da senha padrão 'ridethewaves!' é proibido pelo próprio nó para evitar falhas graves de segurança."
echo

while true; do
  read -p "Digite a sua nova Swagger REST API Key (mínimo 10 caracteres): " REST_API_KEY
  if [ -z "$REST_API_KEY" ]; then
    echo -e "${RED}⚠️  Erro: A senha não pode ser vazia.${NC}"
  elif [ "$REST_API_KEY" = "ridethewaves!" ]; then
    echo -e "${RED}⚠️  Erro: A senha padrão 'ridethewaves!' é proibida e bloqueada pelo node. Escolha uma senha personalizada e segura.${NC}"
  elif [ ${#REST_API_KEY} -lt 10 ]; then
    echo -e "${RED}⚠️  Erro: A senha precisa ter pelo menos 10 caracteres para garantir a segurança da rede.${NC}"
  else
    echo -e "${GREEN}✅ Senha de acesso REST API definida com sucesso!${NC}"
    break
  fi
  echo
done

echo
echo -e "${YELLOW}${BOLD}--- 📂 STEP 6: CONFIGURE RUN DATA DIRECTORIES ---${NC}"
read -p "Enter Run Directory name [default: run-amzx-$CHAIN_ID]: " RUN_DIR_NAME
RUN_DIR_NAME=${RUN_DIR_NAME:-run-amzx-$CHAIN_ID}
RUN_DIR="$WIZARD_DIR/$RUN_DIR_NAME"

echo
echo -e "${YELLOW}${BOLD}--- 🌐 STEP 6b: CONFIGURE DOMAIN & SUBDOMAINS ---${NC}"
read -p "Do you want to configure Nginx Reverse Proxy with SSL/Certbot for this network? [y/N]: " CONFIGURE_NGINX
CONFIGURE_NGINX=${CONFIGURE_NGINX:-N}

BASE_DOMAIN=""
CERTBOT_EMAIL=""
if [[ "$CONFIGURE_NGINX" =~ ^[Yy]$ ]]; then
  read -p "Enter base domain (e.g. amzxblockchain.com.br): " BASE_DOMAIN
  while [ -z "$BASE_DOMAIN" ]; do
    read -p "Domain cannot be empty. Enter base domain (e.g. amzxblockchain.com.br): " BASE_DOMAIN
  done
  read -p "Enter contact email for Certbot SSL expiration alerts: " CERTBOT_EMAIL
  while [ -z "$CERTBOT_EMAIL" ]; do
    read -p "Email cannot be empty. Enter contact email for Certbot: " CERTBOT_EMAIL
  done
fi

echo
echo -e "${CYAN}Creating directories under ${BOLD}$RUN_DIR${NC}..."
mkdir -p "$RUN_DIR/node-data"
mkdir -p "$RUN_DIR/matcher-data"
mkdir -p "$RUN_DIR/lib"
touch "$RUN_DIR/node-data/lp-accounts.txt"
touch "$RUN_DIR/matcher-data/lp-accounts.txt"

# Hardening file system permissions to protect sensitive cryptographic materials (Seed, Keys, databases)
chmod 700 "$RUN_DIR"

# Copy DEX extensions/libs if available in current project
if [ -d "$PROJECT_ROOT/custom-network/lib" ]; then
  echo -e "${GREEN}Copying DEX integration libraries...${NC}"
  cp -r "$PROJECT_ROOT/custom-network/lib/"* "$RUN_DIR/lib/"
fi

# Copy compiled waves-ext extension JARs dynamically from matcher project if they exist
echo -e "${CYAN}Checking and copying compiled waves-ext libraries dynamically...${NC}"
if [ -d "$MATCHER_SRC_DIR/waves-ext/target/universal/stage/lib" ]; then
  echo -e "${GREEN}Copying compiled waves-ext libraries to $RUN_DIR/lib/...${NC}"
  cp -r "$MATCHER_SRC_DIR/waves-ext/target/universal/stage/lib/"*.jar "$RUN_DIR/lib/"
  echo -e "✅ ${GREEN}waves-ext libraries successfully copied!${NC}"
else
  # Se por algum motivo o stage/lib não foi criado, mas existe o assembly ou target comum
  echo -e "${YELLOW}waves-ext stage/lib directory not found. Let's try compiling waves-ext directly...${NC}"
  cd "$MATCHER_SRC_DIR"
  JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt waves-ext/Universal/stage
  cd "$WIZARD_DIR"
  if [ -d "$MATCHER_SRC_DIR/waves-ext/target/universal/stage/lib" ]; then
    echo -e "${GREEN}Copying compiled waves-ext libraries after on-demand build...${NC}"
    cp -r "$MATCHER_SRC_DIR/waves-ext/target/universal/stage/lib/"*.jar "$RUN_DIR/lib/"
    echo -e "✅ ${GREEN}waves-ext libraries successfully copied!${NC}"
  else
    echo -e "${RED}${BOLD}[WARNING] waves-ext compiled libraries could not be found! The node might fail with ClassNotFoundException.${NC}"
  fi
fi

# ------------------------------------------------------------------------------
# STEP 7: Generate Cryptographic Genesis settings
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}${BOLD}--- 🔑 STEP 7: GENERATING GENESIS CRYPTOGRAPHY ---${NC}"

# Find the fat JAR file
FAT_JAR="$WAVES_SRC_DIR/node/target/waves-all-1.6.3-DIRTY.jar"
if [ ! -f "$FAT_JAR" ]; then
  # Fallback search if path structure is slightly different (e.g. from git clone)
  FAT_JAR=$(find "$WAVES_SRC_DIR" -name "waves-all*.jar" | head -n 1)
  if [ -z "$FAT_JAR" ] || [ ! -f "$FAT_JAR" ]; then
    echo -e "${RED}${BOLD}[ERROR] AMZX Node Fat JAR não foi encontrado em: $WAVES_SRC_DIR/node/target/${NC}"
    echo -e "${YELLOW}Deseja realizar a compilação (Build) automática das suas pastas de código locais agora? [S/n]${NC}"
    read -p "Sua escolha: " RUN_BUILD_LATE
    RUN_BUILD_LATE=${RUN_BUILD_LATE:-S}
    if [[ "$RUN_BUILD_LATE" =~ ^[Ss]$ ]]; then
      echo -e "${CYAN}Compilando AMZX Node (sbt node/assembly)...${NC}"
      cd "$WAVES_SRC_DIR"
      JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt node/assembly
      if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}[ERROR] Falha ao compilar o AMZX Node.${NC}"
        exit 1
      fi
      
      FAT_JAR=$(find "$WAVES_SRC_DIR" -name "waves-all*.jar" | head -n 1)
      if [ -z "$FAT_JAR" ] || [ ! -f "$FAT_JAR" ]; then
        echo -e "${RED}${BOLD}[ERROR] JAR ainda não foi encontrado mesmo após compilação.${NC}"
        exit 1
      fi
      
      echo -e "${CYAN}Compiling AMZX Matcher DEX & Waves gRPC Extension...${NC}"
      cd "$MATCHER_SRC_DIR"
      JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt "project dex" compile waves-ext/Universal/stage
      if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}[ERROR] Falha ao compilar o Matcher DEX.${NC}"
        exit 1
      fi
      
      cd "$WIZARD_DIR"
      echo -e "${GREEN}${BOLD}Compilações completadas com sucesso! Continuando configuração...${NC}"
    else
      echo -e "Please run compilation or ensure sbt assembly succeeded!"
      exit 1
    fi
  fi
fi

# Create temporary config
GENERATOR_INPUT_CONF="$RUN_DIR/temp-generator.conf"
cat <<EOF > "$GENERATOR_INPUT_CONF"
genesis-generator {
  network-type = "$CHAIN_ID"
  base-target = null
  average-block-delay = 60s
  timestamp = $(date +%s%3N)
  distributions = [
    { seed-text = "$SEED", amount = $SUPPLY_SATOSHIS, miner = true }
  ]
}
EOF

# Run Genesis Generator via compiled classpath
GENERATOR_OUTPUT_RAW="$RUN_DIR/temp-generator-out.txt"
GENERATOR_GENESIS_CONF="$RUN_DIR/temp-genesis-out.conf"

java -cp "$FAT_JAR" com.wavesplatform.GenesisBlockGenerator "$GENERATOR_INPUT_CONF" "$GENERATOR_GENESIS_CONF" > "$GENERATOR_OUTPUT_RAW"

if [ $? -ne 0 ] || [ ! -f "$GENERATOR_GENESIS_CONF" ]; then
  echo -e "${RED}${BOLD}[ERROR] Failed to generate genesis block settings.${NC}"
  exit 1
fi

GENESIS_ADDRESS=$(grep -i "Account address:" "$GENERATOR_OUTPUT_RAW" | awk -F': ' '{print $2}' | tr -d '[:space:]')
SEED_BASE58=$(grep -i "Seed:" "$GENERATOR_OUTPUT_RAW" | head -n 1 | awk -F': ' '{print $2}' | tr -d '[:space:]')
PUBLIC_KEY=$(grep -i "Public account key:" "$GENERATOR_OUTPUT_RAW" | awk -F': ' '{print $2}' | tr -d '[:space:]')
PRIVATE_KEY=$(grep -i "Private account key:" "$GENERATOR_OUTPUT_RAW" | awk -F': ' '{print $2}' | tr -d '[:space:]')

echo -e "${GREEN}${BOLD}Cryptographic materials successfully created!${NC}"
echo -e "--------------------------------------------------------"
echo -e "🔑 ${BOLD}Genesis Seed Base58:${NC} $SEED_BASE58"
echo -e "🔑 ${BOLD}Genesis Public Key:${NC}  $PUBLIC_KEY"
echo -e "🔑 ${BOLD}Genesis Private Key:${NC} $PRIVATE_KEY"
echo -e "🛡️ ${BOLD}Genesis Account Addr:${NC} $GENESIS_ADDRESS"
echo -e "--------------------------------------------------------"

# ------------------------------------------------------------------------------
# STEP 8: Create configuration files
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}${BOLD}--- 📄 STEP 8: PROVISIONING CONFIGURATION FILES ---${NC}"

GENESIS_BLOCK_CONTENT=$(cat "$GENERATOR_GENESIS_CONF")

# Computa o hash seguro (Keccak256(Blake2b256)) em Base58 da X-Api-Key definida pelo usuário
echo -e "${CYAN}Criptografando Swagger REST API Key (X-Api-Key) com Keccak256(Blake2b256)...${NC}"
TEMP_JAVA_DIR=$(mktemp -d -p "$RUN_DIR")
cat <<EOF > "$TEMP_JAVA_DIR/HashGenerator.java"
public class HashGenerator {
    public static void main(String[] args) throws Exception {
        byte[] bytes = args[0].getBytes("UTF-8");
        byte[] hashed = com.wavesplatform.crypto.package$.MODULE$.secureHash(bytes);
        String base58 = com.wavesplatform.common.utils.Base58$.MODULE$.encode(hashed);
        System.out.println(base58);
    }
}
EOF

javac -cp "$FAT_JAR" "$TEMP_JAVA_DIR/HashGenerator.java"
API_KEY_HASH=$(java -cp "$TEMP_JAVA_DIR:$FAT_JAR" HashGenerator "$REST_API_KEY")
rm -rf "$TEMP_JAVA_DIR"

if [ -z "$API_KEY_HASH" ]; then
  echo -e "${RED}${BOLD}[ERROR] Erro ao criptografar REST API Key.${NC}"
  exit 1
fi
echo -e "🔒 REST API Key Hash gerada com sucesso: ${GREEN}$API_KEY_HASH${NC}"

BLOCKCHAIN_CONF_PATH="$RUN_DIR/blockchain.conf"
MATCHER_CONF_PATH="$RUN_DIR/matcher.conf"

# Replace variables in Blockchain Config
sed \
  -e "s|__NODE_DATA_DIR__|$RUN_DIR/node-data|g" \
  -e "s|__CHAIN_ID__|$CHAIN_ID|g" \
  -e "s|__P2P_PORT__|$P2P_PORT|g" \
  -e "s|__NODE_NAME__|amz-node-$CHAIN_ID|g" \
  -e "s|__WALLET_PASSWORD__|amzblockchainpassword123!|g" \
  -e "s|__SEED_BASE58__|$SEED_BASE58|g" \
  -e "s|__REST_API_PORT__|$REST_API_PORT|g" \
  -e "s|__API_KEY_HASH__|$API_KEY_HASH|g" \
  -e "s|__GRPC_PORT__|$GRPC_PORT|g" \
  "$WIZARD_DIR/templates/custom-blockchain.conf.template" > "$BLOCKCHAIN_CONF_PATH"

python3 -c "
with open('$BLOCKCHAIN_CONF_PATH', 'r') as f:
    content = f.read()
with open('$GENERATOR_GENESIS_CONF', 'r') as f:
    genesis = f.read()
content = content.replace('__GENESIS_BLOCK_CONFIG__', genesis)
with open('$BLOCKCHAIN_CONF_PATH', 'w') as f:
    f.write(content)
"

# Replace variables in Matcher Config
sed \
  -e "s|__MATCHER_DATA_DIR__|$RUN_DIR/matcher-data|g" \
  -e "s|__CHAIN_ID__|$CHAIN_ID|g" \
  -e "s|__GRPC_PORT__|$GRPC_PORT|g" \
  -e "s|__BLOCKCHAIN_UPDATES_PORT__|$BLOCKCHAIN_UPDATES_PORT|g" \
  -e "s|__MATCHER_PORT__|$MATCHER_PORT|g" \
  -e "s|__API_KEY_HASH__|$API_KEY_HASH|g" \
  "$WIZARD_DIR/templates/custom-matcher.conf.template" > "$MATCHER_CONF_PATH"

# Secure the generated configuration files so that ONLY the current user can read/write them (chmod 600)
chmod 600 "$BLOCKCHAIN_CONF_PATH" "$MATCHER_CONF_PATH"

echo -e "Created Node Config:    ${GREEN}$BLOCKCHAIN_CONF_PATH${NC}"
echo -e "Created Matcher Config: ${GREEN}$MATCHER_CONF_PATH${NC}"

rm -f "$GENERATOR_INPUT_CONF" "$GENERATOR_OUTPUT_RAW" "$GENERATOR_GENESIS_CONF"

# ------------------------------------------------------------------------------
# STEP 9: Generate orchestration startup scripts
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}${BOLD}--- 🚀 STEP 9: CREATING STARTUP UTILITIES ---${NC}"

# Start Node script
START_NODE_SCRIPT="$RUN_DIR/start-node.sh"
cat <<EOF > "$START_NODE_SCRIPT"
#!/usr/bin/env bash
# Startup script for AMZX Private Node

echo -e "\033[1;32mStarting AMZX Node with Chain ID '$CHAIN_ID' and REST API Port '$REST_API_PORT'...\033[0m"

export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
export PATH=\$JAVA_HOME/bin:\$PATH

java \\
  --add-opens=java.base/sun.nio.ch=ALL-UNNAMED \\
  --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED \\
  -cp "$FAT_JAR:$RUN_DIR/lib/*" \\
  com.wavesplatform.Application "$BLOCKCHAIN_CONF_PATH"
EOF
chmod 700 "$START_NODE_SCRIPT"

# Start Matcher script
START_MATCHER_SCRIPT="$RUN_DIR/start-matcher.sh"
cat <<EOF > "$START_MATCHER_SCRIPT"
#!/usr/bin/env bash
# Startup script for Matcher DEX

echo -e "\033[1;32mStarting AMZX Matcher DEX on REST Port '$MATCHER_PORT'...\033[0m"

export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64
export PATH=\$JAVA_HOME/bin:\$PATH

cd "$MATCHER_SRC_DIR"
sbt "project dex" "run $MATCHER_CONF_PATH"
EOF
chmod 700 "$START_MATCHER_SCRIPT"

echo -e "Created startup scripts:"
echo -e " - Node launch:    ${CYAN}$START_NODE_SCRIPT${NC}"
echo -e " - Matcher launch: ${CYAN}$START_MATCHER_SCRIPT${NC}"

if [ -n "$BASE_DOMAIN" ]; then
  NGINX_CONF_PATH="$RUN_DIR/nginx-amzx.conf"
  cat <<EOF > "$NGINX_CONF_PATH"
# ==============================================================================
# NGINX REVERSE PROXY CONFIGURATION FOR AMZX PRIVATE NETWORK (Chain ID '$CHAIN_ID')
# ==============================================================================
# Configures HTTP, HTTPS and gRPC proxies for blockchain subdomains.
# ------------------------------------------------------------------------------

# 1. API Restful Blockchain Node Swagger
server {
    listen 80;
    server_name nodes.$BASE_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$REST_API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Max request size (e.g. for uploading packages or large data)
        client_max_body_size 50M;
    }
}

# 2. API Restful Matcher Swagger
server {
    listen 80;
    server_name matcher.$BASE_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$MATCHER_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# 3. RPC Ethereum MetaMask (Proxy directly to Node REST API /eth endpoint)
server {
    listen 80;
    server_name rpc.$BASE_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$REST_API_PORT/eth/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# 4. gRPC Blockchain Node Extension (Matcher Integration)
server {
    listen 80;
    server_name grpc-dex.$BASE_DOMAIN;

    location / {
        grpc_pass grpc://127.0.0.1:$GRPC_PORT;
        grpc_set_header Host \$host;
        grpc_set_header X-Real-IP \$remote_addr;
    }
}

# 5. gRPC Blockchain Updates Stream
server {
    listen 80;
    server_name grpc-updates.$BASE_DOMAIN;

    location / {
        grpc_pass grpc://127.0.0.1:$BLOCKCHAIN_UPDATES_PORT;
        grpc_set_header Host \$host;
        grpc_set_header X-Real-IP \$remote_addr;
    }
}
EOF

  SETUP_SSL_SCRIPT="$RUN_DIR/setup-nginx-ssl.sh"
  cat <<EOF > "$SETUP_SSL_SCRIPT"
#!/usr/bin/env bash
# Automated Nginx & Certbot SSL setup script for AMZX Network
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\${CYAN}\${BOLD}==============================================================================\${NC}"
echo -e "\${CYAN}\${BOLD}         🛡️  AMZX NGINX REVERSE PROXY & CERTBOT SSL AUTO-SETUP  🛡️         \${NC}"
echo -e "\${CYAN}\${BOLD}==============================================================================\${NC}"
echo

# Check for Nginx
if ! command -v nginx &> /dev/null; then
  echo -e "\${YELLOW}Nginx is not installed. Installing Nginx...\${NC}"
  sudo apt-get update && sudo apt-get install -y nginx
fi

# Check for Certbot
if ! command -v certbot &> /dev/null; then
  echo -e "\${YELLOW}Certbot is not installed. Installing Certbot...\${NC}"
  sudo apt-get update && sudo apt-get install -y certbot python3-certbot-nginx
fi

# Copy Nginx configuration
echo -e "\${CYAN}Copying Nginx configuration for '$BASE_DOMAIN'...\${NC}"
sudo cp "$NGINX_CONF_PATH" "/etc/nginx/sites-available/nginx-amzx-$CHAIN_ID.conf"

# Enable configuration via symlink
if [ ! -f "/etc/nginx/sites-enabled/nginx-amzx-$CHAIN_ID.conf" ]; then
  sudo ln -s "/etc/nginx/sites-available/nginx-amzx-$CHAIN_ID.conf" "/etc/nginx/sites-enabled/"
fi

# Test Nginx configuration
echo -e "\${CYAN}Testing Nginx syntax...\${NC}"
if sudo nginx -t; then
  echo -e "\${GREEN}Nginx configuration is valid! Reloading Nginx...\${NC}"
  sudo systemctl reload nginx
else
  echo -e "\${RED}[ERROR] Nginx configuration test failed. Please check the logs.\${NC}"
  exit 1
fi

# Configure Certbot SSL certificates
echo
echo -e "\${YELLOW}\${BOLD}--- 🔑 ACQUIRING SSL CERTIFICATES VIA CERTBOT ---\${NC}"
echo -e "Domains: nodes.$BASE_DOMAIN, matcher.$BASE_DOMAIN, rpc.$BASE_DOMAIN, grpc-dex.$BASE_DOMAIN, grpc-updates.$BASE_DOMAIN"
echo -e "This will request certificates and automatically configure HTTPS redirection on Nginx."
echo

sudo certbot --nginx \\
  -d nodes.$BASE_DOMAIN \\
  -d matcher.$BASE_DOMAIN \\
  -d rpc.$BASE_DOMAIN \\
  -d grpc-dex.$BASE_DOMAIN \\
  -d grpc-updates.$BASE_DOMAIN \\
  --non-interactive \\
  --agree-tos \\
  -m $CERTBOT_EMAIL

if [ \$? -eq 0 ]; then
  echo
  echo -e "\${GREEN}\${BOLD}==============================================================================\${NC}"
  echo -e "\${GREEN}\${BOLD}                🎉 SSL CERTIFICATES OBTAINED SUCCESSFULLY! 🎉                \${NC}"
  echo -e "\${GREEN}\${BOLD}==============================================================================\${NC}"
  echo -e "All endpoints are now encrypted under HTTPS / secure gRPC (WSS/GRPCS):"
  echo -e " - Node Swagger API:   \${CYAN}https://nodes.$BASE_DOMAIN/api-docs/index.html\${NC}"
  echo -e " - Matcher Swagger API: \${CYAN}https://matcher.$BASE_DOMAIN/api-docs/index.html\${NC}"
  echo -e " - MetaMask JSON-RPC:  \${CYAN}https://rpc.$BASE_DOMAIN\${NC}"
  echo -e " - gRPC Control/DEX:   \${CYAN}https://grpc-dex.$BASE_DOMAIN (WSS/GRPCS:443)\${NC}"
  echo -e " - gRPC Updates:       \${CYAN}https://grpc-updates.$BASE_DOMAIN (GRPCS:443)\${NC}"
  echo -e "=============================================================================="
fi
EOF
  chmod 700 "$SETUP_SSL_SCRIPT" && chmod 600 "$NGINX_CONF_PATH"
fi
echo -e "${YELLOW}${BOLD}--- 🚀 STEP 10: AUTOMATED SERVICE LAUNCH & ONLINE VERIFICATION ---${NC}"

# Define port check function
check_port() {
  local port=$1
  if command -v nc &>/dev/null; then
    nc -z 127.0.0.1 "$port" &>/dev/null
  else
    (echo >/dev/tcp/127.0.0.1/"$port") &>/dev/null 2>&1
  fi
}

NODE_ALREADY_RUNNING=false
MATCHER_ALREADY_RUNNING=false

# Check if ports are already bound
if check_port "$REST_API_PORT"; then
  echo -e "⚠️  ${YELLOW}Something is already listening on Node REST API Port ($REST_API_PORT). Node might already be running!${NC}"
  NODE_ALREADY_RUNNING=true
fi

if check_port "$MATCHER_PORT"; then
  echo -e "⚠️  ${YELLOW}Something is already listening on Matcher DEX REST API Port ($MATCHER_PORT). Matcher might already be running!${NC}"
  MATCHER_ALREADY_RUNNING=true
fi

# Automatically run Nginx & SSL setup if domain is configured
if [ -n "$BASE_DOMAIN" ] && [ -f "$SETUP_SSL_SCRIPT" ]; then
  echo
  echo -e "🛡️  ${YELLOW}Executing Nginx Reverse Proxy and Certbot SSL configuration...${NC}"
  sudo "$SETUP_SSL_SCRIPT"
  SSL_STATUS=$?
  if [ $SSL_STATUS -eq 0 ]; then
    echo -e "✅ ${GREEN}Nginx and SSL Certbot setup completed successfully!${NC}"
  else
    echo -e "❌ ${RED}Nginx and SSL Certbot setup encountered an error (Code: $SSL_STATUS).${NC}"
  fi
fi

# Start services if they are not already running
if [ "$NODE_ALREADY_RUNNING" = false ]; then
  echo
  echo -e "📡 ${CYAN}Starting AMZX Private Node in the background...${NC}"
  nohup "$START_NODE_SCRIPT" < /dev/null > "$RUN_DIR/node.log" 2>&1 &
  NODE_PID=$!
  echo -e "👉 Node started with PID ${BOLD}$NODE_PID${NC}. Log file: ${BLUE}$RUN_DIR/node.log${NC}"
fi

if [ "$MATCHER_ALREADY_RUNNING" = false ]; then
  echo -e "📡 ${CYAN}Starting AMZX Matcher DEX in the background...${NC}"
  nohup "$START_MATCHER_SCRIPT" < /dev/null > "$RUN_DIR/matcher.log" 2>&1 &
  MATCHER_PID=$!
  echo -e "👉 Matcher started with PID ${BOLD}$MATCHER_PID${NC}. Log file: ${BLUE}$RUN_DIR/matcher.log${NC}"
fi

# Polling loop for active verification
MAX_WAIT=120
WAIT_INTERVAL=3
ELAPSED=0

NODE_ONLINE=false
MATCHER_ONLINE=false

if [ "$NODE_ALREADY_RUNNING" = true ]; then
  NODE_ONLINE=true
fi
if [ "$MATCHER_ALREADY_RUNNING" = true ]; then
  MATCHER_ONLINE=true
fi

echo
echo -e "${YELLOW}Waiting for services to initialize and bind to their ports...${NC}"
echo -e "This can take up to 2 minutes on the first execution (JVM & SBT boot time).${NC}"
echo

while [ $ELAPSED -lt $MAX_WAIT ]; do
  if [ "$NODE_ONLINE" = false ]; then
    if check_port "$REST_API_PORT"; then
      NODE_ONLINE=true
    fi
  fi
  
  if [ "$MATCHER_ONLINE" = false ]; then
    if check_port "$MATCHER_PORT"; then
      MATCHER_ONLINE=true
    fi
  fi
  
  # Print progress
  echo -n -e "\r⏳ Elapsed: ${ELAPSED}s / ${MAX_WAIT}s | Node: "
  if [ "$NODE_ONLINE" = true ]; then
    echo -n -e "[${GREEN}ONLINE${NC}]"
  else
    echo -n -e "[${RED}OFFLINE${NC}]"
  fi
  echo -n -e " | Matcher: "
  if [ "$MATCHER_ONLINE" = true ]; then
    echo -n -e "[${GREEN}ONLINE${NC}]"
  else
    echo -n -e "[${RED}OFFLINE${NC}]"
  fi
  
  if [ "$NODE_ONLINE" = true ] && [ "$MATCHER_ONLINE" = true ]; then
    echo -e "\n\n🎉 ${GREEN}${BOLD}SUCCESS! Both blockchain services are now successfully ONLINE and verified!${NC}"
    break
  fi
  
  sleep $WAIT_INTERVAL
  ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

if [ "$NODE_ONLINE" = false ] || [ "$MATCHER_ONLINE" = false ]; then
  echo -e "\n"
  echo -e "⚠️  ${RED}${BOLD}[TIMEOUT] One or more services failed to start within $MAX_WAIT seconds.${NC}"
  if [ "$NODE_ONLINE" = false ]; then
    echo -e "❌ Node on port $REST_API_PORT is ${RED}OFFLINE${NC}."
    echo -e "   Check details in log: ${CYAN}cat $RUN_DIR/node.log${NC}"
  fi
  if [ "$MATCHER_ONLINE" = false ]; then
    echo -e "❌ Matcher on port $MATCHER_PORT is ${RED}OFFLINE${NC}."
    echo -e "   Check details in log: ${CYAN}cat $RUN_DIR/matcher.log${NC}"
  fi
  echo
fi

echo
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo -e "${GREEN}${BOLD}                        🎉 COMPLETE SETUP SUCCESSFUL! 🎉                        ${NC}"
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo
echo -e "The blockchain and Matcher DEX network ecosystem is now configured and running."
echo
echo -e " ${BOLD}Control Scripts (for future manual restarts):${NC}"
echo -e "  - Node launch script:    ${CYAN}$START_NODE_SCRIPT${NC}"
echo -e "  - Matcher launch script: ${CYAN}$START_MATCHER_SCRIPT${NC}"
if [ -n "$BASE_DOMAIN" ]; then
  echo -e "  - SSL/Nginx Setup script: ${YELLOW}$SETUP_SSL_SCRIPT${NC}"
fi
echo
echo -e " ${BOLD}Live Logs:${NC}"
echo -e "  - Node log stream:       ${BLUE}tail -f $RUN_DIR/node.log${NC}"
echo -e "  - Matcher log stream:    ${BLUE}tail -f $RUN_DIR/matcher.log${NC}"
echo
echo -e " ${BOLD}Useful Addresses & Resources:${NC}"
if [ -n "$BASE_DOMAIN" ]; then
  echo -e "  - Node API Swagger Docs (HTTPS): ${BLUE}https://nodes.$BASE_DOMAIN/api-docs/index.html${NC}"
  echo -e "  - Matcher API Swagger (HTTPS):  ${BLUE}https://matcher.$BASE_DOMAIN/api-docs/index.html${NC}"
  echo -e "  - MetaMask JSON-RPC (HTTPS):    ${BLUE}https://rpc.$BASE_DOMAIN${NC}"
  echo -e "  - Node API Swagger Docs (HTTP):  ${BLUE}http://localhost:$REST_API_PORT/api-docs/index.html${NC}"
  echo -e "  - Matcher API Swagger (HTTP):   ${BLUE}http://localhost:$MATCHER_PORT/api-docs/index.html${NC}"
else
  echo -e "  - Node API Swagger Documentation: ${BLUE}http://localhost:$REST_API_PORT/api-docs/index.html${NC}"
  echo -e "  - Matcher DEX API Swagger Docs:  ${BLUE}http://localhost:$MATCHER_PORT/api-docs/index.html${NC}"
fi
echo -e "  - Initial Miner Balance Account: ${MAGENTA}$GENESIS_ADDRESS${NC}"
echo -e "  - Native Coin Asset Name:        ${YELLOW}$COIN_NAME${NC}"
echo -e "  - REST API Password Key (X-Api-Key): ${BOLD}$REST_API_KEY${NC}"
echo
echo -e "${GREEN}Have fun testing your decentralized AMZX Blockchain & Orderbook DEX!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
cd "$WIZARD_DIR"
