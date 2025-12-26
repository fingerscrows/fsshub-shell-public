# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- **Architecture Update**: Updated documentation to reflect the actual "Raw Load" architecture.
- **Dependency Handling**: Clarified that `Shell/init.lua` loads dependencies (Fluent, Modules) via `game:HttpGet` rather than local requires.
- **Removed**: Removed "Dependency Injection" section from docs as the current code does not implement `function(ApiClient, Session)`.

## [3.0.0] - 2025-12-24 (Cyber Shell)

### Added
- **Global Bridge**: `getgenv().FSSHUB_SHELL` is now the primary interface for Core communication.
- **Cyber Neon Theme**: Default theme set to Dark with Cyan accent.

### Changed
- **Loading Strategy**: Switched to `loadstring` based loading for Fluent and internal UI modules to facilitate auto-updates.
- **Stateless Design**: Shell logic decoupled from Game Logic. UI only emits events.

### Integration
- **AutoFarm Launch**: Added 'Launch AutoFarm' button connected to Cloudflare KV via Events.
