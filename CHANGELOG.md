# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

## [0.1.1] - 2026-04-13

### Added

- UV-oriented profile example for project-local `.venv` workflows
- UV guidance in the skill and repository README
- Sanitized `agent1` example showing how to run a real UV project on a fixed node and core allocation

### Changed

- Environment verification now reports `VIRTUAL_ENV`, `pyproject.toml`, `uv.lock`, Python executable path, and `uv --version` when available
- Profile schema now documents how to use `source .venv/bin/activate` or `uv run ...` with remote project roots
- UV guidance now recommends activating an existing `.venv` for quick checks when `uv run ...` would otherwise trigger dependency resolution or source builds

## [0.1.0] - 2026-04-09

### Added

- Initial public release of the `remote-cluster-workflow` Codex skill
- Windows PowerShell helper scripts for:
  - remote task execution
  - profile testing
  - quick environment verification
- Generic remote profile templates for:
  - direct shell execution
  - Slurm `srun`
  - PBS/Torque `qsub`
- Plugin-style repository structure with `.codex-plugin/plugin.json`
- Public README with installation and usage guidance
- MIT license
- Basic SVG icon and logo assets

### Notes

- This release intentionally excludes any private profiles containing real usernames, internal IPs, private project paths, or personal environment names.
- Users should copy and customize the example profiles in `remote-profiles/` for their own infrastructure.
