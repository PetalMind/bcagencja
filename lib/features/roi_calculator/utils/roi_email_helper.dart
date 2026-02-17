import 'package:intl/intl.dart';
import '../models/roi_models.dart';

final _currencyFormat = NumberFormat('#,###', 'pl_PL');

/// Buduje temat i treść e-maila z podsumowaniem kalkulacji ROI.
class RoiEmailHelper {
  RoiEmailHelper._();

  static String _taxFormLabel(TaxForm form) {
    switch (form) {
      case TaxForm.ryczalt85:
        return 'Ryczałt 8,5%';
      case TaxForm.ryczalt125:
        return 'Ryczałt 12,5%';
      case TaxForm.skala:
        return 'Skala podatkowa';
      case TaxForm.cit9:
        return 'CIT 9%';
      case TaxForm.cit19:
        return 'CIT 19%';
    }
  }

  static String subject(RoiQuickResults results) {
    return 'Kalkulacja ROI ${results.roi.toStringAsFixed(1)}% – BC Agencja';
  }

  /// Treść e-maila (zwykły tekst) – parametry wejściowe + wyniki.
  static String body({
    required RoiQuickInputs inputs,
    required RoiQuickResults results,
    RoiAdvancedInputs? advancedInputs,
    RoiAdvancedResults? advancedResults,
  }) {
    final buf = StringBuffer();
    buf.writeln('Podsumowanie kalkulacji ROI – BC Agencja');
    buf.writeln('========================================');
    buf.writeln('');
    buf.writeln('--- PARAMETRY ---');
    buf.writeln('Cena zakupu: ${_currencyFormat.format(inputs.purchasePrice.round())} PLN');
    buf.writeln('Czynsz roczny: ${_currencyFormat.format(inputs.annualRent.round())} PLN');
    buf.writeln('Koszty operacyjne (rocznie): ${_currencyFormat.format(inputs.operatingCosts.round())} PLN');
    buf.writeln('Finansowanie: ${inputs.financing == FinancingType.cash ? "Gotówka" : "Kredyt"}');
    if (inputs.financing == FinancingType.credit) {
      buf.writeln('Wkład własny: ${inputs.downPaymentPercent.toStringAsFixed(0)}%');
      buf.writeln('Oprocentowanie: ${inputs.interestRate.toStringAsFixed(1)}%');
      buf.writeln('Okres kredytu: ${inputs.loanTermYears} lat');
    }
    buf.writeln('Forma opodatkowania: ${_taxFormLabel(inputs.taxForm)}');
    buf.writeln('');
    buf.writeln('--- WYNIKI ---');
    buf.writeln('ROI: ${results.roi.toStringAsFixed(1)}%');
    buf.writeln('ROE: ${results.roe.toStringAsFixed(1)}%');
    buf.writeln('Zysk netto (rok 1): ${_currencyFormat.format(results.netProfitYear1.round())} PLN');
    buf.writeln('Okres zwrotu: ${results.paybackYears.toStringAsFixed(1)} lat');
    buf.writeln('NOI: ${_currencyFormat.format(results.noi.round())} PLN');
    if (inputs.financing == FinancingType.credit) {
      buf.writeln('Rata miesięczna: ${_currencyFormat.format(results.monthlyPayment.round())} PLN');
      buf.writeln('DSCR: ${results.dscr == double.infinity ? "—" : results.dscr.toStringAsFixed(2)}');
    }
    if (advancedResults != null && advancedInputs != null) {
      buf.writeln('');
      buf.writeln('--- TRYB ZAAWANSOWANY ---');
      buf.writeln('Horyzont: ${advancedInputs.investmentHorizonYears} lat');
      buf.writeln('NPV: ${_currencyFormat.format(advancedResults.npv.round())} PLN');
      buf.writeln('IRR: ${advancedResults.irr.toStringAsFixed(1)}%');
      buf.writeln('Zysk skumulowany: ${_currencyFormat.format(advancedResults.cumulativeProfit.round())} PLN');
      buf.writeln('Wartość nieruchomości (koniec): ${_currencyFormat.format(advancedResults.finalPropertyValue.round())} PLN');
    }
    buf.writeln('');
    buf.writeln('---');
    buf.writeln('Wygenerowano w Kalkulatorze ROI – BC Agencja');
    return buf.toString();
  }
}
