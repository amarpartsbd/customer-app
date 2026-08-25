import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';
import 'track_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.orderNumber, this.online = false});
  final String? orderNumber;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final brand = context.read<StoreState>().brandColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 24),
                // Success badge with layered rings
                Center(child: Container(
                  height: 128, width: 128,
                  decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.06), shape: BoxShape.circle),
                  child: Center(child: Container(
                    height: 96, width: 96,
                    decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Center(child: Container(
                      height: 66, width: 66,
                      decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 38, color: Colors.white),
                    )),
                  )),
                )),
                const SizedBox(height: 24),
                const Text('অর্ডার সফল হয়েছে! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: kInk)),
                const SizedBox(height: 10),
                Text(
                  online
                      ? 'পেমেন্ট সম্পন্ন করুন। আমরা শীঘ্রই আপনার অর্ডার কনফার্ম করব।'
                      : 'ধন্যবাদ! আমরা শীঘ্রই কল করে অর্ডার কনফার্ম করব।',
                  textAlign: TextAlign.center, style: const TextStyle(color: kMuted, fontSize: 14, height: 1.5),
                ),

                if (orderNumber != null) ...[
                  const SizedBox(height: 22),
                  Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: brandTint(brand, 0.07), borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_rounded, size: 18, color: brand),
                      const SizedBox(width: 8),
                      const Text('অর্ডার নম্বর', style: TextStyle(color: kMuted, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(orderNumber!, style: TextStyle(color: brand, fontWeight: FontWeight.w800, fontSize: 15)),
                    ]),
                  )),
                ],

                const SizedBox(height: 24),
                // What happens next
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: softCard(radius: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('এরপর যা হবে', style: TextStyle(fontWeight: FontWeight.w800, color: kInk, fontSize: 14.5)),
                    const SizedBox(height: 14),
                    _step(brand, Icons.phone_in_talk_rounded, 'কনফার্মেশন কল', 'আমরা ফোন করে অর্ডার নিশ্চিত করব'),
                    const SizedBox(height: 12),
                    _step(brand, Icons.inventory_2_rounded, 'প্যাকিং', 'তাজা পণ্য যত্নে প্যাক করা হবে'),
                    const SizedBox(height: 12),
                    _step(brand, Icons.local_shipping_rounded, 'ডেলিভারি', 'আপনার ঠিকানায় পৌঁছে দেওয়া হবে', last: true),
                  ]),
                ),
              ]),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Column(children: [
              if (orderNumber != null)
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrackScreen())),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('অর্ডার ট্র্যাক করুন'),
                )),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('কেনাকাটা চালিয়ে যান'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _step(Color brand, IconData icon, String title, String sub, {bool last = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(height: 36, width: 36, decoration: BoxDecoration(color: brandTint(brand, 0.10), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: brand)),
          if (!last) Container(width: 2, height: 22, margin: const EdgeInsets.symmetric(vertical: 2), color: kLine),
        ]),
        const SizedBox(width: 13),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk, fontSize: 13.5)),
            const SizedBox(height: 1),
            Text(sub, style: const TextStyle(fontSize: 12, color: kFaint, height: 1.35)),
          ]),
        )),
      ]);
}
