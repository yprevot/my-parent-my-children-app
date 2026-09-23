import Flutter
import UIKit
import Vision
import PDFKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ocrChannel: FlutterMethodChannel?

  override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MySchoolMyParentsOcr") else { return }
    ocrChannel = FlutterMethodChannel(name: "online.myschoolmyparents/ocr", binaryMessenger: registrar.messenger())
    ocrChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
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

      if call.method == "getPdfPageCount" {
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
          result(FlutterError(code: "invalid_path", message: "Falta la ruta del PDF.", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let url = URL(fileURLWithPath: path)
          guard let document = PDFDocument(url: url) else {
            DispatchQueue.main.async {
              result(FlutterError(code: "pdf_error", message: "No se pudo abrir el PDF.", details: nil))
            }
            return
          }
          let count = document.pageCount
          DispatchQueue.main.async { result(count) }
        }
        return
      }

      if call.method == "processPdfPage" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let pageIndex = args["page"] as? Int else {
          result(FlutterError(code: "invalid_args", message: "Faltan argumentos para procesar la página del PDF.", details: nil))
          return
        }
        let targetPath = args["targetPath"] as? String

        DispatchQueue.global(qos: .userInitiated).async {
          let url = URL(fileURLWithPath: path)
          guard let document = PDFDocument(url: url),
                pageIndex >= 0, pageIndex < document.pageCount,
                let page = document.page(at: pageIndex) else {
            DispatchQueue.main.async {
              result(FlutterError(code: "invalid_page", message: "No se pudo acceder a la página del PDF.", details: nil))
            }
            return
          }

          // 1. Render page to high-res image (2.5x scale) with white background
          let pageBounds = page.bounds(for: .mediaBox)
          let scale: CGFloat = 2.5
          let targetSize = CGSize(width: max(pageBounds.width * scale, 100), height: max(pageBounds.height * scale, 100))
          let renderer = UIGraphicsImageRenderer(size: targetSize)
          let renderedImage = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            ctx.cgContext.translateBy(x: 0.0, y: targetSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
          }

          let finalPath: String
          let shouldCleanup: Bool
          if let tp = targetPath, !tp.isEmpty {
            finalPath = tp
            shouldCleanup = false
          } else {
            let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pdf_page_\(pageIndex)_\(UUID().uuidString).png")
            finalPath = tempUrl.path
            shouldCleanup = true
          }

          let destinationUrl = URL(fileURLWithPath: finalPath)
          try? FileManager.default.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
          if let pngData = renderedImage.pngData() {
            try? pngData.write(to: destinationUrl)
          }

          // 2. Hybrid approach: check if selectable vector text exists in PDF
          let directText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
          if directText.count > 25 {
            let paragraphs = directText
              .components(separatedBy: "\n\n")
              .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
              .filter { !$0.isEmpty }

            let payload: [String: Any] = [
              "rawText": directText,
              "paragraphs": paragraphs.isEmpty ? [directText] : paragraphs,
              "lines": [],
              "imagePath": finalPath,
              "engine": "pdfkit-direct"
            ]
            DispatchQueue.main.async { result(payload) }
            return
          }

          // 3. Fallback: scanned PDF / image-only page -> Apple Vision OCR
          self.recognizeImageAt(path: finalPath, extraPayload: ["imagePath": finalPath], cleanup: shouldCleanup, result: result)
        }
        return
      }

      guard call.method == "recognize" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_path", message: "Falta la imagen.", details: nil)); return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        self.recognizeImageAt(path: path, extraPayload: [:], cleanup: false, result: result)
      }
    }
  }

  private func recognizeImageAt(path: String, extraPayload: [String: Any], cleanup: Bool, result: @escaping FlutterResult) {
    do {
      var directory = URL(fileURLWithPath: path).deletingLastPathComponent()
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try? directory.setResourceValues(values)

      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["en-US", "es-ES"]
      request.usesLanguageCorrection = false

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

      var payload: [String: Any] = [
        "rawText": lines.compactMap { $0["text"] as? String }.joined(separator: "\n"),
        "paragraphs": paragraphs,
        "lines": lines,
        "engine": "apple-vision"
      ]
      for (k, v) in extraPayload {
        payload[k] = v
      }

      if cleanup {
        try? FileManager.default.removeItem(atPath: path)
      }

      DispatchQueue.main.async { result(payload) }
    } catch {
      if cleanup {
        try? FileManager.default.removeItem(atPath: path)
      }
      DispatchQueue.main.async {
        result(FlutterError(code: "ocr_failed", message: "No se pudo leer esta imagen.", details: nil))
      }
    }
  }
}
