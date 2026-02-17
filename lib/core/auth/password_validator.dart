/// Walidator wymagań hasła.
class PasswordValidator {
  static const int minLength = 8;

  static bool hasUppercase(String password) =>
      password.contains(RegExp(r'[A-Z]'));

  static bool hasLowercase(String password) =>
      password.contains(RegExp(r'[a-z]'));

  static bool hasSpecialCharacter(String password) =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'));

  static bool hasNumericCharacter(String password) =>
      password.contains(RegExp(r'[0-9]'));

  static bool hasMinLength(String password) => password.length >= minLength;

  /// Sprawdza, czy hasło spełnia wszystkie wymagania.
  static bool isValid(String password) =>
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasSpecialCharacter(password) &&
      hasNumericCharacter(password) &&
      hasMinLength(password);

  /// Zwraca listę niespełnionych wymagań.
  static List<String> getFailedRequirements(String password) {
    final failed = <String>[];
    if (!hasUppercase(password)) failed.add('Wielka litera');
    if (!hasLowercase(password)) failed.add('Mała litera');
    if (!hasSpecialCharacter(password)) failed.add('Znak specjalny');
    if (!hasNumericCharacter(password)) failed.add('Cyfra');
    if (!hasMinLength(password)) failed.add('Min. $minLength znaków');
    return failed;
  }
}
