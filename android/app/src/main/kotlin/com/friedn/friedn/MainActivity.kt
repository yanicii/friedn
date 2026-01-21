package com.friedn.friedn

import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Bundle
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.friedn.friedn/native"
    private val TAG = "MainActivity"
    private var nfcAdapter: NfcAdapter? = null
    private var methodChannel: MethodChannel? = null
    private var pendingNfcTagId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcAvailable" -> {
                    result.success(nfcAdapter != null)
                }
                "isNfcEnabled" -> {
                    result.success(nfcAdapter?.isEnabled == true)
                }
                "openNfcSettings" -> {
                    startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "isOverlayPermissionGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        android.net.Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: emptyList()
                    AppBlockerService.setBlockedApps(this, apps.toSet())
                    result.success(true)
                }
                "setBlockingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    AppBlockerService.setBlockingEnabled(this, enabled)
                    result.success(true)
                }
                "isBlockingEnabled" -> {
                    result.success(AppBlockerService.isBlockingEnabled(this))
                }
                "setRegisteredNfcTagId" -> {
                    val tagId = call.argument<String>("tagId")
                    AppBlockerService.setRegisteredNfcTagId(this, tagId)
                    result.success(true)
                }
                "getRegisteredNfcTagId" -> {
                    result.success(AppBlockerService.getRegisteredNfcTagId(this))
                }
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "getPendingNfcTagId" -> {
                    val tagId = pendingNfcTagId
                    pendingNfcTagId = null // Clear after reading
                    result.success(tagId)
                }
                "setBlockingEndTime" -> {
                    val endTime = call.argument<Number>("endTime")?.toLong()
                    AppBlockerService.setBlockingEndTime(this, endTime)
                    result.success(true)
                }
                "getBlockingEndTime" -> {
                    val endTime = AppBlockerService.getBlockingEndTime(this)
                    result.success(endTime)
                }
                else -> result.notImplemented()
            }
        }

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        // Start the foreground service to keep the app running
        BlockingForegroundService.start(this)

        // Check if launched via NFC intent
        handleNfcIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        enableNfcForegroundDispatch()
    }

    override fun onPause() {
        super.onPause()
        disableNfcForegroundDispatch()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleNfcIntent(intent)
    }

    private fun enableNfcForegroundDispatch() {
        nfcAdapter?.let { adapter ->
            val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            val filters = arrayOf(
                IntentFilter(NfcAdapter.ACTION_TAG_DISCOVERED),
                IntentFilter(NfcAdapter.ACTION_NDEF_DISCOVERED),
                IntentFilter(NfcAdapter.ACTION_TECH_DISCOVERED)
            )
            adapter.enableForegroundDispatch(this, pendingIntent, filters, null)
        }
    }

    private fun disableNfcForegroundDispatch() {
        nfcAdapter?.disableForegroundDispatch(this)
    }

    private fun handleNfcIntent(intent: Intent) {
        val action = intent.action
        if (NfcAdapter.ACTION_TAG_DISCOVERED == action ||
            NfcAdapter.ACTION_NDEF_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action
        ) {
            val tag: Tag? = intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
            tag?.let {
                val tagId = it.id.joinToString("") { byte -> "%02X".format(byte) }
                Log.d(TAG, "NFC tag scanned: $tagId")

                // Check if tag has existing data and is writable
                val tagInfo = checkNfcTagInfo(it)
                val hasData = tagInfo.first
                val isWritable = tagInfo.second

                Log.d(TAG, "Tag hasData: $hasData, isWritable: $isWritable")

                val tagData = mapOf(
                    "tagId" to tagId,
                    "hasData" to hasData,
                    "isWritable" to isWritable
                )

                if (methodChannel != null) {
                    // Flutter is ready, send directly
                    methodChannel?.invokeMethod("onNfcTagScanned", tagData)
                } else {
                    // Flutter not ready yet, store for later
                    Log.d(TAG, "Storing pending NFC tag: $tagId")
                    pendingNfcTagId = tagId
                }
            }
        }
    }

    private fun checkNfcTagInfo(tag: Tag): Pair<Boolean, Boolean> {
        var hasData = false
        var isWritable = false

        // Try to read as NDEF
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            try {
                ndef.connect()
                val ndefMessage = ndef.cachedNdefMessage
                hasData = ndefMessage != null && ndefMessage.records.isNotEmpty()
                isWritable = ndef.isWritable
                ndef.close()
            } catch (e: Exception) {
                Log.e(TAG, "Error reading NDEF tag", e)
                // If we can't read it, assume it might have data and is not writable for safety
                hasData = false
                isWritable = false
            }
        } else {
            // Check if it's formattable (empty but writable)
            val ndefFormatable = NdefFormatable.get(tag)
            if (ndefFormatable != null) {
                hasData = false
                isWritable = true
            } else {
                // Not NDEF compatible at all
                hasData = false
                isWritable = false
            }
        }

        return Pair(hasData, isWritable)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "$packageName/${AppBlockerService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(serviceName)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any?>>()

        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in packages) {
            // Only include apps that can be launched (have a launch intent)
            if (pm.getLaunchIntentForPackage(appInfo.packageName) == null) continue
            // Skip our own app
            if (appInfo.packageName == packageName) continue

            val appName = pm.getApplicationLabel(appInfo).toString()
            val iconBase64 = try {
                val drawable = pm.getApplicationIcon(appInfo)
                drawableToBase64(drawable)
            } catch (e: Exception) {
                null
            }

            apps.add(
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to appName,
                    "icon" to iconBase64
                )
            )
        }

        return apps.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun drawableToBase64(drawable: Drawable): String? {
        return try {
            val bitmap = if (drawable is BitmapDrawable) {
                drawable.bitmap
            } else {
                val bitmap = Bitmap.createBitmap(
                    drawable.intrinsicWidth.coerceAtLeast(1),
                    drawable.intrinsicHeight.coerceAtLeast(1),
                    Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bitmap
            }

            val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
            val outputStream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 80, outputStream)
            Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }
}
