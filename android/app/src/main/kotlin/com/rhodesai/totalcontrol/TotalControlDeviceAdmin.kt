package com.rhodesai.totalcontrol

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

/**
 * Device Admin Receiver for TotalControl
 * Prevents uninstall while admin is active
 * User must remove admin privileges first (with 1hr delay warning)
 */
class TotalControlDeviceAdmin : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "TotalControl protection enabled", Toast.LENGTH_SHORT).show()

        // Store admin enabled state
        context.getSharedPreferences("totalcontrol", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("admin_enabled", true)
            .putLong("admin_enabled_at", System.currentTimeMillis())
            .apply()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Show warning when user tries to remove admin
        // This doesn't block - just warns
        return "Removing TotalControl protection will allow the app to be uninstalled. " +
               "Your rules will stop working. Are you sure?"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "TotalControl protection disabled", Toast.LENGTH_SHORT).show()

        context.getSharedPreferences("totalcontrol", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("admin_enabled", false)
            .putLong("admin_disabled_at", System.currentTimeMillis())
            .apply()
    }

    override fun onPasswordFailed(context: Context, intent: Intent, userHandle: android.os.UserHandle) {
        // Could track failed attempts if needed
    }

    companion object {
        fun isAdminActive(context: Context): Boolean {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as android.app.admin.DevicePolicyManager
            val adminComponent = android.content.ComponentName(context, TotalControlDeviceAdmin::class.java)
            return dpm.isAdminActive(adminComponent)
        }

        fun requestAdminEnable(context: Context) {
            val adminComponent = android.content.ComponentName(context, TotalControlDeviceAdmin::class.java)
            val intent = Intent(android.app.admin.DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(android.app.admin.DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                putExtra(android.app.admin.DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "TotalControl needs device admin to prevent accidental uninstall during focus time.")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        }
    }
}
