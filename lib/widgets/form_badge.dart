import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Son 5 maçlık form durumunu (Galibiyet / Beraberlik / Mağlubiyet) renkli rozetlerle gösteren widget
class FormBadgeList extends StatelessWidget {
  final List<String> form;

  const FormBadgeList({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    if (form.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: form.take(5).map((result) {
        final upper = result.toUpperCase();
        Color bg;
        String label;

        if (upper == 'W' || upper == 'G') {
          bg = AppColors.winGreen;
          label = 'G';
        } else if (upper == 'D' || upper == 'B') {
          bg = AppColors.drawYellow;
          label = 'B';
        } else {
          bg = AppColors.lossRed;
          label = 'M';
        }

        return Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
