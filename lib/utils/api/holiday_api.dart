import 'dart:convert';
import 'api_client.dart';

class HolidayApi {
  HolidayApi(this._client);
  final ApiClient _client;

  Future<List<DateTime>> listHolidays(DateTime from, DateTime to) async {
    final res = await _client.get('/api/v1/holidays/', query: {
      'start_date': _d(from),
      'end_date'  : _d(to),
    });
    if (res.statusCode != 200) {
      throw Exception('GET /holidays failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list
        .map((e) => DateTime.parse(e['event_date'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
  }

  Future<void> createHoliday(DateTime date, {required String name}) async {
    final body = {
      'event_date' : _d(date),
      'is_holiday' : true,
      'holiday_name': name,
      // 必要があれば 'start_time' / 'end_time': "HH:mm:ss"
    };
    final res = await _client.post('/api/v1/holidays/', body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST /holidays failed: ${res.statusCode} ${res.body}');
    }
  }

  /// 毎週の定休日が指定期間にいつ発生するか
  Future<List<DateTime>> listWeeklyOccurrences(DateTime from, DateTime to) async {
    final res = await _client.get('/api/v1/weekly-holidays/occurrences', query: {
      'start_date': _d(from),
      'end_date'  : _d(to),
    });
    if (res.statusCode != 200) {
      throw Exception('GET /weekly-holidays/occurrences failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list
        .map((e) => DateTime.parse(e['date'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList();
  }
}

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';