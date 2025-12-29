# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Documentation
- **Architecture Update**: Corrected documentation to reflect the Event Bridge pattern instead of Dependency Injection.
- **Clarification**: Documented the "Raw Load" strategy for dependencies (Fluent is loaded remotely, not locally).
- **Audit**: Added `docs/architecture.md` and `docs/audit-log.md` to track system design and drift.

## [3.0.0] - 2025-12-24 (Cyber Shell)

### Added
- **Feature**: **Cyber Neon Dashboard**: New UI theme with Real-time FPS, Ping, and Session TTL monitoring.
- **Feature**: **Settings Tab**: Automatic configuration management using `SaveManager` and `InterfaceManager`.
- **Integration**: **AutoFarm Launch**: Added 'Launch AutoFarm' button connected to Cloudflare KV via Events.

### Fixed
- **Fix**: **Require Paths**: Corrected require paths to support the modular folder structure (`script.Parent.Fluent.src`).

### Changed
- **Architecture**: `Shell/init.lua` now uses a Global Event Bridge (`getgenv().FSSHUB_SHELL`) for Core communication.

### Notes
- *Correction*: Previous changelog mentioned "Integrasi Penuh Source Code Fluent UI" locally. Codebase analysis reveals this was reverted to `loadstring` for remote loading. Documentation now reflects reality.
- *Correction*: Previous changelog mentioned "Dependency Injection". This has been corrected to "Event Bridge" in documentation.
