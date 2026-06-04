<h1 align="center">📈 AMZX Matcher DEX</h1>

<p align="center">
  <a href="https://github.com/D-H-O-R-A/matcher_amzx" target="_blank">
    <img alt="GitHub Repo" src="https://img.shields.io/badge/GitHub-matcher__amzx-blue?logo=github" />
  </a>
  <a href="mailto:diegoantunes2301@gmail.com">
    <img alt="Email Contact" src="https://img.shields.io/badge/Email-diegoantunes2301%40gmail.com-red?logo=gmail" />
  </a>
  <a href="https://wa.me/5511974289097" target="_blank">
    <img alt="WhatsApp Contact" src="https://img.shields.io/badge/WhatsApp-%2B55%2011%2097428--9097-green?logo=whatsapp" />
  </a>
</p>

> The AMZX Matcher DEX is a high-performance, real-time limit order book matching engine designed to integrate with the [AMZX Node](https://github.com/D-H-O-R-A/amzx) core blockchain.

---

## ✨ Features of AMZX Matcher DEX

- **Sub-millisecond Order Matching**: Ultra-low latency limit order processing.
- **gRPC Node Integration**: Connects to the AMZX Node gRPC extension for balance checking and transaction serialization.
- **REST API & Swagger UI**: Fully documented HTTP endpoints to place, cancel, query, and stream orders.
- **In-Memory and LevelDB Queues**: Secure, high-performance orderbook states, with option for LevelDB or Apache Kafka event pipelines.
- **Cryptographic Signature Verification**: Built-in support for Curve25519-signed order verification.

---

## 🚀 Getting Started

Here is how to get the AMZX Matcher compiled and connected to your running AMZX node.

### Prerequisites
- **Java 17 (OpenJDK 17)**
- **SBT (Scala Build Tool)**
- **A running AMZX Node** with the DEX gRPC Extension active.

### 1. Clone the Repository
```bash
git clone https://github.com/D-H-O-R-A/matcher_amzx.git
cd matcher_amzx
```

### 2. Compile and Test
```bash
# Compile everything
sbt "project dex" compile

# Run the unit tests
sbt "project waves-integration" test
```

### 3. Run the Matcher DEX Server
Launch the matcher DEX pointing to your network configuration file (e.g. `matcher.conf`):
```bash
sbt "project dex" "run /path/to/matcher.conf"
```

---

## 🔧 Interactive Network Wizard

To generate custom AMZX network configs (such as custom chainId, supply, and ports) and run both node and matcher step-by-step, use the companion setup tool:

```bash
cd amz-network-wizard
./init-network.sh
```

---

## 👨‍💻 Developer & Support Contacts

For inquiries, support, integration consulting, or commercial collaborations, reach out to the project developer:

- **Developer:** Diego Antunes
- **Email:** [diegoantunes2301@gmail.com](mailto:diegoantunes2301@gmail.com)
- **WhatsApp:** [+55 (11) 97428-9097](https://wa.me/5511974289097)
- **GitHub Repository:** [https://github.com/D-H-O-R-A/matcher_amzx](https://github.com/D-H-O-R-A/matcher_amzx)
- **Blockchain Core Repo:** [https://github.com/D-H-O-R-A/amzx](https://github.com/D-H-O-R-A/amzx)

---

## 📝 License

This project is licensed under the [MIT License](./LICENSE).
