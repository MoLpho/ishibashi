import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/reservation.dart';

/// 右側に表示する「当月の予約一覧」ウィジェット。
/// 親から渡された予約リストを縦に並べて表示する。
class MonthReservationList extends StatelessWidget {
  const MonthReservationList({
    super.key,
    required this.items,
    this.width = 320,
  });

  final List<AdminReservation> items;
  /// サイドパネルの幅（iPad向けに可変）
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('M/d(E)'); // 例: 9/12(木)
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dateOnly(DateTime.now());
    // 当日以降の予約のみ表示
    final visible = items.where((r) => dateOnly(r.start).isAtSameMomentAs(today) || dateOnly(r.start).isAfter(today)).toList();
    return Container(
      width: width, // 可変幅に対応
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // 背景色
        border: Border(left: BorderSide(color: theme.dividerColor)), // 左に区切り線
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('予約リスト', style: theme.textTheme.titleMedium), // セクションタイトル
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('この月の予約はありません')) // 空状態
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = visible[i];
                      final d = dateOnly(r.start);
                      final diffDays = d.difference(today).inDays;
                      Color borderColor;
                      if (diffDays == 0) {
                        borderColor = Colors.orange; // 当日
                      } else if (diffDays == 1) {
                        borderColor = Colors.lightBlue.shade700; // 翌日（濃い目の水色）
                      } else {
                        borderColor = Colors.green; // それ以降
                      }
                      return ListTile(
                        dense: true, // 行の高さを詰める
                        title: Text(r.customerName, maxLines: 1, overflow: TextOverflow.ellipsis), // 氏名
                        subtitle: Text('${df.format(r.start)}  ${r.timeRange}'), // 日付 + 時間帯
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface, // 背景はそのまま
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 2), // 条件に応じた枠線
                          ),
                          child: Text(
                            r.status.label, // 表示は従来通り
                            style: TextStyle(color: borderColor, fontSize: 12), // 枠線色と統一
                          ),
                        ),
                        onTap: () {
                          // TODO: 詳細画面へ遷移（API実装後）
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

