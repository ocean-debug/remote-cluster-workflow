---
name: remote-cluster-workflow
description: Use when the task should run on a user-managed remote Linux server or HPC cluster via SSH inside a specified remote work folder, environment, and compute allocation. Covers reusing local SSH credentials, scoping all remote work to one folder, activating or modifying Python or R environments, and running commands on a chosen node and core allocation.
---

# Remote Cluster Workflow

## Overview

Use this skill when the user wants Codex to perform real work on a remote server or cluster instead of only on the local machine. Prefer local `ssh` plus reusable profile files rather than depending on the visible state of a MobaXterm tab.

Remote profiles live in `%USERPROFILE%\\.codex\remote-profiles`. Each profile defines:

- SSH target and options
- Remote working directory
- Shell bootstrap and environment activation
- Resource wrapper template for direct shells, `srun`, or other schedulers

For environments you use often, prefer one dedicated profile per environment and resource shape instead of repeatedly editing one shared profile. Example: keep separate profiles for `r4.0.5`, `r4.2`, or common Python environments.

## Workflow

1. Choose the matching profile. If none exists, create one from `%USERPROFILE%\\.codex\remote-profiles\profile-template.json`.
2. If the server currently uses password login through MobaXterm, bootstrap SSH key access once from the existing interactive session. After bootstrap, prefer key-based OpenSSH for all Codex work.
3. When a profile is new or recently changed, run `scripts/test-remote-profile.ps1` first.
4. Execute remote work through `scripts/invoke-remote-task.ps1`.
5. Keep all task commands inside the configured `remoteWorkdir`.
6. If the user authorizes environment changes, install packages inside the requested environment and report what changed.
7. Use the profile's `resource.template` to honor node and core requests. If the wrapper is missing or ambiguous, pause and ask one concise question before using expensive resources.
8. Prefer non-interactive commands and summarize the important results back to the user.

## Guardrails

- Do not rely on the visible state of a MobaXterm window.
- Do not run task commands outside `remoteWorkdir` except for shell bootstrap and explicit environment management.
- Do not request larger allocations than the user asked for.
- Before long or expensive runs, state the profile, node, and core count you are using.
- Prefer updating the existing environment before creating a new one. Create a new environment only when necessary and explain why.

## Command Patterns

Test a profile:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\test-remote-profile.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-profile.json" `
  -Node "gpu03" `
  -Cores 8
```

Quickly verify the active environment on the configured node and cores:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\verify-remote-env.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-profile.json" `
  -Node "gpu02" `
  -Cores 8
```

Run a task:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\invoke-remote-task.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-profile.json" `
  -Command "python -m pytest tests/test_model.py -q" `
  -Node "gpu03" `
  -Cores 8
```

Pass additional scheduler variables:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\invoke-remote-task.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-profile.json" `
  -Command "python train.py --epochs 1" `
  -Node "gpu03" `
  -Cores 8 `
  -Vars @("partition=gpu", "gpus=1", "memory=64G")
```

## When To Read References

- Read `references/profile-schema.md` when creating or editing a remote profile.
- Read `references/example-profiles.md` when the user needs a direct-shell or Slurm-style example.
- Read `references/password-bootstrap.md` when the user currently logs in with a password through MobaXterm and wants Codex to take over future remote work.

