# Changelog

All notable changes to this project will be documented in this file.

## [3.1.0] - 2026-01-18

### Added
- **Documentation**: Created `docs/architecture.md` and `docs/audit-log.md` to formalize the system architecture.
- **Audit Log**: Initialized DocsKeeper audit log for tracking architectural shifts.

### Changed
- **Architecture Documentation**: Explicitly defined the "Remote Control" vs "TV Box" philosophy and "Safe Toggle Pattern".
- **README**: Updated to reflect the current "Raw Load" mechanism (where Fluent is loaded via HTTP) and marked the local `Fluent/` directory as reference/dead code.

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
