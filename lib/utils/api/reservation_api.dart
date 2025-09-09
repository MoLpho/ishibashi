import 'dart:convert';
import 'api_client.dart';
import '../../core/constants.dart';

class EventItem {
  final DateTime date;     // event_date
  final String startTime;  // "HH:mm:ss"
  final String endTime;    // "HH:mm:ss"

  EventItem({required this.date, required this.startTime, required this.endTime});

  factory EventItem.fromJson(Map<String, dynamic> j) {
    String hhmmss(String s) {
      final m = RegExp(r'(\d{2}:\d{2}:\d{2})').firstMatch(s);
      return m?.group(1) ?? s;
    }
    return EventItem(
      date: DateTime.parse(j['event_date'] as String),
      startTime: hhmmss(j['start_time'] as String),
      endTime: hhmmss(j['end_time'] as String),
    );
  }
}

class ReservationApi {
  ReservationApi(this._client);
  final ApiClient _client;

  Future<List<EventItem>> listEvents(DateTime from, DateTime to) async {
    final res = await _client.get('/api/v1/events/', query: {
      'start_date': _d(from),
      'end_date'  : _d(to),
    });
    if (res.statusCode != 200) {
      throw Exception('GET /events failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(EventItem.fromJson).toList();
  }

  /// 1つの時間枠 = 1イベントとして作成
  Future<void> createEvent({
    required DateTime date,
    required String startTime, // "HH:mm:ss"
    required String endTime,   // "HH:mm:ss"
    required String name,
    required String phone,
    int numAdults = 1,
    int numChildren = 0,
    String? notes,
    String? plan,
  }) async {
    final body = {
      'event_date'        : _d(date),
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
    final res = await _client.post('/api/v1/events/', body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST /events failed: ${res.statusCode} ${res.body}');
    }
  }
}

String _d(DateTime d) =>
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