package com.saplin.dikt

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "dikt.select.text"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sendTextToFlutter(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sendTextToFlutter(intent)
    }

    private fun sendTextToFlutter(receivedIntent: Intent) {
        val selectedText = receivedIntent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""

        if (selectedText.isNotEmpty()) {
            Log.d("MainActivity", "!!! PROCESS_TEXT $selectedText")
        }

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, channelName).invokeMethod(
                "sendParams",
                mapOf("selectedText" to selectedText))
    }
}
