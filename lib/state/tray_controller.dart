import 'dart:async';
import 'dart:io' show Platform, exit;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/audio/audio_player_service.dart';
import '../core/audio/playback_item.dart';
import 'player_controller.dart';
import 'settings_controller.dart';

/// 桌面端系统托盘：显示/隐藏窗口、播放控制、退出应用。
///
/// 移动端与 Web 不注册这个 controller，托盘相关代码全是 no-op。
///
/// 菜单项的点击直接打音频层 —— 不绕 [PlayerController] 的界面状态，
/// 托盘命令可能在页面销毁之后才到达。
class TrayController extends GetxController with WindowListener {
  /// TrayIcon / Menu / MenuItem **必须**持有引用，否则被 GC 时原生句柄被释放，
  /// 图标或菜单项随之消失。
  TrayIcon? _tray;
  Menu? _menu;
  MenuItem? _currentTrackItem;
  MenuItem? _playPauseItem;

  /// 窗口是否可见 —— 只用于决定菜单项文案，不参与点击分支判断。
  bool _windowVisible = true;

  bool _quitting = false;

  List<Worker> _workers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    if (!isSupportedPlatform) return;
    _initTray();
    _initWindowCloseIntercept();
    _watchPlayback();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    windowManager.removeListener(this);
    _tray?.dispose();
    _menu?.dispose();
    super.onClose();
  }

  /// 托盘只在桌面平台可用。
  static bool get isSupportedPlatform =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  // ---------------------------------------------------------------------------
  // 托盘初始化
  // ---------------------------------------------------------------------------

  Future<void> _initTray() async {
    final icon = TrayIcon.create();
    if (icon == null) {
      // Linux 上没装 AppIndicator 扩展时会这样，跳过托盘，应用主体照常工作。
      if (kDebugMode) {
        debugPrint('[TrayController] TrayIcon.create() 返回 null,跳过托盘');
      }
      return;
    }
    _tray = icon;

    final image = ImageAsset.fromAsset('assets/tray/app_icon_tray.png');
    if (image != null) {
      icon.icon = image;
    }
    icon.setTooltip('ASMR Two');

    _rebuildMenu();
    _tray!.setContextMenu(_menu!);

    icon.setContextMenuTrigger(
      Platform.isMacOS
          ? ContextMenuTrigger.rightClicked
          : ContextMenuTrigger.clicked,
    );
    icon.addListener(_onTrayIconEvent);
    icon.setVisible(true);
  }

  /// 整份重建菜单。
  ///
  /// 改菜单项文案必须重建整份菜单再重新 `setContextMenu`，只改 item.label
  /// 不一定会通知到菜单面板。
  void _rebuildMenu() {
    _currentTrackItem = null;
    _playPauseItem = null;
    _menu?.dispose();

    _menu = Menu.create();
    _buildMenuItems();
  }

  void _buildMenuItems() {
    final menu = _menu!;

    final current = MenuItem.createWithLabelAndType(
      '未在播放',
      MenuItemType.normal,
    );
    current?.isEnabled = false;
    _currentTrackItem = current;
    if (current != null) menu.addItem(current);

    menu.addSeparator();

    final showHide = MenuItem.createWithLabelAndType(
      _windowVisible ? '隐藏主窗口' : '显示主窗口',
      MenuItemType.normal,
    );
    showHide?.addListener((event) {
      if (event is MenuItemClickedEvent) {
        _toggleWindow();
      }
    });
    if (showHide != null) menu.addItem(showHide);

    menu.addSeparator();

    final previous = MenuItem.createWithLabelAndType(
      '上一首',
      MenuItemType.normal,
    );
    previous?.addListener((event) {
      if (event is MenuItemClickedEvent) {
        Get.find<AudioPlayerService>().previous();
      }
    });
    if (previous != null) menu.addItem(previous);

    final playPause = MenuItem.createWithLabelAndType(
      '播放',
      MenuItemType.normal,
    );
    playPause?.addListener((event) {
      if (event is MenuItemClickedEvent) {
        Get.find<AudioPlayerService>().togglePlay();
      }
    });
    _playPauseItem = playPause;
    if (playPause != null) menu.addItem(playPause);

    final next = MenuItem.createWithLabelAndType('下一首', MenuItemType.normal);
    next?.addListener((event) {
      if (event is MenuItemClickedEvent) {
        Get.find<AudioPlayerService>().next();
      }
    });
    if (next != null) menu.addItem(next);

    menu.addSeparator();

    final exit = MenuItem.createWithLabelAndType('退出', MenuItemType.normal);
    exit?.addListener((event) {
      if (event is MenuItemClickedEvent) {
        _quit();
      }
    });
    if (exit != null) menu.addItem(exit);
  }

  // ---------------------------------------------------------------------------
  // 播放状态 → 菜单文案
  // ---------------------------------------------------------------------------

  void _watchPlayback() {
    final player = Get.find<PlayerController>();
    _workers = [
      ever<bool>(player.isPlaying, (_) => refreshMenuLabels()),
      ever<PlaybackItem?>(player.current, (_) => refreshMenuLabels()),
    ];
    refreshMenuLabels();
  }

  /// 刷新托盘里的曲目与播放状态文案。
  void refreshMenuLabels() {
    if (_tray == null || _menu == null) return;
    final player = Get.find<PlayerController>();
    if (_currentTrackItem != null) {
      _currentTrackItem!.label = _trackLabel(player.current.value);
    }
    if (_playPauseItem != null) {
      _playPauseItem!.label = player.isPlaying.value ? '暂停' : '播放';
    }
  }

  /// 托盘里显示的曲目名：优先作品名，没有就用音频文件名。
  static String _trackLabel(PlaybackItem? item) {
    if (item == null) return '未在播放';
    final work = item.workTitle.trim();
    return work.isEmpty ? item.title.trim() : work;
  }

  // ---------------------------------------------------------------------------
  // 交互
  // ---------------------------------------------------------------------------

  void _onTrayIconEvent(TrayIconEvent event) {
    if (event is TrayIconClickedEvent || event is TrayIconDoubleClickedEvent) {
      _toggleWindow();
    }
  }

  /// 显隐判断现查原生真值，不用本地缓存：标题栏 X、任务栏最小化都不保证
  /// 发 focus/blur 事件，缓存会失真。
  Future<void> _toggleWindow() async {
    try {
      final visible = await windowManager.isVisible();
      if (visible) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
      _syncWindowState(!visible);
    } catch (e) {
      if (kDebugMode) debugPrint('[TrayController] toggleWindow 失败: $e');
    }
  }

  void _syncWindowState(bool visible) {
    _windowVisible = visible;
    if (_tray == null || _menu == null) return;
    _rebuildMenu();
    _tray!.setContextMenu(_menu!);
  }

  void _quit() {
    if (_quitting) return;
    _quitting = true;
    // 先释放音频资源，再销毁窗口：窗口一销毁引擎就拆 Dart VM，
    // 正在播的曲目会让工作线程跳进已释放内存。
    unawaited(_quitSafely());
  }

  Future<void> _quitSafely() async {
    try {
      if (Get.isRegistered<AudioPlayerService>()) {
        await Get.delete<AudioPlayerService>(force: true);
      }
      await windowManager.destroy();
    } finally {
      exit(0);
    }
  }

  // ---------------------------------------------------------------------------
  // 窗口关闭
  // ---------------------------------------------------------------------------

  /// 拦截标题栏的关闭按钮，所有桌面平台都要拦：窗口销毁会拆掉 Dart VM。
  Future<void> _initWindowCloseIntercept() async {
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  /// 设置页「窗口退出按钮」打开后，Linux/Windows 点 X 也隐藏到托盘。
  ///
  /// 现查 [SettingsController]，不缓存 —— 用户改完开关下一次点 X 就生效。
  bool get _exitToTrayEnabled =>
      Get.isRegistered<SettingsController>() &&
      Get.find<SettingsController>().exitToTray.value;

  @override
  void onWindowClose() {
    if (Platform.isMacOS || _exitToTrayEnabled) {
      // macOS 点 X → 隐藏到托盘（历史行为，不受开关影响）
      unawaited(windowManager.hide());
      _syncWindowState(false);
      return;
    }
    _quit();
  }

  @override
  void onWindowFocus() {
    unawaited(_refreshWindowState());
  }

  @override
  void onWindowBlur() {
    unawaited(_refreshWindowState());
  }

  @override
  void onWindowMinimize() {
    unawaited(_refreshWindowState());
  }

  @override
  void onWindowRestore() {
    unawaited(_refreshWindowState());
  }

  /// 从原生窗口读一次可见性并同步菜单文案。
  ///
  /// focus/blur/minimize 只表示焦点或图标状态变了，**不等于**窗口被隐藏，
  /// 所以这些回调里不能直接推断可见性。
  Future<void> _refreshWindowState() async {
    try {
      _syncWindowState(await windowManager.isVisible());
    } catch (e) {
      if (kDebugMode) debugPrint('[TrayController] 刷新窗口状态失败: $e');
    }
  }
}
