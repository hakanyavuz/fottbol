import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SignalTickerWidget extends StatefulWidget {
  const SignalTickerWidget({super.key});

  @override
  State<SignalTickerWidget> createState() => _SignalTickerWidgetState();
}

class _SignalTickerWidgetState extends State<SignalTickerWidget> {
  final List<String> _signals = [
    '🔥 FIRSAT: Galatasaray maçında %74 güven skoruyla MS 1 öne çıkıyor.',
    '⚠️ KADRO ŞOKU: Beşiktaş - Trabzonspor maçında kilit oyuncu kadroda yok!',
    '💎 VALUE: Premier League bülteninde 3 maçta hatalı oran saptandı.',
    '📡 CANLI: Amed SK baskısını artırdı, gol beklentisi yükseliyor.',
    '🏆 KUPON: Günün Banko kuponu %90 başarı oranıyla hazır!',
  ];
  
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _signals.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.premiumGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.premiumGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.premiumGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'SİNYAL',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _signals[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.premiumGold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.trending_up, color: AppColors.premiumGold, size: 14),
          ),
        ],
      ),
    );
  }
}
