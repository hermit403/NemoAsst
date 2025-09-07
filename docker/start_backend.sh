#!/usr/bin/env bash
set -euo pipefail

# Environment
: "${CONFIG_FILE:=configs/hackathon_config.yml}"
: "${HOST_BIND:=0.0.0.0}"
: "${PORT:=8001}"
: "${SANDBOX_PORT:=6000}"
: "${SANDBOX_HOST:=0.0.0.0}"
: "${MCP_LOG_LEVEL:=info}"

echo "[backend] Using config: ${CONFIG_FILE}"

# Activate venv if exists
# Prefer project venv, else global (uv venv was created at /workspace/.venv in Dockerfile.backend)
if [ -f "/workspace/.venv/bin/activate" ]; then
  . /workspace/.venv/bin/activate || true
fi

# Install backend python deps (idempotent)
echo "[backend] Installing Python deps (editable NeMo-Agent-Toolkit, MCP libs, docker SDK)..."
python -m pip install -U pip uv || true
uv pip install -e /workspace/NeMo-Agent-Toolkit
uv pip install mcp docker

# Build Filesystem MCP server (Node)
echo "[backend] Building filesystem-mcp-server..."
pushd /workspace/mcps/filesystem-mcp-server >/dev/null
npm ci
npm run build
popd >/dev/null

echo "[backend] Starting Code Execution Sandbox on ${SANDBOX_HOST}:${SANDBOX_PORT}..."
python /workspace/NeMo-Agent-Toolkit/src/nat/tool/code_execution/local_sandbox/local_sandbox_server.py \
  --host "${SANDBOX_HOST}" --port "${SANDBOX_PORT}" &

SANDBOX_PID=$!
trap 'echo "[backend] Stopping..."; kill ${SANDBOX_PID} 2>/dev/null || true' TERM INT EXIT

echo "[backend] Starting NAT API on ${HOST_BIND}:${PORT}..."
export MCP_LOG_LEVEL
cd /workspace/NeMo-Agent-Toolkit
nat serve --config_file "/workspace/${CONFIG_FILE}" --host "${HOST_BIND}" --port "${PORT}"
