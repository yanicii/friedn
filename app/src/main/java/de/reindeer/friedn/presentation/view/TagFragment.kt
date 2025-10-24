package de.reindeer.friedn.presentation.view

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import java.nio.charset.Charset
import java.util.UUID

@Composable
fun TagScreen() {
    val context = LocalContext.current
    val activity = context as? Activity

    val prefs = remember(context) {
        context.getSharedPreferences("friedn_prefs", Context.MODE_PRIVATE)
    }
    var hasWrittenTag by remember { mutableStateOf(prefs.getBoolean("has_written_tag", false)) }
    var waitingForTag by remember { mutableStateOf(false) }
    var statusText by remember { mutableStateOf<String?>(null) }

    fun appVersionName(ctx: Context): String {
        return try {
            if (Build.VERSION.SDK_INT >= 33) {
                ctx.packageManager.getPackageInfo(
                    ctx.packageName,
                    PackageManager.PackageInfoFlags.of(0)
                ).versionName ?: ""
            } else {
                @Suppress("DEPRECATION")
                ctx.packageManager.getPackageInfo(ctx.packageName, 0).versionName ?: ""
            }
        } catch (_: Exception) {
            ""
        }
    }

    fun writeJsonToTag(tag: Tag): Boolean {
        val createdAtSeconds = System.currentTimeMillis() / 1000
        val payload = "{" +
            "\"createdAt\":$createdAtSeconds," +
            "\"name\":\"default\"," +
            "\"version\":\"${appVersionName(context)}\"," +
            "\"id\":\"${UUID.randomUUID()}\"," +
            "\"tag\":\"friedn\"" +
            "}"

        val mimeType = "application/json"
        val record = NdefRecord.createMime(mimeType, payload.toByteArray(Charset.forName("UTF-8")))
        val message = NdefMessage(arrayOf(record))

        try {
            val ndef = Ndef.get(tag)
            if (ndef != null) {
                ndef.connect()
                return try {
                    if (!ndef.isWritable) return false
                    if (ndef.maxSize < message.toByteArray().size) return false
                    ndef.writeNdefMessage(message)
                    true
                } finally {
                    try { ndef.close() } catch (_: Exception) {}
                }
            } else {
                val format = NdefFormatable.get(tag) ?: return false
                format.connect()
                return try {
                    format.format(message)
                    true
                } finally {
                    try { format.close() } catch (_: Exception) {}
                }
            }
        } catch (_: Exception) {
            return false
        }
    }

    val readerCallback = remember(activity) {
        NfcAdapter.ReaderCallback { tag ->
            val mainHandler = Handler(Looper.getMainLooper())
            val success = writeJsonToTag(tag)
            mainHandler.post {
                waitingForTag = false
                if (success) {
                    prefs.edit().putBoolean("has_written_tag", true).apply()
                    hasWrittenTag = true
                    statusText = "Tag written successfully"
                } else {
                    statusText = "Failed to write tag"
                }
            }
        }
    }

    DisposableEffect(waitingForTag) {
        val adapter = activity?.let { NfcAdapter.getDefaultAdapter(it) }
        if (waitingForTag && activity != null && adapter != null) {
            adapter.enableReaderMode(
                activity,
                readerCallback,
                NfcAdapter.FLAG_READER_NFC_A or
                    NfcAdapter.FLAG_READER_NFC_B or
                    NfcAdapter.FLAG_READER_NFC_F or
                    NfcAdapter.FLAG_READER_NFC_V or
                    NfcAdapter.FLAG_READER_NFC_BARCODE,
                null
            )
        }
        onDispose {
            if (activity != null) {
                try {
                    NfcAdapter.getDefaultAdapter(activity)?.disableReaderMode(activity)
                } catch (_: Exception) {}
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(PaddingValues(16.dp)),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        if (!hasWrittenTag) {
            Text(
                text = "Create a friedn tag",
                style = MaterialTheme.typography.headlineSmall
            )
            Spacer(Modifier.height(12.dp))
            Button(onClick = {
                val adapter = activity?.let { NfcAdapter.getDefaultAdapter(it) }
                if (adapter == null) {
                    statusText = "NFC not supported"
                    return@Button
                }
                if (!(adapter.isEnabled)) {
                    statusText = "Enable NFC to continue"
                    return@Button
                }
                statusText = "Hold a tag near the device"
                waitingForTag = true
            }) {
                Text("+")
            }
        } else {
            Text(
                text = "A friedn tag is set up.",
                style = MaterialTheme.typography.bodyLarge
            )
        }

        statusText?.let {
            Spacer(Modifier.height(16.dp))
            Text(it)
        }
    }
}