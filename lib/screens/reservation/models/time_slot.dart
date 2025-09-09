import '../../../core/constants.dart';

class TimeSlot {
  final String id;     // 例: "10-11"
  final String label;  // 例: "10:00–11:00"
  const TimeSlot({required this.id, required this.label});

  /// デフォルトの予約枠リストを生成
  static List<TimeSlot> defaults() {
    String toHm(String hhmmss) => hhmmss.substring(0,5);
    return Constants.slotTime.entries.map((e) {
      final start = toHm(e.value.start); 
      final end   = toHm(e.value.end); 
      return TimeSlot(id: e.key, label: '$start–$end');
    }).toList();
  }
}