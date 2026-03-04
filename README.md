# Tinder Clone – Local Setup

## Prerequisites

- [Docker](https://www.docker.com/)
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)

## 1. Start infrastructure

```bash
docker compose up -d
```

Services: MongoDB (`27017`), Neo4j (`7474`/`7687`), Redis (`6379`)

## 2. Run backend

```bash
cd Backend
dotnet run
```

API runs on `https://localhost:5001`

## 3. Run frontend

```bash
cd Frontend
flutter pub get
flutter run
```
