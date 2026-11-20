package com.r57zone.pcremkey

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity : AppCompatActivity() {
    private lateinit var webView: WebView

    companion object {
        private const val BACKGROUND_COLOR = "#1A1A1A" // тот же цвет, что у body в index.html
            private const val SIDE_PADDING_DP = 36         // пустые поля слева и справа (чтобы не задевать экран ладонями)
        private const val VERTICAL_PADDING_DP = 0      // при желании можно добавить поля сверху и снизу
    }

    /** Вызывается из JS: Android.closeApp() / Android.minimizeApp() */
    inner class AndroidBridge {
        @JavascriptInterface
        fun closeApp() {
            runOnUiThread { finishAndRemoveTask() }
        }

        @JavascriptInterface
        fun minimizeApp() {
            runOnUiThread { moveTaskToBack(true) }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Рисуем под системными панелями и под вырезом камеры, дальше сами задаём поля
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val cutoutMode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        else
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        window.attributes = window.attributes.also { it.layoutInDisplayCutoutMode = cutoutMode }

        val backgroundColor = Color.parseColor(BACKGROUND_COLOR)
        window.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(backgroundColor))
        window.statusBarColor = backgroundColor
        window.navigationBarColor = backgroundColor

        setContentView(R.layout.activity_main)

        // Поля по бокам: корневой контейнер закрашен в цвет фона и сам забирает касания у краёв,
        // до WebView они не доходят
        val root = findViewById<View>(R.id.root)
        root.setBackgroundColor(backgroundColor)
        val density = resources.displayMetrics.density
        val side = (SIDE_PADDING_DP * density).toInt()
        val vertical = (VERTICAL_PADDING_DP * density).toInt()
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val safe = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(
                side,
                safe.top + vertical,
                side,
                safe.bottom + vertical
            )
            WindowInsetsCompat.CONSUMED
        }

        hideSystemBars()

        webView = findViewById(R.id.webView)
        webView.setBackgroundColor(backgroundColor) // без белой вспышки при запуске
        webView.overScrollMode = View.OVER_SCROLL_NEVER
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true // Включение localStorage
        webView.addJavascriptInterface(AndroidBridge(), "Android")

        val webViewClient: WebViewClient = object : WebViewClient() {
            @Deprecated("Deprecated in Java")
            override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
                view.loadUrl(url)
                return true
            }

            @TargetApi(Build.VERSION_CODES.N)
            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest
            ): Boolean {
                view.loadUrl(request.url.toString())
                return true
            }
        }

        webView.webViewClient = webViewClient
        webView.webChromeClient = WebChromeClient() // Включение confirm & alert & prompt
        webView.loadUrl("file:///android_asset/index.html")
    }

    private fun hideSystemBars() {
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller.hide(WindowInsetsCompat.Type.systemBars())
    }

    // После диалогов (prompt/alert) и свайпа от края системные панели возвращаются - прячем снова
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                webView.evaluateJavascript("SendRemoteCommand('VOLUME_UP');", null)
                return true // не даём телефону заодно изменить свою собственную громкость
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                webView.evaluateJavascript("SendRemoteCommand('VOLUME_DOWN');", null)
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
