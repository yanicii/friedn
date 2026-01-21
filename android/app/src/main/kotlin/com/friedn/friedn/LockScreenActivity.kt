package com.friedn.friedn

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.Drawable
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class LockScreenActivity : Activity() {
    private var nfcAdapter: NfcAdapter? = null
    private var blockedPackage: String? = null
    private var timerTextView: TextView? = null
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        blockedPackage = intent.getStringExtra("blocked_package")
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)

        // Make this activity appear over other apps
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        setupUI()
    }

    private fun isDarkMode(): Boolean {
        val nightModeFlags = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return nightModeFlags == Configuration.UI_MODE_NIGHT_YES
    }

    private fun setupUI() {
        val isDark = isDarkMode()

        // Colors based on theme
        val backgroundColor = if (isDark) 0xFF1a1a2e.toInt() else 0xFFF5F5F7.toInt()
        val titleColor = if (isDark) 0xFFFFFFFF.toInt() else 0xFF1a1a2e.toInt()
        val subtitleColor = if (isDark) 0xFFB0B0B0.toInt() else 0xFF666666.toInt()
        val iconColor = if (isDark) 0xFFFFFFFF.toInt() else 0xFF1a1a2e.toInt()
        val buttonColor = 0xFF4A90D9.toInt() // Blue in both modes

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(backgroundColor)
            setPadding(48, 48, 48, 48)
        }

        val lockIcon = LockIconView(this, iconColor)
        lockIcon.layoutParams = LinearLayout.LayoutParams(120, 120)

        val titleText = TextView(this).apply {
            text = "App Blocked by friedn"
            textSize = 28f
            setTextColor(titleColor)
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }

        val descText = TextView(this).apply {
            text = "This app is currently blocked.\nScan your NFC tag to unlock."
            textSize = 16f
            setTextColor(subtitleColor)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }

        // Timer display
        timerTextView = TextView(this).apply {
            textSize = 20f
            setTextColor(0xFFFF9800.toInt()) // Orange color
            gravity = Gravity.CENTER
            setPadding(24, 16, 24, 16)
            visibility = View.GONE
        }

        val goBackButton = Button(this).apply {
            text = "Go Back"
            textSize = 14f
            setTextColor(buttonColor)
            setBackgroundColor(0x00000000) // Transparent background
            setOnClickListener {
                goToHome()
            }
        }

        layout.addView(lockIcon)
        layout.addView(titleText)
        layout.addView(descText)
        layout.addView(timerTextView)
        layout.addView(goBackButton)

        setContentView(layout)

        // Start timer update
        startTimerUpdate()
    }

    private fun startTimerUpdate() {
        timerRunnable = object : Runnable {
            override fun run() {
                updateTimerDisplay()
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(timerRunnable!!)
    }

    private fun stopTimerUpdate() {
        timerRunnable?.let { handler.removeCallbacks(it) }
        timerRunnable = null
    }

    private fun updateTimerDisplay() {
        val remainingMillis = AppBlockerService.getRemainingTimeMillis(this)

        if (remainingMillis == null) {
            timerTextView?.visibility = View.GONE
            return
        }

        if (remainingMillis <= 0) {
            // Timer expired
            timerTextView?.visibility = View.GONE
            AppBlockerService.setBlockingEnabled(this, false)
            AppBlockerService.setBlockingEndTime(this, null)

            Toast.makeText(
                this,
                "Timer expired - blocking disabled",
                Toast.LENGTH_SHORT
            ).show()

            finish()

            // Re-launch the blocked app
            blockedPackage?.let { pkg ->
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                launchIntent?.let { startActivity(it) }
            }
            return
        }

        timerTextView?.visibility = View.VISIBLE
        timerTextView?.text = "Remaining: ${formatDuration(remainingMillis)}"
    }

    private fun formatDuration(millis: Long): String {
        val totalSeconds = millis / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60

        return when {
            hours > 0 -> String.format("%dh %dm %ds", hours, minutes, seconds)
            minutes > 0 -> String.format("%dm %ds", minutes, seconds)
            else -> String.format("%ds", seconds)
        }
    }

    // Simple lock icon drawn with Canvas
    private class LockIconView(context: android.content.Context, private val iconColor: Int) : View(context) {
        private val paint = Paint().apply {
            color = iconColor
            style = Paint.Style.STROKE
            strokeWidth = 8f
            isAntiAlias = true
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }

        private val fillPaint = Paint().apply {
            color = iconColor
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val w = width.toFloat()
            val h = height.toFloat()
            val cx = w / 2

            // Draw the shackle (U shape at top)
            val shackleWidth = w * 0.5f
            val shackleHeight = h * 0.35f
            val shackleTop = h * 0.1f

            val path = Path()
            path.moveTo(cx - shackleWidth / 2, h * 0.45f)
            path.lineTo(cx - shackleWidth / 2, shackleTop + shackleHeight * 0.3f)
            path.quadTo(cx - shackleWidth / 2, shackleTop, cx, shackleTop)
            path.quadTo(cx + shackleWidth / 2, shackleTop, cx + shackleWidth / 2, shackleTop + shackleHeight * 0.3f)
            path.lineTo(cx + shackleWidth / 2, h * 0.45f)

            canvas.drawPath(path, paint)

            // Draw the lock body (rounded rectangle)
            val bodyLeft = cx - w * 0.35f
            val bodyRight = cx + w * 0.35f
            val bodyTop = h * 0.4f
            val bodyBottom = h * 0.85f
            val cornerRadius = 12f

            canvas.drawRoundRect(bodyLeft, bodyTop, bodyRight, bodyBottom, cornerRadius, cornerRadius, fillPaint)
        }
    }

    override fun onResume() {
        super.onResume()
        enableNfcForegroundDispatch()
        startTimerUpdate()
    }

    override fun onPause() {
        super.onPause()
        disableNfcForegroundDispatch()
        stopTimerUpdate()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTimerUpdate()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
    }

    private fun enableNfcForegroundDispatch() {
        nfcAdapter?.let { adapter ->
            val pendingIntent = PendingIntent.getActivity(
                this, 0,
                Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
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
                verifyNfcTag(tagId)
            }
        }
    }

    private fun verifyNfcTag(scannedTagId: String) {
        val registeredTagId = AppBlockerService.getRegisteredNfcTagId(this)

        if (registeredTagId != null && scannedTagId == registeredTagId) {
            // Correct tag! Disable blocking entirely (not just session unlock)
            AppBlockerService.setBlockingEnabled(this, false)
            AppBlockerService.setSessionUnlocked(this, true)
            AppBlockerService.setBlockingEndTime(this, null) // Clear timer

            Toast.makeText(
                this,
                "friedn is disabled",
                Toast.LENGTH_SHORT
            ).show()

            finish()

            // Re-launch the blocked app
            blockedPackage?.let { pkg ->
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                launchIntent?.let { startActivity(it) }
            }
        } else {
            // Wrong tag
            Toast.makeText(
                this,
                "Wrong NFC tag. Please use your registered tag.",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun goToHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Override back press to go to home instead
        goToHome()
    }
}
