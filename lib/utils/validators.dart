class Validators {
  static String? requiredText(String? v) =>
      (v == null || v.trim().isEmpty) ? '必須です' : null;

  static String? phoneJp(String? v) {
    final t = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
    final ok = RegExp(r'^0\d{9,10}$').hasMatch(t);
    return ok ? null : '電話番号の形式が正しくありません';
  }

  static String? intInRange(String? v, {int min = 1, int max = 20}) {
  if (v == null || v.trim().isEmpty) return '必須です';
  final n = int.tryParse(v);
  if (n == null) return '数値を入力してください';
  if (n < min) return '$min 以上を入力してください';
  if (n > max) return '$max 以下を入力してください';
  return null;
  }


  

}