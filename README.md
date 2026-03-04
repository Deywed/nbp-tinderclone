# TinderClone – Uputstvo za pokretanje projekta

Ovaj projekat je full-stack mobilna aplikacija inspirisana Tinder-om.  
Sastoji se od:
- **Backend** – ASP.NET Core Web API (.NET 9, C#)
- **Frontend** – Flutter mobilna aplikacija (Dart)
- **Baze podataka** – MongoDB, Neo4j i Redis (pokretane putem Docker-a)

---

## Preduslovi – šta je potrebno instalirati

### 1. Docker Desktop

Sve tri baze podataka pokrću se automatski putem Docker-a. Nije potrebno ručno instalirati MongoDB, Neo4j niti Redis.

- Preuzeti sa: https://www.docker.com/products/docker-desktop
- Instalirati i pokrenuti Docker Desktop pre nego što se krene sa pokretanjem projekta.

---

### 2. .NET 9 SDK

Backend je napisan u ASP.NET Core i zahteva .NET 9 SDK.

- Preuzeti sa: https://dotnet.microsoft.com/en-us/download/dotnet/9.0
- Proveriti instalaciju u terminalu:
  ```bash
  dotnet --version
  ```
  Treba da ispiše `9.x.x`.

---

### 3. Flutter SDK

Frontend je mobilna aplikacija pisana u Flutter-u. Minimalna verzija Dart SDK-a je `3.7.2`.

- Uputstvo za instalaciju: https://docs.flutter.dev/get-started/install
- Proveriti instalaciju u terminalu:
  ```bash
  flutter doctor
  ```
  Sve stavke vezane za Flutter i Dart treba da budu zelene (✓).

**Napomena:** Za pokretanje Flutter aplikacije potreban je ili:
- Android emulator (instalira se kroz Android Studio), ili
- fizički Android/iOS uređaj sa omogućenim developer mode-om, ili
- Chrome (za web verziju, mada je aplikacija optimizovana za mobilne uređaje).

Android Studio preuzeti sa: https://developer.android.com/studio

---

## Pokretanje projekta

### Korak 1 – Pokrenuti baze podataka (Docker)

U root folderu projekta (gde se nalazi `docker-compose.yml`) pokrenuti:

```bash
docker-compose up -d
```

Ovo će pokrenuti tri kontejnera u pozadini:

| Kontejner       | Baza    | Port(ovi)              |
|-----------------|---------|------------------------|
| tinder-mongodb  | MongoDB | 27017                  |
| tinder-neo4j    | Neo4j   | 7474 (UI), 7687 (Bolt) |
| tinder-redis    | Redis   | 6379                   |

Proveriti da li su kontejneri pokrenuti:
```bash
docker ps
```

Neo4j browser interfejs dostupan je na: http://localhost:7474

---

### Korak 2 – Pokrenuti Backend

```bash
cd Backend
dotnet run
```

Backend će biti dostupan na: **http://localhost:5225**

API dokumentacija (Scalar) dostupna je na: http://localhost:5225/scalar/v1

---

### Korak 3 – Pokrenuti Frontend (Flutter)

```bash
cd Frontend
flutter pub get
flutter run
```

Flutter će ponuditi izbor uređaja/emulatora ukoliko ih je više dostupno.

> **Važno:** Flutter aplikacija se po defaultu konektuje na `http://localhost:5225`. Ukoliko se aplikacija pokreće na fizičkom uređaju, adresu treba promeniti u `http://<IP-adresa-računara>:5225` u fajlu `Frontend/lib/api_endpoints.dart`.

---

## Konfiguracija

Sve konfiguracije Backend-a nalaze se u fajlu `Backend/appsettings.json` i podrazumevano su postavljene za lokalno pokretanje:

| Podešavanje              | Vrednost                               |
|--------------------------|----------------------------------------|
| MongoDB ConnectionString | `mongodb://localhost:27017`            |
| MongoDB DatabaseName     | `TinderCloneDb`                        |
| Neo4j Uri                | `bolt://localhost:7687`                |
| Neo4j Auth               | bez autentifikacije (`NEO4J_AUTH=none`)|
| Redis ConnectionString   | `localhost:6379`                       |
| Backend port             | `http://localhost:5225`                |

Nije potrebno menjati nikakve konfiguracije za lokalno pokretanje.

---

## Tehnološki stack

| Komponenta      | Tehnologija                               |
|-----------------|-------------------------------------------|
| Backend         | ASP.NET Core (.NET 9), C#                 |
| Autentifikacija | JWT Bearer tokeni, BCrypt                 |
| Real-time       | SignalR (match notifikacije)              |
| Frontend        | Flutter (Dart 3.7)                        |
| Baza dokumenata | MongoDB                                   |
| Graf baza       | Neo4j (korisnici, swipe-ovi, match-evi)   |
| Keš             | Redis                                     |
| Infrastruktura  | Docker, Docker Compose                    |

---

## Kratki pregled funkcionalnosti

- Registracija i prijava korisnika (JWT autentifikacija)
- Podešavanje korisničkih preferencija (pol, starost, udaljenost)
- Discovery feed – prikaz korisnika sortiranih po poklapanju preferencija
- Swipe left / Swipe right mehanizam
- Automatska detekcija match-a uz real-time notifikaciju putem SignalR
- Top Picks – prikaz najpoklapajućih korisnika
- Statistike (broj swipe-ova, match-ova)
- Keširanje podataka putem Redis-a
