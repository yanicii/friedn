package com.friedn.friedn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Boot completed - resetting blocking state")

            // Always disable blocking on boot
            AppBlockerService.setBlockingEnabled(context, false)
            AppBlockerService.setSessionUnlocked(context, false)

            // Start the foreground service to keep the app running
            BlockingForegroundService.start(context)
        }
    }
}
