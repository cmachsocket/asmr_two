package com.cmach.asmr_two

import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

/// 主 Activity（audio_service 集成）。
///
/// 继承 [AudioServiceActivity]，让前台播放服务可以共享 FlutterEngine；
/// 同时保留系统状态栏 / 导航栏，不启用 Android 15+ 的强制 edge-to-edge。
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setDecorFitsSystemWindows(true)
    }
}
