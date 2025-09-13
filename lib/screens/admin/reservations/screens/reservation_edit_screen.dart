import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/reservation.dart';

/// 予約の詳細表示・編集画面
class ReservationEditScreen extends StatefulWidget {
  const ReservationEditScreen({
    super.key,
    required this.reservation,
    this.onSave,
  });

  final AdminReservation reservation;
  final Function(AdminReservation)? onSave;

  @override
  State<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _numPeopleController;
  late final TextEditingController _noteController;
  late ReservationStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reservation.customerName);
    _phoneController = TextEditingController(text: ''); // 電話番号はモデルにないので空
    _numPeopleController = TextEditingController(text: widget.reservation.numPeople.toString());
    _noteController = TextEditingController(text: widget.reservation.note ?? '');
    _status = widget.reservation.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _numPeopleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // 更新された予約を作成
      final updated = AdminReservation(
        id: widget.reservation.id,
        customerName: _nameController.text.trim(),
        start: widget.reservation.start,
        end: widget.reservation.end,
        numPeople: int.tryParse(_numPeopleController.text) ?? 1,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        status: _status,
      );

      // コールバックを呼び出して保存処理を実行
      if (widget.onSave != null) {
        await widget.onSave!(updated);
      }

      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('yyyy年M月d日(E) HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('予約詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _handleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本情報セクション
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('基本情報', style: theme.textTheme.titleMedium),
                    const Divider(),
                    _buildInfoRow('日時', '${df.format(widget.reservation.start)} 〜 ${df.format(widget.reservation.end)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('ステータス', _status.label,
                        style: TextStyle(color: _status.color, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildInfoRow('予約ID', widget.reservation.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 予約詳細フォーム
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('予約内容', style: theme.textTheme.titleMedium),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '氏名 *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? '必須項目です' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: '電話番号',
                        border: OutlineInputBorder(),
                        hintText: '090-1234-5678',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _numPeopleController,
                      decoration: const InputDecoration(
                        labelText: '人数 *',
                        border: OutlineInputBorder(),
                        suffixText: '名',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '必須項目です';
                        final num = int.tryParse(value);
                        if (num == null || num < 1) return '1以上の数値を入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: '備考',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReservationStatus>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'ステータス',
                        border: OutlineInputBorder(),
                      ),
                      items: ReservationStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.label,
                            style: TextStyle(color: status.color),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('変更を保存', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
