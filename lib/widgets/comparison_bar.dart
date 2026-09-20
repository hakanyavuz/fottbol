import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// İki takımın istatistiklerini karşılıklı görselleştiren çift yönlü bar widget'ı
class ComparisonBar extends StatelessWidget {
  final String title;
  final String homeValueText;
  final String awayValueText;
  final double homeValue;
  final double awayValue;
  final Color homeColor;
  final Color awayColor;

  const ComparisonBar({
    super.key,
    required this.title,
    required this.homeValueText,
    required this.awayValueText,
    required this.homeValue,
    required this.awayValue,
    this.homeColor = AppColors.homeTeamColor,
    this.awayColor = AppColors.awayTeamColor,
  });

  @override
  Widget build(BuildContext context) {
    final double total = (homeValue + awayValue) == 0 ? 1.0 : (homeValue + awayValue);
    final double homeFlex = (homeValue / total).clamp(0.05, 0.95);
    final double awayFlex = (awayValue / total).clamp(0.05, 0.95);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Başlık ve Değerler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeValueText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: homeColor,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                awayValueText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: awayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Çift Renkli İlerleme Çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeFlex * 1000).toInt(),
                    child: Container(
                      color: homeColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (awayFlex * 1000).toInt(),
                    child: Container(
                      color: awayColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
