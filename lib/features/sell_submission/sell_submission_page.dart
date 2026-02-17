import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/services/listing_submission_service.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/mobile_menu.dart';
import '../../widgets/common/custom_button.dart';
import '../add_listing/widgets/progress_indicator.dart';
import 'listing_submission_model.dart';
import 'steps/step1_what_where.dart';
import 'steps/step2_contact.dart';
import 'steps/step3_summary.dart';

/// Lead magnet "Chcę sprzedać" – prosty, zachęcający proces zgłoszenia.
/// Zgłoszenia trafiają do Firestore `listing_submissions` (status: pending) – baza "Oczekiwanie" w panelu admina.
class SellSubmissionPage extends StatefulWidget {
  const SellSubmissionPage({super.key});

  @override
  State<SellSubmissionPage> createState() => _SellSubmissionPageState();
}

class _SellSubmissionPageState extends State<SellSubmissionPage> {
  int _currentStep = 0;
  final _formData = ListingSubmissionData();
  bool _isSubmitting = false;
  final _submissionService = ListingSubmissionService();

  static const _stepLabels = ['Co i gdzie', 'Kontakt', 'Podsumowanie'];
  static const _stepLabelsShort = ['Co i gdzie', 'Kontakt', 'Podsum.'];

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _formData.isStep1Valid;
      case 1:
        return _formData.isStep2Valid;
      case 2:
        return true;
      default:
        return true;
    }
  }

  bool _hasUnsavedData() {
    return _formData.assetType != null ||
        (_formData.city != null && _formData.city!.trim().isNotEmpty) ||
        (_formData.contactName != null &&
            _formData.contactName!.trim().isNotEmpty) ||
        (_formData.contactEmail != null &&
            _formData.contactEmail!.trim().isNotEmpty);
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

  Future<void> _submit() async {
    if (!_formData.isStep1Valid || !_formData.isStep2Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wszystkie wymagane pola')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _submissionService.submit(_formData);
      if (!mounted) return;
      context.go('${AppRouter.chceSprzedac}/sukces');
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
    final isLastStep = _currentStep >= _stepLabels.length - 1;

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
              totalSteps: _stepLabels.length,
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
                        label: 'Wstecz',
                        onPressed: _isSubmitting ? null : _goPrev,
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
        return Step1WhatWhere(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 1:
        return Step2Contact(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 2:
        return Step3Summary(formData: _formData);
      default:
        return const Center(child: Text('Krok nieznany'));
    }
  }
}
