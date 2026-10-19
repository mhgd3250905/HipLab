package com.ugk.hiplab

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Training session keep-alive (lib/core/platform/training_service.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hiplab/training_session")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(TrainingSessionService.start(applicationContext))
                    "stop" -> {
                        TrainingSessionService.stop(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
