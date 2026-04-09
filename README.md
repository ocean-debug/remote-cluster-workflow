# Remote Cluster Workflow

Run Codex tasks on remote Linux servers or HPC clusters through SSH, a fixed remote work directory, a chosen environment, and an explicit compute allocation.

This repository is packaged in two useful ways:

- As a reusable Codex skill under [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow)
- As an install-ready plugin-shaped repository with [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json)

## What It Does

`remote-cluster-workflow` helps Codex:

- connect to a remote machine with local `ssh`
- stay inside one declared remote work directory
- activate a chosen `conda`, `venv`, or R environment
- run work on direct shells, Slurm, PBS/Torque, or similar schedulers
- verify environments quickly before longer jobs
- run tests, inspect failures, and summarize results

## Repository Layout

```text
.
+-- .codex-plugin/
|   +-- plugin.json
+-- assets/
|   +-- icon.svg
|   +-- logo.svg
+-- skills/
|   +-- remote-cluster-workflow/
|       +-- SKILL.md
|       +-- agents/openai.yaml
|       +-- references/
|       +-- scripts/
+-- remote-profiles/
    +-- profile-template.json
    +-- direct-shell.example.json
    +-- slurm-srun.example.json
    +-- pbs-torque.example.json
```

## Quick Start

### Option 1: Use It As A Skill

1. Copy [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow) into your local Codex skills directory.
   Windows example: `%USERPROFILE%\.codex\skills\remote-cluster-workflow`
2. Copy one of the example profiles from [`remote-profiles`](./remote-profiles) into your local remote profile directory.
   Windows example: `%USERPROFILE%\.codex\remote-profiles\`
3. Edit the copied profile for your own infrastructure:
   - `sshTarget`
   - `remoteWorkdir`
   - `environment.activate`
   - `resource.template`
   - `resource.defaults`
4. Use `$remote-cluster-workflow` in Codex.

### Option 2: Use It As A Plugin-Shaped Repo

1. Clone this repository into your local plugin directory.
2. Keep the repo root intact so Codex can read [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json).
3. If your Codex setup uses plugin marketplace wiring, point it at this repo-local plugin.

The exact marketplace wiring varies by local Codex setup, but this repo now has the expected plugin manifest and `skills/` layout.

## Example Prompts

```text
Use $remote-cluster-workflow.
Profile: my-pbs-profile.json
Remote workdir: /path/to/project
Environment: conda activate my-env
Resources: gpu02, 8 cores
Run tests and fix failures.
```

```text
Use $remote-cluster-workflow.
Profile: my-r-profile.json
Remote workdir: /data/analysis/C5
Environment: conda activate r4.2
Resources: gpu02, 8 cores
Verify the environment, then run the R script and summarize outputs.
```

## Example Profile Types

- [`profile-template.json`](./remote-profiles/profile-template.json): minimal starting point
- [`direct-shell.example.json`](./remote-profiles/direct-shell.example.json): login host runs the commands directly
- [`slurm-srun.example.json`](./remote-profiles/slurm-srun.example.json): use `srun` for node/core requests
- [`pbs-torque.example.json`](./remote-profiles/pbs-torque.example.json): use `qsub` for PBS/Torque clusters

## Security Notes

- This repository does not include any private hostnames, usernames, internal IPs, project paths, or personal environment names.
- If a server still uses password login, bootstrap SSH key access first. See [`password-bootstrap.md`](./skills/remote-cluster-workflow/references/password-bootstrap.md).
- Keep private profiles outside the public repository unless you have scrubbed all sensitive details.

## Development Notes

- The skill implementation lives in [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow).
- The PowerShell helpers under `scripts/` are intended for Windows hosts that launch remote Linux work through `ssh`.
- The repository is designed to be easy to fork and customize for different clusters or schedulers.

## License

This project is released under the MIT License. See [LICENSE](./LICENSE).

## Changelog

Version history is tracked in [CHANGELOG.md](./CHANGELOG.md).
