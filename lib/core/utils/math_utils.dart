import 'dart:math' as math;

/// Matematiksel ve istatistiksel hesaplama fonksiyonları
class MathUtils {
  /// Faktöriyel hesaplayıcı: n! = n * (n-1) * ... * 1 (0! = 1)
  static int factorial(int n) {
    if (n <= 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  /// Poisson Dağılımı Olasılık Fonksiyonu:
  /// P(k; λ) = (λ^k * e^(-λ)) / k!
  ///
  /// [k]: Gerçekleşmesi beklenen gol sayısı (0, 1, 2, 3...)
  /// [lambda]: Takımın beklenen gol değeri (Expected Goals - xG)
  static double poissonProbability(int k, double lambda) {
    if (lambda <= 0) return k == 0 ? 1.0 : 0.0;
    // P(k) = (lambda^k * e^(-lambda)) / k!
    final double numerator = math.pow(lambda, k) * math.exp(-lambda);
    final double denominator = factorial(k).toDouble();
    return numerator / denominator;
  }

  /// Dixon-Coles düşük skor düzeltme çarpanı τ(h, a).
  ///
  /// Yalnızca 0-0, 0-1, 1-0 ve 1-1 skorlarını değiştirir; diğer skorlar için 1'dir.
  /// Düzeltmeler birbirini dengeler, toplam olasılık kütlesi korunur.
  /// [rho] geçerli aralığa sıkıştırılır ki hiçbir olasılık negatif olmasın.
  static double dixonColesTau(int h, int a, double lambda, double mu, double rho) {
    if (h > 1 || a > 1) return 1.0;

    final safeRho = clampRho(rho, lambda, mu);
    if (h == 0 && a == 0) return 1 - lambda * mu * safeRho;
    if (h == 0 && a == 1) return 1 + lambda * safeRho;
    if (h == 1 && a == 0) return 1 + mu * safeRho;
    return 1 - safeRho; // 1-1
  }

  /// τ değerlerinin negatif olmaması için ρ'nun izin verilen aralığı:
  /// max(-1/λ, -1/μ) ≤ ρ ≤ min(1/(λμ), 1)
  static double clampRho(double rho, double lambda, double mu) {
    if (lambda <= 0 || mu <= 0) return 0.0;
    final lower = math.max(-1 / lambda, -1 / mu);
    final upper = math.min(1 / (lambda * mu), 1.0);
    return rho.clamp(lower, upper).toDouble();
  }

  /// Yüzdelik değere çevirip yuvarlama (örn: 0.354 -> 35.4)
  static double toPercentage(double value, [int fractionDigits = 1]) {
    final factor = math.pow(10, fractionDigits);
    return ((value * 100) * factor).round() / factor;
  }
}
