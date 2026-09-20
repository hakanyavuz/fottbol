/// API-Football ve Ağ Hataları Yönetimi
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Günlük istek kotası dolduğunda veya rate-limit aşıldığında fırlatılan özel hata
class ApiQuotaExceededException extends ApiException {
  final bool hasCachedFallback;

  ApiQuotaExceededException({
    String message = 'API-Football günlük istek limitiniz (100 istek/gün) doldu.',
    this.hasCachedFallback = false,
  }) : super(message, statusCode: 429);
}

/// İnternet bağlantı hatası veya zaman aşımı
class NetworkException extends ApiException {
  NetworkException([super.message = 'İnternet bağlantısı kurulamadı veya zaman aşımına uğradı.']);
}
