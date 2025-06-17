package com.example.launcher

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.launcher/messages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMessages" -> {
                    val limit = call.argument<Int>("limit") ?: 20
                    val offset = call.argument<Int>("offset") ?: 0
                    try {
                        val messages = getMessages(limit, offset)
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "sendMessage" -> {
                    val recipient = call.argument<String>("recipient")
                    val content = call.argument<String>("content")
                    if (recipient != null && content != null) {
                        try {
                            sendMessage(recipient, content)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Recipient and content are required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getMessages(limit: Int, offset: Int): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = applicationContext.contentResolver
        val uri = Uri.parse("content://sms")
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.TYPE
        )
        val selection = null
        val selectionArgs = null
        val sortOrder = "${Telephony.Sms.DATE} DESC LIMIT $limit OFFSET $offset"

        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms._ID))
                val address = cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                val body = cursor.getString(cursor.getColumnIndexOrThrow(Telephony.Sms.BODY))
                val date = cursor.getLong(cursor.getColumnIndexOrThrow(Telephony.Sms.DATE))
                val type = cursor.getInt(cursor.getColumnIndexOrThrow(Telephony.Sms.TYPE))

                val message = mapOf(
                    "id" to (id ?: ""),
                    "sender" to (address ?: ""),
                    "content" to (body ?: ""),
                    "timestamp" to SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
                        .format(Date(date)),
                    "isIncoming" to (type == Telephony.Sms.MESSAGE_TYPE_INBOX)
                )
                messages.add(message)
            }
        }

        return messages
    }

    private fun sendMessage(recipient: String, content: String) {
        // Note: Sending SMS requires additional permissions and implementation
        // This is a placeholder for the actual implementation
        throw Exception("Sending SMS is not implemented yet")
    }
}
