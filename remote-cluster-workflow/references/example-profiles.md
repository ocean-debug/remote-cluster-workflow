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

