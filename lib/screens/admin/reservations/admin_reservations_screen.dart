import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../utils/validators.dart';
import 'data/admin_reservation_repository.dart';
import 'data/reservation.dart';
import 'widgets/month_reservation_list.dart';

/// 管理者用の「予約管理」画面。
/// 画面中央に月間カレンダー、右側に当月の予約一覧を表示する。
class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({
    super.key,
    this.rightPanelWidth = 320,
    this.compact = false,
  });

  /// 右側の予約リストパネル幅（iPad対応のため可変）
  final double rightPanelWidth;
  /// コンパクト表示（スマホ縦向け）: カレンダーの下に予約リストを縦積み
  final bool compact;

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  /// データ取得（バックエンドAPI利用）
  final _repo = AdminReservationRepository.defaultClient();

  /// カレンダーのフォーカス中の月（1日固定）
  DateTime _focusedDay = DateTime.now();
  /// カレンダーで選択中の日付
  DateTime _selectedDay = DateTime.now();
  /// 当月の予約一覧（右ペインに表示）
  List<AdminReservation> _monthly = const [];
  /// ローディング表示制御
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, 1); // 月初に正規化
    _selectedDay = _focusedDay;
    _load();
  }

  /// 当月の予約一覧を読み込む
  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.fetchMonthly(_focusedDay);
    if (!mounted) return;
    setState(() {
      _monthly = data;
      _loading = false;
    });
  }

  List<AdminReservation> _reservationsFor(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _monthly.where((r) => r.dateOnly == d).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> _openEditModal(AdminReservation r) async {
    final nameCtrl = TextEditingController(text: r.customerName);
    final numPeopleCtrl = TextEditingController(text: r.numPeople.toString());
    final noteCtrl = TextEditingController(text: r.note ?? '');
    TimeOfDay st = TimeOfDay(hour: r.start.hour, minute: r.start.minute);
    TimeOfDay en = TimeOfDay(hour: r.end.hour, minute: r.end.minute);
    ReservationStatus status = r.status;

    Future<TimeOfDay?> pick(TimeOfDay init) => showTimePicker(
          context: context,
          initialTime: init,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Row(
              children: [
                const Text('予約の編集'),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    // 適用
                    final updated = AdminReservation(
                      id: r.id,
                      customerName: nameCtrl.text.trim().isEmpty ? r.customerName : nameCtrl.text.trim(),
                      start: DateTime(r.start.year, r.start.month, r.start.day, st.hour, st.minute),
                      end: DateTime(r.end.year, r.end.month, r.end.day, en.hour, en.minute),
                      status: status,
                      numPeople: int.tryParse(numPeopleCtrl.text) ?? 1,
                      note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
                    );
                    try {
                      await _repo.update(updated);
                      if (!mounted) return;
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('更新に失敗しました: $e')),
                      );
                    }
                  },
                  child: const Text('適用'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '代表者名'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await pick(st);
                          if (t != null) setStateDialog(() => st = t);
                        },
                        child: Text('開始 ${st.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await pick(en);
                          if (t != null) setStateDialog(() => en = t);
                        },
                        child: Text('終了 ${en.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numPeopleCtrl,
                  decoration: const InputDecoration(labelText: '人数'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.intInRange(v, min: 1, max: 20),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: '備考'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReservationStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'ステータス'),
                  items: ReservationStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => status = v ?? status),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('閉じる'),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('予約の取り消し'),
                      content: const Text('この予約を取り消しますか？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('取り消す')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await _repo.delete(r.id);
                      if (!mounted) return;
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('取り消しに失敗しました: $e')),
                      );
                    }
                  }
                },
                child: const Text('予約の取り消し'),
              ),
            ],
          );
        });
      },
    );

    if (ok == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // スマホ縦向け: カレンダー -> 予約リスト の縦積み
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(child: _buildCalendar(context)),
          _buildSelectedDayDetailsSection(),
          const Divider(height: 1),
          SizedBox(
            height: 280,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : MonthReservationList(items: _monthly, width: double.infinity),
          ),
        ],
      );
    }

    // タブレット/デスクトップ: 左カレンダー・右リスト
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              // 上部ヘッダー（年月と月送りボタン）
              _buildHeader(context),
              const Divider(height: 1),
              Expanded(
                child: _buildCalendar(context),
              ),
              _buildSelectedDayDetailsSection(),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: widget.rightPanelWidth, // 右側の予約リスト領域の幅（可変）
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : MonthReservationList(items: _monthly, width: widget.rightPanelWidth),
        ),
      ],
    );
  }

  /// ヘッダー（年月表示と月移動ボタン）
  Widget _buildHeader(BuildContext context) {
    final title = '${_focusedDay.year}年${_focusedDay.month}月';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1); // 前月へ
              });
              _load();
            },
          ),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1); // 次月へ
              });
              _load();
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// 月間カレンダー（TableCalendar）
  Widget _buildCalendar(BuildContext context) {
    return TableCalendar<AdminReservation>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      locale: 'ja_JP',
      startingDayOfWeek: StartingDayOfWeek.sunday, // 日曜始まり
      calendarFormat: CalendarFormat.month,
      // 縦方向の見やすさを上げるためにセルの高さを拡大
      rowHeight: 56,
      daysOfWeekHeight: 28,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day); // 時刻を落として選択
          _focusedDay = focusedDay; // 内部でページ遷移時に与えられるフォーカス日
        });
      },
      onPageChanged: (focused) {
        setState(() => _focusedDay = DateTime(focused.year, focused.month, 1)); // 月替わり検知
        _load();
      },
      headerVisible: false, // ヘッダーは自前実装のため非表示
      eventLoader: (day) {
        // 同日の予約を返す（ドットの数＝予約件数）
        return _monthly.where((r) => r.dateOnly == DateTime(day.year, day.month, day.day)).toList();
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(events.length.clamp(0, 3), (i) {
                final AdminReservation r = events[i]; // ステータス色で小さな丸を表示
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(Icons.circle, size: 6, color: r.status.color),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  /// 選択した日付の予約詳細一覧（カレンダー直下に表示）
  Widget _buildSelectedDayDetailsSection() {
    final items = _reservationsFor(_selectedDay);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_selectedDay.year}/${_selectedDay.month}/${_selectedDay.day} の予約',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...items.map((r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                child: ListTile(
                  title: Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.timeRange),
                      const SizedBox(height: 4),
                      Text('人数: ${r.numPeople}名', style: Theme.of(context).textTheme.bodySmall),
                      if (r.note?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          '備考: ${r.note}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: r.note?.isNotEmpty == true,
                  trailing: FilledButton.tonal(
                    onPressed: () => _openEditModal(r),
                    child: const Text('編集'),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}