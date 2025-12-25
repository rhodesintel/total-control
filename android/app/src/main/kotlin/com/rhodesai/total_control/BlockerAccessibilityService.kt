package com.rhodesai.total_control

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.TextView

/**
 * Total Control Accessibility Service
 *
 * Monitors app usage and browser URLs. Checks content against syllabus whitelist.
 * Shows blocking overlay when non-whitelisted streaming content is detected.
 *
 * Logic:
 * 1. Streaming app opened → Check if current content is on syllabus
 * 2. Browser on streaming site → Check URL for syllabus content
 * 3. If on syllabus → allow
 * 4. If not on syllabus → show blocking overlay
 */
class BlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "TotalControl"

        // SharedPreferences keys (must match Flutter's ConfigService)
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_BLOCKER_ENABLED = "flutter.blocker_enabled"
        private const val KEY_BLOCKED_SITES = "flutter.blocked_sites"
        private const val KEY_SYLLABUS_FILMS = "flutter.syllabus_films"
    }

    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var lastBlockedUrl: String? = null
    private lateinit var prefs: SharedPreferences

    // Browser package -> URL bar view ID mapping
    private val browserUrlBarIds = mapOf(
        "com.android.chrome" to "com.android.chrome:id/url_bar",
        "com.chrome.beta" to "com.chrome.beta:id/url_bar",
        "com.chrome.dev" to "com.chrome.dev:id/url_bar",
        "com.chrome.canary" to "com.chrome.canary:id/url_bar",
        "org.mozilla.firefox" to "org.mozilla.firefox:id/mozac_browser_toolbar_url_view",
        "org.mozilla.firefox_beta" to "org.mozilla.firefox_beta:id/mozac_browser_toolbar_url_view",
        "org.mozilla.fenix" to "org.mozilla.fenix:id/mozac_browser_toolbar_url_view",
        "com.opera.browser" to "com.opera.browser:id/url_field",
        "com.opera.mini.native" to "com.opera.mini.native:id/url_field",
        "com.brave.browser" to "com.brave.browser:id/url_bar",
        "com.microsoft.emmx" to "com.microsoft.emmx:id/url_bar",
        "com.sec.android.app.sbrowser" to "com.sec.android.app.sbrowser:id/location_bar_edit_text",
        "com.duckduckgo.mobile.android" to "com.duckduckgo.mobile.android:id/omnibarTextInput",
        "com.kiwibrowser.browser" to "com.kiwibrowser.browser:id/url_bar",
        "com.UCMobile.intl" to "com.aspect.browser:id/search_box",
    )

    // Streaming apps that need content checking
    private val streamingApps = mapOf(
        "com.netflix.mediaclient" to "Netflix",
        "com.google.android.youtube" to "YouTube",
        "com.google.android.apps.youtube.kids" to "YouTube Kids",
        "com.google.android.youtube.tv" to "YouTube TV",
        "com.amazon.avod.thirdpartyclient" to "Prime Video",
        "com.disney.disneyplus" to "Disney+",
        "com.hulu.plus" to "Hulu",
        "com.hbo.hbonow" to "HBO",
        "com.wbd.stream" to "Max",
        "tv.twitch.android.app" to "Twitch",
        "com.zhiliaoapp.musically" to "TikTok",
        "com.ss.android.ugc.trill" to "TikTok",
        "com.crunchyroll.crunchyroid" to "Crunchyroll",
        "com.peacocktv.peacockandroid" to "Peacock",
        "com.cbs.ott" to "Paramount+",
        "com.apple.atve.androidtv.appletv" to "Apple TV",
        "com.plexapp.android" to "Plex",
    )

    // Always-allowed apps (music, etc.)
    private val alwaysAllowedApps = setOf(
        "com.google.android.apps.youtube.music", // YouTube Music app
    )

    // System apps - always allowed
    private val systemApps = setOf(
        "com.rhodesai.total_control",
        "com.android.settings",
        "com.android.systemui",
        "com.google.android.apps.nexuslauncher",
        "com.google.android.launcher",
        "com.sec.android.app.launcher",
        "com.miui.home",
        "com.huawei.android.launcher",
        "com.oppo.launcher",
        "com.android.launcher",
        "com.android.launcher3",
        "com.google.android.packageinstaller",
        "com.android.packageinstaller",
        "com.android.permissioncontroller",
        "com.google.android.permissioncontroller",
        "com.android.vending",
    )

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun isBlockerEnabled(): Boolean {
        return prefs.getBoolean(KEY_BLOCKER_ENABLED, true)
    }

    private fun getBlockedSites(): Set<String> {
        val sites = prefs.getStringSet(KEY_BLOCKED_SITES, null)
        if (sites != null) return sites

        return setOf(
            "netflix.com",
            "youtube.com",
            "primevideo.com",
            "disneyplus.com",
            "hulu.com",
            "max.com",
            "hbomax.com",
            "twitch.tv",
            "tiktok.com",
            "crunchyroll.com",
            "peacocktv.com",
            "paramountplus.com",
        )
    }

    private fun getSyllabusFilms(): Set<String> {
        val films = prefs.getStringSet(KEY_SYLLABUS_FILMS, null)
        return films ?: emptySet()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!isBlockerEnabled()) {
            hideOverlay()
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // System apps always allowed
        if (systemApps.contains(packageName)) {
            hideOverlay()
            return
        }

        // Always-allowed apps (YouTube Music, etc.)
        if (alwaysAllowedApps.contains(packageName)) {
            hideOverlay()
            return
        }

        // Streaming apps - check content against syllabus
        if (streamingApps.containsKey(packageName)) {
            val appName = streamingApps[packageName] ?: "Streaming"
            checkStreamingAppContent(packageName, appName)
            return
        }

        // Browsers - check URL
        if (browserUrlBarIds.containsKey(packageName)) {
            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
                AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                    checkBrowserUrl(packageName)
                }
            }
            return
        }

        // Everything else allowed
        hideOverlay()
    }

    /**
     * Check if a streaming app is showing syllabus content.
     * Reads screen text and checks against syllabus film titles.
     */
    private fun checkStreamingAppContent(packageName: String, appName: String) {
        val syllabusFilms = getSyllabusFilms()

        // If no syllabus, block streaming apps
        if (syllabusFilms.isEmpty()) {
            showOverlay("$appName is blocked.\n\nAdd films to your syllabus to watch educational content.")
            return
        }

        // Try to read screen content to check if it's syllabus content
        val rootNode = rootInActiveWindow
        if (rootNode == null) {
            // Can't read screen - block to be safe
            showOverlay("$appName is blocked.\n\nOpen a syllabus film to watch.")
            return
        }

        try {
            val screenText = extractAllText(rootNode).lowercase()

            // Check if any syllabus film title appears on screen
            for (film in syllabusFilms) {
                val filmLower = film.lowercase()
                // Check for exact match or partial match (handle "The Matrix" vs "Matrix")
                if (screenText.contains(filmLower)) {
                    Log.d(TAG, "Found syllabus film '$film' on screen - allowing")
                    hideOverlay()
                    return
                }
            }

            // No syllabus content found
            Log.d(TAG, "No syllabus content found on $appName screen")
            showOverlay("$appName is blocked.\n\nThis content is not on your syllabus.")

        } catch (e: Exception) {
            Log.e(TAG, "Error reading screen content: ${e.message}")
            showOverlay("$appName is blocked.")
        } finally {
            rootNode.recycle()
        }
    }

    /**
     * Extract all text from the accessibility tree.
     */
    private fun extractAllText(node: AccessibilityNodeInfo): String {
        val textBuilder = StringBuilder()

        node.text?.let { textBuilder.append(it).append(" ") }
        node.contentDescription?.let { textBuilder.append(it).append(" ") }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                textBuilder.append(extractAllText(child))
                child.recycle()
            }
        }

        return textBuilder.toString()
    }

    private fun checkBrowserUrl(packageName: String) {
        val urlBarId = browserUrlBarIds[packageName] ?: return
        val rootNode = rootInActiveWindow ?: return

        try {
            val urlNodes = rootNode.findAccessibilityNodeInfosByViewId(urlBarId)
            val url = urlNodes?.firstOrNull()?.text?.toString()

            if (url != null && url.isNotEmpty()) {
                Log.d(TAG, "Browser URL: $url")

                if (shouldBlockUrl(url)) {
                    if (lastBlockedUrl != url) {
                        lastBlockedUrl = url
                        showOverlay("This site is blocked.\n\n$url\n\nAccess your syllabus films through their direct links.")
                    }
                } else {
                    lastBlockedUrl = null
                    hideOverlay()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading URL: ${e.message}")
        } finally {
            rootNode.recycle()
        }
    }

    /**
     * Check if a URL should be blocked.
     * Allows search/browse pages so users can find their syllabus content.
     * Only blocks actual video/content consumption pages.
     */
    private fun shouldBlockUrl(url: String): Boolean {
        val lowerUrl = url.lowercase()

        // Always allow music
        if (lowerUrl.contains("music.youtube.com")) {
            return false
        }

        // Allow search pages - user needs to find syllabus content
        if (lowerUrl.contains("/results") ||     // YouTube search
            lowerUrl.contains("/search") ||      // Google/Netflix search
            lowerUrl.contains("?q=") ||          // Search queries
            lowerUrl.contains("?search") ||      // Search queries
            lowerUrl.contains("/browse")) {      // Browse pages
            return false
        }

        // Allow home pages (no path or just /)
        val pathStart = lowerUrl.indexOf(".com/")
        if (pathStart != -1) {
            val path = lowerUrl.substring(pathStart + 5)
            if (path.isEmpty() || path == "/" || path.startsWith("?")) {
                return false
            }
        }

        // Check if URL matches any blocked site
        val blockedSites = getBlockedSites()
        var isBlockedSite = false

        for (site in blockedSites) {
            if (lowerUrl.contains(site.lowercase())) {
                isBlockedSite = true
                break
            }
        }

        if (!isBlockedSite) {
            return false
        }

        // URL is on blocked list - check syllabus
        val syllabusFilms = getSyllabusFilms()
        for (film in syllabusFilms) {
            val filmNormalized = film.lowercase().replace(" ", "").replace("-", "")
            val urlNormalized = lowerUrl.replace(" ", "").replace("-", "")

            if (urlNormalized.contains(filmNormalized)) {
                Log.d(TAG, "URL contains syllabus film '$film' - allowing")
                return false
            }
        }

        // No syllabus match - block
        return true
    }

    override fun onInterrupt() {}

    private fun showOverlay(message: String) {
        if (overlayView != null) {
            overlayView?.findViewById<TextView>(R.id.blockingMessage)?.text = message
            return
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        overlayView = View.inflate(this, R.layout.blocking_overlay, null)
        overlayView?.findViewById<TextView>(R.id.blockingMessage)?.text = message

        overlayView?.findViewById<Button>(R.id.openTotalControl)?.setOnClickListener {
            val intent = packageManager.getLaunchIntentForPackage("com.rhodesai.total_control")
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent != null) {
                startActivity(intent)
            }
        }

        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay: ${e.message}")
        }
    }

    private fun hideOverlay() {
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                Log.e(TAG, "Error hiding overlay: ${e.message}")
            }
            overlayView = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }
}
