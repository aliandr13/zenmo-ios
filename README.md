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

`project.yml` is the XcodeGen spec — the `.xcodeproj` is generated and not committed.

## Project structure

```
Sources/
├── ZenmoApp.swift                # App entry point
├── Models/
│   └── APITypes.swift            # Codable types mirroring the REST API
├── API/
│   ├── APIClient.swift           # URLSession wrapper, JWT refresh, actor-isolated
│   ├── AuthAPI.swift             # login / register / me
│   ├── AccountsAPI.swift         # accounts endpoints
│   ├── TransactionsAPI.swift     # transactions endpoints (paged list, create, delete)
│   └── CategoriesAPI.swift       # categories endpoints
├── Auth/
│   ├── AuthStore.swift           # Session state (@MainActor ObservableObject)
│   └── KeychainService.swift     # Token persistence in the Keychain
└── Screens/
    ├── RootView.swift            # Auth gate → TabView (+ Settings tab)
    ├── Login/
    ├── Register/
    ├── Accounts/
    │   └── AccountsView.swift
    └── Transactions/
        └── TransactionsView.swift
```

## API

Points to `http://localhost:8080` in debug builds and `https://zenmo.fyi` in release. Change `baseURL` in
`APIClient.swift` if needed.

## Features

- **Login / Register** — email + password; tokens are stored in the Keychain so the session survives app restarts.
- **Accounts** — accounts grouped into *Credit*, *Checking & Cash*, and *Savings* sections, showing current
  balance and, for credit cards with a limit, utilization. Pull to refresh.
- **Transactions** — infinite-scroll list (loads the next page as you scroll), pull to refresh, swipe to delete,
  and an *Add transaction* form (account, category, date, amount, currency, optional description, status, merchant).
  The amount is signed (negative = expense, positive = income); posted transactions update the account balance on the
  server, and the currency must match the account's.
- **Settings** — shows the signed-in email and a *Log out* button.

## Status

| Screen       | Status  |
|--------------|---------|
| Login        | Done    |
| Register     | Done    |
| Accounts     | Done (read-only list) |
| Transactions | Done (list, add, delete) |
| Settings     | Done    |
| Dashboard    | Planned (placeholder tab) |
| Categories   | Planned (placeholder tab; categories are already loaded for the transaction form) |
