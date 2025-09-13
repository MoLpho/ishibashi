import '../../../../utils/api/api_client.dart';
import '../../../../utils/api/reservation_api.dart';

import 'reservation.dart';

/// 管理者画面向け：バックエンドAPIから当月の予約を取得
class AdminReservationRepository {
  AdminReservationRepository(ApiClient client)
      : _api = ReservationApi(client);

  factory AdminReservationRepository.defaultClient() =>
      AdminReservationRepository(ApiClient());

  final ReservationApi _api;

  Future<List<AdminReservation>> fetchMonthly(DateTime month) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    final events = await _api.listEvents(from, to);

    return [
      for (final e in events)
        AdminReservation(
          id: e.id ?? _idFrom(e),
          customerName: e.representativeName ?? '予約',
          start: DateTime(
            e.date.year,
            e.date.month,
            e.date.day,
            int.parse(e.startTime.substring(0, 2)),
            int.parse(e.startTime.substring(3, 5)),
          ),
          end: DateTime(
            e.date.year,
            e.date.month,
            e.date.day,
            int.parse(e.endTime.substring(0, 2)),
            int.parse(e.endTime.substring(3, 5)),
          ),
          status: _mapStatus(e.status),
          numPeople: e.numPeople,
          note: e.notes,
        )
    ];
  }

  String _idFrom(EventItem e) =>
      '${e.date.toIso8601String()}_${e.startTime}_${e.endTime}';

  ReservationStatus _mapStatus(String? s) {
    switch (s) {
      case 'pending':
        return ReservationStatus.pending;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.confirmed;
    }
  }

  /// 予約の更新
  Future<void> update(AdminReservation r) async {
    final date = DateTime(r.start.year, r.start.month, r.start.day);
    await _api.updateEvent(
      id: r.id,
      date: date,
      startTime: _fmtHMS(r.start),
      endTime: _fmtHMS(r.end),
      representativeName: r.customerName,
      status: switch (r.status) {
        ReservationStatus.pending => 'pending',
        ReservationStatus.cancelled => 'cancelled',
        ReservationStatus.confirmed => 'confirmed',
      },
      notes: r.note,
      numAdults: r.numPeople, // 仮に全員を大人として扱う。必要に応じて調整
      numChildren: 0, // 子供の人数は0として扱う。必要に応じて調整
    );
  }

  /// 予約の削除（キャンセル）
  Future<void> delete(String id) async {
    await _api.deleteEvent(id);
  }

  String _fmtHMS(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:00';
}
