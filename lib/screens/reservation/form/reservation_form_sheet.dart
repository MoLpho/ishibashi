import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/validators.dart';
import '../models/time_slot.dart';
import '../models/form_result.dart';

class ReservationFormSheet extends StatefulWidget {
  final DateTime date; // 予約日
  final List<TimeSlot> allSlots; // 全予約枠のリスト
  final Set<String> initialSelected; //初期選択済みの枠
  final Set<String> booked; // 予約済みの枠（その日は選択不可）

  // コンストラクタの定義
  const ReservationFormSheet({
    super.key,
    required this.date,
    required this.allSlots,
    required this.initialSelected,
    required this.booked,
  });

  // Stateクラスの生成
  @override
  State<ReservationFormSheet> createState() => _ReservationFormSheetState();
}

// Stateクラスの定義
class _ReservationFormSheetState extends State<ReservationFormSheet> {
  final _key = GlobalKey<FormState>();  // フォームの状態を管理するキー
  final _name = TextEditingController(); // 代表者名のテキストコントローラー
  final _phone = TextEditingController(); // 電話番号のテキストコントローラー
  final _note = TextEditingController(); // 備考のテキストコントローラー
  final _numPeople = TextEditingController(text: '1');
  late Set<String> _selected; // 選択された予約枠ID

  // Stateの初期化
  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
  }

  // Stateの破棄
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
    _numPeople.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy年M月d日(E)');
    //デザインの構築
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
              Text("予約入力", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text("利用日：${df.format(widget.date)}"),

              const SizedBox(height: 12),
              Text("利用時間（複数選択可）"),
              const SizedBox(height: 8),
              //折り返し処理
              Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.allSlots.map((s) {
                  final selected = _selected.contains(s.id);
                  final isBooked = widget.booked.contains(s.id);
                  return FilterChip(
                    label: Text(s.label), // チップのラベル
                    selected: selected,   //見た目＆選択状態を同期
                    onSelected: isBooked
                        ? null   // 予約済みならタップ不可
                        : (v) {
                            setState(() => v ? _selected.add(s.id) : _selected.remove(s.id)); // 選択状態の更新
                          },
                    avatar: isBooked ? const Icon(Icons.lock, size: 16) : null,
                  );
                }).toList(),
              ),

              //代表者名の入力欄
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,//コントローラーの設定
                decoration: const InputDecoration(labelText: "代表者名 *"),//ラベル
                validator: Validators.requiredText, // 必須入力のバリデーション
                textInputAction: TextInputAction.next, // 次へボタン
                autofillHints: const [AutofillHints.name], // オートフィルヒント
              ),
              //人数の入力欄
              const SizedBox(height: 12),
              Text('人数'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numPeople,
                decoration: const InputDecoration(labelText: '人数 *'),
                keyboardType: TextInputType.number,
              validator: (v) => Validators.intInRange(v, min: 1, max: 20),
              ),

              //電話番号の入力欄
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,//コントローラーの設定
                decoration: const InputDecoration(labelText: "電話番号 *", hintText: "09012345678"),//ラベル
                keyboardType: TextInputType.phone, // 電話番号キーボードを表示
                autofillHints: const [AutofillHints.telephoneNumber],// オートフィルヒント
                validator: Validators.phoneJp, // 日本の電話番号バリデーション
              ),
              //備考の入力欄
              const SizedBox(height: 8),
              TextFormField(
                controller: _note, //コントローラーの設定
                decoration: const InputDecoration(labelText: "備考（任意）"), //ラベル
                maxLines: 3, //複数行入力可能
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), // 戻るボタン
                      child: const Text("戻る"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (!(_key.currentState?.validate() ?? false)) return; // バリデーションチェック
                        // 予約枠が1つも選択されていない場合はエラーを表示
                        if (_selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("時間枠を1つ以上選択してください")),
                          );
                          return;
                        }
                        // フォームの結果をFormResultとして返す
                        Navigator.pop(
                          context,
                          FormResult(
                            date: widget.date,
                            slotIds: _selected.toList(),
                            name: _name.text.trim(),
                            phone: _phone.text.trim(),
                            note: _note.text.trim(),
                            numPeople: int.parse(_numPeople.text),
                          ),
                        );
                      },
                      child: const Text("確認"), // 確認ボタン
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