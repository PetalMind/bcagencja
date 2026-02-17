import '../models/roi_models.dart';

/// Logika obliczeń ROI dla nieruchomości komercyjnych.
/// Formuły zgodne ze specyfikacją.
class RoiCalculations {
  RoiCalculations._();

  /// Stawka podatkowa dla danej formy opodatkowania
  static double _taxRate(TaxForm form) {
    switch (form) {
      case TaxForm.ryczalt85:
        return 0.085;
      case TaxForm.ryczalt125:
        return 0.125;
      case TaxForm.skala:
        return 0.19; // uproszczone - średnia
      case TaxForm.cit9:
        return 0.09;
      case TaxForm.cit19:
        return 0.19;
    }
  }

  /// Przychód - koszty = dochód przed opodatkowaniem
  static double _grossProfit(double rent, double opex) => rent - opex;

  /// Podatek od dochodu
  static double _taxAmount(double grossProfit, TaxForm form) {
    if (grossProfit <= 0) return 0;
    return grossProfit * _taxRate(form);
  }

  /// Zysk netto roczny (bez kredytu)
  static double netProfitCash(
    double annualRent,
    double operatingCosts,
    TaxForm taxForm,
  ) {
    final gross = _grossProfit(annualRent, operatingCosts);
    final tax = _taxAmount(gross, taxForm);
    return gross - tax;
  }

  /// NOI (Net Operating Income) = Przychód - Koszty operacyjne (bez podatku)
  static double noi(double annualRent, double operatingCosts) =>
      annualRent - operatingCosts;

  /// ROI (Return on Investment) dla gotówki
  /// ROI = (Przychód - Koszty - Podatek) / Cena zakupu * 100%
  static double roiCash(
    double purchasePrice,
    double annualRent,
    double operatingCosts,
    TaxForm taxForm,
  ) {
    if (purchasePrice <= 0) return 0;
    final net = netProfitCash(annualRent, operatingCosts, taxForm);
    return (net / purchasePrice) * 100;
  }

  /// Miesięczna rata kredytu (annuity formula)
  /// P = L * [r(1+r)^n] / [(1+r)^n - 1]
  /// gdzie L = kwota kredytu, r = miesięczna stopa, n = liczba miesięcy
  static double monthlyPayment(
    double loanAmount,
    double annualInterestRate,
    int years,
  ) {
    if (loanAmount <= 0 || years <= 0) return 0;
    final r = annualInterestRate / 100 / 12;
    final n = years * 12;
    if (r == 0) return loanAmount / n;
    return loanAmount * (r * _pow(1 + r, n)) / (_pow(1 + r, n) - 1);
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  /// ROE (Return on Equity) dla kredytu
  /// ROE = (Zysk netto - Koszty kredytu) / Kapitał własny * 100%
  static double roe(
    double equity,
    double netProfitBeforeLoan,
    double annualLoanPayment,
  ) {
    if (equity <= 0) return 0;
    final netAfterLoan = netProfitBeforeLoan - annualLoanPayment;
    return (netAfterLoan / equity) * 100;
  }

  /// DSCR = NOI / Roczna spłata kredytu
  static double dscr(double noiValue, double annualLoanPayment) {
    if (annualLoanPayment <= 0) return double.infinity;
    return noiValue / annualLoanPayment;
  }

  /// Okres zwrotu (lata) = Kapitał własny / Zysk netto roczny
  static double paybackYears(double equity, double annualNetProfit) {
    if (annualNetProfit <= 0) return double.infinity;
    return equity / annualNetProfit;
  }

  /// Oblicza wyniki dla trybu szybkiego
  static RoiQuickResults calculateQuick(RoiQuickInputs inputs) {
    final gross = _grossProfit(inputs.annualRent, inputs.operatingCosts);
    final tax = _taxAmount(gross, inputs.taxForm);
    final netProfitBeforeLoan = gross - tax;
    final roiValue = roiCash(
      inputs.purchasePrice,
      inputs.annualRent,
      inputs.operatingCosts,
      inputs.taxForm,
    );
    final noiValue = noi(inputs.annualRent, inputs.operatingCosts);

    if (inputs.financing == FinancingType.cash) {
      return RoiQuickResults(
        roi: roiValue,
        roe: roiValue, // dla gotówki ROE = ROI (cały kapitał to equity)
        netProfitYear1: netProfitBeforeLoan,
        equity: inputs.purchasePrice,
        monthlyPayment: 0,
        paybackYears: paybackYears(inputs.purchasePrice, netProfitBeforeLoan),
        dscr: double.infinity,
        noi: noiValue,
        annualLoanPayment: 0,
      );
    }

    // Kredyt
    final equity = inputs.purchasePrice * (inputs.downPaymentPercent / 100);
    final loanAmount = inputs.purchasePrice - equity;
    final monthly = monthlyPayment(
      loanAmount,
      inputs.interestRate,
      inputs.loanTermYears,
    );
    final annualLoan = monthly * 12;
    final roeValue = roe(equity, netProfitBeforeLoan, annualLoan);
    final dscrValue = dscr(noiValue, annualLoan);
    final netAfterLoan = netProfitBeforeLoan - annualLoan;
    final payback = paybackYears(equity, netAfterLoan > 0 ? netAfterLoan : 0);

    return RoiQuickResults(
      roi: roiValue, // ROI = yield nieruchomości (przed kredytem)
      roe: roeValue,
      netProfitYear1: netAfterLoan,
      equity: equity,
      monthlyPayment: monthly,
      paybackYears: payback,
      dscr: dscrValue,
      noi: noiValue,
      annualLoanPayment: annualLoan,
    );
  }

  /// Oblicza wyniki dla trybu zaawansowanego (NPV, IRR, tabela rok-po-roku)
  static RoiAdvancedResults calculateAdvanced(RoiAdvancedInputs inputs) {
    final quick = calculateQuick(inputs);
    final discountRate = 0.05; // 5% stopa dyskonta

    // Tabela rok-po-roku z prognozą czynszu i kosztów
    final rows = <RoiYearRow>[];
    double rent = inputs.annualRent;
    double totalCostsBase = inputs.operatingCosts;
    double cumulativeProfit = 0;
    double pvSum = 0;

    // Koszt kredytu roczny (maleje przy spłacie - uproszczenie: stała rata)
    double annualLoan = 0;
    if (inputs.financing == FinancingType.credit) {
      annualLoan = quick.annualLoanPayment;
    }

    for (int year = 1; year <= inputs.investmentHorizonYears; year++) {
      // Wzrost czynszu (indeksacja)
      if (year > 1) {
        rent *= (1 + inputs.rentGrowthPercent / 100);
      }
      // Koszty operacyjne - uproszczenie: stałe + ewent. inflacja
      final opex = totalCostsBase * (year == 1 ? 1 : 1.02); // 2% inflacja kosztów
      final gross = _grossProfit(rent, opex);
      final tax = _taxAmount(gross, inputs.taxForm);
      final netBeforeLoan = gross - tax;
      final netProfit = netBeforeLoan - annualLoan;
      cumulativeProfit += netProfit;

      rows.add(RoiYearRow(
        year: year,
        rent: rent,
        costs: opex + annualLoan,
        netProfit: netProfit,
      ));

      // PV dla NPV
      pvSum += netProfit / _pow(1 + discountRate, year);
    }

    // Inwestycja początkowa: zakup + koszty nabycia + remont
    final initialInvestment = inputs.purchasePrice +
        inputs.acquisitionCosts +
        inputs.vacancyRenovation;
    final equity = inputs.financing == FinancingType.credit
        ? inputs.purchasePrice * (inputs.downPaymentPercent / 100) +
            inputs.acquisitionCosts +
            inputs.vacancyRenovation
        : initialInvestment;

    // Wartość nieruchomości po N latach (wzrost)
    final finalPropertyValue = inputs.purchasePrice *
        _pow(1 + inputs.propertyValueGrowthPercent / 100, inputs.investmentHorizonYears);

    // NPV = -inwestycja + suma PV(cash flow)
    final npv = -equity + pvSum;

    // Zwrot całkowity (zysk skumulowany + wartość nieruchomości - pozostały dług)
    double remainingDebt = 0;
    if (inputs.financing == FinancingType.credit) {
      final loanAmount = inputs.purchasePrice - (inputs.purchasePrice * inputs.downPaymentPercent / 100);
      final totalPaid = quick.annualLoanPayment * inputs.investmentHorizonYears;
      // Uproszczenie: liniowa spłata - w rzeczywistości kapitał rośnie w czasie
      remainingDebt = (loanAmount - (totalPaid * 0.4)).clamp(0, double.infinity);
    }
    final totalReturn = cumulativeProfit + finalPropertyValue - remainingDebt - equity;

    // IRR - Newton-Raphson uproszczony
    final irr = _estimateIrr(equity, rows.map((r) => r.netProfit).toList());

    return RoiAdvancedResults(
      npv: npv,
      irr: irr,
      yearRows: rows,
      cumulativeProfit: cumulativeProfit,
      finalPropertyValue: finalPropertyValue,
      totalReturn: totalReturn,
      discountRate: discountRate,
    );
  }

  static double _estimateIrr(double initialInvestment, List<double> cashFlows) {
    if (cashFlows.isEmpty || initialInvestment <= 0) return 0;
    double rate = 0.1;
    for (int iter = 0; iter < 100; iter++) {
      double npv = -initialInvestment;
      for (int i = 0; i < cashFlows.length; i++) {
        npv += cashFlows[i] / _pow(1 + rate, i + 1);
      }
      if (npv.abs() < 100) break;
      rate += npv > 0 ? 0.01 : -0.01;
      rate = rate.clamp(0.01, 2.0);
    }
    return rate * 100;
  }
}
