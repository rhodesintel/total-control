package com.rhodesai.total_control

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * Boot receiver to restart VPN service after device reboot.
 * Only starts VPN if it was enabled before reboot.
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "TotalControlBoot"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_VPN_ENABLED = "flutter.vpn_enabled"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            
            Log.d(TAG, "Boot completed, checking VPN state")
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val vpnWasEnabled = prefs.getBoolean(KEY_VPN_ENABLED, true)
            
            if (vpnWasEnabled) {
                Log.d(TAG, "VPN was enabled, starting service")
                val serviceIntent = Intent(context, TotalControlVpnService::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } else {
                Log.d(TAG, "VPN was disabled, not starting")
            }
        }
    }
}
