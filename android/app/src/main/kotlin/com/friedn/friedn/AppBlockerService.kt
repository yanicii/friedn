package com.friedn.friedn

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AppBlockerService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerService"
        private const val PREFS_NAME = "friedn_prefs"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_BLOCKING_ENABLED = "blocking_enabled"
        private const val KEY_REGISTERED_NFC_TAG = "registered_nfc_tag"
        private const val KEY_SESSION_UNLOCKED = "session_unlocked"

        private var instance: AppBlockerService? = null
        private var lastBlockedTime: Long = 0
        private var lastBlockedPackage: String? = null

        fun setBlockedApps(context: Context, apps: Set<String>) {
            Log.d(TAG, "Setting blocked apps: $apps")
            getPrefs(context).edit().putStringSet(KEY_BLOCKED_APPS, apps).apply()
        }

        fun getBlockedApps(context: Context): Set<String> {
            return getPrefs(context).getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
        }

        fun setBlockingEnabled(context: Context, enabled: Boolean) {
            Log.d(TAG, "Setting blocking enabled: $enabled")
            getPrefs(context).edit().putBoolean(KEY_BLOCKING_ENABLED, enabled).apply()
            if (enabled) {
                setSessionUnlocked(context, false)
            }
        }

        fun isBlockingEnabled(context: Context): Boolean {
            return getPrefs(context).getBoolean(KEY_BLOCKING_ENABLED, false)
        }

        fun setRegisteredNfcTagId(context: Context, tagId: String?) {
            getPrefs(context).edit().putString(KEY_REGISTERED_NFC_TAG, tagId).apply()
        }

        fun getRegisteredNfcTagId(context: Context): String? {
            return getPrefs(context).getString(KEY_REGISTERED_NFC_TAG, null)
        }

        fun setSessionUnlocked(context: Context, unlocked: Boolean) {
            Log.d(TAG, "Setting session unlocked: $unlocked")
            getPrefs(context).edit().putBoolean(KEY_SESSION_UNLOCKED, unlocked).apply()
        }

        fun isSessionUnlocked(context: Context): Boolean {
            return getPrefs(context).getBoolean(KEY_SESSION_UNLOCKED, false)
        }

        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility service connected")

        // Configure the service
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        Log.d(TAG, "Window changed to: $packageName")

        // Don't block our own app, system UI, or launchers
        if (packageName == this.packageName ||
            packageName == "com.android.systemui" ||
            packageName.contains("launcher") ||
            packageName.contains("home") ||
            packageName == "com.google.android.apps.nexuslauncher" ||
            packageName == "com.android.launcher3"
        ) {
            return
        }

        // Check if blocking is enabled
        if (!isBlockingEnabled(this)) {
            Log.d(TAG, "Blocking is disabled")
            return
        }

        // Check if session is unlocked
        if (isSessionUnlocked(this)) {
            Log.d(TAG, "Session is unlocked")
            return
        }

        // Check if this app is in the blocked list
        val blockedApps = getBlockedApps(this)
        Log.d(TAG, "Blocked apps: $blockedApps")

        if (blockedApps.contains(packageName)) {
            // Debounce to prevent multiple lock screens
            val currentTime = System.currentTimeMillis()
            if (packageName == lastBlockedPackage && currentTime - lastBlockedTime < 1000) {
                Log.d(TAG, "Debouncing block for: $packageName")
                return
            }

            lastBlockedPackage = packageName
            lastBlockedTime = currentTime

            Log.d(TAG, "BLOCKING APP: $packageName")
            showLockScreen(packageName)
        }
    }

    private fun showLockScreen(blockedPackage: String) {
        Log.d(TAG, "Showing lock screen for: $blockedPackage")
        val intent = Intent(this, LockScreenActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            putExtra("blocked_package", blockedPackage)
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Service destroyed")
    }
}
