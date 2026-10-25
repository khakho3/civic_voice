package com.example.civic_voice

import io.flutter.embedding.engine.FlutterJNI
import io.flutter.embedding.engine.systemchannels.SettingsChannel
import io.flutter.plugin.common.JSONMessageCodec
import org.json.JSONObject
import java.nio.ByteBuffer

/** Keeps Flutter's secure fields masked without changing the phone's password setting. */
class PasswordMaskingFlutterJNI : FlutterJNI() {
    override fun dispatchPlatformMessage(
        channel: String,
        message: ByteBuffer?,
        position: Int,
        responseId: Int,
    ) {
        val outbound = if (channel == SettingsChannel.CHANNEL_NAME) {
            rewriteSettings(message, position)
        } else {
            message
        }
        super.dispatchPlatformMessage(
            channel,
            outbound,
            if (outbound !== message) outbound?.position() ?: 0 else position,
            responseId,
        )
    }

    companion object {
        fun rewriteSettings(message: ByteBuffer?, position: Int): ByteBuffer? {
            if (message == null) return null
            return try {
                // Outgoing buffers end at position. Decode a copy so the caller's
                // buffer is untouched, and retain every other engine setting.
                val copy = message.duplicate().apply {
                    position(0)
                    limit(position)
                }
                val settings = JSONMessageCodec.INSTANCE.decodeMessage(copy) as? JSONObject
                    ?: return message
                settings.put("brieflyShowPassword", false)
                JSONMessageCodec.INSTANCE.encodeMessage(settings)
            } catch (_: RuntimeException) {
                // Let the engine handle unknown/invalid messages normally.
                message
            }
        }
    }
}
