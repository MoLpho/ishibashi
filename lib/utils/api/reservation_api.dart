
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../../core/constants.dart';

/// 単一の予約(イベント)の最小表現
class EventItem {
  final DateTime date;     // event_date (yyyy-MM-dd)
  final String startTime;  // HH:mm:ss
  final String endTime;    // HH:mm:ss
  final int? id;           // サーバー採番ID (一覧では返る/返らないことがある想定)

  EventItem({
    required this.date,
    required this.startTime,
    required this.endTime,
    this.id,
  });

  factory EventItem.fromJson(Map<String, dynamic> j) {
    // APIのtimeが"13:00:00" or "13:00:00Z" といった形式でも安全に切り出す
    String _hhmmss(dynamic v) {
      final s = (v ?? '').toString();
      final m = RegExp(r'(\d{2}:\d{2}:\d{2})').firstMatch(s);
      return m?.group(1) ?? s;
    }

    DateTime _toDate(dynamic v) {
      // event_date が "2025-09-10" で来る前提
      final s = (v ?? '').toString();
      return DateTime.parse(s);
    }

    return EventItem(
      date: _toDate(j['event_date']),
      startTime: _hhmmss(j['start_time']),
      endTime: _hhmmss(j['end_time']),
      id: j['id'] is int ? j['id'] as int : null,
    );
  }
}

class ReservationApi {
  final ApiClient _client;
  ReservationApi(this._client);

  /// 期間で予約一覧を取得
  Future<List<EventItem>> listEvents(DateTime from, DateTime to) async {
    final res = await _client.get('/api/v1/events/', query: {
      'start_date': dateYmd(from),
      'end_date'  : dateYmd(to),
    });
    if (res.statusCode != 200) {
      throw Exception('GET /events failed: ${res.statusCode} ${res.body}');
    }
    final body = jsonDecode(res.body);
    if (body is! List) return <EventItem>[];
    return body
        .cast<Map<String, dynamic>>()
        .map<EventItem>((e) => EventItem.fromJson(e))
        .toList();
  }

  /// 予約作成
  /// フォームでは人数を扱っていないため、デフォルトで 大人1, 子供0 を設定
  Future<Map<String, dynamic>> createEvent({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String name,
    required String phone,
    int numAdults = 1,
    int numChildren = 0,
    String? notes,
    String? plan,
  }) async {
    final payload = {
      'event_date'        : dateYmd(date),
      'start_time'        : startTime,
      'end_time'          : endTime,
      'representative_name': name,
      'phone_number'      : phone,
      'num_adults'        : numAdults,
      'num_children'      : numChildren,
      'notes'             : notes,
      'plan'              : plan,
      'is_holiday'        : false,
      'holiday_name'      : null,
    };

    final http.Response res = await _client.post('/api/v1/events/', body: payload);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST /events failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 予約取得
  Future<Map<String, dynamic>> getEvent(int id) async {
    final res = await _client.get('/api/v1/events/$id');
    if (res.statusCode != 200) {
      throw Exception('GET /events/$id failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 予約更新（必要に応じて使用）
  Future<Map<String, dynamic>> updateEvent(
    int id, {
      DateTime? date,
      String? startTime,
      String? endTime,
      String? name,
      String? phone,
      int? numAdults,
      int? numChildren,
      String? notes,
      String? plan,
      bool? isHoliday,
      String? holidayName,
    }
  ) async {
    final payload = <String, dynamic>{
      if (date != null)         'event_date': dateYmd(date),
      if (startTime != null)    'start_time': startTime,
      if (endTime != null)      'end_time': endTime,
      if (name != null)         'representative_name': name,
      if (phone != null)        'phone_number': phone,
      if (numAdults != null)    'num_adults': numAdults,
      if (numChildren != null)  'num_children': numChildren,
      if (notes != null)        'notes': notes,
      if (plan != null)         'plan': plan,
      if (isHoliday != null)    'is_holiday': isHoliday,
      if (holidayName != null)  'holiday_name': holidayName,
    };

    final res = await _client.put('/api/v1/events/$id', body: payload);
    if (res.statusCode != 200) {
      throw Exception('PUT /events/$id failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 予約削除
  Future<void> deleteEvent(int id) async {
    final res = await _client.delete('/api/v1/events/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('DELETE /events/$id failed: ${res.statusCode} ${res.body}');
    }
  }
}

String dateYmd(DateTime d) =>
    '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

/// EventItem → slotId を推定（満席判定用）
String? slotIdFromEvent(EventItem e) {
  for (final entry in Constants.slotTime.entries) {
    if (entry.value.start == e.startTime && entry.value.end == e.endTime) {
      return entry.key;
    }
  }
  return null;
}
