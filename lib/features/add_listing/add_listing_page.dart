import 'package:flutter/material.dart';
import '../../widgets/navigation/app_bar_custom.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/state/models/listing_form_model.dart';
import 'widgets/progress_indicator.dart';
import 'steps/step1_type_location.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  int _currentStep = 0;
  final _formData = ListingFormData();
  
  final _stepLabels = [
    'Typ',
    'Podstawy',
    'Szczegóły',
    'Zdjęcia',
    'Kontakt',
    'Podsumowanie',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(showBackButton: true),
      body: Column(
        children: [
          StepProgressIndicator(
            currentStep: _currentStep,
            totalSteps: _stepLabels.length,
            stepLabels: _stepLabels,
          ),
          
          Expanded(
            child: _buildCurrentStep(),
          ),
          
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: const Text('Wstecz'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < _stepLabels.length - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        // Submit form
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ogłoszenie dodane!')),
                        );
                      }
                    },
                    child: Text(_currentStep < _stepLabels.length - 1 ? 'Dalej' : 'Opublikuj'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return Step1TypeLocation(
          formData: _formData,
          onDataChanged: (data) {
            setState(() {});
          },
        );
      default:
        return Center(
          child: Text('Krok ${_currentStep + 1} - W budowie'),
        );
    }
  }
}
