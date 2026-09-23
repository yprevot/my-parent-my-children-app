package online.myschoolmyparents

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "online.myschoolmyparents/ocr")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTtsSettings" -> {
                        startActivity(Intent("android.settings.TTS_SETTINGS"))
                        result.success(null)
                    }
                    "getPdfPageCount" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("invalid_path", "Falta la ruta del PDF.", null)
                            return@setMethodCallHandler
                        }
                        worker.execute {
                            var fd: ParcelFileDescriptor? = null
                            try {
                                fd = openParcelFile(path)
                                val renderer = PdfRenderer(fd)
                                val count = renderer.pageCount
                                renderer.close()
                                runOnUiThread { result.success(count) }
                            } catch (e: Exception) {
                                android.util.Log.e("MainActivity", "getPdfPageCount failed", e)
                                runOnUiThread { result.error("pdf_error", "No se pudo abrir el PDF: ${e.message}", null) }
                            } finally {
                                try { fd?.close() } catch (_: Exception) {}
                            }
                        }
                    }
                    "processPdfPage" -> {
                        val path = call.argument<String>("path")
                        val pageIndex = call.argument<Int>("page")
                        val targetPath = call.argument<String>("targetPath")
                        if (path == null || pageIndex == null) {
                            result.error("invalid_args", "Falta la ruta o el índice de página.", null)
                            return@setMethodCallHandler
                        }
                        worker.execute { processPdfPage(path, pageIndex, targetPath, result) }
                    }
                    "recognize" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("invalid_path", "Falta la imagen.", null)
                            return@setMethodCallHandler
                        }
                        worker.execute { recognizeImage(path, result) }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openParcelFile(path: String): ParcelFileDescriptor {
        return if (path.startsWith("content://")) {
            contentResolver.openFileDescriptor(Uri.parse(path), "r")
                ?: throw IllegalArgumentException("No se pudo abrir el descriptor de contenido para: $path")
        } else {
            ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
        }
    }

    private fun processPdfPage(path: String, pageIndex: Int, targetPath: String?, result: MethodChannel.Result) {
        var fd: ParcelFileDescriptor? = null
        try {
            fd = openParcelFile(path)
            val renderer = PdfRenderer(fd)
            if (pageIndex < 0 || pageIndex >= renderer.pageCount) {
                renderer.close()
                runOnUiThread { result.error("invalid_page", "Índice de página fuera de rango ($pageIndex). Total: ${renderer.pageCount}", null) }
                return
            }

            val page = renderer.openPage(pageIndex)
            // Render at 3x scale for crisp OCR (standard 72 DPI -> 216 DPI)
            val scale = 3
            val bitmap = Bitmap.createBitmap(
                page.width * scale,
                page.height * scale,
                Bitmap.Config.ARGB_8888
            )
            bitmap.eraseColor(Color.WHITE)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            page.close()
            renderer.close()

            // Save to targetPath if provided, or temporary cache file
            val finalImageFile: File
            val shouldCleanup: Boolean
            if (targetPath != null && targetPath.isNotEmpty()) {
                finalImageFile = File(targetPath)
                finalImageFile.parentFile?.mkdirs()
                shouldCleanup = false
            } else {
                finalImageFile = File.createTempFile("pdf_page_${pageIndex}_", ".png", cacheDir)
                shouldCleanup = true
            }

            FileOutputStream(finalImageFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            bitmap.recycle()

            recognizeImage(
                finalImageFile.absolutePath,
                result,
                cleanup = if (shouldCleanup) finalImageFile else null,
                extraPayload = mapOf("imagePath" to finalImageFile.absolutePath)
            )
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "PDF page processing failed", e)
            runOnUiThread { result.error("pdf_page_error", "No se pudo procesar la página del PDF: ${e.message}", null) }
        } finally {
            try { fd?.close() } catch (_: Exception) {}
        }
    }

    private fun recognizeImage(
        path: String,
        result: MethodChannel.Result,
        cleanup: File? = null,
        extraPayload: Map<String, Any> = emptyMap()
    ) {
        try {
            val file = File(path)
            android.util.Log.i("MainActivity", "OCR: Processing image at path=$path, exists=${file.exists()}, length=${file.length()}")
            if (!file.exists() || file.length() == 0L) {
                cleanup?.delete()
                runOnUiThread { result.error("file_not_found", "El archivo de imagen no existe o está vacío: $path", null) }
                return
            }

            val image: InputImage = try {
                InputImage.fromFilePath(applicationContext, Uri.fromFile(file))
            } catch (e: Exception) {
                android.util.Log.w("MainActivity", "OCR: InputImage.fromFilePath failed, falling back to Bitmap decoding", e)
                val bitmap = android.graphics.BitmapFactory.decodeFile(file.absolutePath)
                    ?: throw IllegalArgumentException("No se pudo decodificar el archivo como imagen: $path")
                InputImage.fromBitmap(bitmap, 0)
            }

            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            recognizer.process(image)
                .addOnSuccessListener { text ->
                    android.util.Log.i("MainActivity", "OCR: Success, text length=${text.text.length}, blocks=${text.textBlocks.size}")
                    val payload = mutableMapOf<String, Any>(
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
                    payload.putAll(extraPayload)
                    cleanup?.delete()
                    runOnUiThread { result.success(payload) }
                }
                .addOnFailureListener { e ->
                    android.util.Log.e("MainActivity", "OCR: ML Kit recognizer.process failed", e)
                    cleanup?.delete()
                    runOnUiThread { result.error("ocr_failed", "No se pudo leer esta imagen: ${e.message}", null) }
                }
                .addOnCompleteListener { recognizer.close() }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "OCR: Exception while opening image or initializing recognizer", e)
            cleanup?.delete()
            runOnUiThread { result.error("image_failed", "No se pudo abrir esta imagen: ${e.message}", null) }
        }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
