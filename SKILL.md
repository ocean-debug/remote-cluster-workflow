---
name: remote-cluster-workflow
description: Use when work must run on a user-managed remote Linux server or HPC cluster over SSH, inside one remote work folder, environment, and compute allocation. Covers reusing local SSH credentials, validating or creating remote profiles, activating Python or R environments, honoring node and core requests, and running remote commands safely. Trigger on requests like "在远端跑", "去集群上执行", "ssh 到服务器", "login node", "Slurm", "srun", "远端环境", "remote host", or "cluster job".
---

# Remote Cluster Workflow

## Overview

Use this skill when the user wants Codex to perform real work on a remote server or cluster instead of only on the local machine. Prefer local `ssh` plus reusable profile files rather than depending on the visible state of a MobaXterm tab.

Remote profiles live in `%USERPROFILE%\\.codex\remote-profiles`. Each profile defines:

- SSH target and options
- Remote working directory
- Shell bootstrap and environment activation for `conda`, `venv`, or UV-managed `.venv` setups
- Resource wrapper template for direct shells, `srun`, or other schedulers

For environments you use often, prefer one dedicated profile per environment and resource shape instead of repeatedly editing one shared profile. Example: keep separate profiles for `r4.0.5`, `r4.2`, a common Python environment, or a UV project rooted at `/path/to/project`.

## When To Use This Skill

Use this skill when the user wants work to happen on:

- A remote Linux host reached over `ssh`
- A login node that then launches work on compute nodes
- An HPC cluster that needs node, core, partition, GPU, or memory selection
- A remote project-specific Python, R, `conda`, `venv`, or UV environment

Do not force this skill for purely local work.

## When Not To Use This Skill

Do not use this skill when:

- The task is entirely local and does not require `ssh` or a remote scheduler
- The user only wants documentation or profile examples, not actual remote execution
- The request is about MobaXterm window state rather than reproducible OpenSSH-based automation

If the user mixes local and remote language, explicitly confirm which machine should do the work before proceeding.

## Minimum Inputs

Before running real work, identify these inputs:

- Which remote profile to use, or enough information to create one
- The intended remote working directory
- The environment mode: `conda`, `venv`, UV project `.venv`, `uv run`, R environment, or no activation
- The command the user actually wants run
- The resource shape, at minimum node and core count when the cluster requires them

If the request already implies a known profile, prefer reusing it instead of re-asking every field.

## Minimal Question Set

If important inputs are missing and cannot be inferred from an existing profile, ask the fewest questions needed. Prefer this order:

1. Which remote profile or SSH target should be used?
2. Which remote folder should all work stay inside?
3. What exact command or task should run there?
4. Which node and core count should be used, if the profile or scheduler does not already define them?

If only one field is missing, ask only for that field. Do not ask broad setup questions when the profile already answers them.

## Workflow

1. Choose the matching profile. If none exists, create one from `%USERPROFILE%\\.codex\remote-profiles\profile-template.json`.
2. Confirm that the task truly belongs on the remote machine rather than locally.
3. If the server currently uses password login through MobaXterm, bootstrap SSH key access once from the existing interactive session. After bootstrap, prefer key-based OpenSSH for all Codex work.
4. When a profile is new or recently changed, run `scripts/test-remote-profile.ps1` first before any real task command.
5. If profile validation fails, stop and fix the profile or authentication path first. Do not continue into task execution on guesses.
6. Execute remote work through `scripts/invoke-remote-task.ps1`.
7. Keep all task commands inside the configured `remoteWorkdir`.
8. For UV projects, point `remoteWorkdir` at the project root. If the project already has `.venv`, set `environment.activate` to `source .venv/bin/activate`. If the project prefers ephemeral execution, leave activation empty and run task commands as `uv run ...`.
9. If the user authorizes environment changes, install packages inside the requested environment and report what changed. For UV projects, prefer `uv sync`, `uv add`, or `uv remove` inside the project root instead of mixing in unrelated package managers. When a project already has a healthy `.venv`, prefer activating it for quick verification because `uv run ...` may trigger dependency resolution or source builds.
10. Use the profile's `resource.template` to honor node and core requests. If the wrapper is missing or ambiguous, pause and ask one concise question before using expensive resources.
11. Before making environment changes, explicitly confirm the target environment if there is any chance of modifying the wrong one.
12. Before long or expensive runs, explicitly state the profile, remote folder, node, and core count you are about to use.
13. Prefer non-interactive commands and summarize the important results back to the user.

## Decision Order

Use this decision order so the workflow stays predictable:

1. Reuse an existing profile if it already matches the target host, workdir, and environment.
2. If there is no matching profile, create or edit one before running the task.
3. Test the profile if it is new, edited, or suspected stale.
4. Verify the environment if the task depends on Python, R, packages, or project-local tooling.
5. Run the requested task.
6. Only then consider package installation or environment edits, and only if the user authorized them or the task clearly requires them.

## Common Failure Paths

- If SSH authentication fails, do not keep retrying interactively. Switch to the password-bootstrap flow or fix the profile's SSH settings.
- If the user request is actually local, stop and switch out of this skill instead of forcing a remote profile flow.
- If `remoteWorkdir` does not exist, stop and ask for the correct folder rather than silently creating a new project location.
- If the environment activation command fails, report the failing step and verify whether the profile points at the right environment.
- If scheduler placeholders remain unresolved, do not guess missing values. Ask for the exact missing variable such as `partition`, `gpus`, or `memory`.
- If the remote command would write outside `remoteWorkdir`, stop unless the user explicitly asked for environment management or bootstrap work.
- If the user asks for an expensive run but gives no allocation, ask one concise question before consuming shared cluster resources.

## Happy Path

For the most common case, the flow should look like this:

1. Select an existing profile.
2. Run `test-remote-profile`.
3. Optionally run `verify-remote-env` if the task depends on a specific environment.
4. Run `invoke-remote-task` with the requested command, node, and cores.
5. Summarize the result and any files or outputs that matter.

Use this as the default path unless one of the failure conditions above is triggered.

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

Run a UV-managed project after activating its local `.venv`:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\invoke-remote-task.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-uv-project.json" `
  -Command "python main.py" `
  -Node "gpu02" `
  -Cores 8
```

Run a UV-managed project without an explicit activation step:

```powershell
& "%USERPROFILE%\\.codex\skills\remote-cluster-workflow\scripts\invoke-remote-task.cmd" `
  -Profile "%USERPROFILE%\\.codex\remote-profiles\my-uv-project.json" `
  -Command "uv run python main.py" `
  -Node "gpu02" `
  -Cores 8 `
  -SkipEnvironment
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
- Read `references/example-profiles.md` when the user needs a direct-shell, Slurm, or UV project example.
- Read `references/password-bootstrap.md` when the user currently logs in with a password through MobaXterm and wants Codex to take over future remote work.

## Response Shape

When using this skill in a live task, prefer replying in this order:

1. The profile you will use or create
2. The remote folder and environment mode
3. The node and core count
4. The exact command you plan to run
5. The important result summary

This keeps remote execution auditable and reduces wasted back-and-forth on cluster jobs.
