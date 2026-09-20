import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ocrChannel: FlutterMethodChannel?

  override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ImagesToBookOcr") else { return }
    ocrChannel = FlutterMethodChannel(name: "images_to_book/ocr", binaryMessenger: registrar.messenger())
    ocrChannel?.setMethodCallHandler { call, result in
      if call.method == "openTtsSettings" {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
          UIApplication.shared.open(settingsUrl, options: [:]) { _ in
            result(true)
          }
        } else {
          result(false)
        }
        return
      }
      guard call.method == "recognize" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_path", message: "Falta la imagen.", details: nil)); return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          var directory = URL(fileURLWithPath: path).deletingLastPathComponent()
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          try directory.setResourceValues(values)
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.recognitionLanguages = ["en-US", "es-ES"]
          request.usesLanguageCorrection = false
          // El handler de URL respeta la orientación EXIF de la foto.
          let handler = VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:])
          try handler.perform([request])
          let observations = (request.results ?? []).sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) < 0.01 {
              return $0.boundingBox.minX < $1.boundingBox.minX
            }
            return $0.boundingBox.midY > $1.boundingBox.midY
          }
          let lines: [[String: Any]] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return ["text": candidate.string, "confidence": candidate.confidence,
              "left": box.minX, "top": 1 - box.maxY, "width": box.width, "height": box.height]
          }
          // Agrupación acotada a una columna para la prueba A00. Texto bruto intacto.
          var paragraphs: [String] = []
          var previous: VNRecognizedTextObservation?
          for observation in observations {
            guard let text = observation.topCandidates(1).first?.string else { continue }
            if let prev = previous, let last = paragraphs.last,
              prev.boundingBox.minY - observation.boundingBox.maxY < max(prev.boundingBox.height, observation.boundingBox.height) * 1.2,
              abs(prev.boundingBox.minX - observation.boundingBox.minX) < 0.08 {
              paragraphs[paragraphs.count - 1] = last + "\n" + text
            } else { paragraphs.append(text) }
            previous = observation
          }
          let payload: [String: Any] = ["rawText": lines.compactMap { $0["text"] as? String }.joined(separator: "\n"),
            "paragraphs": paragraphs, "lines": lines, "engine": "apple-vision"]
          DispatchQueue.main.async { result(payload) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr_failed", message: "No se pudo leer esta imagen.", details: nil))
          }
        }
      }
    }
  }
}
