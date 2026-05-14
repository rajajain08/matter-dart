#!/usr/bin/env bash
set -euo pipefail

if cd flutter 2>/dev/null; then
  git pull
  cd ..
else
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

flutter/bin/flutter config --enable-web

cd example
../flutter/bin/flutter pub get
../flutter/bin/flutter build web --release --base-href /

cp -r build/web ../build-web
