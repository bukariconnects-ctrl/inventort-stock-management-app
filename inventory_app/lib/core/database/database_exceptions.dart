/// استثناء يتم إلقاؤه عند محاولة صرف أو إتلاف كمية تتجاوز الرصيد المتوفر في المخزن
class InsufficientStockException implements Exception {
  final String message;
  final int? availableQuantity;
  final int? requestedQuantity;

  InsufficientStockException([
    this.message = 'الرصيد المتاح لا يكفي لعملية الصرف',
    this.availableQuantity,
    this.requestedQuantity,
  ]);

  @override
  String toString() {
    if (availableQuantity != null && requestedQuantity != null) {
      return '$message (الرصيد المتاح: $availableQuantity كرتون | المطلوب: $requestedQuantity كرتون)';
    }
    return message;
  }
}

