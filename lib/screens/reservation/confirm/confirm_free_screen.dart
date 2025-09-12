import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/api/api_client.dart';
import '../../../utils/api/reservation_api.dart';

class ConfirmFreeScreen extends StatelessWidget {
  final DateTime date;
  final String start; // HH:mm:ss
  final String end;   // HH:mm:ss
  final String name;
  final String phone;
  final String note;

  const ConfirmFreeScreen({
    super.key,
    required this.date,
    required this.start,
    required this.end,
    required this.name,
    required this.phone,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy年M月d日(E)');
    return Scaffold(
      appBar: AppBar(title: const Text('予約確認')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('利用日：${df.format(date)}'),
            const SizedBox(height: 4),
            Text('時間：$start - $end'),
            Text('代表者名：$name'),
            Text('電話番号：$phone'),
            if (note.isNotEmpty) Text('備考：$note'),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final client = ApiClient();
                final resApi = ReservationApi(client);
                try {
                  await resApi.createEvent(
                    date: date,
                    startTime: start,
                    endTime: end,
                    name: name,
                    phone: phone,
                    notes: note.isEmpty ? null : note,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('予約が完了しました')),
                    );
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('予約に失敗しました：$e')),
                    );
                  }
                }
              },
              child: const Text('確定する'),
            ),
          ],
        ),
      ),
    );
  }
}
