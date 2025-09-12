import 'package:flutter/material.dart';

import 'widgets/admin_sidebar.dart';
import 'reservations/admin_reservations_screen.dart';
import 'settings/admin_settings_screen.dart';

/// 管理者用の共通レイアウト（シェル）。
/// 左にサイドバー、右に選択されたタブの中身を表示します。
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  /// 現在選択中のタブ（初期値は予約管理）
  AdminTab _tab = AdminTab.reservations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者コンソール'), // 画面上部のタイトル
        actions: [
          // コンパクト時のタブ切替ショートカット（iPhone想定）
          IconButton(
            tooltip: '予約管理',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => setState(() => _tab = AdminTab.reservations),
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => _tab = AdminTab.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // iPad想定の自動レイアウト幅
            final maxW = constraints.maxWidth;
            final isCompact = maxW < 600; // おおよその電話縦基準
            final sidebarW = maxW.isFinite
                ? (maxW * 0.18).clamp(220.0, 280.0)
                : 240.0;
            final rightPanelW = maxW.isFinite
                ? (maxW * 0.28).clamp(300.0, 360.0)
                : 320.0;

            if (isCompact) {
              // スマホ縦向け: サイドバーを隠し、コンテンツのみ表示
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildMobileTab(_tab, theme),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 高さを揃える
              children: [
                // 左側のサイドバー。選択状態と変更イベントを渡す
                AdminSidebar(
                  current: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                  width: sidebarW,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200), // タブ切替時のフェードアニメーション
                    child: _buildTabWithRightWidth(_tab, theme, rightPanelW), // タブごとの中身を構築
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 右サイドの幅を渡す版（予約タブで使用）
  Widget _buildTabWithRightWidth(AdminTab tab, ThemeData theme, double rightWidth) {
    switch (tab) {
      case AdminTab.reservations:
        return AdminReservationsScreen(rightPanelWidth: rightWidth);
      case AdminTab.settings:
        return const AdminSettingsScreen();
    }
  }

  /// モバイル（縦）用のタブ内容
  Widget _buildMobileTab(AdminTab tab, ThemeData theme) {
    switch (tab) {
      case AdminTab.reservations:
        return const AdminReservationsScreen(compact: true);
      case AdminTab.settings:
        return const AdminSettingsScreen();
    }
  }
}

