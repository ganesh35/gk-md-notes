#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}


COMPOSE_CMD="podman-compose"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
RECOMMENDED_MODELS=("phi3:mini")

if [[ -n "${COMPOSE_CMD:-}" ]]; then
  # Split custom compose command into an array
  read -r -a COMPOSE_ARR <<<"${COMPOSE_CMD}"
else
  COMPOSE_ARR=(docker compose)
fi

usage() {
  cat <<'EOF'
Usage: manage-stack.sh <start|stop|restart>

Commands:
  start     Launch the Ollama + Open WebUI stack (docker compose up -d)
  stop      Stop all services (docker compose down)
  restart   Stop then start the stack

Environment:
  COMPOSE_CMD  Override the compose command (default: "docker compose")
EOF
}

run_compose() {
  "${COMPOSE_ARR[@]}" -f "${COMPOSE_FILE}" "$@"
}
compose_cmd() {
    "${COMPOSE_CMD[@]}" "$@"
}


success_message(){

  ################################################################################
  # Success Message
  ################################################################################
  for model in "${RECOMMENDED_MODELS[@]}"; do
      print_info "Downloading $model..."
      if compose_cmd exec -T ollama ollama pull "$model"; then
          print_success "$model downloaded successfully"
      else
          print_warning "Failed to download $model (continuing anyway)"
      fi
  done

  ################################################################################
  # Verify Installation
  ################################################################################

  print_header "Verifying Installation"

  print_info "Listing available models..."
  compose_cmd exec -T ollama ollama list
  
  print_header "Installation Complete! 🎉"

  print_info "Next Steps:"
  echo "  1. Open ${GREEN}http://localhost:3000${NC} in your browser"
  echo "  2. Create your admin account"
  echo "  3. Start chatting with your local LLM!"
  echo ""
  print_info "Download more models:"
  echo "  ${COMPOSE_CMD} exec ollama ollama pull <model-name>"
  echo ""
  print_info "Available models: llama3.1, mistral, codellama, phi3, qwen2.5-coder"
  echo ""
  print_warning "Note: Keep Podman Desktop (or your podman machine) running for Ollama to work"
  echo ""

  # Open browser
  print_info "Opening Open WebUI in your browser..."
  sleep 2
  open "http://localhost:3000"

  print_success "Setup complete! Enjoy your local LLM! 🚀"
}
main() {
  if [[ $# -ne 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    start)
      run_compose up -d
      success_message
      ;;
    stop)
      run_compose down
      ;;
    restart)
      run_compose down
      run_compose up -d
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
