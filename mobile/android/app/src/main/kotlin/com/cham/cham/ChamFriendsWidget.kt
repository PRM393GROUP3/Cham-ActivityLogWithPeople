package com.cham.cham

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

data class FriendActivityItem(
    val shareId: String,
    val name: String,
    val avatar: String?,
    val emoji: String,
    val activity: String,
    val occurredAt: Instant,
    val myReaction: String?
) {
    val loved: Boolean get() = myReaction == ChamFriendsStore.LOVE
}

/**
 * Dữ liệu cho Widget 4×2 "Bạn bè". App (Flutter) ghi bản chụp mỗi lần tải feed; widget chỉ đọc.
 * Thả tim trên widget được ghi vào hàng chờ, app gửi lên server ở lần mở tiếp theo.
 */
object ChamFriendsStore {
    const val LOVE = "❤️"

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_FRIENDS = "flutter.cham_widget_friends_v1"
    private const val KEY_PENDING = "flutter.cham_widget_pending_reactions_v1"

    /** Lâu hơn mốc này chưa đồng bộ thì báo dữ liệu cũ. */
    private val STALE_AFTER: Duration = Duration.ofMinutes(30)
    private val VN_ZONE: ZoneId = ZoneId.of("Asia/Ho_Chi_Minh")
    private val HM = DateTimeFormatter.ofPattern("HH:mm")

    data class Snapshot(val syncedAt: Instant?, val items: List<FriendActivityItem>)

    fun load(context: Context): Snapshot {
        val raw = prefs(context).getString(KEY_FRIENDS, null) ?: return Snapshot(null, emptyList())
        return try {
            val root = JSONObject(raw)
            val syncedAt = Instant.parse(root.getString("syncedAt"))
            val arr = root.getJSONArray("items")
            val items = (0 until arr.length()).mapNotNull { i ->
                val o = arr.optJSONObject(i) ?: return@mapNotNull null
                try {
                    FriendActivityItem(
                        shareId = o.getString("shareId"),
                        name = o.getString("name"),
                        avatar = o.optString("avatar").ifEmpty { null },
                        emoji = o.getString("emoji"),
                        activity = o.getString("activity"),
                        occurredAt = Instant.parse(o.getString("occurredAt")),
                        myReaction = o.optString("myReaction").ifEmpty { null }
                    )
                } catch (_: Exception) {
                    null
                }
            }
            Snapshot(syncedAt, items)
        } catch (_: Exception) {
            Snapshot(null, emptyList())
        }
    }

    /**
     * Bật / tắt tim cho một bài: đổi ngay trong bản chụp để widget hiện đúng, và ghi vào hàng chờ
     * (`""` = gỡ cảm xúc). Trả về `true` nếu vừa thả tim.
     */
    fun toggleLove(context: Context, shareId: String): Boolean {
        val prefs = prefs(context)
        val raw = prefs.getString(KEY_FRIENDS, null) ?: return false
        val root = JSONObject(raw)
        val arr = root.getJSONArray("items")
        var nowLoved = false
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            if (o.optString("shareId") != shareId) continue
            nowLoved = o.optString("myReaction") != LOVE
            o.put("myReaction", if (nowLoved) LOVE else "")
        }
        val pending = try {
            JSONObject(prefs.getString(KEY_PENDING, null) ?: "{}")
        } catch (_: Exception) {
            JSONObject()
        }
        pending.put(shareId, if (nowLoved) LOVE else "")
        prefs.edit()
            .putString(KEY_FRIENDS, root.toString())
            .putString(KEY_PENDING, pending.toString())
            .commit()
        return nowLoved
    }

    fun isStale(syncedAt: Instant): Boolean = Duration.between(syncedAt, Instant.now()) > STALE_AFTER

    fun hm(t: Instant): String = HM.format(t.atZone(VN_ZONE))

    /** "vừa xong", "5 phút", "2 giờ". */
    fun ago(t: Instant): String {
        val minutes = Duration.between(t, Instant.now()).toMinutes()
        return when {
            minutes < 1 -> "vừa xong"
            minutes < 60 -> "$minutes phút"
            else -> "${minutes / 60} giờ"
        }
    }

    fun notifyListChanged(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, ChamMediumWidgetProvider::class.java))
        manager.notifyAppWidgetViewDataChanged(ids, R.id.medium_list)
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}

/** Cấp các dòng cho danh sách cuộn của Widget 4×2. */
class ChamFriendsWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
        private var items: List<FriendActivityItem> = emptyList()

        override fun onCreate() {}

        override fun onDataSetChanged() {
            items = ChamFriendsStore.load(context).items
        }

        override fun onDestroy() {}

        /** Các dòng bạn bè, cộng một dòng cuối "Xem tất cả trong app". */
        override fun getCount(): Int = if (items.isEmpty()) 0 else items.size + 1

        override fun getViewAt(position: Int): RemoteViews {
            if (position >= items.size) {
                return RemoteViews(context.packageName, R.layout.cham_friend_footer).apply {
                    setOnClickFillInIntent(R.id.footer_root, actionIntent(ChamWidgetActionActivity.KIND_ALL, null))
                }
            }
            val item = items[position]
            return RemoteViews(context.packageName, R.layout.cham_friend_row).apply {
                setTextViewText(R.id.row_avatar, item.avatar ?: item.name.take(1).uppercase())
                setTextViewText(R.id.row_badge, item.emoji)
                setTextViewText(R.id.row_name, item.name)
                setTextViewText(R.id.row_act, item.activity)
                setTextViewText(R.id.row_ago, ChamFriendsStore.ago(item.occurredAt))
                setContentDescription(R.id.row_root, "${item.name} ${item.activity}, ${ChamFriendsStore.ago(item.occurredAt)} trước")

                setTextViewText(R.id.row_heart, if (item.loved) ChamFriendsStore.LOVE else "♡")
                setTextColor(R.id.row_heart, Color.parseColor(if (item.loved) "#E5484D" else "#857469"))
                setInt(R.id.row_heart, "setBackgroundResource", if (item.loved) R.drawable.widget_heart_on_bg else 0)
                setContentDescription(R.id.row_heart, if (item.loved) "Gỡ tim cho ${item.name}" else "Thả tim cho ${item.name}")

                setOnClickFillInIntent(R.id.row_root, actionIntent(ChamWidgetActionActivity.KIND_OPEN, item))
                setOnClickFillInIntent(R.id.row_heart, actionIntent(ChamWidgetActionActivity.KIND_HEART, item))
            }
        }

        private fun actionIntent(kind: String, item: FriendActivityItem?) = Intent().apply {
            putExtra(ChamWidgetActionActivity.EXTRA_KIND, kind)
            if (item != null) {
                putExtra(ChamWidgetActionActivity.EXTRA_SHARE_ID, item.shareId)
                putExtra(ChamWidgetActionActivity.EXTRA_NAME, item.name)
            }
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 2

        override fun getItemId(position: Int): Long =
            items.getOrNull(position)?.shareId?.hashCode()?.toLong() ?: -1L

        override fun hasStableIds(): Boolean = true
    }
}
