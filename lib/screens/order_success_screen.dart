import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';
import '../theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, this.orderNumber, this.online = false});
  final String? orderNumber;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final brand = context.read<StoreState>().brandColor;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(height: 96, width: 96, decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, size: 54, color: kSuccess)),
            const SizedBox(height: 20),
            const Text('অর্ডার সফল হয়েছে! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
            const SizedBox(height: 8),
            Text(online
                ? 'পেমেন্ট সম্পন্ন করুন। আমরা শীঘ্রই আপনার অর্ডার কনফার্ম করব।'
                : 'ধন্যবাদ! আমরা শীঘ্রই কল করে অর্ডার কনফার্ম করব।',
              textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
            if (orderNumber != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('অর্ডার নম্বর  ', style: TextStyle(color: kMuted, fontSize: 13)),
                  Text(orderNumber!, style: TextStyle(color: brand, fontWeight: FontWeight.w800)),
                ])),
            ],
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('কেনাকাটা চালিয়ে যান'),
            )),
          ]),
        ),
      ),
    );
  }
}
