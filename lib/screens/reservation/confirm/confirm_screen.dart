import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../utils/api/api_client.dart';
import '../../../utils/api/reservation_api.dart';
import '../../reservation/models/form_result.dart';

class ConfirmScreen extends StatelessWidget {
  final FormResult result;
  const ConfirmScreen({super.key, required this.result});

  
  @override
  Widget build(BuildContext context) { // 画面のビルド
  // 日付フォーマット
    final df = DateFormat('yyyy年M月d日(E)');
    return Scaffold(
      appBar: AppBar(title: const Text("予約確認")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("利用日：${df.format(result.date)}"),
            const SizedBox(height: 4),
            Text("時間枠：${result.slotIds.join(', ')}"),
            Text("代表者名：${result.name}"),
            Text("電話番号：${result.phone}"),
            if (result.note.isNotEmpty) Text("備考：${result.note}"),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final client = ApiClient();// APIクライアントの作成
                final resApi = ReservationApi(client);// 予約APIクライアントの作成
                // 予約を実行
                try {
                  // 選択された各予約枠について予約を作成
                  for (final id in result.slotIds) {
                    final times = Constants.slotTime[id]!; // 予約枠IDから開始・終了時刻を取得
                    // APIを呼び出して予約を作成
                    await resApi.createEvent( 
                      date: result.date,
                      startTime: times.start,
                      endTime:   times.end,
                      name: result.name,
                      phone: result.phone,
                      notes: result.note.isEmpty ? null : result.note,
                    );
                  }
                  // 予約成功メッセージを表示して前画面に戻る
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("予約が完了しました")),
                    );
                    Navigator.of(context).pop(true); // ← 呼び出し元へ成功を返す
                  }
                } catch (e) {  // 予約失敗時のエラーハンドリング
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('予約に失敗しました：$e')),
                    );
                  }
                }
              },
              child: const Text("確定する"),
            ),
          ],
        ),
      ),
    );
  }
}