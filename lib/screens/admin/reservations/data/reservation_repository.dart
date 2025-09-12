import 'dart:async';

import 'reservation.dart';

/// モック実装のリポジトリ。
/// 将来的にはここをバックエンドAPIクライアントに置き換える。
/// 例）`ApiClient` を注入して `GET /admin/reservations?month=...` を叩く。
class ReservationRepository {
  const ReservationRepository();

  /// 指定月の予約一覧を取得
  Future<List<AdminReservation>> fetchMonthly(DateTime focusedMonth) async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // 擬似遅延（UIのLoading表示確認用）
    // 一時的にすべての予約を消す
    // 以前のモックデータは下記。必要になれば戻してください。
    // final first = DateTime(focusedMonth.year, focusedMonth.month, 1);
    // final samples = <AdminReservation>[
    //   AdminReservation(
    //     id: 'r1',
    //     customerName: '山田太郎',
    //     start: DateTime(first.year, first.month, 5, 10, 0),
    //     end: DateTime(first.year, first.month, 5, 12, 0),
    //     status: ReservationStatus.confirmed,
    //   ),
    //   AdminReservation(
    //     id: 'r2',
    //     customerName: '田中一郎',
    //     start: DateTime(first.year, first.month, 12, 13, 0),
    //     end: DateTime(first.year, first.month, 12, 16, 0),
    //     status: ReservationStatus.pending,
    //   ),
    //   AdminReservation(
    //     id: 'r3',
    //     customerName: '伊東四郎',
    //     start: DateTime(first.year, first.month, 20, 15, 30),
    //     end: DateTime(first.year, first.month, 20, 18, 0),
    //     status: ReservationStatus.confirmed,
    //   ),
    // ];
    // return samples;
    return <AdminReservation>[];
  }
}

