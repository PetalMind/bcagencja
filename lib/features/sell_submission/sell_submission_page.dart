import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/services/listing_submission_service.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/custom_button.dart';
import 'widgets/progress_indicator.dart';
import 'listing_submission_model.dart';
import 'steps/step1_property_type.dart';
import 'steps/step2_location.dart';
import 'steps/step3_basic_data.dart';
import 'steps/step4_price.dart';
import 'steps/step5_documentation.dart';
import 'steps/step6_contact.dart';

/// Lead magnet "Chcę sprzedać" – 6-krokowy wizard.
/// Zgłoszenia trafiają do Firestore `listing_submissions` (status: pending) – baza "Oczekiwanie" w panelu admina.
class SellSubmissionPage extends StatefulWidget {
  const SellSubmissionPage({super.key});

  @override
  State<SellSubmissionPage> createState() => _SellSubmissionPageState();
}

class _SellSubmissionPageState extends State<SellSubmissionPage> {
  static const int _totalSteps = 6;
  int _currentStep = 0;
  final _formData = ListingSubmissionData();
  bool _isSubmitting = false;
  final _submissionService = ListingSubmissionService();

  static const _stepLabels = [
    'Typ',
    'Lokalizacja',
    'Dane',
    'Cena',
    'Dokumenty',
    'Kontakt',
  ];
  static const _stepLabelsShort = [
    'Typ',
    'Lokalizacja',
    'Dane',
    'Cena',
    'Dok.',
    'Kontakt',
  ];

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _formData.isStep1Valid;
      case 1:
        return _formData.isStep2Valid;
      case 2:
        return _formData.isStep3Valid;
      case 3:
        return _formData.isStep4Valid;
      case 4:
        return _formData.isStep5Valid;
      case 5:
        return _formData.isStep6Valid;
      default:
        return true;
    }
  }

  bool _hasUnsavedData() {
    return _formData.propertyType != null ||
        (_formData.city != null && _formData.city!.trim().isNotEmpty) ||
        (_formData.contactName != null && _formData.contactName!.trim().isNotEmpty) ||
        (_formData.contactEmail != null && _formData.contactEmail!.trim().isNotEmpty);
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyjdź z formularza?'),
        content: const Text(
          'Masz niewypełnione dane. Na pewno chcesz wyjść? Niezapisane zmiany zostaną utracone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nie'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tak, wyjdź'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.pop();
      }
    });
  }

  void _goNext() {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wymagane pola')),
      );
      return;
    }
    setState(() => _currentStep++);
  }

  void _goPrev() {
    setState(() => _currentStep--);
  }

  void _skipStep5() {
    setState(() => _currentStep++);
  }

  Future<void> _submit() async {
    if (!_formData.isStep1Valid ||
        !_formData.isStep2Valid ||
        !_formData.isStep3Valid ||
        !_formData.isStep6Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wszystkie wymagane pola')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (_formData.estimatedValueMin == null && _formData.estimatedRangeFromRent != null) {
        _formData.estimatedValueMin = _formData.estimatedRangeFromRent!.$1;
        _formData.estimatedValueMax = _formData.estimatedRangeFromRent!.$2;
      }
      final id = await _submissionService.submit(_formData);
      if (!mounted) return;
      context.go(
        '${AppRouter.chceSprzedac}/sukces',
        extra: {'submissionId': id, 'email': _formData.contactEmail},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się wysłać zgłoszenia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < AppSpacing.mobileBreakpoint;
    final isLastStep = _currentStep >= _totalSteps - 1;
    final isStep5 = _currentStep == 4;

    return PopScope(
      canPop: !_hasUnsavedData(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedData()) _showExitConfirmation(context);
      },
      child: Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        drawer: isMobile ? const MobileMenu() : null,
        body: Column(
          children: [
            StepProgressIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepLabels: _stepLabels,
              stepLabelsShort: _stepLabelsShort,
              onStepTapped: (index) {
                if (index <= _currentStep) setState(() => _currentStep = index);
              },
            ),
            Expanded(child: _buildCurrentStep()),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: CustomButton(
                        label: 'Wróć',
                        onPressed: _isSubmitting ? null : _goPrev,
                        variant: ButtonVariant.outlined,
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  if (isStep5) ...[
                    Expanded(
                      child: CustomButton(
                        label: 'Pomiń ten krok',
                        onPressed: _isSubmitting ? null : _skipStep5,
                        variant: ButtonVariant.outlined,
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: CustomButton(
                      label: isLastStep ? 'Wyślij zgłoszenie' : 'Dalej',
                      onPressed: _isSubmitting
                          ? null
                          : (isLastStep ? _submit : _goNext),
                      variant: ButtonVariant.primary,
                      fullWidth: true,
                      isLoading: isLastStep && _isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isMobile ? const BottomNavBar(currentIndex: 0) : null,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1PropertyType(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
          onTypeSelected: () => _goNext(),
        );
      case 1:
        return Step2Location(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
          onAddressSelected: () => _goNext(),
        );
      case 2:
        return Step3BasicData(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 3:
        return Step4Price(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 4:
        return Step5Documentation(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 5:
        return Step6Contact(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      default:
        return const Center(child: Text('Krok nieznany'));
    }
  }
}
