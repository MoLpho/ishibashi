import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../utils/api/api_client.dart';
import '../../../utils/api/holiday_api.dart';
import '../../../utils/api/reservation_api.dart';
import '../../../utils/api/settings_api.dart';
import '../form/reservation_free_form_sheet.dart';
import '../confirm/confirm_free_screen.dart';

class ReservationCalendarScreen extends StatefulWidget { 
  const ReservationCalendarScreen({super.key});
  @override
  State<ReservationCalendarScreen> createState() => _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends State<ReservationCalendarScreen> {
  
  // API クライアント
  final _client = ApiClient();
  // API クライアントの初期化
  late final ReservationApi _resApi = ReservationApi(_client);// 予約APIクライアント
  late final HolidayApi _holApi = HolidayApi(_client);// 休業日APIクライアント
  late final SettingsApi _setApi = SettingsApi(_client);// 営業時間APIクライアント

  late DateTime _focusedDay;// カレンダーで現在表示している月の基準日
  late DateTime _selectedDay;// カレンダーで選択されている日

  // 休業日集合
  Set<DateTime> _closed = {};
  // 月内の予約イベント（日付ごとに生の時間帯で扱う）
  Map<DateTime, List<EventItem>> _eventsByDate = {};

  // 曜日ごとの営業時間（0=Mon..6=Sun）
  final Map<int, ({TimeOfDay open, TimeOfDay close})> _businessHours = {};

  // 旧スロットUIは廃止。自由時間選択へ移行。

  @override
  void initState() {
    super.initState(); 
    _focusedDay = _dateOnly(DateTime.now()); 
    _selectedDay = _focusedDay; //
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth(_focusedDay)); // 初期表示月のデータを取得
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);// 時刻を切り捨てて日付のみに変換

  //データを取得して状態を更新する関数
  Future<void> _loadMonth(DateTime focused) async {
    final from = DateTime(focused.year, focused.month, 1);// 月初
    final to   = DateTime(focused.year, focused.month + 1, 0);// 月末(翌月の0日)
    // APIからデータを取得
    try {
      final events   = await _resApi.listEvents(from, to);// 予約済み一覧
      final holidays = await _holApi.listHolidays(from, to); // 休業日一覧
      final weekly   = await _holApi.listWeeklyOccurrences(from, to); // 毎週休業日一覧
      // 営業時間（初回のみ取得して保持）
      if (_businessHours.isEmpty) {
        final bhs = await _setApi.listBusinessHours();
        for (final bh in bhs) {
          _businessHours[bh.weekday] = (
            open: _parseTod(bh.openTime),
            close: _parseTod(bh.closeTime),
          );
        }
        // デフォルト（万一不足があれば）
        for (int d = 0; d < 7; d++) {
          _businessHours.putIfAbsent(d, () => (open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0)));
        }
      }

      // 日付→イベントリスト へ変換
      final byDate = <DateTime, List<EventItem>>{};
      for (final e in events) {
        final d = _dateOnly(e.date);
        byDate.putIfAbsent(d, () => <EventItem>[]).add(e);
      }

      // 状態を更新
      setState(() {
        _eventsByDate = byDate; // 日ごとの予約（自由時間計算用）
        _closed = {...holidays, ...weekly}; // 休業日セット
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データ取得に失敗しました：$e')),// エラーメッセージを表示
      );
    }
  }

  // 休業日かどうか判定
  bool _isClosed(DateTime d) => _closed.contains(_dateOnly(d));

  // 予約のある/なし
  bool _hasReservations(DateTime d) => (_eventsByDate[_dateOnly(d)]?.isNotEmpty ?? false);

  // 営業時間の範囲を分で取得
  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  ({TimeOfDay open, TimeOfDay close}) _bhOf(DateTime d) =>
      _businessHours[d.weekday] ?? (open: const TimeOfDay(hour: 9, minute: 0), close: const TimeOfDay(hour: 18, minute: 0));

  // 指定日の自由時間（分）を算出（営業時間内で既存予約を差し引き）
  int _freeMinutes(DateTime d) {
    final day = _dateOnly(d);
    if (_isClosed(day)) return 0;
    final bh = _bhOf(day);
    final open = _toMinutes(bh.open);
    final close = _toMinutes(bh.close);
    int busy = 0;
    final evts = [...?_eventsByDate[day]];
    // 時間帯を結合（単純に和をとる前に重複をまとめる）
    evts.sort((a, b) => a.startTime.compareTo(b.startTime));
    int? curS; int? curE;
    int clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
    for (final e in evts) {
      final s = clamp(_hhmmssToMin(e.startTime), open, close);
      final eMin = clamp(_hhmmssToMin(e.endTime), open, close);
      if (eMin <= s) continue;
      if (curS == null || curE == null) {
        curS = s; curE = eMin;
      } else if (s <= curE) {
        curE = eMin > curE ? eMin : curE; // 結合
      } else {
        busy += (curE - curS);
        curS = s; curE = eMin;
      }
    }
    if (curS != null && curE != null) busy += (curE - curS);
    final total = (close - open);
    final free = total - busy;
    return free < 0 ? 0 : free;
  }

  int _hhmmssToMin(String hhmmss) {
    final sp = hhmmss.split(':');
    final h = int.tryParse(sp[0]) ?? 0;
    final m = int.tryParse(sp[1]) ?? 0;
    return h * 60 + m;
  }

  TimeOfDay _parseTod(String s) {
    final sp = s.split(':');
    return TimeOfDay(hour: int.tryParse(sp[0]) ?? 0, minute: int.tryParse(sp[1]) ?? 0);
  }

  // 旧スロット用のヘルパーは削除（自由時間計算に移行）

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy年M月d日(E)');
    final eventsToday = _eventsByDate[_dateOnly(_selectedDay)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('レンタルルーム予約')),
      body: Column(
        children: [
          // カレンダーの設定
          TableCalendar(
            locale: 'ja_JP',// 日本語に設定
            firstDay: DateTime.utc(2020, 1, 1),// 過去の日付の範囲設定
            lastDay: DateTime.utc(2035, 12, 31), // 未来の日付の範囲設定 DBのデータに合わせる
            focusedDay: _focusedDay, // 現在表示している月の基準日
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay), // 選択されている日をハイライト
            // 日付選択時の処理 選択された日と表示中の月を更新
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = _dateOnly(selectedDay);
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focused) {
              // ページ移動時に現在のfocusedDayを更新してから、その月のデータを取得
              setState(() {
                _focusedDay = _dateOnly(focused);
              });
              _loadMonth(focused);
            }, // 月が変わったときにデータを再取得
            calendarFormat: CalendarFormat.month,      // 月表示にフォーマット指定
            availableCalendarFormats: const {CalendarFormat.month: '月'}, 
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            enabledDayPredicate: (day) => !_isClosed(day), // 休業日は選択不可にする
            // 日付セルのカスタマイズ設定（自由時間に基づく色分け）
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final d = _dateOnly(day);
                final base = Center(child: Text('${day.day}'));
                if (_isClosed(d)) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFFFE5E5), shape: BoxShape.rectangle),
                    child: base,
                  );
                }
                final hasRes = _hasReservations(d);
                if (!hasRes) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFE6F4EA)), // 緑系（予約なし）
                    child: base,
                  );
                }
                final free = _freeMinutes(d);
                if (free >= 360) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFFFF4E0)), // オレンジ系（>=6h 空き）
                    child: base,
                  );
                }
                if (free <= 120) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFFFE6E6)), // 赤系（<=2h 空き）
                    child: base,
                  );
                }
                return base;
              },
            ),
          ),
          const Divider(height: 1),
          // 選択された日の情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text("${df.format(_selectedDay)} の状況",
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_isClosed(_selectedDay))
                  const Text("休業日", style: TextStyle(color: Colors.red)),
                if (!_isClosed(_selectedDay)) ...[
                  const SizedBox(width: 8),
                  Text('空き: ${_freeMinutes(_selectedDay)} 分'),
                ]
              ],
            ),
          ),
          Expanded(
            child: _isClosed(_selectedDay)
                ? const Center(child: Text("この日は休業日です"))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 営業時間表示
                        Builder(builder: (context) {
                          final bh = _bhOf(_selectedDay);
                          String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                          return Text('営業時間: ${fmt(bh.open)} - ${fmt(bh.close)}');
                        }),
                        const SizedBox(height: 8),
                        Text('この日の予約状況'),
                        const SizedBox(height: 8),
                        Expanded(
                          child: eventsToday.isEmpty
                              ? const Center(child: Text('予約なし'))
                              : ListView.separated(
                                  itemCount: eventsToday.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final e = eventsToday[i];
                                    final s = e.startTime.substring(0,5);
                                    final en = e.endTime.substring(0,5);
                                    return ListTile(
                                      leading: const Icon(Icons.schedule),
                                      title: Text('$s - $en'),
                                      subtitle: e.representativeName != null ? Text(e.representativeName!) : null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: _isClosed(_selectedDay)
                    ? null
                    : () => _openFreeReservationForm(context: context, date: _selectedDay),
                icon: const Icon(Icons.calendar_month),
                label: const Text('予約する（時間指定）'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 自由時間予約フロー
  Future<void> _openFreeReservationForm({
    required BuildContext context,
    required DateTime date,
  }) async {
    final day = _dateOnly(date);
    final bh = _bhOf(day);
    // その日の既存予約をTimeOfDay区間に変換
    final booked = (_eventsByDate[day] ?? [])
        .map((e) => (
              start: _parseTod(e.startTime),
              end: _parseTod(e.endTime),
            ))
        .toList();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReservationFreeFormSheet(
        date: day,
        open: bh.open,
        close: bh.close,
        booked: booked,
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ConfirmFreeScreen(
        date: day,
        start: result['start'] as String,
        end: result['end'] as String,
        name: result['name'] as String,
        phone: result['phone'] as String,
        note: (result['note'] as String?) ?? '',
        numPeople: result['numPeople'] as int,
      ),
    ));
    if (ok == true && mounted) {
      await _loadMonth(day);
      setState(() {});
    }
  }
}