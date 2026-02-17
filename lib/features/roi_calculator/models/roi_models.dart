// Modele dla kalkulatora ROI nieruchomości komercyjnych.

/// Tryb finansowania: gotówka lub kredyt/leasing
enum FinancingType { cash, credit }

/// Forma opodatkowania
enum TaxForm {
  ryczalt85,  // Ryczałt 8.5% (najem prywatny)
  ryczalt125, // Ryczałt 12.5% (najem komercyjny)
  skala,      // Skala podatkowa 17%/32%
  cit9,       // CIT 9% (mała firma)
  cit19,      // CIT 19%
}

/// Parametry wejściowe trybu szybkiego
class RoiQuickInputs {
  const RoiQuickInputs({
    this.purchasePrice = 2000000,
    this.annualRent = 180000,
    this.operatingCosts = 30000,
    this.financing = FinancingType.credit,
    this.downPaymentPercent = 30,
    this.interestRate = 7.5,
    this.loanTermYears = 20,
    this.taxForm = TaxForm.ryczalt125,
  });

  final double purchasePrice;
  final double annualRent;
  final double operatingCosts;
  final FinancingType financing;
  final double downPaymentPercent;
  final double interestRate;
  final int loanTermYears;
  final TaxForm taxForm;

  RoiQuickInputs copyWith({
    double? purchasePrice,
    double? annualRent,
    double? operatingCosts,
    FinancingType? financing,
    double? downPaymentPercent,
    double? interestRate,
    int? loanTermYears,
    TaxForm? taxForm,
  }) =>
      RoiQuickInputs(
        purchasePrice: purchasePrice ?? this.purchasePrice,
        annualRent: annualRent ?? this.annualRent,
        operatingCosts: operatingCosts ?? this.operatingCosts,
        financing: financing ?? this.financing,
        downPaymentPercent: downPaymentPercent ?? this.downPaymentPercent,
        interestRate: interestRate ?? this.interestRate,
        loanTermYears: loanTermYears ?? this.loanTermYears,
        taxForm: taxForm ?? this.taxForm,
      );
}

/// Parametry wejściowe trybu zaawansowanego (rozszerzają szybki)
class RoiAdvancedInputs extends RoiQuickInputs {
  const RoiAdvancedInputs({
    super.purchasePrice,
    super.annualRent,
    super.operatingCosts,
    super.financing,
    super.downPaymentPercent,
    super.interestRate,
    super.loanTermYears,
    super.taxForm,
    this.acquisitionCosts = 80000,
    this.vacancyRenovation = 0,
    this.propertyValueGrowthPercent = 3,
    this.rentGrowthPercent = 2,
    this.investmentHorizonYears = 10,
  });

  final double acquisitionCosts;
  final double vacancyRenovation;
  final double propertyValueGrowthPercent;
  final double rentGrowthPercent;
  final int investmentHorizonYears;

  RoiAdvancedInputs copyWithAdvanced({
    double? purchasePrice,
    double? annualRent,
    double? operatingCosts,
    FinancingType? financing,
    double? downPaymentPercent,
    double? interestRate,
    int? loanTermYears,
    TaxForm? taxForm,
    double? acquisitionCosts,
    double? vacancyRenovation,
    double? propertyValueGrowthPercent,
    double? rentGrowthPercent,
    int? investmentHorizonYears,
  }) =>
      RoiAdvancedInputs(
        purchasePrice: purchasePrice ?? this.purchasePrice,
        annualRent: annualRent ?? this.annualRent,
        operatingCosts: operatingCosts ?? this.operatingCosts,
        financing: financing ?? this.financing,
        downPaymentPercent: downPaymentPercent ?? this.downPaymentPercent,
        interestRate: interestRate ?? this.interestRate,
        loanTermYears: loanTermYears ?? this.loanTermYears,
        taxForm: taxForm ?? this.taxForm,
        acquisitionCosts: acquisitionCosts ?? this.acquisitionCosts,
        vacancyRenovation: vacancyRenovation ?? this.vacancyRenovation,
        propertyValueGrowthPercent:
            propertyValueGrowthPercent ?? this.propertyValueGrowthPercent,
        rentGrowthPercent: rentGrowthPercent ?? this.rentGrowthPercent,
        investmentHorizonYears:
            investmentHorizonYears ?? this.investmentHorizonYears,
      );
}

/// Wyniki kalkulacji szybkiej
class RoiQuickResults {
  const RoiQuickResults({
    required this.roi,
    required this.roe,
    required this.netProfitYear1,
    required this.equity,
    required this.monthlyPayment,
    required this.paybackYears,
    required this.dscr,
    required this.noi,
    required this.annualLoanPayment,
  });

  final double roi;
  final double roe;
  final double netProfitYear1;
  final double equity;
  final double monthlyPayment;
  final double paybackYears;
  final double dscr;
  final double noi;
  final double annualLoanPayment;
}

/// Rząd tabeli rok-po-roku dla trybu zaawansowanego
class RoiYearRow {
  const RoiYearRow({
    required this.year,
    required this.rent,
    required this.costs,
    required this.netProfit,
  });

  final int year;
  final double rent;
  final double costs;
  final double netProfit;
}

/// Wyniki kalkulacji zaawansowanej
class RoiAdvancedResults {
  const RoiAdvancedResults({
    required this.npv,
    required this.irr,
    required this.yearRows,
    required this.cumulativeProfit,
    required this.finalPropertyValue,
    required this.totalReturn,
    required this.discountRate,
  });

  final double npv;
  final double irr;
  final List<RoiYearRow> yearRows;
  final double cumulativeProfit;
  final double finalPropertyValue;
  final double totalReturn;
  final double discountRate;
}

/// Predefiniowany scenariusz (przycisk "Mały lokal 500k" itd.)
class RoiScenario {
  const RoiScenario({
    required this.label,
    required this.inputs,
  });

  final String label;
  final RoiQuickInputs inputs;
}
