package com.bonobo.dnd

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"com.bonobo.dnd/installer"
		).setMethodCallHandler { call, result ->
			if (call.method == "getInstallerPackage") {
				try {
					val installer = applicationContext.packageManager
						.getInstallerPackageName(applicationContext.packageName)
					// Return empty string if null to avoid sending null across platform channel
					result.success(installer ?: "")
				} catch (e: Exception) {
					result.error("ERROR", "Failed to get installer: ${e.message}", null)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
