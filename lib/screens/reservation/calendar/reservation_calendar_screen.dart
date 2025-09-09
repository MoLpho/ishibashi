import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants.dart';
import '../../../utils/api/api_client.dart';
import '../../../utils/api/holiday_api.dart';
import '../../../utils/api/reservation_api.dart';
import '../../reservation/models/time_slot.dart';
import '../../reservation/models/form_result.dart';
import '../form/reservation_form_sheet.dart';
import '../confirm/confirm_screen.dart';


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

  late DateTime _focusedDay;// カレンダーで現在表示している月の基準日
  late DateTime _selectedDay;// カレンダーで選択されている日

  // 休業日集合
  Set<DateTime> _closed = {};
  // 日付→予約済み枠ID集合,満、空き判定用
  Map<DateTime, Set<String>> _bookedByDate = {};

  // ラベル用スロット
  final _slots = TimeSlot.defaults();// /lib/core/constants.dart の slotTime から生成

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

      // 日付→予約済み枠ID集合 に変換
      final byDate = <DateTime, Set<String>>{};
      for (final e in events) {
        final id = slotIdFromEvent(e);// 予約枠IDを取得
        if (id == null) continue;
        final d = _dateOnly(e.date);  // 時刻を切り捨てて日付のみに変換
        byDate.putIfAbsent(d, () => <String>{}).add(id); // 日付ごとに予約済み枠IDを追加
      }

      // 状態を更新
      setState(() {
        _bookedByDate = byDate; // 日ごとの予約済み枠
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

  // 満席かどうか判定
  bool _isFull(DateTime d) {
    final day = _dateOnly(d);  // 時刻を切り捨てて日付のみに変換
    final booked = _bookedByDate[day]?.length ?? 0; 
    final total  = Constants.slotTime.length; 
    return !_isClosed(day) && booked >= total && total > 0;// 休業日でなく、予約済み数が全枠数以上なら満席
  }

  Set<String> _bookedSlots(DateTime d) => _bookedByDate[_dateOnly(d)] ?? {}; // 指定日の予約済み枠ID集合を取得 例11時から13時までが予約済みなら {'11-13'}

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy年M月d日(E)');
    final bookedToday = _bookedSlots(_selectedDay);

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
            onPageChanged: (focused) => _loadMonth(focused), // 月が変わったときにデータを再取得
            calendarFormat: CalendarFormat.month,      // 月表示にフォーマット指定
            availableCalendarFormats: const {CalendarFormat.month: '月'}, 
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            enabledDayPredicate: (day) => !_isClosed(day), // 休業日は選択不可にする
            // 日付セルのカスタマイズ設定
            calendarBuilders: CalendarBuilders( 
              // 日付セルの下に予約状況を示すマーカーを表示
              markerBuilder: (context, day, events) {
                final d = _dateOnly(day);// 時刻を切り捨てて日付のみに変換
                
                //休業日かどうか判定、休業日なら赤色のマーカーを表示
                if (_isClosed(d)) {
                  return const Positioned(
                    bottom: 4, child: Icon(Icons.circle, size: 8, color: Colors.red),//色の設定
                  );
                }
                //既に予約済みかどうか判定、既に予約済みならオレンジ色のマーカーを表示
                if (_isFull(d)) {
                  return const Positioned(
                    bottom: 4, child: Icon(Icons.circle, size: 8, color: Colors.orange),//色の設定
                  );
                }
                final booked = _bookedByDate[d]?.length ?? 0;// 予約済み数を取得
                // 予約済みが1つ以上かつ満席でない場合は緑色のマーカーを表示
                if (booked > 0 && booked < Constants.slotTime.length) {
                  return const Positioned(
                    bottom: 4, child: Icon(Icons.circle, size: 8, color: Colors.green),//色の設定
                  );
                }
                return null; // 予約がない場合はマーカーを表示しない 要相談
              },
            ),
          ),
          const Divider(height: 1),
          // 選択された日の予約枠と状態説明を表示
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text("${df.format(_selectedDay)} の予約枠",
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                // 休業日なら赤色で表示
                if (_isClosed(_selectedDay))
                  const Text("休業日", style: TextStyle(color: Colors.red)),
                //既に予約済みオレンジ色で表示
                if (!_isClosed(_selectedDay) && _isFull(_selectedDay)) 
                  const Text("満席", style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          Expanded(
            // 休業日なら「この日は休業日です」と表示、そうでなければ予約枠リストを表示
            child: _isClosed(_selectedDay)
                ? const Center(child: Text("この日は休業日です"))
                : ListView.separated(
                    itemCount: _slots.length,
                    separatorBuilder: (_, __) => const Divider(height: 1), // リスト間に区切り線
                    itemBuilder: (_, i) {
                      final s = _slots[i]; 
                      final isBooked = bookedToday.contains(s.id);// 予約済みかどうか
                      return ListTile(
                        title: Text(s.label),
                        trailing: Text(isBooked ? "満" : "空き", // 予約済みなら「満」、そうでなければ「空き」と表示
                            style: TextStyle(color: isBooked ? Colors.orange : Colors.green)),
                        enabled: !isBooked, // 予約済みならタップ不可にする
                        onTap: isBooked
                            ? null
                            : () => _openReservationForm(
                                  context: context,
                                  date: _selectedDay,
                                  initialSelected: {s.id},
                                ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon( // 予約ボタン
              // 休業日または予約済みならボタンを無効化
                onPressed: _isClosed(_selectedDay) || _isFull(_selectedDay) 
                    ? null
                    : () => _openReservationForm(
                          context: context,
                          date: _selectedDay,
                          initialSelected: {},
                        ),
                icon: const Icon(Icons.calendar_month),
                label: const Text("予約する"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 予約ボタン押下時の処理
  Future<void> _openReservationForm({
    required BuildContext context,
    required DateTime date,
    required Set<String> initialSelected,
  }) async {

    final booked = _bookedSlots(date); // 選択した日の予約済み枠ID集合を取得

    // 予約フォームをモーダルボトムシートで表示
    final result = await showModalBottomSheet<FormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReservationFormSheet(
        date: date,
        allSlots: _slots, // 全予約枠
        initialSelected: initialSelected, 
        booked: booked,  // 予約済み枠
      ),
    );

    // ユーザーがキャンセルした場合は何もしない
    if (result == null) return;
    if (!context.mounted) return; 

    //if (!mounted || result == null) return;

    // 予約確認画面に遷移 trueなら予約成功、falseならキャンセルor失敗
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ConfirmScreen(result: result),
    ));

    if (!context.mounted) return;

    if (ok == null) return;   // 戻り値がnullのときだけ抜ける
    if (ok == true && mounted) {
    await _loadMonth(date);
  
    }
    // 予約成功時は再読込
    if (ok == true && mounted) {
      await _loadMonth(date);
      setState(() {}); // 表示更新
    }
  }
}