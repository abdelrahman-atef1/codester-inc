/// invoice_list_screen.dart — T-014: Invoice List Screen
///
/// Paper Ledger style: cream paper, bordered cards, filter tabs, search,
/// staggered animation, empty state, status badges, payment icons.
/// RTL Arabic-first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/database.dart' as db;
import '../../providers/invoice_providers.dart';
import '../widgets/invoice_card.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final filter = ref.watch(invoiceFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navInvoices),
        automaticallyImplyLeading: false,
        actions: [
          // ─── بيع جديد ⚡ button ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
            child: FilledButton.icon(
              onPressed: () => context.push('/pos'),
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('بيع جديد ⚡'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.stampRed,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                  vertical: AppSizes.paddingSM,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: AppSizes.sm),
          // Filter tabs
          _buildFilterTabs(filter),
          const SizedBox(height: AppSizes.sm),
          // Invoice list
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return _buildEmptyState();
                }
                // Trigger stagger animation
                _staggerController.reset();
                _staggerController.forward();
                return _buildInvoiceList(invoices);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.forest,
                  strokeWidth: 2,
                ),
              ),
              error: (err, stack) => _buildErrorState(err),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (value) {
          ref.read(invoiceSearchProvider.notifier).state = value;
        },
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: AppSizes.fontMD,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث برقم الفاتورة...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.inkMuted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(invoiceSearchProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
            vertical: AppSizes.paddingSM + 2,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            borderSide: const BorderSide(color: AppColors.ledgerBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            borderSide: const BorderSide(color: AppColors.forest, width: 2),
          ),
        ),
      ),
    );
  }

  // ─── Filter Tabs ───
  Widget _buildFilterTabs(InvoiceFilter currentFilter) {
    final tabs = [
      (InvoiceFilter.today, 'اليوم'),
      (InvoiceFilter.week, 'أسبوع'),
      (InvoiceFilter.month, 'شهر'),
      (InvoiceFilter.all, 'الكل'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = tabs[index];
          final isActive = currentFilter == value;
          return GestureDetector(
            onTap: () {
              ref.read(invoiceFilterProvider.notifier).state = value;
            },
            child: AnimatedContainer(
              duration: AppSizes.durationShort,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.forest : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSM),
                border: Border.all(
                  color: isActive ? AppColors.forest : AppColors.ledgerBorder,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: AppSizes.fontSM,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.background : AppColors.inkLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Invoice List with Staggered Animation ───
  Widget _buildInvoiceList(List<db.Invoice> invoices) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.sm,
      ),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        // Staggered fade + slide-up animation
        final intervalStart = (index * 0.08).clamp(0.0, 0.8);
        final intervalEnd = (intervalStart + 0.3).clamp(0.0, 1.0);
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
          ),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
          ),
        );

        return AnimatedBuilder(
          animation: _staggerController,
          builder: (context, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          child: InvoiceCard(
            invoice: invoices[index],
            onTap: () {
              context.push('/invoices/${invoices[index].id}');
            },
          ),
        );
      },
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.ledgerBorder, width: 2),
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 44,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          const Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontXL,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإنشاء فاتورة جديدة من نقطة البيع',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          // ─── ابدأ أول بيع button ───
          FilledButton.icon(
            onPressed: () => context.push('/pos'),
            icon: const Icon(Icons.point_of_sale, size: 20),
            label: const Text('ابدأ أول بيع'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.stampRed,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLG,
                vertical: AppSizes.paddingMD,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ───
  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.stampRed),
          const SizedBox(height: AppSizes.sm),
          Text(
            'حدث خطأ: $err',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: AppSizes.fontSM,
              color: AppColors.inkLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(invoiceListProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}