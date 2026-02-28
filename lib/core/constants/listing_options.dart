/// Stałe opcje dla formularzy ogłoszeń (zgłoszenia i edycja ofert).
/// Używane w sell_submission (Step3) oraz edit_listing_page.

// Przeznaczenie lokalu – multi-select.
/// gastronomiczny, biurowy, handlowy, usługowy
class DesignationOptions {
  static const String gastronomiczny = 'gastronomiczny';
  static const String biurowy = 'biurowy';
  static const String handlowy = 'handlowy';
  static const String uslugowy = 'uslugowy';

  static const List<String> all = [
    gastronomiczny,
    biurowy,
    handlowy,
    uslugowy,
  ];

  static String label(String key) {
    switch (key) {
      case gastronomiczny:
        return 'Gastronomiczny';
      case biurowy:
        return 'Biurowy';
      case handlowy:
        return 'Handlowy';
      case uslugowy:
        return 'Usługowy';
      default:
        return key;
    }
  }
}

/// Informacje dodatkowe – multi-select (najpopularniejsze opcje w ogłoszeniach 2025/2026).
class AdditionalInfoOptions {
  // Klimatyzacja i wentylacja
  static const String klimatyzacja = 'klimatyzacja';
  static const String klimatyzacjaRekuperacja = 'klimatyzacja_rekuperacja';
  static const String sufitPodwieszany = 'sufit_podwieszany';
  static const String podsufitka = 'podsufitka';
  static const String sufitNapinany = 'sufit_napinany';
  static const String rolety = 'rolety';
  static const String zaluzje = 'zaluzje';
  static const String roletyAntywlamaniowe = 'rolety_antywlamaniowe';
  static const String monitoring = 'monitoring';
  static const String monitoringWizyjny = 'monitoring_wizyjny';
  static const String monitoringAlarm = 'monitoring_alarm';
  static const String systemAlarmowy = 'system_alarmowy';
  static const String ochrona = 'ochrona';
  static const String ochrona24h = 'ochrona_24h';
  static const String portier = 'portier';
  static const String ochronaObiektu = 'ochrona_obiektu';
  static const String recepcja = 'recepcja';
  static const String wideodomofon = 'wideodomofon';
  static const String wideofonicznySystemWejsciowy = 'wideofoniczny_system_wejsciowy';
  static const String podlogaTechniczna = 'podloga_techniczna';
  static const String siecKomputerowa = 'siec_komputerowa';
  static const String okablowanieStrukturalne = 'okablowanie_strukturalne';
  static const String punktyLan = 'punkty_lan';
  static const String swiatlowod = 'swiatlowod';
  static const String internetSwiatlowodowy = 'internet_swiatlowodowy';
  static const String wysokaPredkoscInternetu = 'wysoka_predkosc_internetu';
  static const String salaKonferencyjna = 'sala_konferencyjna';
  static const String salaKonferencyjnaDoDyspozycji = 'sala_konferencyjna_do_dyspozycji';
  static const String czescSocjalna = 'czesc_socjalna';
  static const String kuchnia = 'kuchnia';
  static const String aneksKuchenny = 'aneks_kuchenny';
  static const String jadalnia = 'jadalnia';
  static const String lazienkaPersonelu = 'lazienka_personelu';
  static const String duzeOkna = 'duze_okna';
  static const String oknaOdPodlogi = 'okna_od_podlogi';
  static const String przeszklenia = 'przeszklenia';
  static const String drzwiAntywlamaniowe = 'drzwi_antywlamaniowe';
  static const String wzmocnioneDrzwiWejsciowe = 'wzmocnione_drzwi_wejsciowe';
  static const String sufitWentylacyjny = 'sufit_wentylacyjny';
  static const String wentylacjaMechaniczna = 'wentylacja_mechaniczna';
  static const String wentylacjaOdzyskCiepla = 'wentylacja_odzysk_ciepla';
  static const String podjazdNiepelnosprawni = 'podjazd_niepelnosprawni';
  static const String windaTowarowa = 'winda_towarowa';
  static const String platformaWozkow = 'platforma_wozkow';
  static const String piwnica = 'piwnica';
  static const String magazyn = 'magazyn';
  static const String dodatkowaPowierzchniaMagazynowa = 'dodatkowa_powierzchnia_magazynowa';
  static const String antresola = 'antresola';
  static const String taras = 'taras';
  static const String ogrodek = 'ogrodek';
  static const String patio = 'patio';
  static const String ogrodekLetni = 'ogrodek_letni';
  static const String ladowarkaEv = 'ladowarka_ev';
  static const String stacjaLadowaniaEv = 'stacja_ladowania_ev';
  static const String siecNiskopradowa = 'siec_niskopradowa';
  static const String slupyReklamowe = 'slupy_reklamowe';
  static const String reklamaZewnetrzna = 'reklama_zewnetrzna';
  static const String reklamaNaElewacji = 'reklama_na_elewacji';
  static const String wlasneWejscie = 'wlasne_wejscie';
  static const String niezalezneWejscie = 'niezalezne_wejscie';
  static const String osobneWejscieOdUlicy = 'osobne_wejscie_od_ulicy';
  static const String duzaWysokoscPomieszczen = 'duza_wysokosc_pomieszczen';
  static const String naglosnienie = 'naglosnienie';
  static const String systemAudio = 'system_audio';
  static const String oswietlenieLed = 'oswietlenie_led';
  static const String oswietleniePrzemyslowe = 'oswietlenie_przemyslowe';
  static const String oswietlenieAwaryjne = 'oswietlenie_awaryjne';
  static const String systemBms = 'system_bms';
  static const String certyfikatEnergetyczny = 'certyfikat_energetyczny';
  static const String certyfikatBreeam = 'certyfikat_breeam';
  static const String certyfikatLeed = 'certyfikat_leed';
  static const String klasaEnergetycznaA = 'klasa_energetyczna_a';
  static const String mozliwoscPodzialu = 'mozliwosc_podzialu';
  static const String elastycznaAranzacja = 'elastyczna_aranzacja';
  static const String umowaNajmu = 'umowa_najmu';
  static const String najemca = 'najemca';
  static const String roi = 'roi';
  static const String stopaZwrotu = 'stopa_zwrotu';

  static const List<String> all = [
    klimatyzacja,
    klimatyzacjaRekuperacja,
    sufitPodwieszany,
    podsufitka,
    sufitNapinany,
    rolety,
    zaluzje,
    roletyAntywlamaniowe,
    monitoring,
    monitoringWizyjny,
    monitoringAlarm,
    systemAlarmowy,
    ochrona,
    ochrona24h,
    portier,
    ochronaObiektu,
    recepcja,
    wideodomofon,
    wideofonicznySystemWejsciowy,
    podlogaTechniczna,
    siecKomputerowa,
    okablowanieStrukturalne,
    punktyLan,
    swiatlowod,
    internetSwiatlowodowy,
    wysokaPredkoscInternetu,
    salaKonferencyjna,
    salaKonferencyjnaDoDyspozycji,
    czescSocjalna,
    kuchnia,
    aneksKuchenny,
    jadalnia,
    lazienkaPersonelu,
    duzeOkna,
    oknaOdPodlogi,
    przeszklenia,
    drzwiAntywlamaniowe,
    wzmocnioneDrzwiWejsciowe,
    sufitWentylacyjny,
    wentylacjaMechaniczna,
    wentylacjaOdzyskCiepla,
    podjazdNiepelnosprawni,
    windaTowarowa,
    platformaWozkow,
    piwnica,
    magazyn,
    dodatkowaPowierzchniaMagazynowa,
    antresola,
    taras,
    ogrodek,
    patio,
    ogrodekLetni,
    ladowarkaEv,
    stacjaLadowaniaEv,
    siecNiskopradowa,
    slupyReklamowe,
    reklamaZewnetrzna,
    reklamaNaElewacji,
    wlasneWejscie,
    niezalezneWejscie,
    osobneWejscieOdUlicy,
    duzaWysokoscPomieszczen,
    naglosnienie,
    systemAudio,
    oswietlenieLed,
    oswietleniePrzemyslowe,
    oswietlenieAwaryjne,
    systemBms,
    certyfikatEnergetyczny,
    certyfikatBreeam,
    certyfikatLeed,
    klasaEnergetycznaA,
    mozliwoscPodzialu,
    elastycznaAranzacja,
    umowaNajmu,
    najemca,
    roi,
    stopaZwrotu,
  ];

  static String label(String key) {
    switch (key) {
      case klimatyzacja:
        return 'Klimatyzacja';
      case klimatyzacjaRekuperacja:
        return 'Klimatyzacja + rekuperacja';
      case sufitPodwieszany:
        return 'Sufit podwieszany';
      case podsufitka:
        return 'Podsufitka';
      case sufitNapinany:
        return 'System sufitów napinanych';
      case rolety:
        return 'Rolety';
      case zaluzje:
        return 'Żaluzje';
      case roletyAntywlamaniowe:
        return 'Antywłamaniowe rolety zewnętrzne';
      case monitoring:
        return 'Monitoring';
      case monitoringWizyjny:
        return 'Monitoring wizyjny';
      case monitoringAlarm:
        return 'Monitoring + alarm';
      case systemAlarmowy:
        return 'System alarmowy';
      case ochrona:
        return 'Ochrona';
      case ochrona24h:
        return 'Ochrona 24h';
      case portier:
        return 'Portier';
      case ochronaObiektu:
        return 'Ochrona obiektu';
      case recepcja:
        return 'Recepcja';
      case wideodomofon:
        return 'Wideodomofon';
      case wideofonicznySystemWejsciowy:
        return 'Wideofoniczny system wejściowy';
      case podlogaTechniczna:
        return 'Podłoga techniczna / podwyższona';
      case siecKomputerowa:
        return 'Sieć komputerowa';
      case okablowanieStrukturalne:
        return 'Okablowanie strukturalne';
      case punktyLan:
        return 'Punkty LAN';
      case swiatlowod:
        return 'Światłowód';
      case internetSwiatlowodowy:
        return 'Internet światłowodowy';
      case wysokaPredkoscInternetu:
        return 'Wysoka prędkość internetu';
      case salaKonferencyjna:
        return 'Sala konferencyjna (w budynku)';
      case salaKonferencyjnaDoDyspozycji:
        return 'Sala konferencyjna (do dyspozycji najemców)';
      case czescSocjalna:
        return 'Część socjalna';
      case kuchnia:
        return 'Kuchnia';
      case aneksKuchenny:
        return 'Aneks kuchenny';
      case jadalnia:
        return 'Jadalnia';
      case lazienkaPersonelu:
        return 'Łazienka dla personelu';
      case duzeOkna:
        return 'Duże okna';
      case oknaOdPodlogi:
        return 'Okna od podłogi';
      case przeszklenia:
        return 'Przeszklenia';
      case drzwiAntywlamaniowe:
        return 'Drzwi antywłamaniowe';
      case wzmocnioneDrzwiWejsciowe:
        return 'Wzmocnione drzwi wejściowe';
      case sufitWentylacyjny:
        return 'Sufit wentylacyjny';
      case wentylacjaMechaniczna:
        return 'Wentylacja mechaniczna';
      case wentylacjaOdzyskCiepla:
        return 'Wentylacja z odzyskiem ciepła';
      case podjazdNiepelnosprawni:
        return 'Podjazd dla niepełnosprawnych';
      case windaTowarowa:
        return 'Winda towarowa';
      case platformaWozkow:
        return 'Platforma dla wózków';
      case piwnica:
        return 'Piwnica';
      case magazyn:
        return 'Magazyn';
      case dodatkowaPowierzchniaMagazynowa:
        return 'Dodatkowa powierzchnia magazynowa';
      case antresola:
        return 'Antresola';
      case taras:
        return 'Taras';
      case ogrodek:
        return 'Ogródek';
      case patio:
        return 'Patio';
      case ogrodekLetni:
        return 'Ogródek letni (przy gastronomii/usługach)';
      case ladowarkaEv:
        return 'Ładowarka do samochodów elektrycznych';
      case stacjaLadowaniaEv:
        return 'Stacja ładowania EV';
      case siecNiskopradowa:
        return 'Sieć niskoprądowa';
      case slupyReklamowe:
        return 'Słupy reklamowe';
      case reklamaZewnetrzna:
        return 'Możliwość montażu reklamy zewnętrznej';
      case reklamaNaElewacji:
        return 'Reklama na elewacji';
      case wlasneWejscie:
        return 'Własne wejście';
      case niezalezneWejscie:
        return 'Niezależne wejście';
      case osobneWejscieOdUlicy:
        return 'Osobne wejście od ulicy';
      case duzaWysokoscPomieszczen:
        return 'Duża wysokość pomieszczeń (np. 3,5–4,5 m)';
      case naglosnienie:
        return 'Nagłośnienie';
      case systemAudio:
        return 'System audio';
      case oswietlenieLed:
        return 'Oświetlenie LED';
      case oswietleniePrzemyslowe:
        return 'Oświetlenie przemysłowe';
      case oswietlenieAwaryjne:
        return 'Oświetlenie awaryjne';
      case systemBms:
        return 'System BMS (Building Management System)';
      case certyfikatEnergetyczny:
        return 'Certyfikat energetyczny';
      case certyfikatBreeam:
        return 'Certyfikat BREEAM';
      case certyfikatLeed:
        return 'Certyfikat LEED';
      case klasaEnergetycznaA:
        return 'Klasa energetyczna A / A+';
      case mozliwoscPodzialu:
        return 'Możliwość podziału powierzchni';
      case elastycznaAranzacja:
        return 'Elastyczna aranżacja';
      case umowaNajmu:
        return 'Umowa najmu';
      case najemca:
        return 'Najemca';
      case roi:
        return 'ROI';
      case stopaZwrotu:
        return 'Stopa zwrotu';
      default:
        return key;
    }
  }
}
