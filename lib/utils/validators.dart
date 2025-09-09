class Validators {
  static String? requiredText(String? v) =>
      (v == null || v.trim().isEmpty) ? '必須です' : null;

  static String? phoneJp(String? v) {
    final t = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
    final ok = RegExp(r'^0\d{9,10}$').hasMatch(t);
    return ok ? null : '電話番号の形式が正しくありません';
  }
}