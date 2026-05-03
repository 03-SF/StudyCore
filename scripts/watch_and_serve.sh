#!/usr/bin/env bash

echo "=== StudyCore — Watch & Serve ==="

_build() {
  echo ""
  echo ">>> Building Flutter web bundle..."
  rm -rf .dart_tool/flutter_build
  if nix-shell -p flutter --run "flutter build web" 2>&1; then
    echo ">>> Build complete."
  else
    echo ">>> Build FAILED — check errors above."
  fi
}

if [ ! -d "build/web" ]; then
  _build
fi

nix-shell -p python3 --run "python3 -m http.server 5000 --directory build/web" &
SERVER_PID=$!
echo "Serving on http://0.0.0.0:5000 (PID $SERVER_PID)"

trap "kill $SERVER_PID 2>/dev/null; exit" INT TERM EXIT

echo "Watching lib/, web/, pubspec.yaml for changes..."
while true; do
  inotifywait -r -e modify,create,delete,move \
    --include '.*\.(dart|yaml|json|js|html|css)$' \
    lib/ web/ pubspec.yaml 2>/dev/null
  _build
done
