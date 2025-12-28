# Changelog

All notable changes to this project will be documented in this file.

## [3.0.1] - 2025-01-18 (DocsKeeper Audit)

### Changed
- **Documentation**: Updated `README.md` and created `docs/architecture.md` to correctly reflect the "Remote Control" architecture.
- **Correction**: Clarified that `Shell/init.lua` does **not** use Dependency Injection but rather an internal Event Bridge pattern, correcting the previous changelog entry [3.0.0].
- **Integration**: Documented the raw `loadstring` reliance for `Events.lua` and `UI/Tabs.lua` in the architecture docs.

## [3.0.0] - 2024-12-24 (Cyber Shell)

### Added
- **Integrasi Penuh Source Code Fluent UI**: Integrated the full Fluent UI source code locally (instead of `loadstring`) to ensure stability on Delta/Xeno executors.
- **Dependency Injection**: `Shell/init.lua` now implements the Dependency Injection pattern, requiring `ApiClient` and `Session` as arguments.

### Feature
- **Cyber Neon Dashboard**: New UI theme with Real-time FPS, Ping, and Session TTL monitoring.
- **Settings Tab**: Automatic configuration management using `SaveManager` and `InterfaceManager`.

### Fixed
- **Require Paths**: Corrected require paths to support the modular folder structure (`script.Parent.Fluent.src`).

### Integration
- **AutoFarm Launch**: Added 'Launch AutoFarm' button connected to Cloudflare KV via Events.
