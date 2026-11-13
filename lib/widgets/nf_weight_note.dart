import 'package:flutter/material.dart';
import '../skin.dart';

/// Whole-bird price notice (duck / chicken), same wording as the website: the shop lists a
/// per-kg price but each bird weighs 2–3 kg, so the final price depends on the bird.
class NfWeightNote extends StatelessWidget {
  const NfWeightNote({super.key, required this.kinds});
  final List<String> kinds; // ['duck'], ['chicken'] or both

  static List<String> kindsIn(Iterable<Map<String, dynamic>> products) {
    final found = products.map((p) => p['whole_bird']?.toString()).whereType<String>().toSet();
    return ['duck', 'chicken'].where(found.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final of = kinds.length > 1 ? 'হাঁস ও মুরগির' : (kinds.first == 'chicken' ? 'মুরগির' : 'হাঁসের');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF2D27A))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.scale_outlined, size: 20, color: Color(0xFF8A5A00)),
        const SizedBox(width: 10),
        Expanded(child: Text.rich(TextSpan(style: Nf.t(12.5, color: Nf.ink, height: 1.5), children: [
          TextSpan(text: '$of দাম সম্পর্কে জেনে নিন\n', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: 'এখানে শুধুমাত্র প্রতি কেজির দাম দেয়া আছে, আমাদের প্রতিটি $of ওজন ২-৩ কেজির মধ্যে হয় তাই আপনার অর্ডারের ফাইনাল দাম $of ওজনের উপর নির্ভর করবে।'),
        ]))),
      ]),
    );
  }
}
