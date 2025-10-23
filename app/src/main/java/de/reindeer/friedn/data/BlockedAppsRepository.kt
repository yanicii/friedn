package de.reindeer.friedn.data

import android.content.Context

class BlockedAppsRepository(context: Context) {

    private val sharedPreferences = context.getSharedPreferences("locked_apps", Context.MODE_PRIVATE)

    fun getLockedApps(): Set<String> {
        return sharedPreferences.getStringSet("locked_apps_set", emptySet()) ?: emptySet()
    }

    fun addLockedApp(packageName: String) {
        val lockedApps = getLockedApps().toMutableSet()
        lockedApps.add(packageName)
        sharedPreferences.edit().putStringSet("locked_apps_set", lockedApps).apply()
    }

    fun removeLockedApp(packageName: String) {
        val lockedApps = getLockedApps().toMutableSet()
        lockedApps.remove(packageName)
        sharedPreferences.edit().putStringSet("locked_apps_set", lockedApps).apply()
    }
}