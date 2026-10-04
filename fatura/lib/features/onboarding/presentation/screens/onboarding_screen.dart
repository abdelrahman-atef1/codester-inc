/// onboarding_screen.dart — First-run wizard for store setup
/// Paper Ledger style: cream paper, ink text, forest green accents, bordered cards.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../../../inventory/providers/inventory_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _storePhoneController = TextEditingController();
  String _storeType = AppStrings.typeShop;

  // PIN setup
  String _pin = '';
  bool _pinMismatch = false;
  bool _pinTooShort = false;

  static const _pinMaxLength = 6;

  @override
  void dispose() {
    _pageController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: AppSizes.durationMedium,
        curve: Curves.easeInOutCubicEmphasized,
      );
    } else {
      _saveAndNavigate();
    }
  }

  void _skip() {
    context.go('/login');
  }

  Future<void> _saveAndNavigate() async {
    // Validate PIN length (4-6 digits)
    if (_pin.length < 4 || _pin.length > 6) {
      setState(() => _pinTooShort = true);
      return;
    }

    final database = ref.read(appDatabaseProvider);

    // 1. Insert store
    final storeId = await database.storesDao.insertStore(
      StoresCompanion(
        name: Value(_storeNameController.text.trim()),
        type: Value(_storeType),
        address: Value(_storeAddressController.text.trim()),
        phone: Value(_storePhoneController.text.trim()),
      ),
    );

    // 2. Hash PIN and insert Owner user
    final salt = generateSalt();
    final pinHash = hashPin(_pin, salt);

    await database.usersDao.insertUser(
      UsersCompanion(
        storeId: Value(storeId),
        name: const Value('المالك'),
        pinHash: Value(pinHash),
        pinSalt: Value(salt),
        role: const Value('owner'),
      ),
    );

    if (mounted) {
      context.go('/login');
    }
  }

  void _onPinDigitPressed(String digit) {
    if (_pin.length < _pinMaxLength) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += digit;
        _pinMismatch = false;
        _pinTooShort = false;
      });
    }
  }

  void _onPinDeletePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _pinMismatch = false;
        _pinTooShort = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    AppStrings.skip,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _welcomePage(),
                  _storeInfoPage(),
                  _storeTypePage(),
                  _pinSetupPage(),
                ],
              ),
            ),
            // Progress dots + button
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: AppSizes.durationShort,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? AppColors.forest
                              : AppColors.surfaceLight,
                          border: Border.all(
                            color: _currentPage == index
                                ? AppColors.forestDark
                                : AppColors.ledgerBorder,
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == 3 ? AppStrings.save : 'التالي',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.forest,
              border: Border.all(color: AppColors.forestDark, width: 2.5),
            ),
            child: const Icon(
              Icons.receipt,
              size: 60,
              color: AppColors.background,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            AppStrings.welcome,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            AppStrings.welcomeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _storeInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'بيانات المتجر',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSizes.xl),
          TextField(
            controller: _storeNameController,
            decoration: const InputDecoration(
              hintText: AppStrings.storeName,
              prefixIcon: Icon(Icons.store, color: AppColors.forest),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _storeAddressController,
            decoration: const InputDecoration(
              hintText: AppStrings.storeAddress,
              prefixIcon: Icon(Icons.location_on, color: AppColors.forest),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          TextField(
            controller: _storePhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: AppStrings.storePhone,
              prefixIcon: Icon(Icons.phone, color: AppColors.forest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeTypePage() {
    final types = [
      AppStrings.typeKiosk,
      AppStrings.typeShop,
      AppStrings.typeHandicraft,
      AppStrings.typeOther,
    ];
    final icons = [Icons.storefront, Icons.shop, Icons.handyman, Icons.more_horiz];

    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.storeType,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSizes.xl),
            ...List.generate(types.length, (index) {
              final isSelected = _storeType == types[index];
              return GestureDetector(
                onTap: () => setState(() => _storeType = types[index]),
                child: AnimatedContainer(
                  duration: AppSizes.durationShort,
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.forest.withValues(alpha: 0.08)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    border: Border.all(
                      color: isSelected ? AppColors.forest : AppColors.ledgerBorder,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icons[index],
                        color: isSelected ? AppColors.forest : AppColors.inkLight,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Text(
                        types[index],
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: AppSizes.fontLG,
                          color: isSelected ? AppColors.forest : AppColors.ink,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.forest),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _pinSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ادخل الرمز السري',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '4-6 أرقام — سيُستخدم للدخول للتطبيق',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinMaxLength, (index) {
              final isFilled = index < _pin.length;
              return AnimatedContainer(
                duration: AppSizes.durationMicro,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pinMismatch
                      ? AppColors.stampRed
                      : isFilled
                          ? AppColors.forest
                          : Colors.transparent,
                  border: Border.all(
                    color: _pinMismatch
                        ? AppColors.stampRed
                        : AppColors.inkMuted,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          // Fixed-height error area
          SizedBox(
            height: AppSizes.lg,
            child: AnimatedSwitcher(
              duration: AppSizes.durationShort,
              child: _pinMismatch
                  ? Text(
                      'الرمزان غير متطابقين',
                      key: const ValueKey('mismatch'),
                      style: TextStyle(
                        color: AppColors.stampRed,
                        fontFamily: 'Cairo',
                        fontSize: AppSizes.fontSM,
                      ),
                    )
                  : _pinTooShort
                      ? Text(
                          'الرمز يجب أن يكون 4-6 أرقام',
                          key: const ValueKey('short'),
                          style: TextStyle(
                            color: AppColors.stampRed,
                            fontFamily: 'Cairo',
                            fontSize: AppSizes.fontSM,
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty')),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // Numpad
          _buildOnboardingNumPad(),
        ],
      ),
    );
  }

  Widget _buildOnboardingNumPad() {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['delete', '0', null],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              textDirection: TextDirection.rtl,
              children: row.map((digit) {
                if (digit == null) {
                  return const SizedBox(width: 72, height: 72);
                }
                if (digit == 'delete') {
                  return _OnboardingNumPadButton(
                    icon: Icons.backspace_outlined,
                    onTap: _onPinDeletePressed,
                  );
                }
                return _OnboardingNumPadButton(
                  label: digit,
                  onTap: () => _onPinDigitPressed(digit),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _OnboardingNumPadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _OnboardingNumPadButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.ledgerBorder, width: 1.5),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: AppColors.inkLight, size: 28)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
        ),
      ),
    );
  }
}