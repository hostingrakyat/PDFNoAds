package com.pdfnoads.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.pdfnoads.app/intent"
    }

    private var pendingUri: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractUriFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractUriFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialUri" -> {
                        result.success(pendingUri)
                        pendingUri = null
                    }
                    "readUri" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID", "No URI provided", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriStr)
                            val bytes = readUriBytes(uri)
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error("READ_ERROR", e.message, null)
                        }
                    }
                    "openDefaultApps" -> {
                        openDefaultAppsSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun extractUriFromIntent(intent: Intent?) {
        intent ?: return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
                }
            }
            else -> null
        }
        if (uri != null) {
            pendingUri = uri.toString()
        }
    }

    private fun readUriBytes(uri: Uri): ByteArray {
        val inputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open URI: $uri")
        return inputStream.use { stream ->
            val buffer = ByteArrayOutputStream()
            val chunk = ByteArray(8192)
            var bytesRead: Int
            while (stream.read(chunk).also { bytesRead = it } != -1) {
                buffer.write(chunk, 0, bytesRead)
            }
            buffer.toByteArray()
        }
    }

    private fun openDefaultAppsSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback to general app settings
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
            } catch (_: Exception) {}
        }
    }
}
