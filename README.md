# Remote Cluster Workflow

Run Codex tasks on remote Linux servers or HPC clusters through SSH, a fixed remote work directory, a chosen environment, and an explicit compute allocation.

This repository is organized around one canonical root-level skill source:

- The canonical skill files live at the repository root: [`SKILL.md`](./SKILL.md), [`test-prompts.json`](./test-prompts.json), and [`results.tsv`](./results.tsv)
- The repository also includes [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json) and a mirrored copy under [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow) for plugin-shaped installation

Treat the repository root as the source of truth. The copy under `skills/remote-cluster-workflow/` exists as a packaged mirror for plugin or marketplace-style layouts.

## What It Does

`remote-cluster-workflow` helps Codex:

- connect to a remote machine with local `ssh`
- stay inside one declared remote work directory
- activate a chosen `conda`, `venv`, UV-managed `.venv`, or R environment
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
+-- SKILL.md
+-- test-prompts.json
+-- results.tsv
+-- skills/
|   +-- remote-cluster-workflow/
|       +-- SKILL.md
|       +-- README.md
|       +-- test-prompts.json
|       +-- results.tsv
|       +-- agents/openai.yaml
|       +-- references/
|       +-- scripts/
+-- remote-profiles/
    +-- profile-template.json
    +-- direct-shell.example.json
    +-- uv-project.example.json
    +-- slurm-srun.example.json
    +-- pbs-torque.example.json
```

## Quick Start

### Option 1: Use It As A Skill

1. Copy the root-level canonical skill files and folders into your local Codex skill directory, or copy the packaged mirror from [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow).
   Windows example target: `%USERPROFILE%\.codex\skills\remote-cluster-workflow`
2. If you are installing manually, make sure the final local skill directory contains:
   - `SKILL.md`
   - `test-prompts.json`
   - `results.tsv`
   - `references/`
   - `scripts/`
   - `agents/`
3. Copy one of the example profiles from [`remote-profiles`](./remote-profiles) into your local remote profile directory.
   Windows example: `%USERPROFILE%\.codex\remote-profiles\`
4. Edit the copied profile for your own infrastructure:
   - `sshTarget`
   - `remoteWorkdir`
   - `environment.activate`
   - `resource.template`
   - `resource.defaults`
5. For UV projects, point `remoteWorkdir` at the project root. Then choose one of two patterns:
   - activate the project venv with `source .venv/bin/activate`
   - or leave activation empty and run tasks with `uv run ...`
   For quick validation, the first pattern is usually faster and more stable. `uv run ...` may sync dependencies or build native extensions if the project environment is not already ready.
6. Use `$remote-cluster-workflow` in Codex.

### Option 2: Use It As A Plugin-Shaped Repo

1. Clone this repository into your local plugin directory.
2. Keep the repo root intact so Codex can read [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json).
3. If your Codex setup uses plugin marketplace wiring, point it at this repo-local plugin.

The exact marketplace wiring varies by local Codex setup, but this repo now has the expected plugin manifest and `skills/` layout.

## Conda vs UV

| Situation | Prefer | Why |
| --- | --- | --- |
| You already have a stable shared environment such as `r4.2` or `analysis-env` | Conda | Good fit for team-wide environments, R stacks, and long-lived shared packages |
| Your project already contains `pyproject.toml`, `uv.lock`, and `.venv/` | UV with `source .venv/bin/activate` | Fastest day-to-day debugging path for project-local Python environments |
| You want the command to respect the project's locked Python dependencies | UV with `uv run ...` | Lets UV resolve or sync against the project definition for that command |
| You are only doing a quick environment or smoke check | Existing `.venv` or existing Conda env | Avoids unnecessary dependency resolution and native rebuilds |
| You need to add or remove Python dependencies inside a UV project | UV | `uv add`, `uv remove`, and `uv sync` keep the project definition and lockfile consistent |
| You need a mixed R or system-tool-heavy analysis environment | Conda | Usually simpler than forcing non-Python tooling into a UV workflow |
| `uv run ...` starts building packages or compiling native extensions | Existing `.venv` first | More stable for iterative debugging, especially on shared clusters |

### Rule Of Thumb

- Choose Conda for shared, long-lived, multi-language environments.
- Choose UV for project-local Python apps that already live around `pyproject.toml` and `uv.lock`.
- When both are possible, prefer the already-warmed environment for faster remote validation.

## `.venv` Activation vs `uv run`

| Goal | `.venv` activation flow | `uv run` flow |
| --- | --- | --- |
| Quick environment check | `verify-remote-env.cmd -Profile my-uv-profile.json -Node gpu02 -Cores 8` | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "uv run python --version" -Node gpu02 -Cores 8 -SkipEnvironment` |
| Run the main app | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "python main.py" -Node gpu02 -Cores 8` | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "uv run python main.py" -Node gpu02 -Cores 8 -SkipEnvironment` |
| Run pytest | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "python -m pytest -q" -Node gpu02 -Cores 8` | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "uv run pytest -q" -Node gpu02 -Cores 8 -SkipEnvironment` |
| Install or sync deps | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "python -m pip install -e ." -Node gpu02 -Cores 8` | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "uv sync" -Node gpu02 -Cores 8 -SkipEnvironment` |
| Add one dependency | Usually avoid mixing `pip` into a UV-managed project unless you know why | `invoke-remote-task.cmd -Profile my-uv-profile.json -Command "uv add rich" -Node gpu02 -Cores 8 -SkipEnvironment` |

### Practical Advice

- Prefer the `.venv` activation flow when the project environment already works and you want the fastest debug loop.
- Prefer `uv run` when you intentionally want the command to respect the current lockfile and dependency graph.
- Prefer `uv sync` and `uv add` over `pip install` for UV-managed projects, so `pyproject.toml` and `uv.lock` stay aligned.
- If `uv run` starts compiling packages on a cluster node, switch back to the warmed `.venv` flow unless you explicitly need a fresh resolution.

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
Profile: my-uv-profile.json
Remote workdir: /home/user/my_agent_project/agent1
Environment: source .venv/bin/activate
Resources: gpu02, 8 cores
Verify the UV environment, then run the agent tests.
```

```text
Use $remote-cluster-workflow.
Profile: my-r-profile.json
Remote workdir: /data/analysis/C5
Environment: conda activate r4.2
Resources: gpu02, 8 cores
Verify the environment, then run the R script and summarize outputs.
```

## Agent1 Example

This is a sanitized version of the workflow used for a real UV project named `agent1`.

### Profile Shape

```json
{
  "profileName": "my-agent1-uv-gpu02-8",
  "sshTarget": "user@login-host",
  "remoteWorkdir": "/home/user/my_agent_project/agent1/",
  "preCommands": [
    "source ~/.bashrc"
  ],
  "environment": {
    "activate": "if [ -f .venv/bin/activate ]; then source .venv/bin/activate; fi"
  },
  "resource": {
    "template": "qsub-wrapper-or-other-scheduler-template",
    "defaults": {
      "node": "gpu02",
      "cores": "8"
    }
  }
}
```

### Prompt Pattern

```text
Use $remote-cluster-workflow.
Profile: my-agent1-uv-gpu02-8.json
Remote workdir: /home/user/my_agent_project/agent1/
Environment: source .venv/bin/activate
Resources: gpu02, 8 cores
Verify the environment, then run the agent task or tests.
```

### Why This Pattern Works Well

- The project root already contains `pyproject.toml`, `uv.lock`, and `.venv/`.
- Activating `.venv` is usually faster than `uv run ...` for day-to-day debugging.
- `uv run ...` is still useful when you explicitly want UV to resolve or sync dependencies for the current command.

### Example Verification Output

Typical quick verification for this pattern should confirm:

- `pwd` points at `/home/user/my_agent_project/agent1`
- `VIRTUAL_ENV` points at `/home/user/my_agent_project/agent1/.venv`
- `PYPROJECT_TOML=present`
- `UV_LOCK=present`
- `which python` resolves to `.venv/bin/python`
- `which uv` resolves to the installed UV binary

## Example Profile Types

- [`profile-template.json`](./remote-profiles/profile-template.json): minimal starting point
- [`direct-shell.example.json`](./remote-profiles/direct-shell.example.json): login host runs the commands directly
- [`uv-project.example.json`](./remote-profiles/uv-project.example.json): project-local `.venv` activated from a UV-managed root
- [`slurm-srun.example.json`](./remote-profiles/slurm-srun.example.json): use `srun` for node/core requests
- [`pbs-torque.example.json`](./remote-profiles/pbs-torque.example.json): use `qsub` for PBS/Torque clusters

## Security Notes

- This repository does not include any private hostnames, usernames, internal IPs, project paths, or personal environment names.
- If a server still uses password login, bootstrap SSH key access first. See [`password-bootstrap.md`](./skills/remote-cluster-workflow/references/password-bootstrap.md).
- Keep private profiles outside the public repository unless you have scrubbed all sensitive details.

## Development Notes

- The canonical skill source lives at the repository root.
- The mirrored plugin copy lives in [`skills/remote-cluster-workflow`](./skills/remote-cluster-workflow).
- If a file exists both at the repo root and under `skills/remote-cluster-workflow/`, treat the root copy as authoritative.
- The PowerShell helpers under `scripts/` are intended for Windows hosts that launch remote Linux work through `ssh`.
- The repository is designed to be easy to fork and customize for different clusters or schedulers.

## License

This project is released under the MIT License. See [LICENSE](./LICENSE).

## Changelog

Version history is tracked in [CHANGELOG.md](./CHANGELOG.md).
