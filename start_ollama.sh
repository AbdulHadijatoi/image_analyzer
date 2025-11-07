#!/bin/bash

# Start Ollama with network access
# This allows your phone to connect to Ollama on your computer

echo "Starting Ollama with network access..."

# Check if Ollama is already running
if pgrep -x "ollama" > /dev/null; then
    echo "Ollama is already running. Stopping it first..."
    killall ollama
    sleep 1
fi

# Start Ollama on all network interfaces
OLLAMA_HOST=0.0.0.0:11434 ollama serve > /tmp/ollama.log 2>&1 &

# Wait a moment for it to start
sleep 2

# Check if it's running
if pgrep -x "ollama" > /dev/null; then
    echo "✅ Ollama is running!"
    echo "📡 Listening on: 0.0.0.0:11434"
    echo "📝 Logs: /tmp/ollama.log"
    echo ""
    echo "To view logs: tail -f /tmp/ollama.log"
    echo "To stop: killall ollama"
else
    echo "❌ Failed to start Ollama"
    echo "Check logs: cat /tmp/ollama.log"
fi

