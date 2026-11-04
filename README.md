# DeepSeek Harness + Local LLM Suite 🚀

> **1-Click Full Automation Suite for DeepSeek Harness + Local LLMs (Ollama GGUF + TabbyAPI EXL2 64K), Zero-Overhead Lifecycle, MCPs, and Gemi AI Steering.**

---

## ⚡ Overview

This repository provides an automated, reproducible setup to turn **DeepSeek Harness** into a private, local AI engineering powerhouse backed by high-speed local inference engines:

1. **TabbyAPI (ExLlamaV2 Engine):**
   - `Qwen2.5-Coder-7B-Instruct-exl2-4_25` (Turboderp 4.25bpw, 64K YaRN, 120+ TPS).
   - `Qwen2.5-7B-Instruct-1M-exl2-4_25` (Bartowski 4.25bpw, 64K YaRN, 1M base architecture).
   - `Mistral-Nemo-Instruct-2407-exl2-4_25` (Bartowski 4.25bpw, 12B parameter, 64K YaRN).
   - `Qwen2.5-14B-Instruct-1M-exl2-4_25` (Bartowski 4.25bpw, 14B parameter, 48K YaRN).
   - **Q8 KV-Cache Invariant:** Zero Indonesian vocabulary corruption, perfectly stable grammar.
2. **Antigravity-Style MCP Lazy-Loading Engine:**
   - DeepSeek Harness out-of-the-box inlines full JSON schemas for every registered MCP tool into the LLM prompt. Connecting heavy suites (like REA, Bitbucket, Confluence, Jira) quickly consumes **30,000–80,000+ tokens per step**, crashing context windows.
   - Our **MCP Lazy-Loading Engine** (`scripts/patch_dsh_mcp_lazy_loading.py`) transforms tool registration into dynamic meta proxies (`mcp__<server>__call` and `describe_tool`), compressing prompt tokens by **>95%** (down to ~1,500 tokens)!
   - Upstream feature branch: [geadalfa/deepseek-harness:feature/mcp-lazy-loading](https://github.com/geadalfa/deepseek-harness/tree/feature/mcp-lazy-loading).
   - Upstream RFC & Discussion: [deepseek-ai/deepseek-harness#12196](https://github.com/deepseek-ai/deepseek-harness/discussions/12196).
3. **Ollama (GGUF Suite):**
   - `deepseek-r1:7b` (Distill reasoning model for deep chain-of-thought analysis).
   - `qwen2.5-coder:7b` (Versatile multi-language coding agent).
   - `qwen3.8:27b-ista-das` (ISTA-DASLab GSQ-RCO IQ3_XXS 27B model).
4. **Zero-Overhead Daemon Lifecycle:**
   - Background servers (Ollama + TabbyAPI) **ONLY spin up when DeepSeek Harness is opened**.
   - Upon closing DeepSeek Harness, all daemon processes are **instantly terminated**, reclaiming 100% of your RAM and VRAM for gaming and high-performance workflows.
   - **0 MB boot overhead**: Windows startup registry remains clean.
4. **Curated MCP Server Ecosystem:**
   - **DuckDuckGo Search MCP** (`duckduckgo-mcp`): Real-time internet search and web retrieval.
   - **GitHub MCP** (`@modelcontextprotocol/server-github`): Code search, pull requests, issues.
   - **Financial Engine MCP**: Deterministic financial math (waterfall cashflow, debt payoff, compound interest).
5. **Gemi AI Steering & Engineering Protocols:**
   - Disciplined AI Software Engineering (Anti-Vibe-Coding protocol, 5 Quality Gates).
   - Ergonomic zero-nausea gaming profile (FOV 90-105°, Motion Blur 0%, Camera Shake 0%, Frame Pacing).
   - Microsoft LLMLingua-2 prompt compressor for 50%–80% context token reduction.

---

## 🖥️ System Architecture

```
                    ┌────────────────────────────────────────┐
                    │      DeepSeek Harness Desktop GUI       │
                    └───────────────────┬────────────────────┘
                                        │
                         cordis.patch.yml + AGENTS.md
                                        │
           ┌────────────────────────────┴───────────────────────────┐
           │                                                        │
           ▼                                                        ▼
┌──────────────────────┐                                 ┌──────────────────────┐
│  TabbyAPI (Port 5000)│                                 │ Ollama (Port 11434)  │
│  ExLlamaV2 Backend   │                                 │ GGUF Inference Engine│
├──────────────────────┤                                 ├──────────────────────┤
│ Qwen 2.5 Coder 7B    │                                 │ • deepseek-r1:7b     │
│ EXL2 (4.25bpw)       │                                 │ • qwen2.5-coder:7b   │
│ 64K Q8 Cache 120+ TPS│                                 │ • qwen3.8:27b        │
└──────────┬───────────┘                                 └──────────┬───────────┘
           │                                                        │
           └────────────────────────────┬───────────────────────────┘
                                        │
                  ┌─────────────────────┴─────────────────────┐
                  ▼                                           ▼
       ┌───────────────────────┐                  ┌────────────────────────┐
       │   Active MCP Tools    │                  │  Lifecycle Automation  │
       ├───────────────────────┤                  ├────────────────────────┤
       │ • DuckDuckGo Search   │                  │ • launch_harness.vbs   │
       │ • GitHub API          │                  │ • Auto-boot on open    │
       │ • Financial Engine    │                  │ • Auto-kill on exit    │
       │ • LLMLingua Compressor│                  │ • 0 MB Boot Overhead   │
       └───────────────────────┘                  └────────────────────────┘
```

---

## 📋 Hardware Requirements

| Component | Minimum | Recommended |
| :--- | :--- | :--- |
| **GPU** | NVIDIA GPU with 8GB VRAM | NVIDIA RTX 4070 / 4070 SUPER / 4080 (12GB+ VRAM) |
| **CUDA** | CUDA 12.1+ | CUDA 12.4+ / 12.8 |
| **RAM** | 16 GB | 32 GB DDR4 / DDR5 |
| **Storage** | 30 GB SSD Space | NVMe SSD (Drive C, D, or I) |
| **OS** | Windows 10 / 11 (64-bit) | Windows 11 (64-bit) |

---

## 🚀 1-Click Quick Start

### 1. Clone the Repository
```powershell
git clone https://github.com/geadalfa/deepseek-harness-local-llm-suite.git C:\LocalLLM
cd C:\LocalLLM
```

### 2. Run the Master Installer
Open PowerShell and run:
```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -InstallDir "C:\LocalLLM"
```

*Optional flags:*
- `-GitHubToken "ghp_..."`: Automatically configures the GitHub MCP server with your token.
- `-SkipModelDownload`: Skips pulling models if weights are already present.

### 3. Launch & Enjoy
A desktop shortcut named **`DeepSeek Harness (Local LLM)`** will be created.
- Double-click the shortcut to start DeepSeek Harness.
- Ollama and TabbyAPI will spin up invisibly in the background.
- Select **`Qwen 2.5 Coder 7B EXL2 (Turboderp 64K)`** and chat!
- When you close DeepSeek Harness, all local LLM processes are immediately stopped.

---

## 📂 Repository Layout

```
.
├── README.md                           # Documentation & architecture guide
├── LICENSE                             # MIT License
├── install.ps1                         # 1-Click Master Installer script
├── automation/
│   ├── launch_deepseek_harness.ps1     # Process lifecycle orchestrator
│   └── launch_deepseek_harness.vbs     # Silent background launcher
├── configs/
│   ├── cordis.patch.yml.template       # DeepSeek Harness profile configuration
│   ├── tabbyapi_config.yml.template    # TabbyAPI 64K Q8 configuration template
│   ├── Modelfile.qwen3.8               # Ollama modelfile for Qwen 3.8 27B ISTA-DAS
│   └── AGENTS.md                       # High-density Gemi AI steering rules
├── scripts/
│   ├── download_exl2.py                # Resumable Hugging Face model downloader
│   └── compress_prompt.py              # Microsoft LLMLingua-2 prompt compressor
├── knowledge/                          # Curated engineering & domain knowledge base
│   ├── anti_vibe_coding_engineering_protocol.md
│   ├── disciplined_software_engineering_framework.md
│   ├── windows_desktop_app_engineering.md
│   ├── windows_gaming_optimization_and_comfort.md
│   ├── ui_ux_anti_slop_design_engineering.md
│   ├── financial_market_and_etf_intelligence.md
│   ├── holistic_financial_agent_intelligence.md
│   ├── system_analyst_designer_diagramming.md
│   ├── display_colorimetry_and_monitor_calibration.md
│   └── spec_driven_development_and_token_compression.md
├── tools/                              # Dedicated standalone helper tools & MCP scripts
│   ├── fetch_web.py                    # Direct web/URL scraper & extractor
│   ├── financial_calculator.py         # Deterministic financial math calculator
│   ├── financial_mcp_server.py         # MCP server for financial calculations
│   ├── rtk.py                          # Token-efficient reconnaissance & output filter
│   └── monitor_color_tool.py           # DDC/CI monitor calibration & color integrity
└── skills/                             # Agent skill workflows
    ├── anti-vibe-coding/
    ├── token-efficient-reconnaissance/
    ├── display-color-calibration/
    ├── windows-gaming-optimizer/
    ├── holistic-financial-advisor/
    ├── anti-slop-ui-design/
    ├── verify-before-done/
    ├── plan-first/
    └── systematic-debugging/
```

---

## 🗜️ Microsoft LLMLingua Prompt Compressor

For large documents or multi-file prompts that exceed standard context allowances, use the bundled LLMLingua-2 utility:

```powershell
# Compress a large text file by 50%
python scripts/compress_prompt.py --file path/to/large_code.txt --rate 0.5 --output compressed.txt

# Compress inline text by 60%
python scripts/compress_prompt.py --text "Very long prompt..." --rate 0.4
```

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE).
Feel free to use, modify, and distribute for personal or commercial projects.
