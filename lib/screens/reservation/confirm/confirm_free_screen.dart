import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/api/api_client.dart';
import '../../../utils/api/reservation_api.dart';

class ConfirmFreeScreen extends StatefulWidget {
  final DateTime date;
  final String start; // "HH:mm:ss"
  final String end;   // "HH:mm:ss"
  final String name;
  final String phone;
  final String note;
  final int numPeople;

  const ConfirmFreeScreen({
    super.key,
    required this.date,
    required this.start,
    required this.end,
    required this.name,
    required this.phone,
    required this.note,
    required this.numPeople,
  });

  @override
  State<ConfirmFreeScreen> createState() => _ConfirmFreeScreenState();
}

class _ConfirmFreeScreenState extends State<ConfirmFreeScreen> {
  bool _agree = false;

  String _toHm(String hhmmss) => hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('yyyy年M月d日(E)', 'ja');

    BoxDecoration _cardDeco() => BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: theme.dividerColor),
    );

    TextStyle _titleStyle() =>
        theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold);

    // 店舗情報カード用の1行ヘルパ
    Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: theme.hintColor)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );

    // 「コロン無し」で縦揃えする2カラムTableの1行
    const double _labelW = 100; // 必要なら 96〜112 で微調整
    TableRow _tr(String label, String value, TextStyle body, TextStyle hint) => TableRow(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: hint),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(value, style: body),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('予約確認')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ===== 予約内容カード =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDeco(),
                      child: Builder(builder: (context) {
                        final bodyL = theme.textTheme.bodyLarge!;
                        final bodyM = theme.textTheme.bodyMedium!;
                        final hint  = bodyM.copyWith(color: theme.hintColor);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('予約内容', style: _titleStyle(), textAlign: TextAlign.center),
                            const SizedBox(height: 12),

                            // 予約日時（左寄せ）
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${df.format(widget.date)}  ${_toHm(widget.start)}–${_toHm(widget.end)}',
                                style: bodyL,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ラベル＋値（左寄せ・コロン無し・縦揃え）
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(_labelW),
                                1: FlexColumnWidth(),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.top,
                              children: [
                                _tr('お名前　',       widget.name,          bodyL, hint),
                                _tr('ご予約人数　',   '${widget.numPeople}名', bodyL, hint),
                                _tr('お電話番号　',   widget.phone,         bodyL, hint),
                                if (widget.note.isNotEmpty)
                                  _tr('備考　',      widget.note,          bodyL, hint),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(height: 1),

                            const SizedBox(height: 16),
                            Text('ご利用に関するお願い', style: _titleStyle(), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(
                              '1. お食事のお持ち込みは可能ですが、お持ち込み分のゴミは必ずお持ち帰りください。\n'
                              '2. 冷蔵庫やテレビの配線は触れないでください。(Wi-Fiが切れるとお店の機能が停止します)\n'
                              '3. 窓の桟に上がったり、ぶら下がったりしないでください。\n'
                              '4. ご利用中のケガなどについては当店は責任を負いかねますのでご注意ください。\n'
                              '5. 飛び跳ねなど、不必要な大きな振動が出る行為はご遠慮ください。',
                              style: bodyM,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // 同意チェック
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      title: const Text('上記の注意事項に同意します'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 8),

                    // ===== 店舗情報カード（例） =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('店名', 'カフェ＆クレープ ボンボン'),
                          _infoRow('住所', '池田市天神2-3-11'),
                          _infoRow('電話番号', '072-762-6320'),
                          _infoRow('営業時間', '11:30〜19:00'),
                          _infoRow('定休日', '日曜日'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== 全幅の確定ボタン =====
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _agree
                    ? () async {
                        final api = ReservationApi(ApiClient());
                        try {
                          await api.createEvent(
                            date: widget.date,
                            startTime: widget.start,
                            endTime: widget.end,
                            name: widget.name,
                            phone: widget.phone,
                            numAdults: widget.numPeople, // 合計人数
                            numChildren: 0,
                            notes: widget.note.isEmpty ? null : widget.note,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('予約が完了しました')),
                          );
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('予約に失敗しました：$e')),
                          );
                        }
                      }
                    : null,
                child: const Text('予約を確定する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}