import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'state/store_state.dart';
import 'theme.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge with a transparent status bar; dark icons by default (light screens).
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoreState()..bootstrap(),
      child: const StoreApp(),
    ),
  );
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StoreState>();
    return MaterialApp(
      title: state.storeName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(state.brandColor),
      home: switch (state.status) {
        LoadStatus.loading => const _Splash(),
        LoadStatus.error => _ErrorScreen(message: state.loadError),
        LoadStatus.ready => const HomeShell(),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF16A34A),
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: kFaint),
              const SizedBox(height: 14),
              const Text('স্টোর লোড করা যায়নি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
              const SizedBox(height: 6),
              Text(message ?? 'ইন্টারনেট সংযোগ দেখুন এবং আবার চেষ্টা করুন।', textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.read<StoreState>().bootstrap(), child: const Text('আবার চেষ্টা করুন')),
              const SizedBox(height: 8),
              Text(AppConfig.apiBaseUrl, style: const TextStyle(fontSize: 11, color: kFaint)),
            ]),
          ),
        ),
      );
}
