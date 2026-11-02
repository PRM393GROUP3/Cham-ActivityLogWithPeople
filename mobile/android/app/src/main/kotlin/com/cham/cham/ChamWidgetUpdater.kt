package com.cham.cham

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.UUID

data class WidgetHabitItem(
    val id: String,
    val name: String,
    val emoji: String
)

object ChamWidgetUpdater {
    const val ACTION_QUICK_LOG = "com.cham.cham.ACTION_QUICK_LOG"
    const val EXTRA_EVENT_ID = "extra_event_id"
    const val EXTRA_EVENT_NAME = "extra_event_name"
    const val EXTRA_EVENT_EMOJI = "extra_event_emoji"

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_LOGS = "flutter.cham_activity_logs_v1"
    private const val KEY_EVENT_TYPES = "flutter.cham_event_types_v2"

    private val VN_ZONE: ZoneId = ZoneId.of("Asia/Ho_Chi_Minh")
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var animatingEventId: String? = null

    @Volatile
    private var animStep: Int = 0

    private val glowBitmapCache = mutableMapOf<String, Bitmap>()

    // chưa từng chỉnh danh sách nên Flutter chưa lưu KEY_EVENT_TYPES.
    private val ALL_DEFAULT_TYPES = listOf(
        WidgetHabitItem("coffee", "Cà phê", "☕"),
        WidgetHabitItem("water", "Nước", "💧"),
        WidgetHabitItem("running", "Chạy bộ", "🏃"),
        WidgetHabitItem("eating", "Ăn uống", "🍽️"),
        WidgetHabitItem("focus", "Tập trung", "💻"),
        WidgetHabitItem("reading", "Đọc sách", "📖"),
        WidgetHabitItem("meditate", "Thiền", "🧘"),
        WidgetHabitItem("walk", "Đi dạo", "🚶"),
        WidgetHabitItem("sleep", "Ngủ", "🌙"),
        WidgetHabitItem("clean", "Dọn dẹp", "🏠"),
        WidgetHabitItem("music", "Nghe nhạc", "🎧"),
        WidgetHabitItem("pet", "Thú cưng", "🐾"),
        WidgetHabitItem("cook", "Nấu ăn", "🍲"),
        WidgetHabitItem("plant", "Tưới cây", "🪴"),
        WidgetHabitItem("gym", "Gym", "🏋️"),
        WidgetHabitItem("movie", "Xem phim", "🎬"),
        WidgetHabitItem("journal", "Nhật ký", "✏️"),
        WidgetHabitItem("shopping", "Mua sắm", "🛍️"),
        WidgetHabitItem("cycling", "Đạp xe", "🚲")
    )

    /**
     * Các loại sự kiện cho vòng chọn của Widget 2×2: xếp theo số lần chấm trong 30 ngày gần nhất
     * (nhiều trước), bằng nhau thì giữ thứ tự trên vòng Dial; lấy tối đa [limit] loại.
     */
    fun topTypesForPicker(context: Context, limit: Int): List<WidgetHabitItem> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val types = loadEventTypesOrDefaults(prefs)
        val since = Instant.now().minus(30, ChronoUnit.DAYS)
        val counts = mutableMapOf<String, Int>()
        val logs = loadOrSeedLogsArray(prefs)
        for (i in 0 until logs.length()) {
            val obj = logs.optJSONObject(i) ?: continue
            val id = obj.optString("eventTypeId", "")
            if (id.isEmpty()) continue
            try {
                if (Instant.parse(obj.optString("occurredAt", "")).isBefore(since)) continue
            } catch (_: Exception) {
                continue
            }
            counts[id] = (counts[id] ?: 0) + 1
        }
        // sortedByDescending giữ nguyên thứ tự gốc khi bằng nhau
        return types.sortedByDescending { counts[it.id] ?: 0 }.take(limit)
    }

    fun handleQuickLogIntent(context: Context, intent: Intent) {
        if (intent.action != ACTION_QUICK_LOG) return
        val id = intent.getStringExtra(EXTRA_EVENT_ID) ?: "coffee"
        val name = intent.getStringExtra(EXTRA_EVENT_NAME) ?: "Cà phê"
        val emoji = intent.getStringExtra(EXTRA_EVENT_EMOJI) ?: "☕"

        appendQuickLog(context, id, name, emoji)
    }

    fun appendQuickLog(context: Context, eventTypeId: String, name: String, emoji: String) {
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val logsArray = loadOrSeedLogsArray(prefs)

        val newLog = JSONObject().apply {
            put("id", UUID.randomUUID().toString())
            put("eventTypeId", eventTypeId)
            put("name", name)
            put("emoji", emoji)
            put("occurredAt", Instant.now().toString())
            put("visibility", "private")
            put("syncStatus", "synced")
        }

        val updatedArray = JSONArray()
        updatedArray.put(newLog)
        for (i in 0 until logsArray.length()) {
            updatedArray.put(logsArray.getJSONObject(i))
        }

        prefs.edit().putString(KEY_LOGS, updatedArray.toString()).commit()

        Toast.makeText(
            appContext,
            "Đã chấm: $emoji $name (+1 chấm) — Đã lưu",
            Toast.LENGTH_SHORT
        ).show()

        // Smooth 4-stage blooming under-glow animation beneath the tapped icon
        mainHandler.removeCallbacksAndMessages(null)
        animatingEventId = eventTypeId
        animStep = 1
        updateAllWidgets(appContext)

        mainHandler.postDelayed({
            animStep = 2
            updateAllWidgets(appContext)
        }, 120L)

        mainHandler.postDelayed({
            animStep = 3
            updateAllWidgets(appContext)
        }, 280L)

        mainHandler.postDelayed({
            animStep = 4
            updateAllWidgets(appContext)
        }, 460L)

        mainHandler.postDelayed({
            animatingEventId = null
            animStep = 0
            updateAllWidgets(appContext)
        }, 680L)

        MainActivity.notifyWidgetLogged()
    }

    fun updateAllWidgets(context: Context) {
        val appContext = context.applicationContext
        val manager = AppWidgetManager.getInstance(appContext)

        val smallIds = manager.getAppWidgetIds(ComponentName(appContext, ChamSmallWidgetProvider::class.java))
        for (id in smallIds) {
            updateSmallWidget(appContext, manager, id)
        }

        val mediumIds = manager.getAppWidgetIds(ComponentName(appContext, ChamMediumWidgetProvider::class.java))
        for (id in mediumIds) {
            updateMediumWidget(appContext, manager, id)
        }
    }

    fun updateSmallWidget(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val logsArray = loadOrSeedLogsArray(prefs)
        val stats = computeStats(logsArray)

        val options = manager.getAppWidgetOptions(appWidgetId)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120)
        val isCompact = minHeight in 1..95
        val isLarge = minHeight >= 180

        // Dấu + mở vòng chọn hoạt động thay vì chấm một loại cố định
        val views = RemoteViews(context.packageName, R.layout.cham_small_widget)
        views.setTextViewText(R.id.small_widget_title, "Chấm")
        views.setViewVisibility(R.id.small_widget_habit_emoji, View.GONE)
        views.setTextViewText(R.id.small_widget_count, "${stats.todayCount} chấm hôm nay")

        views.setViewVisibility(R.id.small_widget_header, if (isCompact) View.GONE else View.VISIBLE)

        val lastToday = latestLogToday(logsArray)
        if (lastToday != null && !isCompact) {
            views.setTextViewText(R.id.small_widget_last, "Bạn vừa chấm ${lastToday.emoji} ${lastToday.name}")
            views.setViewVisibility(R.id.small_widget_last, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.small_widget_last, View.GONE)
        }
        views.setTextViewTextSize(
            R.id.small_widget_title,
            TypedValue.COMPLEX_UNIT_SP,
            if (isLarge) 14f else 12f
        )
        views.setTextViewTextSize(
            R.id.small_widget_count,
            TypedValue.COMPLEX_UNIT_SP,
            if (isLarge) 14f else if (isCompact) 10f else 12f
        )

        val isAnimating = animatingEventId != null && animStep > 0
        if (isAnimating) {
            views.setImageViewBitmap(R.id.small_pulse_ring, getCircleUnderGlowBitmap(animStep))
            views.setViewVisibility(R.id.small_pulse_ring, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.small_pulse_ring, View.GONE)
        }

        val openAppIntent = createOpenAppPendingIntent(context, appWidgetId)
        views.setOnClickPendingIntent(R.id.small_widget_header, openAppIntent)
        views.setOnClickPendingIntent(R.id.small_widget_count, openAppIntent)

        views.setOnClickPendingIntent(
            R.id.small_widget_plus_btn,
            createDialPickerPendingIntent(context, appWidgetId * 10 + 1)
        )

        manager.updateAppWidget(appWidgetId, views)
    }

    /**
     * Widget 4×2 "Bạn bè": danh sách cuộn những người bạn có hoạt động hôm nay (mới nhất trước),
     * thả tim ngay trên widget. Dữ liệu là bản chụp app ghi lại ở lần tải feed gần nhất.
     */
    @Suppress("DEPRECATION")
    fun updateMediumWidget(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        val snapshot = ChamFriendsStore.load(context)
        val views = RemoteViews(context.packageName, R.layout.cham_medium_widget)
        val openAppIntent = createOpenAppPendingIntent(context, appWidgetId + 5000)

        // Dòng phụ cạnh tiêu đề: số người, hoặc báo dữ liệu cũ khi lâu chưa đồng bộ
        val syncedAt = snapshot.syncedAt
        when {
            syncedAt != null && ChamFriendsStore.isStale(syncedAt) -> {
                views.setTextViewText(R.id.medium_meta, "⟳ ${ChamFriendsStore.hm(syncedAt)} · mở app để làm mới")
                views.setTextColor(R.id.medium_meta, Color.parseColor("#9A6A14"))
                views.setViewVisibility(R.id.medium_meta, View.VISIBLE)
            }
            snapshot.items.isNotEmpty() -> {
                views.setTextViewText(R.id.medium_meta, "${snapshot.items.size} người hôm nay")
                views.setTextColor(R.id.medium_meta, Color.parseColor("#857469"))
                views.setViewVisibility(R.id.medium_meta, View.VISIBLE)
            }
            else -> views.setViewVisibility(R.id.medium_meta, View.INVISIBLE)
        }
        views.setOnClickPendingIntent(R.id.medium_meta, openAppIntent)
        views.setOnClickPendingIntent(R.id.medium_title, openAppIntent)
        views.setOnClickPendingIntent(
            R.id.medium_plus_btn,
            createDialPickerPendingIntent(context, appWidgetId * 10 + 5)
        )

        // Trạng thái trống: chưa từng tải feed, hoặc hôm nay bạn bè chưa chấm gì
        if (syncedAt == null) {
            views.setTextViewText(R.id.medium_empty_text, "Mở Chấm để xem bạn bè đang làm gì")
            views.setTextViewText(R.id.medium_empty_cta, "Mở Chấm")
        } else {
            views.setTextViewText(
                R.id.medium_empty_text,
                "Hôm nay bạn bè chưa chấm gì. Rủ thêm bạn để cùng xem nhịp ngày."
            )
            views.setTextViewText(R.id.medium_empty_cta, "Mời bạn")
        }
        views.setOnClickPendingIntent(R.id.medium_empty_cta, openAppIntent)

        val serviceIntent = Intent(context, ChamFriendsWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.medium_list, serviceIntent)
        views.setEmptyView(R.id.medium_list, R.id.medium_empty)

        // Mỗi dòng gắn thêm loại thao tác (mở / thả tim / xem tất cả) vào mẫu intent này
        val templateFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val template = PendingIntent.getActivity(
            context,
            appWidgetId + 7000,
            Intent(context, ChamWidgetActionActivity::class.java),
            templateFlags
        )
        views.setPendingIntentTemplate(R.id.medium_list, template)

        manager.updateAppWidget(appWidgetId, views)
        manager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.medium_list)
    }

    private fun getCircleUnderGlowBitmap(step: Int): Bitmap {
        val key = "circle_$step"
        glowBitmapCache[key]?.let { return it }

        val size = 240
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)

        val intensity = when (step) {
            1 -> 0.82f
            2 -> 1.00f
            3 -> 0.72f
            else -> 0.42f
        }
        val cx = size / 2f
        val cy = size / 2f + 4f

        val radialPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                cx,
                cy,
                size * 0.48f,
                intArrayOf(
                    withAlpha(Color.parseColor("#FF9E44"), (235 * intensity).toInt()),
                    withAlpha(Color.parseColor("#FF5722"), (165 * intensity).toInt()),
                    withAlpha(Color.parseColor("#FF5722"), 0)
                ),
                floatArrayOf(0f, 0.62f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawCircle(cx, cy, size * 0.48f, radialPaint)

        glowBitmapCache[key] = bmp
        return bmp
    }

    private fun withAlpha(color: Int, alpha: Int): Int {
        val clamped = alpha.coerceIn(0, 255)
        return Color.argb(clamped, Color.red(color), Color.green(color), Color.blue(color))
    }

    private fun createOpenAppPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    private fun createDialPickerPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, ChamDialPickerActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                Intent.FLAG_ACTIVITY_NO_ANIMATION
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    private fun loadEventTypesOrDefaults(prefs: android.content.SharedPreferences): List<WidgetHabitItem> {
        val raw = prefs.getString(KEY_EVENT_TYPES, null)
        if (!raw.isNullOrEmpty()) {
            try {
                val arr = JSONArray(raw)
                val list = mutableListOf<WidgetHabitItem>()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    list.add(WidgetHabitItem(obj.optString("id"), obj.optString("name"), obj.optString("emoji")))
                }
                if (list.isNotEmpty()) return list
            } catch (_: Exception) {
            }
        }
        return ALL_DEFAULT_TYPES
    }

    private fun loadOrSeedLogsArray(prefs: android.content.SharedPreferences): JSONArray {
        val raw = prefs.getString(KEY_LOGS, null)
        if (!raw.isNullOrEmpty()) {
            try {
                return JSONArray(raw)
            } catch (_: Exception) {
            }
        }

        val now = Instant.now()
        val seeds = listOf(
            Triple("coffee", "Cà phê", "☕") to now.minus(45, ChronoUnit.MINUTES),
            Triple("water", "Nước", "💧") to now.minus(130, ChronoUnit.MINUTES),
            Triple("focus", "Tập trung", "💻") to now.minus(180, ChronoUnit.MINUTES),
            Triple("reading", "Đọc sách", "📖") to now.minus(270, ChronoUnit.MINUTES)
        )
        val arr = JSONArray()
        for ((info, time) in seeds) {
            val obj = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("eventTypeId", info.first)
                put("name", info.second)
                put("emoji", info.third)
                put("occurredAt", time.toString())
                put("visibility", "private")
                put("syncStatus", "synced")
            }
            arr.put(obj)
        }
        prefs.edit().putString(KEY_LOGS, arr.toString()).apply()
        return arr
    }

    /** Lần chấm mới nhất trong hôm nay (giờ VN), `null` nếu hôm nay chưa chấm. */
    private fun latestLogToday(logsArray: JSONArray): WidgetHabitItem? {
        val todayVn = LocalDate.now(VN_ZONE)
        var latest: Instant? = null
        var item: WidgetHabitItem? = null
        for (i in 0 until logsArray.length()) {
            val obj = logsArray.optJSONObject(i) ?: continue
            try {
                val instant = Instant.parse(obj.optString("occurredAt", ""))
                if (instant.atZone(VN_ZONE).toLocalDate() != todayVn) continue
                if (latest == null || instant.isAfter(latest)) {
                    latest = instant
                    item = WidgetHabitItem(
                        obj.optString("eventTypeId", ""),
                        obj.optString("name", ""),
                        obj.optString("emoji", "")
                    )
                }
            } catch (_: Exception) {
            }
        }
        return item
    }

    private data class WidgetStats(
        val todayCount: Int,
        val todayCountsByType: Map<String, Int>,
        val streakDays: Int
    )

    private fun computeStats(logsArray: JSONArray): WidgetStats {
        val todayVn = LocalDate.now(VN_ZONE)
        var todayCount = 0
        val countsByType = mutableMapOf<String, Int>()
        val activeDays = mutableSetOf<LocalDate>()

        for (i in 0 until logsArray.length()) {
            val obj = logsArray.optJSONObject(i) ?: continue
            val occurredAtStr = obj.optString("occurredAt", "")
            val eventTypeId = obj.optString("eventTypeId", "")
            if (occurredAtStr.isEmpty()) continue
            try {
                val instant = Instant.parse(occurredAtStr)
                val dateVn = instant.atZone(VN_ZONE).toLocalDate()
                activeDays.add(dateVn)
                if (dateVn == todayVn) {
                    todayCount++
                    if (eventTypeId.isNotEmpty()) {
                        countsByType[eventTypeId] = (countsByType[eventTypeId] ?: 0) + 1
                    }
                }
            } catch (_: Exception) {
            }
        }

        var streak = 0
        var cursor = if (activeDays.contains(todayVn)) todayVn else todayVn.minusDays(1)
        while (activeDays.contains(cursor)) {
            streak++
            cursor = cursor.minusDays(1)
        }
        if (streak == 0 && todayCount > 0) streak = 1

        return WidgetStats(
            todayCount = todayCount,
            todayCountsByType = countsByType,
            streakDays = streak
        )
    }
}
