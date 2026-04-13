# Example Profiles

## Direct Shell

Use this when the login host itself is the place where commands should run.

```json
{
  "profileName": "direct-shell-example",
  "sshTarget": "user@example-host",
  "sshOptions": ["-p", "22"],
  "remoteWorkdir": "/data/project",
  "preCommands": [
    "source ~/.bashrc"
  ],
  "environment": {
    "activate": "conda activate analysis-env"
  },
  "resource": {
    "template": "bash -lc {command_quoted}",
    "defaults": {
      "node": "login",
      "cores": "4"
    }
  }
}
```

## UV Project

Use this when the project root contains `pyproject.toml`, `uv.lock`, and a local `.venv`.

```json
{
  "profileName": "uv-project-example",
  "sshTarget": "user@login-host",
  "remoteWorkdir": "/home/user/my-agent-project",
  "preCommands": [
    "source ~/.bashrc"
  ],
  "environment": {
    "activate": "if [ -f .venv/bin/activate ]; then source .venv/bin/activate; fi"
  },
  "resource": {
    "template": "bash -lc {command_quoted}",
    "defaults": {
      "node": "login",
      "cores": "4"
    }
  }
}
```

If you prefer `uv run ...` for each command instead of activating `.venv`, keep `remoteWorkdir` at the project root and either leave `environment.activate` empty or call `invoke-remote-task` with `-SkipEnvironment`. This is convenient for a clean UV workflow, but it can also trigger dependency resolution or source builds if the environment is not already warmed up.

## Slurm `srun`

Use this when you log into a gateway or login node and then ask Slurm for a specific node and core count.

```json
{
  "profileName": "slurm-srun-example",
  "sshTarget": "user@login-host",
  "remoteWorkdir": "/home/user/project",
  "preCommands": [
    "source ~/.bashrc"
  ],
  "environment": {
    "activate": "conda activate ml-env"
  },
  "resource": {
    "template": "srun -w {node} -c {cores} -p {partition} bash -lc {command_quoted}",
    "defaults": {
      "node": "gpu03",
      "cores": "8",
      "partition": "gpu"
    }
  }
}
```

## Custom Scheduler

If your cluster uses another scheduler, keep the same shape and replace only `resource.template`. The wrapper can contain any extra placeholders as long as you supply them in `defaults` or through `-Vars`.
