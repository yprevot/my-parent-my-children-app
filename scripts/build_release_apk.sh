#!/usr/bin/env bash
set -euo pipefail

# Script oficial de compilación y empaquetado de MySchoolMyParents Online
# Cumple con la regla del proyecto: Los instaladores deben incluir el nombre y versión de la app.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

FULL_VERSION="$(grep '^version:' pubspec.yaml | head -n1 | awk '{print $2}')"
VERSION_NAME="$(echo "$FULL_VERSION" | cut -d'+' -f1)"
VERSION_CODE="$(echo "$FULL_VERSION" | cut -d'+' -f2)"

echo "=========================================================="
echo "Compilando MySchoolMyParents Online"
echo "Versión: v${VERSION_NAME} (Build ${VERSION_CODE})"
echo "=========================================================="

./scripts/flutterw build apk --release

SRC_APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$SRC_APK" ]; then
  echo "Error: No se encontró $SRC_APK tras la compilación."
  exit 1
fi

mkdir -p dist

TARGET_FULL="MySchoolMyParents-Online-v${VERSION_NAME}+${VERSION_CODE}.apk"
TARGET_SIMPLE="MySchoolMyParents-Online-v${VERSION_NAME}.apk"

# Copiar a dist/
cp "$SRC_APK" "dist/${TARGET_FULL}"
cp "$SRC_APK" "dist/${TARGET_SIMPLE}"
cp "$SRC_APK" "dist/MySchoolMyParents-Online-latest.apk"

# Copiar al directorio del servidor HTTP
cp "$SRC_APK" "build/app/outputs/flutter-apk/${TARGET_FULL}"
cp "$SRC_APK" "build/app/outputs/flutter-apk/${TARGET_SIMPLE}"

# Obtener IP local
LOCAL_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo 'localhost')"
DOWNLOAD_URL="http://${LOCAL_IP}:8080/${TARGET_SIMPLE}"

# Generar QR code si curl está disponible
curl -s "https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=${DOWNLOAD_URL}" \
  -o "build/app/outputs/flutter-apk/qr.png" 2>/dev/null || true

# Generar página web index.html
cat > "build/app/outputs/flutter-apk/index.html" <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Descargar MySchoolMyParents Online v${VERSION_NAME}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 24px;
      background: #f8fafc;
      color: #0f172a;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 90vh;
      text-align: center;
    }
    .card {
      background: white;
      padding: 32px 24px;
      border-radius: 24px;
      box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1);
      max-width: 400px;
      width: 100%;
      box-sizing: border-box;
      border: 1px solid #e2e8f0;
    }
    h1 {
      font-size: 20px;
      margin-top: 0;
      margin-bottom: 6px;
      color: #1e3a8a;
    }
    .badge {
      display: inline-block;
      background: #dbeafe;
      color: #1d4ed8;
      padding: 4px 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 18px;
    }
    .qr {
      width: 220px;
      height: 220px;
      border-radius: 12px;
      margin-bottom: 20px;
      border: 1px solid #e2e8f0;
    }
    .btn {
      display: block;
      background: #2563eb;
      color: white;
      text-decoration: none;
      font-weight: 700;
      font-size: 15px;
      padding: 14px 18px;
      border-radius: 14px;
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
      margin-bottom: 10px;
      word-break: break-all;
    }
    .btn:active {
      background: #1d4ed8;
    }
    .filename {
      font-family: monospace;
      font-size: 11px;
      color: #475569;
      background: #f1f5f9;
      padding: 6px 10px;
      border-radius: 8px;
      margin-bottom: 14px;
      word-break: break-all;
    }
    .note {
      font-size: 12px;
      color: #64748b;
      margin-top: 8px;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>MySchoolMyParents Online</h1>
    <div class="badge">Versión ${VERSION_NAME} (Build ${VERSION_CODE})</div>
    <div>
      <img class="qr" src="qr.png" alt="Código QR de Descarga">
    </div>
    <div class="filename">${TARGET_SIMPLE}</div>
    <a class="btn" href="/${TARGET_SIMPLE}">📲 Descargar Instalador (${TARGET_SIMPLE})</a>
    <p class="note">Actualización in-place: Se instala directamente encima de la versión previa conservando todos tus libros y datos.</p>
  </div>
</body>
</html>
EOF

echo ""
echo "Instaladores generados con éxito:"
echo " - dist/${TARGET_FULL}"
echo " - dist/${TARGET_SIMPLE}"
echo " - build/app/outputs/flutter-apk/${TARGET_FULL}"
echo " - build/app/outputs/flutter-apk/${TARGET_SIMPLE}"
echo ""
echo "Enlace de descarga en red local:"
echo " 👉 ${DOWNLOAD_URL}"
