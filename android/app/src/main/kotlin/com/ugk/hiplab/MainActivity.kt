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
                    "start" -> {
                        val session = (call.argument<Number>("session") ?: 0).toLong()
                        val maxMs = (call.argument<Number>("maxMs") ?: 0).toLong()
                        result.success(
                            session != 0L &&
                                TrainingSessionService.start(applicationContext, session, maxMs),
                        )
                    }
                    "stop" -> {
                        val session = (call.argument<Number>("session") ?: 0).toLong()
                        TrainingSessionService.stop(applicationContext, session)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
