# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
1. Added `.gitignore` for local workflow data, editor files, and common temporary artifacts.
2. Added `COPYRIGHT` to make repository copyright information explicit.

### Changed
1. Simplified `README.md` for a cleaner GitHub homepage presentation.

## [0.1.0] - 2026-03-29

### Added
1. Rebuilt the project as `easy-specflow-zh`, a platform-neutral Chinese workflow repository for AI coding clients.
2. Added unified `spec -> plan -> execute -> verify -> accept` stage definitions.
3. Added a single `.specflow/` working-directory convention with `index.json`, `tasks/`, `archive/`, and `trash/`.
4. Added Chinese templates, prompts, rules, schema, scripts, and cross-agent collaboration docs.
5. Added minimal `agents/openai.yaml` metadata so Codex can identify the repository without creating a platform-specific dependency.
