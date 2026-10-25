import 'package:context_app_bar/context_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../core/default.dart';
import '../widgets/bottom_player.dart';
import '../controller/home_controller.dart';

import 'find_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

enum HomeScreenTab { find, search, library, settings }

/// 首页，浏览作品列表。
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const int maxPageIndex = 4;
  static const int protraitFlex = 6;
  static const int landscapeFlex = 5;
  static const int bottomPlayerFlex = 1;

  static Widget _screens(HomeScreenTab tab) {
    switch (tab) {
      case HomeScreenTab.find:
        return const FindScreen();
      case HomeScreenTab.search:
        return const SearchScreen();
      case HomeScreenTab.library:
        return const LibraryScreen();
      case HomeScreenTab.settings:
        return const SettingsScreen();
    }
  }

  static Bindings? _bindings(HomeScreenTab tab) {
    switch (tab) {
      case HomeScreenTab.find:
        return FindScreenBinding();
      case HomeScreenTab.search:
        return SearchScreenBinding();
      case HomeScreenTab.library:
        return LibraryScreenBinding();
      case HomeScreenTab.settings:
        return SettingsScreenBinding();
    }
  }

  static Widget _navigator(HomeScreenTab tab) {
    final key = Get.nestedKey(DefaultValues.shellNavigatorId);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        final navigator = key?.currentState;

        if (navigator != null && navigator.canPop()) {
          navigator.pop(result);
        }
      },
      child: Navigator(
        key: key,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return GetPageRoute(
              page: () => _screens(tab),
              binding: _bindings(tab),
            );
          }
          return null;
        },
      ),
    );
  }

  static Widget _responsiveBody(HomeScreenTab i) {
    return Column(
      children: [
        OrientationLayoutBuilder(
          portrait: (_) => Expanded(flex: protraitFlex, child: _navigator(i)),
          landscape: (_) => Expanded(flex: landscapeFlex, child: _navigator(i)),
        ),
        const Expanded(flex: bottomPlayerFlex, child: BottomPlayer()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: DefaultValues.onlyZero),
      child: SafeArea(
        child: Obx(() {
          final tailOfTheTab = maxPageIndex - 1;
          final tabIndex = controller.index.value.clamp(0, tailOfTheTab);
          return Scaffold(
            appBar: ContextAppBar(
              appbarSelector: controller.appbarSelector,
              children: [
                AppBar(title: const Text("发现"), key: const ValueKey("发现")),
                AppBar(title: const Text("搜索"), key: const ValueKey("搜索")),
                AppBar(title: const Text("我的"), key: const ValueKey("我的")),
                AppBar(title: const Text("设置"), key: const ValueKey("设置")),
              ],
            ),
            body: _responsiveBody(HomeScreenTab.values[tabIndex]),

            bottomNavigationBar: BottomNavigationBar(
              currentIndex: tabIndex,
              onTap: (changedIndex) {
                if (changedIndex == tabIndex) return;
                controller.change(changedIndex);
                final toTheTab =
                    HomeScreenTab.values[changedIndex.clamp(0, tailOfTheTab)];
                Get.offAll(
                  () => _screens(toTheTab),
                  binding: _bindings(toTheTab),
                  id: DefaultValues.shellNavigatorId,
                );
              },
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: '发现'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
/*
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.padding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            AppSpacing.gap(context),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
*/
