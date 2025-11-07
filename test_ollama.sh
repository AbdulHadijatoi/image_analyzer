#!/bin/bash

# Test script to verify Ollama is accessible from network
# This simulates what your phone will do

IP="192.168.100.6"
PORT="11434"

echo "Testing Ollama connection at http://$IP:$PORT"
echo ""

echo "1. Testing /api/tags endpoint..."
curl -s -m 5 "http://$IP:$PORT/api/tags" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    if models:
        print('✅ Connection successful!')
        print(f'   Found {len(models)} model(s):')
        for m in models:
            print(f'   - {m[\"name\"]}')
    else:
        print('⚠️  Connected but no models found')
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "2. Testing text generation..."
curl -s -m 10 -X POST "http://$IP:$PORT/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:latest", "prompt": "Say hello in one word", "stream": false}' | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    response = data.get('response', '')
    if response:
        print('✅ Text generation works!')
        print(f'   Response: {response[:50]}...')
    else:
        print('❌ No response from model')
except Exception as e:
    print(f'❌ Error: {e}')
"

echo ""
echo "Note: Opening this in a browser will NOT work - Ollama is an API, not a website!"
echo "The app uses these API endpoints programmatically."

