import 'package:flutter/foundation.dart';

@immutable
class FormResult {
  final DateTime date;   // 予約日
  final List<String> slotIds;  // 選択された予約枠ID
  final String name; // 代表者名
  final String phone; // 電話番号
  final String note;  // 備考(空文字可)

  const FormResult({
    required this.date,
    required this.slotIds,
    required this.name,
    required this.phone,
    required this.note,
  });
}