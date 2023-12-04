package com.saplin.dikt

import android.app.Activity
import android.app.ActivityOptions
import android.content.Intent
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import io.flutter.Log
import kotlin.math.min


class TextActivity: Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("TextActivity", "!!!!! onCreate $intent")

        if (intent.action == Intent.ACTION_PROCESS_TEXT) {
            val selectedText = intent.getStringExtra("android.intent.extra.PROCESS_TEXT") ?: ""
            Log.d("TextActivity", "!!! ACTION_PROCESS_TEXT $selectedText")

            val intent = applicationContext.packageManager.getLaunchIntentForPackage("com.saplin.dikt")?.apply {
                // Don't let navigate back to this activity and don't show black screen
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                putExtra("android.intent.extra.PROCESS_TEXT", selectedText)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Calculate the bounds to show the app in the top right corner with 70% screen width
                val displayMetrics = resources.displayMetrics
                val screenWidth = displayMetrics.widthPixels
                val screenHeight = displayMetrics.heightPixels
                val width = min((screenWidth * 0.7).toInt(), 1000)
                val height = min((screenHeight * 0.5).toInt(), 1000)
                val mBounds = Rect(screenWidth - width - 25, 25, screenWidth-25, height)
                var activityOptions = ActivityOptions.makeBasic()
                // Using undocumented Android API to launch activity in new window
                try {
                    val method = ActivityOptions::class.java.getMethod("setLaunchWindowingMode", Int::class.javaPrimitiveType)
                    method.invoke(activityOptions, 5)
                } catch (_: Exception) {}
                activityOptions = activityOptions.setLaunchBounds(mBounds)
                startActivity(intent, activityOptions.toBundle())
                //Shared.appStartedInWindow = true
            }
            else {
                startActivity(intent)
            }
        }

        finish()
    }
}
