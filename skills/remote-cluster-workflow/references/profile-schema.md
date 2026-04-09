# Remote Profile Schema

Remote profiles are JSON files stored in `%USERPROFILE%\\.codex\remote-profiles`.

## Required Fields

```json
{
  "profileName": "project-name",
  "sshTarget": "user@login-host",
  "remoteWorkdir": "/path/to/project",
  "preCommands": [
    "source ~/.bashrc"
  ],
  "environment": {
    "activate": "conda activate analysis-env"
  },
  "resource": {
    "template": "bash -lc {command_quoted}",
    "defaults": {
      "node": "gpu03",
      "cores": "8"
    }
  }
}
```

## Field Notes

- `profileName`: Friendly label used in discussion and file naming.
- `sshTarget`: Anything accepted by `ssh`, including aliases from `~/.ssh/config`.
- `sshOptions`: Optional string array such as `["-p", "20003"]`.
- `remoteShell`: Optional shell executable. Default is `bash`.
- `remoteWorkdir`: Every task command is executed from here.
- `preCommands`: Optional array of shell commands run before `cd remoteWorkdir`.
- `environment.activate`: Optional activation command such as `conda activate env`, `mamba activate env`, `source venv/bin/activate`, or module-loading commands.
- `resource.template`: Wrapper used to honor resource requests. It must include `{command_quoted}` and may include placeholders such as `{node}`, `{cores}`, `{partition}`, `{gpus}`, or `{memory}`.
- `resource.defaults`: Default values for wrapper placeholders. User-specified `-Node`, `-Cores`, and `-Vars key=value` override these defaults.

## Placeholder Rules

`invoke-remote-task.ps1` always provides:

- `{command}`: Unquoted multi-line shell script
- `{command_quoted}`: Single-quoted command safe for `bash -lc`
- `{script}`: Unquoted multi-line shell script prefixed with `#!/bin/bash`
- `{script_quoted}`: Single-quoted Bash script with the shebang already included

It also provides:

- `{node}` when passed with `-Node` or present in defaults
- `{cores}` when passed with `-Cores` or present in defaults
- `{workdir}` and `{workdir_quoted}` from `remoteWorkdir`
- `{profile}` and `{profile_quoted}` from `profileName`
- Anything from `resource.defaults`
- Anything from `-Vars key=value`

If a placeholder remains unresolved, the script exits with an error instead of guessing.

