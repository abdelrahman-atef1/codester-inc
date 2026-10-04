/// app_strings.dart — App-wide string constants for Fatura
///
/// Arabic-first strings. English fallbacks included.
library;

class AppStrings {
  AppStrings._();

  // ===== App Info =====
  static const String appName = 'فاتورة';
  static const String appNameEn = 'Fatura';
  static const String appTagline = 'نظام إدارة المبيعات والفواتير';

  // ===== Navigation =====
  static const String navPos = 'نقطة البيع';
  static const String navInvoices = 'الفواتير';
  static const String navInventory = 'المخزون';
  static const String navReports = 'التقارير';
  static const String navSettings = 'الإعدادات';

  // ===== Auth =====
  static const String enterPin = 'أدخل الرمز السري';
  static const String pinHint = '4-6 أرقام';
  static const String wrongPin = 'رمز خاطئ، حاول مرة أخرى';
  static const String login = 'تسجيل الدخول';
  static const String logout = 'تسجيل الخروج';

  // ===== Onboarding =====
  static const String welcome = 'مرحباً بك في فاتورة';
  static const String welcomeSubtitle = 'لنبدأ بإعداد متجرك';
  static const String storeName = 'اسم المتجر';
  static const String storeType = 'نوع المتجر';
  static const String storeAddress = 'العنوان';
  static const String storePhone = 'رقم الهاتف';
  static const String save = 'حفظ ومتابعة';
  static const String skip = 'تخطٍ';

  // ===== Store Types =====
  static const String typeKiosk = 'كشك';
  static const String typeShop = 'متجر';
  static const String typeHandicraft = 'صناع يدوي';
  static const String typeOther = 'أخرى';

  // ===== POS =====
  static const String quickSale = 'بيع سريع';
  static const String scanBarcode = 'امسح الباركود';
  static const String cart = 'السلة';
  static const String checkout = 'إتمام البيع';
  static const String paymentMethod = 'طريقة الدفع';
  static const String cash = 'نقداً';
  static const String card = 'بطاقة';
  static const String wallet = 'محفظة إلكترونية';
  static const String total = 'الإجمالي';
  static const String subtotal = 'المجموع الفرعي';
  static const String tax = 'ضريبة';
  static const String discount = 'خصم';
  static const String amountPaid = 'المبلغ المدفوع';
  static const String change = 'الباقي';
  static const String emptyCart = 'السلة فارغة';
  static const String productNotFound = 'منتج غير موجود، هل تريد إضافته يدوياً؟';

  // ===== Invoices =====
  static const String invoiceNumber = 'رقم الفاتورة';
  static const String invoiceDate = 'تاريخ الفاتورة';
  static const String customerName = 'اسم العميل';
  static const String customerPhone = 'هاتف العميل';
  static const String share = 'مشاركة';
  static const String print = 'طباعة';
  static const String refund = 'استرجاع';
  static const String invoiceStatusDraft = 'مسودة';
  static const String invoiceStatusCompleted = 'مكتملة';
  static const String invoiceStatusRefunded = 'مسترجعة';

  // ===== Inventory =====
  static const String addProduct = 'إضافة منتج';
  static const String editProduct = 'تعديل منتج';
  static const String productName = 'اسم المنتج';
  static const String productPrice = 'السعر';
  static const String productCost = 'التكلفة';
  static const String productQuantity = 'الكمية';
  static const String productBarcode = 'الباركود';
  static const String productMinQuantity = 'حد التنبيه';
  static const String productCategory = 'الفئة';
  static const String productUnit = 'الوحدة';
  static const String lowStock = 'مخزون منخفض';
  static const String lowStockWarning = 'منتجات تحتاج إعادة طلب';

  // ===== Reports =====
  static const String dailyReport = 'تقرير اليوم';
  static const String monthlyReport = 'تقرير شهري';
  static const String totalSales = 'إجمالي المبيعات';
  static const String invoiceCount = 'عدد الفواتير';
  static const String topProducts = 'أكثر المنتجات مبيعاً';
  static const String exportPdf = 'تصدير PDF';

  // ===== Settings =====
  static const String language = 'اللغة';
  static const String currency = 'العملة';
  static const String arabic = 'العربية';
  static const String english = 'English';
  static const String backup = 'نسخة احتياطية';
  static const String googleDrive = 'Google Drive';
  static const String about = 'عن التطبيق';

  // ===== Users =====
  static const String addUser = 'إضافة موظف';
  static const String editUser = 'تعديل موظف';
  static const String userName = 'الاسم';
  static const String userPin = 'الرمز السري';
  static const String userRole = 'الدور';
  static const String userPermissions = 'الصلاحيات';
  static const String userStatus = 'الحالة';
  static const String userActive = 'نشط';
  static const String userInactive = 'معطل';
  static const String roleOwner = 'مالك';
  static const String roleClerk = 'بائع';
  static const String roleInventory = 'مدير مخزون';
  static const String roleViewer = 'مشاهد';
  static const String deactivateUser = 'تعطيل';
  static const String activateUser = 'تفعيل';
  static const String deleteUser = 'حذف الموظف';
  static const String confirmDeleteUser = 'هل أنت متأكد من حذف هذا الموظف؟';
  static const String noUsers = 'لا يوجد موظفون بعد';
  static const String pinMustBe4To6 = 'الرمز يجب أن يكون 4-6 أرقام';
  static const String nameRequired = 'الاسم مطلوب';
  static const String selectRole = 'اختر الدور';

  // ===== Activity Log =====
  static const String activityLog = 'سجل النشاط';
  static const String activityAll = 'الكل';
  static const String activitySale = 'بيع';
  static const String activityInventory = 'مخزون';
  static const String activityLogin = 'تسجيل دخول';
  static const String activityEdit = 'تعديل';
  static const String activityAdd = 'إضافة';
  static const String activityDelete = 'حذف';
  static const String noActivity = 'لا يوجد نشاط مسجل';
  static const String filterByType = 'تصفية حسب النوع';

  // ===== Role-based messages =====
  static const String accessDenied = 'لا تملك صلاحية الوصول لهذه الشاشة';
  static const String ownerOnly = 'هذه الشاشة متاحة للمالك فقط';
  static const String selectYourRole = 'اختر دورك';
  static const String loginAs = 'تسجيل الدخول كـ';

  // ===== Common =====
  static const String save2 = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String confirm = 'تأكيد';
  static const String yes = 'نعم';
  static const String no = 'لا';
  static const String loading = 'جاري التحميل...';
  static const String error = 'حدث خطأ';
  static const String retry = 'إعادة المحاولة';
  static const String search = 'بحث';

  // ===== Currencies =====
  static const String currencyEGP = 'ج.م';
  static const String currencySAR = 'ر.س';
  static const String currencyAED = 'د.إ';
  static const String currencyKWD = 'د.ك';
  static const String currencyUSD = '\$';
}