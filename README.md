# Zenmo iOS

Native iOS client for [Zenmo](https://zenmo.fyi) — a personal finance tracker with accounts, transactions, and categories.

## Requirements

- Xcode 16+
- iOS 17+ simulator or device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Getting started

```bash
brew install xcodegen
git clone <repo>
cd zenmo-ios
xcodegen generate
open ZenmoApp.xcodeproj
```

## Project structure

```
Sources/
├── ZenmoApp.swift          # App entry point
├── Models/
│   └── APITypes.swift      # Codable types mirroring the REST API
├── API/
│   ├── APIClient.swift     # URLSession wrapper, JWT refresh, actor-isolated
│   └── AuthAPI.swift       # login / register / me
├── Auth/
│   ├── AuthStore.swift     # Session state (@MainActor ObservableObject)
│   └── KeychainService.swift
└── Screens/
    ├── RootView.swift      # Auth gate → TabView
    ├── Login/
    └── Register/
```

`project.yml` is the XcodeGen spec — the `.xcodeproj` is generated and not committed.

## API

Points to `http://localhost:8080` in debug builds and `https://zenmo.fyi` in release. Change `baseURL` in `APIClient.swift` if needed.

## Status

| Screen | Status |
|---|---|
| Login | Done |
| Register | Done |
| Dashboard | Planned |
| Accounts | Planned |
| Transactions | Planned |
| Categories | Planned |
