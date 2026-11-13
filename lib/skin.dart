import 'package:flutter/material.dart';

/// Nogor Farm look — used when the store API reports `skin: nogorfarm`.
/// Mirrors the website's design tokens (resources/views/storefront/skins/nogorfarm/layout.blade.php).
class Nf {
  static const ink = Color(0xFF10291F);
  static const green = Color(0xFF14532D);
  static const greenDark = Color(0xFF0B3B1F);
  static const gold = Color(0xFFF5B81F);
  static const red = Color(0xFFB42318);
  static const pill = Color(0xFFE7EFE5);
  static const bg = Color(0xFFF5F7F2);
  static const line = Color(0xFFDDE5DC);
  static const line2 = Color(0xFFC9D4C9);
  static const muted = Color(0xFF4B5B52);
  static const muted2 = Color(0xFF3C4D43);
  static const faint = Color(0xFF5F7166);
  static const sel = Color(0xFFFDF1CC);

  static const font = 'Poppins';
  static const fallback = ['Kalpurush'];

  /// Text style with the site's fonts (Poppins for Latin, Kalpurush for Bangla).
  static TextStyle t(double size, {FontWeight w = FontWeight.w400, Color color = ink, double? height, TextDecoration? deco}) => TextStyle(
        fontFamily: font,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        decoration: deco,
      );
}

const _bnDigits = {'0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'};

/// "1,050" → "১,০৫০".
String bnDigits(Object v) => v.toString().replaceAllMapped(RegExp(r'[0-9]'), (m) => _bnDigits[m[0]]!);

/// Grouped whole-taka amount with Bangla digits: ৳১,০৫০.
String bnMoney(String cur, num v) {
  final s = v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$cur${bnDigits(s)}';
}

String _trim(num q) {
  final s = q.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

/// Quantity label like the website: ৫০০ গ্রাম · ১ কেজি · ১.৫ কেজি · ২ পিস.
String bnQty(num q, Map<String, dynamic> product) {
  if (product['sold_by_weight'] == true) {
    return q < 1 ? '${bnDigits((q * 1000).round())} গ্রাম' : '${bnDigits(_trim(q))} কেজি';
  }
  final unit = (product['unit_bn'] ?? product['unit'] ?? '').toString().trim();
  return '${bnDigits(_trim(q))}${unit.isNotEmpty ? ' $unit' : ''}';
}
