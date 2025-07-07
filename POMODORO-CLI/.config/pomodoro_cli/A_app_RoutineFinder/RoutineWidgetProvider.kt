package com.example.routinefinder // Adjust package name as per your Android project

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews

class RoutineWidgetProvider : AppWidgetProvider() {

    private val TAG = "RoutineWidgetProvider"

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate called")
        // Perform this loop for each App Widget that belongs to this provider.
        appWidgetIds.forEach { appWidgetId ->
            // Create a RemoteViews object for the widget layout
            val views = RemoteViews(context.packageName, R.layout.routine_widget_layout)

            // Set up a pending intent for manual refresh (e.g., on widget click)
            val refreshIntent = Intent(context, RoutineWidgetProvider::class.java).apply {
                action = ACTION_MANUAL_REFRESH
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context, 0, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.routine_name_text_view, refreshPendingIntent) // Make routine name clickable for refresh

            // Get routine info (this should ideally be done in a background thread/worker)
            // For simplicity in this example, we'll do it directly, but for a real app,
            // you'd trigger a WorkManager task here.
            val routineFinder = RoutineFinder(context)
            val routineInfo = routineFinder.findCurrentRoutine()
            Log.d(TAG, "RoutineInfo: $routineInfo")

            // Update the TextViews in the widget layout
            views.setTextViewText(R.id.routine_name_text_view, "Routine: ${routineInfo.routineName}")
            views.setTextViewText(R.id.category_action_text_view, "Category/Action: ${routineInfo.categoryAction}")
            views.setTextViewText(R.id.task_text_view, "Task: ${routineInfo.task}")
            views.setTextViewText(R.id.sub_task_text_view, "SubTask: ${routineInfo.subTask}")
            views.setTextViewText(R.id.mini_task_text_view, "MiniTask: ${routineInfo.miniTask}")

            // Tell the AppWidgetManager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive called with action: ${intent?.action}")
        if (ACTION_MANUAL_REFRESH == intent?.action) {
            // Trigger a full update of all widgets managed by this provider
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisAppWidget = this.javaClass
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget.toComponentName())
            onUpdate(context, appWidgetManager, appWidgetIds)
            Log.d(TAG, "Manual refresh triggered.")
        }
    }

    companion object {
        const val ACTION_MANUAL_REFRESH = "com.example.routinefinder.ACTION_MANUAL_REFRESH"
    }
}
