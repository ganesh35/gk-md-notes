# Local LLM Server with Web UI

This folder contains a zero-code setup for running a local LLM API (Ollama) plus a browser interface (Open WebUI). Everything is orchestrated through `docker-compose.yml`, which works with either Docker Compose or Podman Compose.

## Prerequisites
- 16 GB+ RAM machine with virtualization enabled (Apple Silicon/modern laptops already satisfy this).
- Container runtime:
  - **Docker path:** Docker Desktop ≥4.24 or Docker Engine ≥24.
  - **Podman path:** Podman ≥4.4 with an initialized podman machine (`podman machine init && podman machine start` if you have not done this before).
- Optional: NVIDIA GPU + drivers if you want CUDA acceleration (see customization tips).

## Podman-specific setup (one time)
If `podman compose version` fails because the CLI plugin is missing, install the lightweight wrapper:

```bash
python3 -m pip install --user podman-compose
export PATH="$HOME/Library/Python/3.9/bin:$PATH"   # or add it to your shell profile
```

Verify your environment before proceeding:

```bash
podman --version
podman machine list          # should show the default VM running
podman system connection list
podman-compose version       # replace with the absolute path if not on PATH
```

## Step-by-step runbook
1. **Clone and enter the project**
   ```bash
   git clone <this-repo>
   cd gk-md-notes
   ```

   > macOS helper: from the repo root you can run `./run-ollama-on-mac.sh` for a guided install. It performs the same pre-flight checks (RAM, Apple Silicon detection, Podman readiness), ensures Metal acceleration is enabled, and then launches the stack for you. Linux/Windows users can follow the manual `docker compose` steps below.

2. **Start the services**
   ```bash
   docker compose up -d
   # Podman equivalent (if installed via pip as shown above):
   # /Users/ganesh/Library/Python/3.9/bin/podman-compose up -d
   ```
   The command will download two images: `ollama/ollama:latest` and `ghcr.io/open-webui/open-webui:main`.
3. **Confirm both containers are running**
   ```bash
   docker compose ps
   ```
   You should see `ollama` (exposing port `11434`) and `open-webui` (port `3000`).
4. **Open the web interface** at `http://localhost:3000` and create the initial Open WebUI admin user.
5. **Download models inside the Ollama container**
   ```bash
   docker compose exec ollama ollama pull phi3:mini
   docker compose exec ollama ollama pull llama3.1:8b
   ```
   > Note: the legacy tag `llama3:8b-instruct` has been removed from Ollama’s registry and now fails with `pull model manifest: file does not exist`, so stick to the active `phi3:*` or `llama3.1:*` tags.
6. **List available models**
   ```bash
   docker compose exec ollama ollama list
   ```
   Expected output after the pulls above:
   ```
   NAME           ID              SIZE
   llama3.1:8b    46e0c10c039e    4.9 GB
   phi3:mini      4f2222927938    2.2 GB
   ```
7. **(Optional) Install curl for debugging inside the Ollama container**
   ```bash
   docker compose exec ollama bash -lc "apt-get update && apt-get install -y curl"
   docker compose exec ollama curl -I https://ollama.com
   ```
8. **Test the REST API directly**
   ```bash
   curl -s http://127.0.0.1:11434/api/pull -d '{"name":"phi3:mini"}'
   curl -s http://127.0.0.1:11434/api/generate -d '{"model":"phi3:mini","prompt":"Hello!"}'
   ```
9. **Use the model from Open WebUI** by selecting it in the settings sidebar and starting a chat.

## Managing the stack
- `docker compose logs -f ollama` (or `open-webui`) to watch logs.
- `docker compose exec ollama ollama rm <model>` to delete models.
- `docker compose down` to stop services (add `-v` to wipe cached data and downloaded models).
- `docker compose pull && docker compose up -d` to update to the latest images.

## Data persistence
Two named volumes keep your state across restarts:
- `ollama` → `/root/.ollama` (model blobs + metadata).
- `open-webui` → `/app/backend/data` (users, settings, chat history).
Deleting them requires `docker compose down -v` (or the equivalent Podman command), which wipes all downloads and chats.

## Customization tips
- Swap in any Ollama model tag (`phi3.5`, `llama3.2`, `codellama`, etc.) in the pull command.
- Force GPU acceleration manually (e.g., Linux/NVIDIA) by prefixing `OLLAMA_USE_GPU=1` when you start the stack: `OLLAMA_USE_GPU=1 docker compose up -d` (or `podman compose up -d`). Apple Silicon users get Metal acceleration automatically when running `run-ollama-on-mac.sh` (which now provisions Podman for you).
- To expose Open WebUI on another host/port, adjust the `ports` mapping and secure it with HTTPS or a reverse proxy.
- NVIDIA GPU acceleration (Linux): install `nvidia-container-toolkit` and add the following under the `ollama` service in `docker-compose.yml`:
  ```yaml
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            capabilities: [gpu]
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
  ```
- AMD/Intel GPU instructions follow the same pattern—consult the Ollama docs for the right environment variables.

## Troubleshooting
- **500: model requires more system memory (Apple Silicon/Podman)** – Podman’s default VM often allocates only 8 GB, which is not enough for GPU-backed loads (e.g., `phi3:mini`). Increase the Podman machine memory, then restart the stack:
  ```bash
  podman machine stop
  podman machine set --memory 16   # bump to 16 GB or higher if you have headroom
  podman machine start
  ./manage-stack.sh start          # or rerun run-ollama-on-mac.sh
  ```
  If you still run out of memory, either raise the number further or force CPU inference with `OLLAMA_USE_GPU=0`.

## Cleanup / Uninstall
Follow the sequence below if you need to remove everything (containers, images, volumes, and helper tools):

1. **Stop the running stack**
   ```bash
   docker compose down
   ```
2. **Remove persistent volumes and cached data**
   ```bash
   docker compose down -v        # deletes the ollama + open-webui volumes
   ```
3. **Delete the pulled images (optional but frees disk space)**
   ```bash
   docker rmi ollama/ollama:latest ghcr.io/open-webui/open-webui:main
   ```
4. **Podman equivalents**
   ```bash
   podman-compose down -v
   podman rmi ollama/ollama:latest ghcr.io/open-webui/open-webui:main
   podman volume rm ollama open-webui   # if volumes were created as named volumes
   ```
5. **Remove the Podman machine (only if you no longer use Podman for anything else)**
   ```bash
   podman machine stop podman-machine-default
   podman machine rm podman-machine-default
   ```
6. **Uninstall the Podman Compose helper (if you installed it via pip)**
   ```bash
   python3 -m pip uninstall podman-compose
   ```
7. **Delete this project folder** once you no longer need the compose files.

After these steps there will be no running containers, no cached GGUF models, and no residual CLI helpers from this setup.

With these steps, anyone can reproducibly launch the local LLM backend (`http://localhost:11434`) and the Open WebUI frontend (`http://localhost:3000`) using either Docker or Podman. Share this README alongside the compose file so teammates can replicate the setup verbatim.
