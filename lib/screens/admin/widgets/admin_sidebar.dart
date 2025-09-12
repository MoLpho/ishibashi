import 'package:flutter/material.dart';

// 管理者画面で使用するタブの種別
// - reservations: 予約管理タブ
// - settings    : 設定タブ
enum AdminTab { reservations, settings }

/// 左側に固定表示するサイドバーウィジェット。
/// 現在選択中のタブを強調表示し、タップでタブ切り替えイベントを親へ通知します。
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.current,
    required this.onChanged,
    this.width = 220,
  });

  /// 現在選択中のタブ
  final AdminTab current;
  /// タブ変更時のコールバック（親の状態を更新するため）
  final ValueChanged<AdminTab> onChanged;
  /// サイドバーの幅（iPad想定でやや広め）
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width, // レイアウトに応じて調整可能
      color: theme.colorScheme.surface, // テーマのサーフェス色で背景を塗る
      child: Column(
        children: [
          const SizedBox(height: 24),
          // 予約管理ボタン
          _SidebarButton(
            icon: Icons.calendar_month,
            label: '予約管理',
            selected: current == AdminTab.reservations,
            onTap: () => onChanged(AdminTab.reservations),
          ),
          const SizedBox(height: 16),
          // 設定ボタン
          _SidebarButton(
            icon: Icons.settings,
            label: '設定',
            selected: current == AdminTab.settings,
            onTap: () => onChanged(AdminTab.settings),
          ),
          const Spacer(), // 余白を下に押しやるためのスペーサー
        ],
      ),
    );
  }
}

/// サイドバー内で使う共通のボタン部品。
/// 選択状態に応じて枠線の色/太さを切り替えます。
class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12), // サイドの左右余白
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Ripple用の角丸指定
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // ボタン内余白
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor, // 選択時は強調色
              width: selected ? 2 : 1, // 選択時は太く
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.onSurface), // アイコン
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label, // ボタンラベル
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

