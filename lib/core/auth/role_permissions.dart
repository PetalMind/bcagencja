/// Role w systemie według specyfikacji (GUEST … ADMIN, SELLER_LEAD).
/// SELLER_LEAD nie jest rolą zalogowanego użytkownika – to status zgłoszenia z formularza.
enum UserRoleLevel {
  /// Level 0 – niezalogowany gość
  guest,

  /// Level 1 – zarejestrowany, BEZ akceptacji NDA
  investorBasic,

  /// Level 2 – zarejestrowany + akceptacja NDA
  investorVerified,

  /// Level 3 – zweryfikowany + dostęp VDR (per oferta)
  investorVip,

  /// Level 4 – agent nieruchomości
  agent,

  /// Level 5 – dyrektor obszaru
  director,

  /// Level 6 – administrator systemu
  admin,
}

/// Uprawnienia wg roli – centralna definicja.
class RolePermissions {
  const RolePermissions._();

  static double level(UserRoleLevel role) {
    switch (role) {
      case UserRoleLevel.guest:
        return 0;
      case UserRoleLevel.investorBasic:
        return 1;
      case UserRoleLevel.investorVerified:
        return 2;
      case UserRoleLevel.investorVip:
        return 3;
      case UserRoleLevel.agent:
        return 4;
      case UserRoleLevel.director:
        return 5;
      case UserRoleLevel.admin:
        return 6;
    }
  }

  static String label(UserRoleLevel role) {
    switch (role) {
      case UserRoleLevel.guest:
        return 'Gość';
      case UserRoleLevel.investorBasic:
        return 'Inwestor podstawowy';
      case UserRoleLevel.investorVerified:
        return 'Inwestor zweryfikowany';
      case UserRoleLevel.investorVip:
        return 'Inwestor VIP';
      case UserRoleLevel.agent:
        return 'Agent';
      case UserRoleLevel.director:
        return 'Dyrektor obszaru';
      case UserRoleLevel.admin:
        return 'Administrator';
    }
  }

  // –––––– GUEST (Level 0) ––––––
  static bool canAccessHome(UserRoleLevel role) => true;
  static bool canAccessRoiCalculator(UserRoleLevel role) => true;
  static bool canViewListingTeasers(UserRoleLevel role) => true;
  static bool canSubmitSellForm(UserRoleLevel role) => true;

  static bool canViewFullListing(UserRoleLevel role) =>
      role != UserRoleLevel.guest &&
      role != UserRoleLevel.investorBasic;

  static bool canSaveRoiCalculation(UserRoleLevel role) =>
      role != UserRoleLevel.guest;

  static bool canUseWatchlist(UserRoleLevel role) =>
      role != UserRoleLevel.guest;

  static bool canEditProfile(UserRoleLevel role) =>
      role != UserRoleLevel.guest;

  // –––––– INVESTOR_BASIC ––––––
  static bool showNdaBanner(UserRoleLevel role) =>
      role == UserRoleLevel.investorBasic;

  // –––––– INVESTOR_VERIFIED / VIP ––––––
  static bool canDownloadBasicDocuments(UserRoleLevel role) =>
      role == UserRoleLevel.investorVerified ||
      role == UserRoleLevel.investorVip ||
      role == UserRoleLevel.agent ||
      role == UserRoleLevel.director ||
      role == UserRoleLevel.admin;

  static bool canAccessVdr(UserRoleLevel role, [String? listingId]) =>
      role == UserRoleLevel.investorVip ||
      role == UserRoleLevel.agent ||
      role == UserRoleLevel.director ||
      role == UserRoleLevel.admin;

  static bool canRequestVdrAccess(UserRoleLevel role) =>
      role == UserRoleLevel.investorVerified ||
      role == UserRoleLevel.investorVip;

  // –––––– AGENT (Level 4) ––––––
  static bool hasAgentDashboard(UserRoleLevel role) =>
      role == UserRoleLevel.agent ||
      role == UserRoleLevel.director ||
      role == UserRoleLevel.admin;

  static bool canAddListings(UserRoleLevel role) =>
      role == UserRoleLevel.agent ||
      role == UserRoleLevel.director ||
      role == UserRoleLevel.admin;

  static bool canEditOwnListings(UserRoleLevel role) =>
      role == UserRoleLevel.agent ||
      role == UserRoleLevel.director ||
      role == UserRoleLevel.admin;

  static bool canPublishListings(UserRoleLevel role) =>
      role == UserRoleLevel.director || role == UserRoleLevel.admin;

  // –––––– DIRECTOR (Level 5) ––––––
  static bool hasDirectorDashboard(UserRoleLevel role) =>
      role == UserRoleLevel.director || role == UserRoleLevel.admin;

  static bool canApproveListings(UserRoleLevel role) =>
      role == UserRoleLevel.director || role == UserRoleLevel.admin;

  static bool canApproveVdrRequests(UserRoleLevel role) =>
      role == UserRoleLevel.director || role == UserRoleLevel.admin;

  static bool canViewRegionalStats(UserRoleLevel role) =>
      role == UserRoleLevel.director || role == UserRoleLevel.admin;

  // –––––– ADMIN (Level 6) ––––––
  static bool hasAdminDashboard(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  static bool canManageUsers(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  static bool canManageContent(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  static bool canModerateSellSubmissions(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  static bool canViewSystemLogs(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  static bool canManageGlobalSettings(UserRoleLevel role) =>
      role == UserRoleLevel.admin;

  /// Czy rola ma dostęp do panelu partnera (Agent/Dyrektor/Admin)?
  static bool hasPartnerDashboard(UserRoleLevel role) =>
      hasAgentDashboard(role);

  /// Czy zalogowany inwestor powinien widzieć dashboard inwestora?
  static bool hasInvestorDashboard(UserRoleLevel role) =>
      role == UserRoleLevel.investorBasic ||
      role == UserRoleLevel.investorVerified ||
      role == UserRoleLevel.investorVip;
}
