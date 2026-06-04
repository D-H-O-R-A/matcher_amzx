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
CLONE_REPOS=${CLONE_REPOS:-N}

WAVES_SRC_DIR="$PROJECT_ROOT/waves"
MATCHER_SRC_DIR="$PROJECT_ROOT/matcher"

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
  
  # Compile Matcher
  echo -e "${CYAN}Compiling AMZX Matcher DEX...${NC}"
  cd "$MATCHER_SRC_DIR"
  JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 sbt "project dex" compile
  if [ $? -ne 0 ]; then
    echo -e "${RED}${BOLD}[ERROR] Failed to compile AMZX Matcher.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}${BOLD}Compilation of cloned sources finished successfully!${NC}"
else
  echo -e "Proceeding with current pre-existing workspace folders."
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
echo -e "${YELLOW}${BOLD}--- 📂 STEP 6: CONFIGURE RUN DATA DIRECTORIES ---${NC}"
read -p "Enter Run Directory name [default: run-amzx-$CHAIN_ID]: " RUN_DIR_NAME
RUN_DIR_NAME=${RUN_DIR_NAME:-run-amzx-$CHAIN_ID}
RUN_DIR="$WIZARD_DIR/$RUN_DIR_NAME"

echo
echo -e "${CYAN}Creating directories under ${BOLD}$RUN_DIR${NC}..."
mkdir -p "$RUN_DIR/node-data"
mkdir -p "$RUN_DIR/matcher-data"
mkdir -p "$RUN_DIR/lib"

# Copy DEX extensions/libs if available in current project
if [ -d "$PROJECT_ROOT/custom-network/lib" ]; then
  echo -e "${GREEN}Copying DEX integration libraries...${NC}"
  cp -r "$PROJECT_ROOT/custom-network/lib/"* "$RUN_DIR/lib/"
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
    echo -e "${RED}${BOLD}[ERROR] AMZX Node Fat JAR not found in: $WAVES_SRC_DIR/node/target/${NC}"
    echo -e "Please run compilation or ensure sbt assembly succeeded!"
    exit 1
  fi
fi

# Create temporary config
GENERATOR_INPUT_CONF="$RUN_DIR/temp-generator.conf"
cat <<EOF > "$GENERATOR_INPUT_CONF"
genesis-generator {
  networkType = "$CHAIN_ID"
  baseTarget = null
  averageBlockDelay = 10s
  timestamp = $(date +%s%3N)
  distributions = [
    { seedText = "$SEED", amount = $SUPPLY_SATOSHIS, miner = true }
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
API_KEY_HASH="7B74gZMpdzQSB45A7KRwKW6mDUYaWhFY8kWh5qiLRRoA" # default "ridethewaves!" Blake2b hash

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

perl -i -pe "s|__GENESIS_BLOCK_CONFIG__|\Q$GENESIS_BLOCK_CONTENT\E|g" "$BLOCKCHAIN_CONF_PATH"

# Replace variables in Matcher Config
sed \
  -e "s|__MATCHER_DATA_DIR__|$RUN_DIR/matcher-data|g" \
  -e "s|__CHAIN_ID__|$CHAIN_ID|g" \
  -e "s|__GRPC_PORT__|$GRPC_PORT|g" \
  -e "s|__BLOCKCHAIN_UPDATES_PORT__|$BLOCKCHAIN_UPDATES_PORT|g" \
  -e "s|__MATCHER_PORT__|$MATCHER_PORT|g" \
  -e "s|__API_KEY_HASH__|$API_KEY_HASH|g" \
  "$WIZARD_DIR/templates/custom-matcher.conf.template" > "$MATCHER_CONF_PATH"

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
chmod +x "$START_NODE_SCRIPT"

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
chmod +x "$START_MATCHER_SCRIPT"

echo -e "Created startup scripts:"
echo -e " - Node launch:    ${CYAN}$START_NODE_SCRIPT${NC}"
echo -e " - Matcher launch: ${CYAN}$START_MATCHER_SCRIPT${NC}"

echo
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo -e "${GREEN}${BOLD}                        🎉 COMPLETE SETUP SUCCESSFUL! 🎉                        ${NC}"
echo -e "${GREEN}${BOLD}==============================================================================${NC}"
echo
echo -e "To launch your new blockchain and Matcher DEX network ecosystem, execute:"
echo
echo -e " ${BOLD}Terminal 1 (Node):${NC}"
echo -e "   $ ${BOLD}$START_NODE_SCRIPT${NC}"
echo
echo -e " ${BOLD}Terminal 2 (Matcher):${NC}"
echo -e "   $ ${BOLD}$START_MATCHER_SCRIPT${NC}"
echo
echo -e " ${BOLD}Useful Addresses & Resources:${NC}"
echo -e "  - Node API Swagger Documentation: ${BLUE}http://localhost:$REST_API_PORT/api-docs/index.html${NC}"
echo -e "  - Matcher DEX API Swagger Docs:  ${BLUE}http://localhost:$MATCHER_PORT/api-docs/index.html${NC}"
echo -e "  - Initial Miner Balance Account: ${MAGENTA}$GENESIS_ADDRESS${NC}"
echo -e "  - Native Coin Asset Name:        ${YELLOW}$COIN_NAME${NC}"
echo -e "  - REST API Password Key:        ${BOLD}ridethewaves!${NC}"
echo
echo -e "${GREEN}Have fun testing your decentralized AMZX Blockchain & Orderbook DEX!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
cd "$WIZARD_DIR"
