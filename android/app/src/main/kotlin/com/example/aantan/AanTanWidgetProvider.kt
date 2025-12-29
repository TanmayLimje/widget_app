package com.example.aantan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.io.File

class AanTanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        
        // Color map matching Flutter colors
        private val colorMap = mapOf(
            "FF6366F1" to "#6366F1", // Purple
            "FF3B82F6" to "#3B82F6", // Blue
            "FF10B981" to "#10B981", // Green
            "FFF97316" to "#F97316", // Orange
            "FFEC4899" to "#EC4899", // Pink
            "FFEF4444" to "#EF4444", // Red
            "FF14B8A6" to "#14B8A6", // Teal
            "FFEAB308" to "#EAB308"  // Yellow
        )

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get data from shared preferences
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            val user1Text = prefs.getString("user1_text", "") ?: ""
            val user2Text = prefs.getString("user2_text", "") ?: ""
            val user1ColorKey = prefs.getString("user1_color", "FF6366F1") ?: "FF6366F1"
            val user2ColorKey = prefs.getString("user2_color", "FF3B82F6") ?: "FF3B82F6"
            val user1ImagePath = prefs.getString("user1_image", "") ?: ""
            val user2ImagePath = prefs.getString("user2_image", "") ?: ""
            
            val user1Color = colorMap[user1ColorKey] ?: "#6366F1"
            val user2Color = colorMap[user2ColorKey] ?: "#3B82F6"

            // Construct the RemoteViews object
            val views = RemoteViews(context.packageName, R.layout.aantan_widget)
            
            // Set text for both users
            views.setTextViewText(R.id.user1_text, user1Text)
            views.setTextViewText(R.id.user2_text, user2Text)
            
            // Show/hide text based on content
            views.setViewVisibility(R.id.user1_text, if (user1Text.isNotEmpty()) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.user2_text, if (user2Text.isNotEmpty()) View.VISIBLE else View.GONE)
            
            // Set background colors
            views.setInt(R.id.user1_container, "setBackgroundColor", Color.parseColor(user1Color))
            views.setInt(R.id.user2_container, "setBackgroundColor", Color.parseColor(user2Color))

            // Set user images if available
            if (user1ImagePath.isNotEmpty()) {
                val bitmap = loadBitmapFromPath(user1ImagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.user1_image, bitmap)
                    views.setViewVisibility(R.id.user1_image, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.user1_image, View.VISIBLE)
                }
            } else {
                views.setViewVisibility(R.id.user1_image, View.VISIBLE)
            }
            
            if (user2ImagePath.isNotEmpty()) {
                val bitmap = loadBitmapFromPath(user2ImagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.user2_image, bitmap)
                    views.setViewVisibility(R.id.user2_image, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.user2_image, View.VISIBLE)
                }
            } else {
                views.setViewVisibility(R.id.user2_image, View.VISIBLE)
            }

            // Create an Intent to launch MainActivity when widget is clicked
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Set click listener on both user containers
            views.setOnClickPendingIntent(R.id.user1_container, pendingIntent)
            views.setOnClickPendingIntent(R.id.user2_container, pendingIntent)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun loadBitmapFromPath(path: String): Bitmap? {
            return try {
                val file = File(path)
                if (file.exists()) {
                    // Scale down the image to avoid memory issues
                    val options = BitmapFactory.Options().apply {
                        inSampleSize = 2
                    }
                    BitmapFactory.decodeFile(path, options)
                } else {
                    null
                }
            } catch (e: Exception) {
                null
            }
        }
    }
}
