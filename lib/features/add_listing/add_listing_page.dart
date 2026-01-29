import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../widgets/common/custom_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../core/state/models/listing_form_model.dart';
import 'widgets/progress_indicator.dart';
import 'steps/step1_type_location.dart';
import 'steps/step2_basics.dart';
import 'steps/step3_details.dart';
import 'steps/step4_photos.dart';
import 'steps/step5_contact.dart';
import 'steps/step6_summary.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  int _currentStep = 0;
  final _formData = ListingFormData();

  /// Błędy walidacji kroku 1 (ustawiane przy naciśnięciu "Dalej" przy niewypełnionych polach).
  Map<String, String?>? _step1Errors;

  final _stepLabels = [
    'Typ',
    'Podstawy',
    'Szczegóły',
    'Zdjęcia',
    'Kontakt',
    'Podsumowanie',
  ];

  final _stepLabelsShort = [
    'Typ',
    'Podst.',
    'Szczeg.',
    'Zdjęcia',
    'Kontakt',
    'Podsum.',
  ];

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _formData.isStep1Valid();
      case 1:
        return _formData.isStep2Valid();
      case 2:
        return _formData.isStep3Valid();
      case 3:
        return _formData.isStep4Valid();
      case 4:
        return _formData.isStep5Valid();
      case 5:
        return _formData.isStep6Valid();
      default:
        return true;
    }
  }

  bool _hasUnsavedData() {
    return _formData.transactionType != null ||
        _formData.propertyType != null ||
        (_formData.city != null && _formData.city!.trim().isNotEmpty) ||
        (_formData.district != null && _formData.district!.trim().isNotEmpty) ||
        (_formData.street != null && _formData.street!.trim().isNotEmpty);
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
      if (_currentStep == 0) {
        setState(() {
          _step1Errors = _formData.validationErrorsForStep1();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij wymagane pola')),
      );
      return;
    }
    setState(() {
      _step1Errors = null;
      _currentStep++;
    });
  }

  void _goPrev() {
    setState(() {
      _step1Errors = null;
      _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep >= _stepLabels.length - 1;
    final nextLabel = isLastStep ? 'Opublikuj' : 'Dalej';

    return PopScope(
      canPop: !_hasUnsavedData(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedData()) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        appBar: const AppBarCustom(showBackButton: true),
        body: Semantics(
          label: 'Krok ${_currentStep + 1} z ${_stepLabels.length}, ${_stepLabels[_currentStep]}',
          child: Column(
            children: [
              StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: _stepLabels.length,
                stepLabels: _stepLabels,
                stepLabelsShort: _stepLabelsShort,
                onStepTapped: (index) {
                  if (index <= _currentStep) {
                    setState(() {
                      _currentStep = index;
                      _step1Errors = null;
                    });
                  }
                },
              ),
              Expanded(
                child: _buildCurrentStep(),
              ),
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
                          onPressed: _goPrev,
                          variant: ButtonVariant.outlined,
                          fullWidth: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 1,
                      child: Semantics(
                        label: isLastStep
                            ? 'Opublikuj ogłoszenie'
                            : 'Dalej do kroku ${_stepLabels[_currentStep + 1]}',
                        child: CustomButton(
                          label: nextLabel,
                          onPressed: isLastStep ? _publish : _goNext,
                          variant: ButtonVariant.primary,
                          fullWidth: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _publish() {
    if (_currentStep < _stepLabels.length - 1) return;
    if (!_formData.isStep6Valid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz pakiet publikacji i zaakceptuj regulamin'),
        ),
      );
      return;
    }
    if (context.mounted) {
      context.go('${AppRouter.addListing}/success');
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1TypeLocation(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
          validationErrors: _step1Errors,
        );
      case 1:
        return Step2Basics(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 2:
        return Step3Details(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 3:
        return Step4Photos(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 4:
        return Step5Contact(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      case 5:
        return Step6Summary(
          formData: _formData,
          onDataChanged: (_) => setState(() {}),
        );
      default:
        return Center(
          child: Text('Krok ${_currentStep + 1} - W budowie'),
        );
    }
  }
}
