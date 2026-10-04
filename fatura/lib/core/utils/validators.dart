/// validators.dart — Input validators for Fatura
library;

class Validators {
  Validators._();

  /// Validate PIN code (4-6 digits)
  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'الرمز السري مطلوب';
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) return '4-6 أرقام';
    return null;
  }

  /// Validate product name
  static String? productName(String? value) {
    if (value == null || value.isEmpty) return 'اسم المنتج مطلوب';
    if (value.length < 2) return 'الاسم قصير جداً';
    return null;
  }

  /// Validate price
  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'السعر مطلوب';
    final price = double.tryParse(value);
    if (price == null) return 'سعر غير صحيح';
    if (price < 0) return 'السعر لا يمكن أن يكون سالباً';
    return null;
  }

  /// Validate quantity
  static String? quantity(String? value) {
    if (value == null || value.isEmpty) return 'الكمية مطلوبة';
    final qty = int.tryParse(value);
    if (qty == null) return 'كمية غير صحيحة';
    if (qty < 0) return 'الكمية لا يمكن أن تكون سالبة';
    return null;
  }

  /// Validate store name
  static String? storeName(String? value) {
    if (value == null || value.isEmpty) return 'اسم المتجر مطلوب';
    if (value.length < 2) return 'الاسم قصير جداً';
    return null;
  }

  /// Validate phone number (Egyptian format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    if (!RegExp(r'^\+?[\d\s-]{8,15}$').hasMatch(value)) return 'رقم هاتف غير صحيح';
    return null;
  }
}