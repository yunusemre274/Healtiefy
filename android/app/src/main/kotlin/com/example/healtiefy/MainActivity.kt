package com.example.healtiefy

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle the intent that started this activity
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle intents received while activity is already running (singleTask)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data = intent?.data
        
        if (Intent.ACTION_VIEW == action && data != null) {
            Log.d(TAG, "╔════════════════════════════════════════════════════════════╗")
            Log.d(TAG, "║           DEEP LINK RECEIVED IN MAINACTIVITY              ║")
            Log.d(TAG, "╠════════════════════════════════════════════════════════════╣")
            Log.d(TAG, "║ Full URI: $data")
            Log.d(TAG, "║ Scheme: ${data.scheme}")
            Log.d(TAG, "║ Host: ${data.host}")
            Log.d(TAG, "║ Path: ${data.path}")
            Log.d(TAG, "║ Query: ${data.query}")
            Log.d(TAG, "╚════════════════════════════════════════════════════════════╝")
            
            // The Flutter app_links plugin will handle this automatically
            // This logging helps debug if the intent is reaching MainActivity
        }
    }
}
