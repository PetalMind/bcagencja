import 'role_permissions.dart';

/// Typ konta: osoba fizyczna vs firma (B2C vs B2B, NDA, faktury).
enum AccountType {
  person,
  company,
}

/// Role użytkownika w Firestore (legacy / backend).
enum UserRole {
  /// Anonim – tylko teasery (dla niezalogowanych).
  guest,

  /// Zalogowany inwestor (lead).
  lead,

  /// Agent – dodawanie ofert.
  agent,

  /// Dyrektor obszaru.
  director,

  /// Admin – pełny dostęp.
  admin,
}

/// Poziom dostępu do ofert (lejek walidacji).
enum AccessLevel {
  /// Tylko teasery – bez adresu, ograniczona galeria.
  teaser(1),

  /// Identity Verified – pełna oferta (lokalizacja, zdjęcia).
  identityVerified(2),

  /// VDR – dokumenty (operaty, umowy) z watermarkingiem.
  vdr(3);

  const AccessLevel(this.level);
  final int level;
}

/// Model użytkownika aplikacji (profil z Firestore + dane z Auth).
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final AccessLevel accessLevel;
  final DateTime? ndaAcceptedAt;
  final List<String> vdrAccessForListingIds;
  /// Województwo (dla dyrektora) – filtrowanie ofert.
  final String? regionVoivodeship;
  /// ID dyrektora (dla agenta).
  final String? directorId;
  /// Osoba fizyczna vs firma (B2C/B2B).
  final AccountType? accountType;
  /// NIP (dla firm).
  final String? nip;
  /// Nazwa firmy (dla firm, z rejestru lub z OAuth).
  final String? companyName;
  /// Adres firmy (z rejestru NIP, tylko do odczytu).
  final String? companyAddress;
  /// Telefon kontaktowy.
  final String? phone;
  /// Preferowane typy inwestycji (multi-select).
  final List<String> preferredInvestmentTypes;
  /// Budżet inwestycyjny min (PLN).
  final int? budgetMin;
  /// Budżet inwestycyjny max (PLN).
  final int? budgetMax;
  /// Czy email zweryfikowany (dla rejestracji NIP).
  final bool emailVerified;
  /// Link do profilu LinkedIn (OAuth).
  final String? linkedInProfileUrl;
  /// Czy konto jest zablokowane przez administratora.
  final bool isBlocked;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.lead,
    this.accessLevel = AccessLevel.teaser,
    this.ndaAcceptedAt,
    this.vdrAccessForListingIds = const [],
    this.regionVoivodeship,
    this.directorId,
    this.accountType,
    this.nip,
    this.companyName,
    this.companyAddress,
    this.phone,
    this.preferredInvestmentTypes = const [],
    this.budgetMin,
    this.budgetMax,
    this.emailVerified = false,
    this.linkedInProfileUrl,
    this.isBlocked = false,
  });

  bool get isGuest => role == UserRole.guest;
  bool get isLead => role == UserRole.lead;
  bool get isAgent => role == UserRole.agent;
  bool get isDirector => role == UserRole.director;
  bool get isAdmin => role == UserRole.admin;

  /// Efektywna rola (poziom) wg specyfikacji: GUEST, INVESTOR_BASIC, INVESTOR_VERIFIED, INVESTOR_VIP, AGENT, DIRECTOR, ADMIN.
  UserRoleLevel get effectiveRoleLevel {
    if (role == UserRole.admin) return UserRoleLevel.admin;
    if (role == UserRole.director) return UserRoleLevel.director;
    if (role == UserRole.agent) return UserRoleLevel.agent;
    if (role == UserRole.guest) return UserRoleLevel.guest;
    // lead
    if (ndaAcceptedAt == null) return UserRoleLevel.investorBasic;
    if (vdrAccessForListingIds.isNotEmpty) return UserRoleLevel.investorVip;
    return UserRoleLevel.investorVerified;
  }

  /// Dostęp do panelu agenta/dyrektora (dashboard).
  bool get hasPartnerDashboard => RolePermissions.hasPartnerDashboard(effectiveRoleLevel);

  /// Czy ma dostęp Level 2 do ofert (lokalizacja, zdjęcia).
  bool get hasIdentityVerifiedAccess =>
      accessLevel.level >= AccessLevel.identityVerified.level;

  /// Czy ma dostęp VDR do danej oferty.
  bool hasVdrAccess(String listingId) =>
      isAdmin ||
      vdrAccessForListingIds.contains(listingId);

  /// Czy powinien widzieć banner „Zaakceptuj NDA”.
  bool get shouldShowNdaBanner =>
      RolePermissions.showNdaBanner(effectiveRoleLevel);

  /// Czy może zapisać kalkulację ROI.
  bool get canSaveRoiCalculation =>
      RolePermissions.canSaveRoiCalculation(effectiveRoleLevel);

  /// Czy może używać watchlisty.
  bool get canUseWatchlist => RolePermissions.canUseWatchlist(effectiveRoleLevel);

  /// Czy może edytować profil.
  bool get canEditProfile => RolePermissions.canEditProfile(effectiveRoleLevel);

  /// Czy widzi pełne oferty (nie tylko teasery).
  bool get canViewFullListings =>
      RolePermissions.canViewFullListing(effectiveRoleLevel);

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    AccessLevel? accessLevel,
    DateTime? ndaAcceptedAt,
    List<String>? vdrAccessForListingIds,
    String? regionVoivodeship,
    String? directorId,
    AccountType? accountType,
    String? nip,
    String? companyName,
    String? companyAddress,
    String? phone,
    List<String>? preferredInvestmentTypes,
    int? budgetMin,
    int? budgetMax,
    bool? emailVerified,
    String? linkedInProfileUrl,
    bool? isBlocked,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      accessLevel: accessLevel ?? this.accessLevel,
      ndaAcceptedAt: ndaAcceptedAt ?? this.ndaAcceptedAt,
      vdrAccessForListingIds:
          vdrAccessForListingIds ?? this.vdrAccessForListingIds,
      regionVoivodeship: regionVoivodeship ?? this.regionVoivodeship,
      directorId: directorId ?? this.directorId,
      accountType: accountType ?? this.accountType,
      nip: nip ?? this.nip,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      phone: phone ?? this.phone,
      preferredInvestmentTypes:
          preferredInvestmentTypes ?? this.preferredInvestmentTypes,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      emailVerified: emailVerified ?? this.emailVerified,
      linkedInProfileUrl: linkedInProfileUrl ?? this.linkedInProfileUrl,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
