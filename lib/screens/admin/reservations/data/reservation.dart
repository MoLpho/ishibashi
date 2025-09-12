import 'package:flutter/material.dart';

/// 予約のステータス
enum ReservationStatus { confirmed, pending, cancelled }

/// 管理者画面用の予約モデル
class AdminReservation {
  /// 一意な予約ID
  final String id;
  /// 利用者の氏名
  final String customerName;
  /// 予約開始日時
  final DateTime start;
  /// 予約終了日時
  final DateTime end;
  /// 予約の現在ステータス
  final ReservationStatus status;

  const AdminReservation({
    required this.id,
    required this.customerName,
    required this.start,
    required this.end,
    required this.status,
  });

  /// 日付部分だけを抽出（時刻は切り捨て）
  DateTime get dateOnly => DateTime(start.year, start.month, start.day);
  /// `HH:mm-HH:mm` 形式の表示用レンジ
  String get timeRange => _fmtTime(start) + '-' + _fmtTime(end);

  static String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}' ;
}

/// ステータスの表示用拡張（ラベルと色）
extension ReservationStatusText on ReservationStatus {
  String get label => switch (this) {
        ReservationStatus.confirmed => '承認済み',
        ReservationStatus.pending => 'キャンセル待ち',
        ReservationStatus.cancelled => 'キャンセル',
      };

  Color get color => switch (this) {
        ReservationStatus.confirmed => Colors.green,
        ReservationStatus.pending => Colors.orange,
        ReservationStatus.cancelled => Colors.red,
      };
}

