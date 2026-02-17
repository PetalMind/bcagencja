import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import 'models/roi_models.dart';
import 'widgets/roi_quick_section.dart';
import 'widgets/roi_advanced_section.dart';

/// Predefiniowane scenariusze (autouzupełnienie typowych wartości)
List<RoiScenario> _buildScenarios() {
  return [
    RoiScenario(
      label: 'Mały lokal 500k',
      inputs: const RoiQuickInputs(
        purchasePrice: 500000,
        annualRent: 45000,
        operatingCosts: 8000,
        financing: FinancingType.cash,
        downPaymentPercent: 100,
        interestRate: 7.5,
        loanTermYears: 20,
      ),
    ),
    RoiScenario(
      label: 'Obiekt handlowy 2M',
      inputs: const RoiQuickInputs(
        purchasePrice: 2000000,
        annualRent: 180000,
        operatingCosts: 30000,
        financing: FinancingType.credit,
        downPaymentPercent: 30,
        interestRate: 7.5,
        loanTermYears: 20,
      ),
    ),
    RoiScenario(
      label: 'Grunt 5M',
      inputs: const RoiQuickInputs(
        purchasePrice: 5000000,
        annualRent: 0,
        operatingCosts: 10000,
        financing: FinancingType.cash,
        downPaymentPercent: 100,
        interestRate: 7.5,
        loanTermYears: 20,
      ),
    ),
  ];
}

/// Strona kalkulatora ROI – publiczne narzędzie marketingowe.
/// Dwa tryby: Szybki (4–5 pól) i Zaawansowany (NPV, IRR, DCF).
class RoiCalculatorPage extends ConsumerStatefulWidget {
  const RoiCalculatorPage({super.key});

  @override
  ConsumerState<RoiCalculatorPage> createState() => _RoiCalculatorPageState();
}

class _RoiCalculatorPageState extends ConsumerState<RoiCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scenarios = _buildScenarios();

  void _onTabChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

    return Scaffold(
      appBar: AppBarCustom(showBackButton: true),
      drawer: isMobile ? const MobileMenu() : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  tabs: const [
                    Tab(text: 'Szybki'),
                    Tab(text: 'Zaawansowany'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _tabController.index == 0
                      ? RoiQuickSection(
                          key: const ValueKey('quick'),
                          scenarios: _scenarios,
                          onShowOffers: () {},
                        )
                      : RoiAdvancedSection(
                          key: const ValueKey('advanced'),
                          onShowOffers: () {},
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.savings_outlined, size: 40, color: AppColors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalkulator ROI Nieruchomości Komercyjnych',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sprawdź rentowność swojej potencjalnej inwestycji w 60 sekund',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
