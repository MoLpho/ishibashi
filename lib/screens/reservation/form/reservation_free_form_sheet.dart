import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/validators.dart';
import 'package:flutter/services.dart';

class ReservationFreeFormSheet extends StatefulWidget {
  final DateTime date;
  final TimeOfDay open;
  final TimeOfDay close;
  final List<({TimeOfDay start, TimeOfDay end})> booked; // その日の既存予約（重複チェック用）
  

  const ReservationFreeFormSheet({
    super.key,
    required this.date,
    required this.open,
    required this.close,
    required this.booked,
    
  });

  @override
  State<ReservationFreeFormSheet> createState() => _ReservationFreeFormSheetState();
}

class _ReservationFreeFormSheetState extends State<ReservationFreeFormSheet> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _numPeople = TextEditingController(text: '1');

  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _start = widget.open;
    _end = widget.close;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    _numPeople.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _overlaps(TimeOfDay aStart, TimeOfDay aEnd, TimeOfDay bStart, TimeOfDay bEnd) {
    final a0 = _toMinutes(aStart), a1 = _toMinutes(aEnd);
    final b0 = _toMinutes(bStart), b1 = _toMinutes(bEnd);
    return a0 < b1 && b0 < a1; // 開区間の重なり
  }

  Future<void> _pick(bool isStart) async {
    final init = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  String? _validateRange() {
    final open = _toMinutes(widget.open);
    final close = _toMinutes(widget.close);
    final s = _toMinutes(_start);
    final e = _toMinutes(_end);
    if (s >= e) return '開始は終了より前にしてください';
    if (s < open || e > close) return '営業時間(${_fmt(widget.open)}-${_fmt(widget.close)})内で選択してください';
    for (final r in widget.booked) {
      if (_overlaps(_start, _end, r.start, r.end)) {
        return '既存の予約(${_fmt(r.start)}-${_fmt(r.end)})と重なっています';
      }
    }
    return null;
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy年M月d日(E)');
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('予約入力', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('利用日：${df.format(widget.date)}'),
              const SizedBox(height: 12),
              Text('利用時間'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _pick(true),
                    child: Text('開始 ${_fmt(_start)}'),
                  ),
                  OutlinedButton(
                    onPressed: () => _pick(false),
                    child: Text('終了 ${_fmt(_end)}'),
                  ),
                  Text('営業時間: ${_fmt(widget.open)} - ${_fmt(widget.close)}'),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: '代表者名 *'),
                validator: (v) => (v==null||v.trim().isEmpty) ? '必須項目です' : null,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 12),
              Text('人数'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numPeople,
                decoration: const InputDecoration(labelText: '人数 *'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => Validators.intInRange(v, min: 1, max: 20),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: '電話番号 *', hintText: '09012345678'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v==null||v.trim().isEmpty) ? '必須項目です' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: '備考（任意）'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!(_key.currentState?.validate() ?? false)) return;
                        final err = _validateRange();
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                          return;
                        }
                        Navigator.pop<Map<String, dynamic>>(context, {
                          'start': _fmt(_start) + ':00',
                          'end': _fmt(_end) + ':00',
                          'name': _name.text.trim(),
                          'phone': _phone.text.trim(),
                          'note': _note.text.trim(),
                          'numPeople': int.parse(_numPeople.text),
                        });
                      },
                      child: const Text('確認'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
