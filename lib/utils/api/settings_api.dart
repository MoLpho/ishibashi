import 'dart:convert';

import 'api_client.dart';

class BusinessHoursItem {
  final int weekday; // 0=Mon ... 6=Sun
  final String openTime; // "HH:mm:ss"
  final String closeTime; // "HH:mm:ss"

  BusinessHoursItem({required this.weekday, required this.openTime, required this.closeTime});

  factory BusinessHoursItem.fromJson(Map<String, dynamic> j) => BusinessHoursItem(
        weekday: j['weekday'] as int,
        openTime: _hhmmss(j['open_time'] as String),
        closeTime: _hhmmss(j['close_time'] as String),
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'open_time': openTime,
        'close_time': closeTime,
      };
}

class WeeklyHolidayRule {
  final int id;
  final int weekday; // 0..6
  final String name;
  final bool active;

  WeeklyHolidayRule({required this.id, required this.weekday, required this.name, required this.active});

  factory WeeklyHolidayRule.fromJson(Map<String, dynamic> j) => WeeklyHolidayRule(
        id: (j['id'] as num).toInt(),
        weekday: j['weekday'] as int,
        name: (j['name'] as String?) ?? '定休日',
        active: (j['is_active'] as bool?) ?? true,
      );
}

class HolidayItem {
  final int id;
  final DateTime date;
  HolidayItem({required this.id, required this.date});
  factory HolidayItem.fromJson(Map<String, dynamic> j) => HolidayItem(
        id: (j['id'] as num).toInt(),
        date: DateTime.parse(j['event_date'] as String),
      );
}

class SettingsApi {
  SettingsApi(this._client);
  final ApiClient _client;

  // Business Hours
  Future<List<BusinessHoursItem>> listBusinessHours() async {
    final res = await _client.get('/api/v1/business-hours/');
    if (res.statusCode != 200) {
      throw Exception('GET /business-hours failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(BusinessHoursItem.fromJson).toList();
  }

  Future<BusinessHoursItem> upsertBusinessHour(BusinessHoursItem item) async {
    final res = await _client.put('/api/v1/business-hours/${item.weekday}', body: jsonEncode(item.toJson()));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT /business-hours/${item.weekday} failed: ${res.statusCode} ${res.body}');
    }
    return BusinessHoursItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // Weekly Holidays (regular weekly closed days)
  Future<List<WeeklyHolidayRule>> listWeeklyHolidayRules() async {
    final res = await _client.get('/api/v1/weekly-holidays/');
    if (res.statusCode != 200) {
      throw Exception('GET /weekly-holidays failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(WeeklyHolidayRule.fromJson).toList();
  }

  Future<WeeklyHolidayRule> createWeeklyHolidayRule({required int weekday, String name = '定休日'}) async {
    final body = jsonEncode({'weekday': weekday, 'name': name});
    final res = await _client.post('/api/v1/weekly-holidays/', body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /weekly-holidays failed: ${res.statusCode} ${res.body}');
    }
    return WeeklyHolidayRule.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deactivateWeeklyHolidayRule(int id) async {
    final res = await _client.delete('/api/v1/weekly-holidays/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('DELETE /weekly-holidays/$id failed: ${res.statusCode} ${res.body}');
    }
  }

  // Ad-hoc Holidays (one-off holidays)
  Future<List<HolidayItem>> listHolidays(DateTime start, DateTime end) async {
    final res = await _client.get('/api/v1/holidays/', query: {
      'start_date': _d(start),
      'end_date': _d(end),
    });
    if (res.statusCode != 200) {
      throw Exception('GET /holidays failed: ${res.statusCode} ${res.body}');
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(HolidayItem.fromJson).toList();
  }

  Future<void> createHoliday(DateTime date) async {
    // EventCreate を満たすため、一日休業として 00:00:00-23:59:59 を送る
    final body = jsonEncode({
      'event_date': _d(date),
      'start_time': '00:00:00',
      'end_time': '23:59:59',
      // EventBase では str 必須のため空文字を送る
      'representative_name': '',
      'phone_number': '',
      'num_adults': 0,
      'num_children': 0,
      'notes': '臨時休業',
      'plan': null,
      'is_holiday': true,
      'holiday_name': '臨時休業',
    });
    final res = await _client.post('/api/v1/holidays/', body: body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /holidays failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteHoliday(int id) async {
    final res = await _client.delete('/api/v1/holidays/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('DELETE /holidays/$id failed: ${res.statusCode} ${res.body}');
    }
  }
}

String _d(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _hhmmss(String s) {
  final m = RegExp(r'\d{2}:\d{2}:\d{2}').firstMatch(s);
  return m?.group(0) ?? s;
}
