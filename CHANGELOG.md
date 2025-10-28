# Changelog

All notable changes to this project will be documented in this file.

## [2.1.1] - 2025-10-28

### Added
- MVVM adoption with Provider for additional screens:
  - TecnicosViewModel (CRUD/search + loading/error)
  - FormIncidenteViewModel (save incidents + load técnicos)
- App now registers new ViewModels globally in `lib/main.dart`.

### Changed
- `tecnicos_screen.dart` refactored to use `TecnicosViewModel`.
- `form_incidente_screen.dart` refactored to use `FormIncidenteViewModel`.
- Documentation aligned with MVVM (README, PROJECT_STATUS) and release notes.

### Docs
- README: expanded MVVM section; added v2.1.1 entry; updated status/date.
- PROJECT_STATUS: bumped to 2.1.1; noted MVVM adoption in architecture.
- SECURITY_IMPROVEMENTS_IMPLEMENTATION: doc-sync note; clarified migration scripts are deprecated; updated date.
- SESSION_COMPLETION_REPORT: banner note about MVVM refactor and deprecations.

### Notes
- No changes to security features; migrations remain deprecated; the app ensures/creates schema at runtime.

## [2.1.0] - 2025-10-21

Security cleanup and audit release. See `SECURITY_IMPROVEMENTS_IMPLEMENTATION.md` for details.
