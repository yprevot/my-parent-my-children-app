package com.imagestobook.images_to_book

import android.content.Intent
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "images_to_book/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method == "openTtsSettings") {
                    startActivity(Intent("android.settings.TTS_SETTINGS"))
                    result.success(null)
                    return@setMethodCallHandler
                }
                if (call.method != "recognize") { result.notImplemented(); return@setMethodCallHandler }
                val path = call.argument<String>("path")
                if (path == null) { result.error("invalid_path", "Falta la imagen.", null); return@setMethodCallHandler }
                worker.execute {
                    try {
                        val image = InputImage.fromFilePath(applicationContext, Uri.fromFile(File(path)))
                        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        recognizer.process(image)
                            .addOnSuccessListener { text ->
                                val payload = mapOf(
                                    "rawText" to text.text,
                                    "paragraphs" to text.textBlocks.map { it.text },
                                    "lines" to text.textBlocks.flatMap { it.lines }.map { line ->
                                        val box = line.boundingBox
                                        mapOf(
                                            "text" to line.text,
                                            "left" to box?.left,
                                            "top" to box?.top,
                                            "width" to box?.width(),
                                            "height" to box?.height()
                                        )
                                    },
                                    "engine" to "mlkit-latin-16.0.1"
                                )
                                runOnUiThread { result.success(payload) }
                            }
                            .addOnFailureListener {
                                runOnUiThread { result.error("ocr_failed", "No se pudo leer esta imagen.", null) }
                            }
                            .addOnCompleteListener { recognizer.close() }
                    } catch (_: Exception) {
                        runOnUiThread { result.error("image_failed", "No se pudo abrir esta imagen.", null) }
                    }
                }
            }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
