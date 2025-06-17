package com.example.launcher

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.launcher/messages"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Configuring Flutter engine")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Received method call: ${call.method}")
            when (call.method) {
                "getAllConversations" -> {
                    try {
                        Log.d(TAG, "Getting all conversations")
                        val conversations = getAllConversations()
                        Log.d(TAG, "Found ${conversations.size} conversations")
                        result.success(conversations)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting conversations", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                "getMessages" -> {
                    val limit = call.argument<Int>("limit") ?: 20
                    val offset = call.argument<Int>("offset") ?: 0
                    try {
                        Log.d(TAG, "Getting messages with limit=$limit, offset=$offset")
                        val messages = getMessages(limit, offset)
                        Log.d(TAG, "Found ${messages.size} messages")
                        result.success(messages)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting messages", e)
                        result.error("ERROR", e.message, null)
                    }
                }
                "sendMessage" -> {
                    val recipient = call.argument<String>("recipient")
                    val content = call.argument<String>("content")
                    if (recipient != null && content != null) {
                        try {
                            Log.d(TAG, "Sending message to $recipient")
                            sendMessage(recipient, content)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error sending message", e)
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        Log.e(TAG, "Invalid arguments for sendMessage")
                        result.error("INVALID_ARGUMENTS", "Recipient and content are required", null)
                    }
                }
                else -> {
                    Log.e(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun getAllConversations(): List<Map<String, Any>> {
        Log.d(TAG, "Starting getAllConversations")
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
        val sortOrder = "${Telephony.Sms.DATE} DESC"

        Log.d(TAG, "Querying SMS content provider")
        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            Log.d(TAG, "Found ${cursor.count} messages")
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

        Log.d(TAG, "Returning ${messages.size} messages")
        return messages
    }

    private fun getMessages(limit: Int, offset: Int): List<Map<String, Any>> {
        Log.d(TAG, "Starting getMessages with limit=$limit, offset=$offset")
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

        Log.d(TAG, "Querying SMS content provider")
        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            Log.d(TAG, "Found ${cursor.count} messages")
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

        Log.d(TAG, "Returning ${messages.size} messages")
        return messages
    }

    private fun sendMessage(recipient: String, content: String) {
        Log.d(TAG, "Starting sendMessage to $recipient")
        // Note: Sending SMS requires additional permissions and implementation
        // This is a placeholder for the actual implementation
        throw Exception("Sending SMS is not implemented yet")
    }
}
