# remote-cluster-workflow share pack

This share pack contains a reusable Codex skill for running tasks on remote servers or HPC clusters through SSH, plus generic example remote profiles.

## What is included

- `remote-cluster-workflow/`
  - Install this folder into your Codex skills directory.
- `remote-profiles/`
  - Example profile templates for direct shell, Slurm, and PBS/Torque.

## What is intentionally not included

This pack does not include any private profiles with real hostnames, usernames, internal IPs, project paths, or personal environment names.

## How to install

1. Copy `remote-cluster-workflow/` into your local Codex skills directory:
   - Windows example: `%USERPROFILE%\.codex\skills\remote-cluster-workflow`
2. Copy one or more example profile JSON files into your local remote profile directory:
   - Windows example: `%USERPROFILE%\.codex\remote-profiles\`
3. Edit a copied profile for your own server:
   - `sshTarget`
   - `remoteWorkdir`
   - `environment.activate`
   - `resource.template`
   - `resource.defaults`
4. If your server still uses password login, bootstrap SSH key access first by following `remote-cluster-workflow/references/password-bootstrap.md`.

## Recommended sharing methods

- Send this whole folder directly to another Codex user
- Send the zip archive version of this folder
- Put this folder into a Git repository and share the repo

## Recommended usage prompt

Use `$remote-cluster-workflow` with a profile that specifies the remote workdir, environment, and compute allocation.

Example:

```text
Use $remote-cluster-workflow.
Profile: my-pbs-profile.json
Remote workdir: /path/to/project
Environment: conda activate my-env
Resources: gpu02, 8 cores
Run tests and fix failures.
```
