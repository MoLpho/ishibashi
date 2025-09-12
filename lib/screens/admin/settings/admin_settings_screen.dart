import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../utils/api/api_client.dart';
import '../../../utils/api/settings_api.dart';

/// 設定タブ本体（営業時間・定休日（曜日）・臨時休業日）
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final SettingsApi _api;
  bool _loading = true;

  // 営業時間（0=Mon..6=Sun）
  final Map<int, TimeOfDay> _open = {};
  final Map<int, TimeOfDay> _close = {};

  // 週次の定休日チェック（0..6）
  final Set<int> _weeklyClosed = {};
  // 現在有効な定休日ルールID（weekday -> ruleId）
  final Map<int, int> _ruleIdByWeekday = {};

  // 臨時休業モーダル用
  DateTime _focused = DateTime.now();
  List<HolidayItem> _monthHolidays = [];

  @override
  void initState() {
    super.initState();
    _api = SettingsApi(ApiClient());
    // 先にデフォルト営業時間を入れておく（API失敗時でもUIが壊れないように）
    for (int d = 0; d < 7; d++) {
      _open.putIfAbsent(d, () => const TimeOfDay(hour: 9, minute: 0));
      _close.putIfAbsent(d, () => const TimeOfDay(hour: 18, minute: 0));
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 営業時間
      final bhs = await _api.listBusinessHours();
      for (final bh in bhs) {
        _open[bh.weekday] = _parseTod(bh.openTime);
        _close[bh.weekday] = _parseTod(bh.closeTime);
      }
      for (int d = 0; d < 7; d++) {
        _open.putIfAbsent(d, () => const TimeOfDay(hour: 9, minute: 0));
        _close.putIfAbsent(d, () => const TimeOfDay(hour: 18, minute: 0));
      }
      // 週次定休日
      final rules = await _api.listWeeklyHolidayRules();
      _weeklyClosed
        ..clear()
        ..addAll(rules.where((r) => r.active).map((r) => r.weekday));
      _ruleIdByWeekday
        ..clear()
        ..addEntries(rules.where((r) => r.active).map((r) => MapEntry(r.weekday, r.id)));
    } catch (e) {
      // 初期ロード失敗時もUIへ復帰
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay _parseTod(String hhmmss) {
    final sp = hhmmss.split(":");
    return TimeOfDay(hour: int.tryParse(sp[0]) ?? 0, minute: int.tryParse(sp[1]) ?? 0);
  }

  String _fmtHMS(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pick(int weekday, bool isOpen) async {
    final init = isOpen
        ? (_open[weekday] ?? const TimeOfDay(hour: 9, minute: 0))
        : (_close[weekday] ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _open[weekday] = picked;
        } else {
          _close[weekday] = picked;
        }
      });
    }
  }

  Future<void> _apply() async {
    // 営業時間の保存（7日分） + 週次定休日の差分適用
    try {
      for (int d = 0; d < 7; d++) {
        final o = _open[d]!;
        final c = _close[d]!;
        if (o.hour > c.hour || (o.hour == c.hour && o.minute >= c.minute)) {
          throw Exception('曜日${d}の営業時間: 開始が終了より後です');
        }
        await _api.upsertBusinessHour(
          BusinessHoursItem(weekday: d, openTime: _fmtHMS(o), closeTime: _fmtHMS(c)),
        );
      }

      final current = _ruleIdByWeekday.keys.toSet();
      final desired = _weeklyClosed;
      for (final d in desired.difference(current)) {
        final created = await _api.createWeeklyHolidayRule(weekday: d, name: '定休日');
        _ruleIdByWeekday[d] = created.id;
      }
      for (final d in current.difference(desired)) {
        final id = _ruleIdByWeekday[d];
        if (id != null) await _api.deactivateWeeklyHolidayRule(id);
        _ruleIdByWeekday.remove(d);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    }
  }

  Future<void> _openHolidayModal() async {
    DateTime selectedDay = DateTime(_focused.year, _focused.month, _focused.day);
    Future<void> loadMonth() async {
      final first = DateTime(_focused.year, _focused.month, 1);
      final last = DateTime(_focused.year, _focused.month + 1, 0);
      _monthHolidays = await _api.listHolidays(first, last);
    }

    await loadMonth();
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setStateDialog) {
        Future<void> addHoliday(DateTime d) async {
          try {
            await _api.createHoliday(d);
            await loadMonth();
            setStateDialog(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('追加に失敗: $e')));
          }
        }

        Future<void> deleteHoliday(int id) async {
          try {
            await _api.deleteHoliday(id);
            await loadMonth();
            setStateDialog(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除に失敗: $e')));
          }
        }

        final modalWidth = (MediaQuery.of(context).size.width * 0.9).clamp(320.0, 560.0);

        return AlertDialog(
          title: const Text('臨時休業日の設定'),
          content: SizedBox(
            width: modalWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // 高さを画面の80%以内に抑えてスクロール可能にする
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focused,
                      selectedDayPredicate: (d) => isSameDay(d, selectedDay),
                      onDaySelected: (sel, foc) {
                        setStateDialog(() {
                          selectedDay = sel;
                          _focused = foc;
                        });
                      },
                      onPageChanged: (foc) async {
                        _focused = foc;
                        await loadMonth();
                        setStateDialog(() {});
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(formatButtonVisible: false),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => addHoliday(selectedDay),
                          child: const Text('この日を臨時休業に追加'),
                        ),
                        const Text('（既存一覧から削除も可能）'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _monthHolidays
                            .map((h) => ListTile(
                                  leading: const Icon(Icons.event_busy),
                                  title: Text('${h.date.year}/${h.date.month}/${h.date.day}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => deleteHoliday(h.id),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 画面ヘッダー（右上に適用ボタン）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('設定', style: theme.textTheme.titleLarge),
              const Spacer(),
              FilledButton(onPressed: _apply, child: const Text('適用')),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('営業時間', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildBusinessHoursTable(),
                      const SizedBox(height: 16),
                      Text('定休日（曜日）', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildWeeklyHolidays(),
                      const SizedBox(height: 16),
                      Text('臨時休業日', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _openHolidayModal,
                        child: const Text('臨時休業日を設定'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBusinessHoursTable() {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return Column(
      children: List.generate(7, (i) {
        final open = _open[i] ?? const TimeOfDay(hour: 9, minute: 0);
        final close = _close[i] ?? const TimeOfDay(hour: 18, minute: 0);
        return Card(
          child: ListTile(
            title: Text('曜日: ${weekdays[i]}'),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _pick(i, true),
                  child: Text('開始 ${open.format(context)}'),
                ),
                OutlinedButton(
                  onPressed: () => _pick(i, false),
                  child: Text('終了 ${close.format(context)}'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWeeklyHolidays() {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final checked = _weeklyClosed.contains(i);
        return FilterChip(
          label: Text(weekdays[i]),
          selected: checked,
          onSelected: (v) {
            setState(() {
              if (v) {
                _weeklyClosed.add(i);
              } else {
                _weeklyClosed.remove(i);
              }
            });
          },
        );
      }),
    );
  }
}
