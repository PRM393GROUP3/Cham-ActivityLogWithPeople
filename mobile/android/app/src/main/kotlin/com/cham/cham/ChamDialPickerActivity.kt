package com.cham.cham

import android.app.Activity
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/**
 * Màn hình trong suốt mở từ dấu + của Widget 2×2: màn hình chính mờ đi, giữa màn hình bung ra
 * vòng Dial 2 vòng gồm tối đa 20 hoạt động dùng nhiều nhất 30 ngày gần nhất.
 * Vòng trong 8 hoạt động đầu, vòng ngoài 12 hoạt động tiếp theo. Chạm emoji là chấm rồi đóng.
 */
class ChamDialPickerActivity : Activity() {

    private val innerCount = 8

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.addFlags(WindowManager.LayoutParams.FLAG_BLUR_BEHIND)
            window.attributes = window.attributes.apply { blurBehindRadius = dp(18f).toInt() }
        }

        val types = ChamWidgetUpdater.topTypesForPicker(this, limit = 20)

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.argb(115, 20, 14, 11))
            setOnClickListener { close() }
        }
        setContentView(root)

        root.post { buildDial(root, types) }
    }

    private fun buildDial(root: FrameLayout, types: List<WidgetHabitItem>) {
        val itemSize = dp(46f)

        // Bán kính co theo màn hình để vòng ngoài không tràn mép
        val maxOuter = min(root.width, root.height) / 2f - itemSize / 2f - dp(10f)
        val outerR = min(dp(150f), maxOuter)
        val innerR = outerR * 0.58f
        val hasOuter = types.size > innerCount

        root.addView(RingGuide(this, innerR), FrameLayout.LayoutParams(-1, -1))
        if (hasOuter) root.addView(RingGuide(this, outerR), FrameLayout.LayoutParams(-1, -1))

        types.forEachIndexed { index, type ->
            val inner = index < innerCount
            val k = if (inner) index else index - innerCount
            val total = if (inner) min(types.size, innerCount) else types.size - innerCount
            val r = if (inner) innerR else outerR
            val offsetDeg = if (inner) 0.0 else 180.0 / total
            val angle = Math.toRadians(-90.0 + k * 360.0 / total + offsetDeg)
            val tx = (cos(angle) * r).toFloat()
            val ty = (sin(angle) * r).toFloat()

            val button = TextView(this).apply {
                text = type.emoji
                textSize = 21f
                gravity = Gravity.CENTER
                includeFontPadding = false
                background = circle(Color.parseColor("#FFFAF5"))
                elevation = dp(4f)
                contentDescription = "Chấm ${type.name}"
                scaleX = 0.3f
                scaleY = 0.3f
                alpha = 0f
                setOnClickListener { v -> logAndClose(v, type) }
            }
            // Đặt giữa bằng gravity; translation chỉ dùng để đẩy ra vị trí trên vòng
            root.addView(button, centered(itemSize))
            button.animate()
                .translationX(tx)
                .translationY(ty)
                .scaleX(1f)
                .scaleY(1f)
                .alpha(1f)
                .setStartDelay(index * 12L)
                .setDuration(320L)
                .setInterpolator(OvershootInterpolator(1.2f))
                .start()
        }

        val closeSize = dp(64f)
        val closeButton = TextView(this).apply {
            text = "✕"
            textSize = 22f
            setTextColor(Color.parseColor("#2B221D"))
            gravity = Gravity.CENTER
            background = circle(Color.parseColor("#FFFAF5"))
            elevation = dp(6f)
            contentDescription = "Đóng"
            setOnClickListener { close() }
        }
        root.addView(closeButton, centered(closeSize))
    }

    private fun centered(size: Float) =
        FrameLayout.LayoutParams(size.toInt(), size.toInt(), Gravity.CENTER)

    private fun logAndClose(view: View, type: WidgetHabitItem) {
        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        view.animate().scaleX(1.3f).scaleY(1.3f).setDuration(120L).withEndAction {
            ChamWidgetUpdater.appendQuickLog(applicationContext, type.id, type.name, type.emoji)
            close()
        }.start()
    }

    private fun close() {
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, android.R.anim.fade_out)
    }

    private fun circle(color: Int) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
    }

    private fun dp(value: Float) = value * resources.displayMetrics.density

    /** Đường tròn nét đứt mờ làm quỹ đạo cho một vòng emoji, giống vòng Dial trong app. */
    private class RingGuide(activity: Activity, private val radius: Float) : View(activity) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 1.2f * activity.resources.displayMetrics.density
            color = Color.argb(90, 255, 255, 255)
            val d = 5f * activity.resources.displayMetrics.density
            pathEffect = DashPathEffect(floatArrayOf(d, d), 0f)
        }

        override fun onDraw(canvas: android.graphics.Canvas) {
            canvas.drawCircle(width / 2f, height / 2f, radius, paint)
        }
    }
}
