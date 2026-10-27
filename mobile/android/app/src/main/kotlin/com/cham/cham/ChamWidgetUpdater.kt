package com.cham.cham

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
    private const val KEY_SMALL_TYPE = "flutter.cham_widget_small_type_v1"
    private const val KEY_MEDIUM_TYPES = "flutter.cham_widget_medium_types_v1"

    private val VN_ZONE: ZoneId = ZoneId.of("Asia/Ho_Chi_Minh")
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var animatingEventId: String? = null

    @Volatile
    private var animStep: Int = 0

    private val glowBitmapCache = mutableMapOf<String, Bitmap>()

    // Vibrant glow colors matching the 4 habit button slots (Coral, Emerald, Violet, Sky Blue)
    private val SLOT_GLOW_COLORS = intArrayOf(
        Color.parseColor("#FF5722"),
        Color.parseColor("#2ECC71"),
        Color.parseColor("#8E44AD"),
        Color.parseColor("#2980B9")
    )

    private val SLOT_CORE_COLORS = intArrayOf(
        Color.parseColor("#FF9E44"),
        Color.parseColor("#69F0AE"),
        Color.parseColor("#CE93D8"),
        Color.parseColor("#64B5F6")
    )

    private val DEFAULT_HABITS = listOf(
        WidgetHabitItem("coffee", "Cà phê", "☕"),
        WidgetHabitItem("running", "Chạy bộ", "🏃"),
        WidgetHabitItem("reading", "Đọc sách", "📖"),
        WidgetHabitItem("meditate", "Thiền", "🧘")
    )

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
        val habit = loadSmallHabit(prefs)

        val options = manager.getAppWidgetOptions(appWidgetId)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120)
        val isCompact = minHeight in 1..95
        val isLarge = minHeight >= 180

        val views = RemoteViews(context.packageName, R.layout.cham_small_widget)
        views.setTextViewText(R.id.small_widget_title, habit.name)
        views.setTextViewText(R.id.small_widget_habit_emoji, habit.emoji)
        views.setTextViewText(R.id.small_widget_count, "${stats.todayCount} chấm hôm nay")

        views.setViewVisibility(R.id.small_widget_header, if (isCompact) View.GONE else View.VISIBLE)
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

        val isAnimating = animatingEventId == habit.id && animStep > 0
        if (isAnimating) {
            views.setImageViewBitmap(R.id.small_pulse_ring, getCircleUnderGlowBitmap(animStep))
            views.setViewVisibility(R.id.small_pulse_ring, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.small_pulse_ring, View.GONE)
        }

        val openAppIntent = createOpenAppPendingIntent(context, appWidgetId)
        views.setOnClickPendingIntent(R.id.small_widget_header, openAppIntent)
        views.setOnClickPendingIntent(R.id.small_widget_count, openAppIntent)

        val logIntent = createQuickLogPendingIntent(
            context = context,
            requestCode = appWidgetId * 10 + 1,
            habit = habit
        )
        views.setOnClickPendingIntent(R.id.small_widget_plus_btn, logIntent)

        manager.updateAppWidget(appWidgetId, views)
    }

    fun updateMediumWidget(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val logsArray = loadOrSeedLogsArray(prefs)
        val stats = computeStats(logsArray)
        val habits = loadMediumHabits(prefs)

        val options = manager.getAppWidgetOptions(appWidgetId)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val isCompactHeight = minHeight in 1..95
        val isExpandedHeight = minHeight >= 175

        val views = RemoteViews(context.packageName, R.layout.cham_medium_widget)

        val completedCount = habits.count { (stats.todayCountsByType[it.id] ?: 0) > 0 }
        views.setTextViewText(R.id.medium_widget_badge, "✓ $completedCount/${habits.size}")
        views.setTextViewText(
            R.id.medium_widget_streak,
            "⚡ Chuỗi ${stats.streakDays} ngày · ${stats.todayCount} chấm"
        )

        views.setViewVisibility(
            R.id.medium_widget_footer,
            if (isCompactHeight) View.GONE else View.VISIBLE
        )

        val openAppIntent = createOpenAppPendingIntent(context, appWidgetId + 5000)
        views.setOnClickPendingIntent(R.id.medium_widget_header, openAppIntent)

        val btnIds = intArrayOf(R.id.medium_btn_1, R.id.medium_btn_2, R.id.medium_btn_3, R.id.medium_btn_4)
        val countIds = intArrayOf(R.id.medium_count_1, R.id.medium_count_2, R.id.medium_count_3, R.id.medium_count_4)
        val pulseIds = intArrayOf(
            R.id.medium_pulse_ring_1,
            R.id.medium_pulse_ring_2,
            R.id.medium_pulse_ring_3,
            R.id.medium_pulse_ring_4
        )
        val boxIds = intArrayOf(
            R.id.medium_icon_box_1,
            R.id.medium_icon_box_2,
            R.id.medium_icon_box_3,
            R.id.medium_icon_box_4
        )
        val defaultBoxBgs = intArrayOf(
            R.drawable.widget_btn_1_bg,
            R.drawable.widget_btn_2_bg,
            R.drawable.widget_btn_3_bg,
            R.drawable.widget_btn_4_bg
        )
        val emojiIds = intArrayOf(R.id.medium_emoji_1, R.id.medium_emoji_2, R.id.medium_emoji_3, R.id.medium_emoji_4)
        val titleIds = intArrayOf(R.id.medium_title_1, R.id.medium_title_2, R.id.medium_title_3, R.id.medium_title_4)
        val dotIds = intArrayOf(R.id.medium_dot_1, R.id.medium_dot_2, R.id.medium_dot_3, R.id.medium_dot_4)

        val emojiSizeSp = if (isExpandedHeight) 24f else 20f
        val titleSizeSp = if (isExpandedHeight) 12f else if (minWidth in 1..200) 9.5f else 11f
        val countSizeSp = if (isExpandedHeight) 10.5f else 9f

        for (i in 0 until 4) {
            val habit = habits.getOrElse(i) { DEFAULT_HABITS[i] }
            val habitCount = stats.todayCountsByType[habit.id] ?: 0
            val isDoneToday = habitCount > 0
            val isAnimating = animatingEventId == habit.id && animStep > 0

            // 1. Count badge above each habit icon
            views.setTextViewText(countIds[i], "$habitCount chấm")
            views.setTextViewTextSize(countIds[i], TypedValue.COMPLEX_UNIT_SP, countSizeSp)
            views.setInt(
                countIds[i],
                "setBackgroundResource",
                if (isDoneToday) R.drawable.widget_count_pill_active else R.drawable.widget_count_pill_zero
            )
            views.setTextColor(
                countIds[i],
                if (isDoneToday) Color.parseColor("#B53216") else Color.parseColor("#7D726A")
            )

            // 2. Soft diffused under-glow aura beneath the icon + glowing border highlight
            if (isAnimating) {
                val glowBmp = getRoundedUnderGlowBitmap(slotIndex = i, step = animStep)
                views.setImageViewBitmap(pulseIds[i], glowBmp)
                views.setViewVisibility(pulseIds[i], View.VISIBLE)
                val boxBgRes = if (animStep == 2) R.drawable.widget_btn_glow_2 else R.drawable.widget_btn_glow_1
                views.setInt(boxIds[i], "setBackgroundResource", boxBgRes)
            } else {
                views.setViewVisibility(pulseIds[i], View.GONE)
                views.setInt(boxIds[i], "setBackgroundResource", defaultBoxBgs[i])
            }

            // 3. Emoji and Habit Title
            views.setTextViewText(emojiIds[i], habit.emoji)
            views.setTextViewTextSize(emojiIds[i], TypedValue.COMPLEX_UNIT_SP, emojiSizeSp)
            views.setTextViewText(titleIds[i], habit.name)
            views.setTextViewTextSize(titleIds[i], TypedValue.COMPLEX_UNIT_SP, titleSizeSp)

            // 4. Footer status dot
            views.setImageViewResource(
                dotIds[i],
                if (isDoneToday) R.drawable.widget_dot_active else R.drawable.widget_dot_inactive
            )

            val logIntent = createQuickLogPendingIntent(
                context = context,
                requestCode = appWidgetId * 100 + i + 10,
                habit = habit
            )
            views.setOnClickPendingIntent(btnIds[i], logIntent)
        }

        manager.updateAppWidget(appWidgetId, views)
    }

    /**
     * Generates a soft, multi-layered glowing backlight bitmap that sits underneath the 44dp rounded-square
     * habit icon, radiating a warm luminous halo around its edges and slightly below it.
     */
    private fun getRoundedUnderGlowBitmap(slotIndex: Int, step: Int): Bitmap {
        val key = "round_${slotIndex}_$step"
        glowBitmapCache[key]?.let { return it }

        val size = 186 // 3x density for 62dp container
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)

        val outerColor = SLOT_GLOW_COLORS[slotIndex % SLOT_GLOW_COLORS.size]
        val coreColor = SLOT_CORE_COLORS[slotIndex % SLOT_CORE_COLORS.size]

        // Intensity multiplier per animation frame (1: bloom, 2: peak radiant, 3: warm pulse, 4: fade)
        val intensity = when (step) {
            1 -> 0.80f
            2 -> 1.00f
            3 -> 0.72f
            else -> 0.42f
        }
        val spreadPx = when (step) {
            1 -> 20f
            2 -> 26f
            3 -> 22f
            else -> 16f
        }

        val cx = size / 2f
        val cy = size / 2f + 4f // Slightly shifted down so light blooms from underneath the icon

        // Layer 1: Wide radial ambient backlight underneath the icon
        val radialPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                cx,
                cy,
                size * 0.48f,
                intArrayOf(
                    withAlpha(coreColor, (220 * intensity).toInt()),
                    withAlpha(outerColor, (150 * intensity).toInt()),
                    withAlpha(outerColor, 0)
                ),
                floatArrayOf(0f, 0.58f, 1f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawCircle(cx, cy, size * 0.48f, radialPaint)

        // Layer 2: Blurred rounded-square neon halo matching the 44dp (132px) icon box shape
        val boxHalf = 66f
        val glowRect = RectF(
            cx - boxHalf - 4f,
            (size / 2f) - boxHalf - 2f,
            cx + boxHalf + 4f,
            (size / 2f) + boxHalf + 8f
        )
        val blurPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = withAlpha(outerColor, (210 * intensity).toInt())
            maskFilter = BlurMaskFilter(spreadPx, BlurMaskFilter.Blur.NORMAL)
        }
        canvas.drawRoundRect(glowRect, 48f, 48f, blurPaint)

        // Layer 3: Crisp luminous border rim right around the icon edge
        val rimRect = RectF(
            (size / 2f) - boxHalf - 2f,
            (size / 2f) - boxHalf - 2f,
            (size / 2f) + boxHalf + 2f,
            (size / 2f) + boxHalf + 2f
        )
        val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = if (step == 2) 7.5f else 5.5f
            color = withAlpha(coreColor, (245 * intensity).toInt())
            maskFilter = BlurMaskFilter(6f, BlurMaskFilter.Blur.NORMAL)
        }
        canvas.drawRoundRect(rimRect, 48f, 48f, rimPaint)

        glowBitmapCache[key] = bmp
        return bmp
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

    private fun createQuickLogPendingIntent(
        context: Context,
        requestCode: Int,
        habit: WidgetHabitItem
    ): PendingIntent {
        val intent = Intent(context, ChamSmallWidgetProvider::class.java).apply {
            action = ACTION_QUICK_LOG
            putExtra(EXTRA_EVENT_ID, habit.id)
            putExtra(EXTRA_EVENT_NAME, habit.name)
            putExtra(EXTRA_EVENT_EMOJI, habit.emoji)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun loadSmallHabit(prefs: android.content.SharedPreferences): WidgetHabitItem {
        val raw = prefs.getString(KEY_SMALL_TYPE, null)
        if (!raw.isNullOrEmpty()) {
            try {
                val obj = JSONObject(raw)
                return WidgetHabitItem(
                    id = obj.optString("id", "coffee"),
                    name = obj.optString("name", "Cà phê"),
                    emoji = obj.optString("emoji", "☕")
                )
            } catch (_: Exception) {
            }
        }
        val allTypes = loadAvailableEventTypes(prefs)
        return allTypes.firstOrNull() ?: DEFAULT_HABITS[0]
    }

    private fun loadMediumHabits(prefs: android.content.SharedPreferences): List<WidgetHabitItem> {
        val raw = prefs.getString(KEY_MEDIUM_TYPES, null)
        if (!raw.isNullOrEmpty()) {
            try {
                val arr = JSONArray(raw)
                val list = mutableListOf<WidgetHabitItem>()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    list.add(
                        WidgetHabitItem(
                            id = obj.optString("id", "coffee"),
                            name = obj.optString("name", "Cà phê"),
                            emoji = obj.optString("emoji", "☕")
                        )
                    )
                }
                if (list.size >= 4) return list.take(4)
            } catch (_: Exception) {
            }
        }
        val allTypes = loadAvailableEventTypes(prefs)
        if (allTypes.size >= 4) return allTypes.take(4)
        return DEFAULT_HABITS
    }

    private fun loadAvailableEventTypes(prefs: android.content.SharedPreferences): List<WidgetHabitItem> {
        val raw = prefs.getString(KEY_EVENT_TYPES, null)
        if (!raw.isNullOrEmpty()) {
            try {
                val arr = JSONArray(raw)
                val list = mutableListOf<WidgetHabitItem>()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    list.add(
                        WidgetHabitItem(
                            id = obj.optString("id"),
                            name = obj.optString("name"),
                            emoji = obj.optString("emoji")
                        )
                    )
                }
                if (list.isNotEmpty()) return list
            } catch (_: Exception) {
            }
        }
        return DEFAULT_HABITS
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
