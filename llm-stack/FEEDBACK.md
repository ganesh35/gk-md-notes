# Feedback – 2025‑11‑09

Ramana Bhamidipati compared the Docker-based Ollama setup with a bare-metal llama.cpp workflow (Mistral/Qwen) and shared the following:

- **llama.cpp (Mistral 7B Q4)**: ~35‑45 tokens/sec, ~6 GB RAM, <2 s startup when launched via `llama-server -hf bartowski/Mistral-7B-Instruct-v0.3-GGUF --port 8080 --n-gpu-layers 999 --ctx-size 4096`.
- **llama.cpp (Qwen 2.5 Coder 14B)**: launched with `llama-server -hf bartowski/Qwen2.5-Coder-14B-Instruct-GGUF --port 8080 --n-gpu-layers 999 --ctx-size 8192`; similar responsiveness to the Mistral run.
- **Ollama (same Mistral model in Docker)**: ~30‑40 tokens/sec (≈10‑15 % slower, attributed to container overhead), ~6.5 GB RAM (≈+0.5 GB), startup in ~5‑10 s due to Docker services.

Key takeaway: the containerized workflow is slightly slower and heavier, but is still preferred for polished distribution—model management, conversation persistence, UI features, easier OS coverage (Linux/Windows), and automatic updates outweigh the performance penalty for end users who want the simplest install path.
