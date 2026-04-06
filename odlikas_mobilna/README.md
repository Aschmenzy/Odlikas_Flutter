# Odlikas Mobile

Flutter mobilna aplikacija za studente Tehničkog veleučilišta u Zagrebu (TVZ) koja objedinjuje akademske podatke — ocjene, raspored, testove i obavijesti — u jedno, pregledno sučelje.

## Funkcionalnosti

- **Ocjene** — pregled trenutnih ocjena po predmetu, detaljan prikaz i tablice vrednovanja
- **Raspored** — tjedni raspored s pregledom predmeta po danima
- **Testovi** — nadolazeći datumi testova povučeni iz studentskog portala
- **Kalendar** — osobni kalendar s mogućnošću kreiranja vlastitih događaja
- **Obavijesti** — push obavijesti putem Firebase Cloud Messaginga
- **Poslovi** — odabrane ponude studentskih poslova
- **Pomodoro** — ugrađeni tajmer za učenje s praćenjem niza dana
- **AI asistent** — chatbot unutar aplikacije pokrenut OpenAI-em
- **Studentska iskaznica** — digitalna radna studentska iskaznica
- **Dijeljenje datoteka** — učitavanje i pregled PDF materijala putem Firebase Storagea

## Tehnologije

| Sloj | Tehnologija |
|---|---|
| UI | Flutter (Dart) |
| Upravljanje stanjem | Provider + ChangeNotifier |
| REST API | Dio s Bearer token autentifikacijom + automatsko osvježavanje tokena |
| Autentifikacija | Sigurna pohrana (flutter_secure_storage) + JWT |
| Push obavijesti | Firebase Cloud Messaging |
| Baza podataka u oblaku | Cloud Firestore |
| Pohrana datoteka | Firebase Storage |
| Lokalna pohrana | Hive |
| AI | OpenAI API |

## Struktura projekta

```
lib/
├── main.dart                   # Ulazna točka aplikacije, routing, Provider setup
├── customBottomNavBar.dart     # Zajednička donja navigacijska traka
├── fontService.dart            # Servis za dinamičke fontove i pristupačnost
├── constants/                  # Konstante za cijelu aplikaciju
├── exceptions/                 # Tipizirane klase iznimki
├── utilities/                  # Zajednički UI alati (prilagođeni gumb i sl.)
├── services/                   # Integracije vanjskih servisa (OpenAI, AI asistent)
├── database/
│   ├── api/                    # Dio klijent, auth interceptor, pohrana tokena, prijava
│   ├── models/                 # Modeli podataka (Grades, Schedule, Tests i dr.)
│   ├── firestore_pomodoro_service.dart
│   └── firebase_options.dart
└── pages/
    ├── HomePage/               # Nadzorna ploča s karticama ocjena, rasporeda i kalendara
    ├── SubjectsPage/           # Popis predmeta
    ├── SpecificSubjectPage/    # Detalji predmeta s ocjenama i bilješkama
    ├── SchedulePage/           # Tjedni raspored
    ├── CalendarPage/           # Kalendar s prilagođenim događajima
    ├── NotificationsPage/      # Povijest obavijesti
    ├── PomodoroPage/           # Tajmer za učenje
    ├── JobsPage/               # Ponude studentskih poslova
    ├── AiChatbotPage/          # AI asistent chat
    ├── SettingsPages/          # Postavke aplikacije i opcije pristupačnosti
    ├── ProfilePage/            # Profil studenta
    ├── LoginPages/             # Ekran za prijavu
    └── ...
```

## Pokretanje projekta

### Preduvjeti

- Flutter SDK `^3.6.1`
- Dart SDK `^3.6.1`
- Android Studio ili VS Code s Flutter ekstenzijom
- Fizički Android uređaj ili emulator (API 21+)
- Pristup Odlikas backend API-ju

### Postavljanje

1. **Kloniranje repozitorija**
   ```bash
   git clone https://github.com/Aschmenzy/Odlikas_Flutter.git
   cd Odlikas_Flutter/odlikas_mobilna
   ```

2. **Instalacija ovisnosti**
   ```bash
   flutter pub get
   ```

3. **Konfiguracija varijabli okoline**

   Kreiraj `.env` datoteku u `odlikas_mobilna/` mapi (pored `pubspec.yaml`):
   ```env
   BASE_URL=http://<ip-adresa-backenda>:<port>
   OPEN_AI_KEY=tvoj_openai_api_kljuc
   ```

   > `.env` datoteka je navedena u `.gitignore` i **nikada se ne smije commitati**.

4. **Postavljanje Firebasea**

   Datoteka `google-services.json` (Android) potrebna je za Firebase funkcionalnosti. Kontaktiraj člana tima za njezino dobivanje — nije pohranjena u repozitoriju.

5. **Pokretanje aplikacije**
   ```bash
   flutter run
   ```

### Pokretanje testova

```bash
flutter test
```

### Statička analiza koda

```bash
flutter analyze
```

## Tok autentifikacije

1. Korisnik unosi podatke za prijavu
2. `LoginService` razmjenjuje podatke za JWT token putem backenda
3. Token se pohranjuje u kriptiranu sigurnu pohranu (`flutter_secure_storage`)
4. `AuthInterceptor` (Dio) dodaje token svakom zahtjevu i automatski ga osvježava pri `401` odgovoru
5. Pri pokretanju, `StartupRouter` provjerava postoji li valjani token i preusmjerava na `HomePage` ili ekran za prijavu

## Varijable okoline

| Varijabla | Opis |
|---|---|
| `BASE_URL` | Osnovna URL adresa Odlikas ASP.NET backend API-ja |
| `OPEN_AI_KEY` | OpenAI API ključ za funkcionalnost AI asistenta |

Osjetljive vrijednosti (API ključevi, lozinke) nikada nisu hardkodirane. Sve tajne učitavaju se iz `.env` datoteke pri pokretanju ili se pohranjuju u kriptiranu pohranu uređaja.

## Doprinos projektu

1. Odvoji granu od `develop` za nove značajke: `git checkout -b feature/naziv-znacajke`
2. Koristi konvencionalne commit poruke: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
3. Otvori pull request prema `develop` — ne guraj direktno na `main`

## Tim

Razvija tim **Odlikas** za Mc2 natjecanje.
