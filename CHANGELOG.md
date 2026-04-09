# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

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
