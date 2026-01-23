#!/bin/bash

# Setup environment
mkdir -p build-wasm/bin
echo "This is a secret" > secret.txt
echo "Hello World" > build-wasm/bin/test.txt

# Start server in background
echo "Starting server..."
node scripts/serve-static.js > server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 2

# Test 1: Path Traversal (Should FAIL)
echo "Test 1: Attempting path traversal (expecting 403/404)..."
curl -v --path-as-is "http://localhost:8080/../../secret.txt" > output_traversal.txt 2>&1

if grep -q "This is a secret" output_traversal.txt; then
  echo "❌ FAIL: Path traversal succeeded (Vulnerability exists)."
else
  echo "✅ PASS: Path traversal blocked."
fi

# Test 2: Legitimate Access (Should SUCCEED)
echo "Test 2: Attempting legitimate access (expecting 200)..."
curl -v "http://localhost:8080/test.txt" > output_legit.txt 2>&1

if grep -q "Hello World" output_legit.txt; then
  echo "✅ PASS: Legitimate access succeeded."
else
  echo "❌ FAIL: Legitimate access failed."
fi

# Cleanup
echo "Cleaning up..."
kill $SERVER_PID
rm -rf build-wasm
rm secret.txt output_traversal.txt output_legit.txt server.log
