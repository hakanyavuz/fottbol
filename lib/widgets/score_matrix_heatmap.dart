import 'package:flutter/material.dart';
import '../models/prediction_result.dart';

/// 6x6 tam skor olasılık matrisini ısı haritası olarak gösterir.
///
/// Renk tek tonlu sıralı bir skaladır (az = yüzeye yakın, çok = koyu/parlak);
/// açık ve koyu tema için ayrı, açıklığı tekdüze doğrulanmış duraklar kullanılır.
/// Değer etiketleri yalnızca anlamlı hücrelere yazılır; tüm değerler dokunma
/// ipucunda ve "Tüm skorlar" tablo görünümünde bulunur.
class ScoreMatrixHeatmap extends StatelessWidget {
  final PredictionResult prediction;

  const ScoreMatrixHeatmap({super.key, required this.prediction});

  /// Açık tema: az -> çok (açıktan koyuya). Tek ton, tekdüze açıklık doğrulandı.
  static const List<Color> _lightRamp = [
    Color(0xFFDCFCE7),
    Color(0xFF86EFAC),
    Color(0xFF4ADE80),
    Color(0xFF22C55E),
    Color(0xFF16A34A),
    Color(0xFF15803D),
    Color(0xFF166534),
  ];

  /// Koyu tema: az -> çok (yüzeye yakın koyudan parlağa)
  static const List<Color> _darkRamp = [
    Color(0xFF1F3B34),
    Color(0xFF166534),
    Color(0xFF15803D),
    Color(0xFF16A34A),
    Color(0xFF22C55E),
    Color(0xFF4ADE80),
    Color(0xFF86EFAC),
  ];

  /// Bu eşiğin üzerindeki hücrelere değer etiketi yazılır (seçici etiketleme)
  static const double labelThreshold = 4.0;

  /// [t] (0-1) değerini skala üzerinde doğrusal olarak renklendirir
  static Color colorFor(double t, List<Color> ramp) {
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (ramp.length - 1);
    final i = scaled.floor().clamp(0, ramp.length - 2);
    return Color.lerp(ramp[i], ramp[i + 1], scaled - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final matrix = prediction.scoreMatrix;
    if (matrix.length != 6 || matrix.any((row) => row.length != 6)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ramp = isDark ? _darkRamp : _lightRamp;
    final inkPrimary = theme.colorScheme.onSurface;
    final inkMuted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    final maxP = matrix.expand((r) => r).fold<double>(0, (a, b) => b > a ? b : a);
    final home = prediction.homeTeam.name;
    final away = prediction.awayTeam.name;

    Widget axisLabel(String text) => Center(
          child: Text(text, style: TextStyle(fontSize: 11, color: inkMuted, fontWeight: FontWeight.w600)),
        );

    // Geniş ekranlarda hücreler aşırı büyümesin (tablet / masaüstü)
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxGridWidth),
        child: _buildBody(context, theme, matrix, ramp, maxP, home, away, inkPrimary, inkMuted, axisLabel),
      ),
    );
  }

  /// Izgaranın en fazla genişliği
  static const double maxGridWidth = 440;

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    List<List<double>> matrix,
    List<Color> ramp,
    double maxP,
    String home,
    String away,
    Color inkPrimary,
    Color inkMuted,
    Widget Function(String) axisLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satır: $home golü  ·  Sütun: $away golü',
          style: TextStyle(fontSize: 11.5, color: inkMuted),
        ),
        const SizedBox(height: 10),

        // Sütun başlıkları (deplasman golü)
        Row(
          children: [
            const SizedBox(width: 22),
            for (int a = 0; a <= 5; a++) Expanded(child: axisLabel('$a')),
          ],
        ),
        const SizedBox(height: 4),

        for (int h = 0; h <= 5; h++)
          Padding(
            // 2px yüzey boşluğu: hücreler kenarlıkla değil boşlukla ayrılır
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(width: 22, child: axisLabel('$h')),
                for (int a = 0; a <= 5; a++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: _Cell(
                        probability: matrix[h][a],
                        fill: colorFor(maxP > 0 ? matrix[h][a] / maxP : 0, ramp),
                        isPredicted: h == prediction.predictedHomeGoals &&
                            a == prediction.predictedAwayGoals,
                        tooltip: '$home $h - $a $away: %${matrix[h][a].toStringAsFixed(1)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 10),
        _RampLegend(ramp: ramp, maxP: maxP, inkMuted: inkMuted),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 13, color: inkMuted),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                'en olası skor · hücreye basılı tutarak tam değeri görebilirsiniz',
                style: TextStyle(fontSize: 10.5, color: inkMuted),
              ),
            ),
          ],
        ),

        // Tablo görünümü: renk ve etiketlere bağlı kalmadan tüm değerler
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Tüm skorlar (tablo)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: inkPrimary),
            ),
            children: [_ScoreTable(prediction: prediction)],
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final double probability;
  final Color fill;
  final bool isPredicted;
  final String tooltip;

  const _Cell({
    required this.probability,
    required this.fill,
    required this.isPredicted,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Dolgu içindeki metin, dolgunun parlaklığına göre beyaz veya koyu seçilir
    final textColor = fill.computeLuminance() > 0.35 ? const Color(0xFF0B0B0B) : Colors.white;
    final showLabel = probability >= ScoreMatrixHeatmap.labelThreshold || isPredicted;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: showLabel
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    // Yıldız glif yerine ikon: her fontta aynı şekilde çizilir
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPredicted) Icon(Icons.star_rounded, size: 12, color: textColor),
                        Text(
                          probability.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor,
                            fontWeight: isPredicted ? FontWeight.w900 : FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Sıralı renk skalası göstergesi: 0 -> en yüksek olasılık
class _RampLegend extends StatelessWidget {
  final List<Color> ramp;
  final double maxP;
  final Color inkMuted;

  const _RampLegend({required this.ramp, required this.maxP, required this.inkMuted});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 10.5, color: inkMuted);
    return Row(
      children: [
        Text('%0', style: style),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: ramp),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('%${maxP.toStringAsFixed(1)}', style: style),
      ],
    );
  }
}

/// Tüm skorların olasılığa göre sıralı tablosu (erişilebilir alternatif görünüm)
class _ScoreTable extends StatelessWidget {
  final PredictionResult prediction;

  const _ScoreTable({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final rows = <ScoreProbability>[
      for (int h = 0; h <= 5; h++)
        for (int a = 0; a <= 5; a++)
          ScoreProbability(homeGoals: h, awayGoals: a, probability: prediction.scoreMatrix[h][a]),
    ]..sort((x, y) => y.probability.compareTo(x.probability));

    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    const numStyle = TextStyle(fontSize: 12.5, fontFeatures: [FontFeature.tabularFigures()]);

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text(r.scoreString, style: numStyle.copyWith(fontWeight: FontWeight.w600))),
                Expanded(
                  child: Text(
                    MatchOutcome.fromGoals(r.homeGoals, r.awayGoals) == MatchOutcome.draw
                        ? 'Beraberlik'
                        : r.homeGoals > r.awayGoals
                            ? '${prediction.homeTeam.name} kazanır'
                            : '${prediction.awayTeam.name} kazanır',
                    style: TextStyle(fontSize: 11.5, color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('%${r.probability.toStringAsFixed(2)}', style: numStyle),
              ],
            ),
          ),
      ],
    );
  }
}
