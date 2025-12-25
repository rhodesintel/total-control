package com.rhodesai.total_control

import android.Manifest
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rhodesai.totalcontrol/blocker"
    private val VPN_REQUEST_CODE = 100
    private val NOTIFICATION_PERMISSION_CODE = 101

    private var pendingVpnResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermission()
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val permissions = mapOf(
                        "accessibility" to isAccessibilityServiceEnabled(),
                        "overlay" to Settings.canDrawOverlays(this),
                        "vpn" to TotalControlVpnService.isRunning
                    )
                    result.success(permissions)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(null)
                }

                // VPN Controls
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        pendingVpnResult = result
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        result.success(true)
                    }
                }
                "startVpn" -> {
                    val intent = Intent(this, TotalControlVpnService::class.java)
                    startService(intent)
                    result.success(true)
                }
                "stopVpn" -> {
                    val intent = Intent(this, TotalControlVpnService::class.java)
                    intent.action = "STOP"
                    startService(intent)
                    result.success(true)
                }
                "isVpnRunning" -> {
                    result.success(TotalControlVpnService.isRunning)
                }

                // Legacy methods
                "startService" -> result.success(null)
                "stopService" -> result.success(null)
                "showBlockingOverlay" -> result.success(null)
                "hideBlockingOverlay" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            pendingVpnResult?.success(resultCode == Activity.RESULT_OK)
            pendingVpnResult = null
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        return enabledServices.any {
            it.resolveInfo.serviceInfo.packageName == packageName
        }
    }
}
