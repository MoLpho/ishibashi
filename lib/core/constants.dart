class Constants {
  /// APIのベースURL,APIを変更したい場合はここを変更する
  static const String baseUrl = 'http://mattya3340.tplinkdns.com:8000';

  /// 予約枠（ID → (開始,終了)）。データベースの予約枠IDと一致させること
  static const Map<String, ({String start, String end})> slotTime = {
    '10-11': (start: '10:00:00', end: '11:00:00'),
    '13-15': (start: '13:00:00', end: '15:00:00'),
    '16-18': (start: '16:00:00', end: '18:00:00'),
  };
}
