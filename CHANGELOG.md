# Changelog

All notable changes to this project will be documented in this file.

## [3.0.0] - 2025-12-24 (Cyber Shell)

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

## [3.0.1] - 2025-12-25

### Documentation
- **Architecture Audit**: Created `docs/architecture.md` detailing the V3 Split Architecture (Public Shell vs Private Core), ApiClient contract, and Sandboxing rules.
- **README Update**: Added Security & Sandboxing section and clarified module roles.

### Maintenance
- **Dead Code Detection**: Flagged `Shell/Events.lua` as currently unused in the main entry point, though preserved for future utility.
- **Architectural Note**: Identified `Shell/init.lua`'s hardcoded UI generation as a deviation from the intended "Game-aware" modular system (pending `UIGenerator` integration).
