package com.cham.cham

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * Nhận thao tác từ các dòng trong danh sách của Widget 4×2 rồi đóng ngay, không hiện gì:
 * thả / gỡ tim, mở app, hoặc xem tất cả.
 */
class ChamWidgetActionActivity : Activity() {
    companion object {
        const val EXTRA_KIND = "extra_widget_action_kind"
        const val EXTRA_SHARE_ID = "extra_widget_share_id"
        const val EXTRA_NAME = "extra_widget_friend_name"
        const val KIND_OPEN = "open"
        const val KIND_HEART = "heart"
        const val KIND_ALL = "all"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent.getStringExtra(EXTRA_KIND)) {
            KIND_HEART -> {
                val shareId = intent.getStringExtra(EXTRA_SHARE_ID)
                if (shareId != null) {
                    val loved = ChamFriendsStore.toggleLove(this, shareId)
                    ChamFriendsStore.notifyListChanged(this)
                    if (loved) {
                        val name = intent.getStringExtra(EXTRA_NAME).orEmpty()
                        Toast.makeText(applicationContext, "${ChamFriendsStore.LOVE} Đã thả tim cho $name", Toast.LENGTH_SHORT).show()
                    }
                }
            }
            else -> startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            )
        }
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
