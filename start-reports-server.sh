#!/bin/bash
# Codester-inc Reports Server — starts Python HTTP server + ngrok tunnel
# Run on boot or manually

REPORTS_DIR="/home/kali/.openclaw/workspace/projects/codester-inc"
PORT=8765

# Start Python HTTP server
cd "$REPORTS_DIR"
python3 -m http.server $PORT --bind 0.0.0.0 &
SERVER_PID=$!
echo "Python server started on port $PORT (PID: $SERVER_PID)"

# Wait for server to be ready
sleep 2

# Start ngrok
ngrok start --all --log stdout &
NGROK_PID=$!
echo "ngrok started (PID: $NGROK_PID)"

echo ""
echo "Reports server is live at: https://joseph-nonhydrated-cecille.ngrok-free.app"
echo "Local: http://localhost:$PORT"