# ADR 0001 — OCR nativo por plataforma

Estado: decisión en validación A00. Fecha: 2026-09-11.

La combinación inicial Flutter 3.47.4 + google_mlkit_text_recognition 0.17.1
resolvió GoogleMLKit 9.0.0 en iOS. La compilación produjo un ejecutable de
simulador x86_64 y advirtió que GoogleMLKit, MLImage, MLKitCommon y MLKitVision
no soportaban arm64 para simulador. Los simuladores disponibles son iOS 26.5
y requieren arm64. La prueba de integración no pudo iniciar esa app.

Decisión: conservar Flutter y usar un MethodChannel propio para OCR:

- Android: ML Kit latino empaquetado `com.google.mlkit:text-recognition:16.0.1`.
- iOS: `VNRecognizeTextRequest` de Apple Vision, sin corrección lingüística.

La interfaz Flutter sigue consumiendo texto bruto y propuestas de párrafos. Esta
prueba agrupa líneas de Vision por proximidad vertical para una columna; no afirma
resolver columnas o reconstrucción editorial. La geometría original queda en la
respuesta nativa para definir el contrato definitivo en A01.

Se elimina el puente Flutter de ML Kit, para que sus frameworks iOS no sigan
entrando transitivamente. Las dependencias de voz continúan mediante flutter_tts.
Se usa CocoaPods para esta versión del proyecto por compatibilidad de los plugins;
la configuración es local al pubspec y no cambia la configuración global de Flutter.

La decisión no convierte G0 en verde: sigue requiriendo pruebas reales de OCR,
voz, selección, pausa, modo sin conexión y cámara física.

Fuentes: [Vision](https://developer.apple.com/documentation/vision/vnrecognizetextrequest),
[ML Kit Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).
Evidencia local: `docs/qa/ios-mlkit-build-attempt.log`,
`docs/qa/ios-mlkit-test-attempt.log`.
