## YAML Configuration File Documentation

## Configuration Example
```yaml
---
jobs:
  - name: testjob
    parameters:
      args: "--update --progress"
      command: copy
      frequency: daily
      program: rclone
    paths:
      destination: /var/test
      source: /tmp/test
    pathtypes:
      destination: local
      source: local
```

### Note on Schedule section

In a live config, you'll see a Schedule sub-section. This is used by the scheduler to map the job to a running systemd timer/service and check that timer for changes. Any modification or deletion of this section will cause the scheduler to recreate systemd timers and possibly cause issues.

```yaml
jobs:
  - name: testjob
    paths:
      destination: /var/test
      source: /tmp/test
    schedule:
      modified: Thu May 23 03:47:26 AM EDT 2024
      timer: run-recefe7ab7126451db1903a9c60e1a1f4.timer
```

## Configuration File Parameters and Options
| Parameter | Default Value | Required? | Description |
|-|-|-|-|
| name | NONE | YES | Unique name of job |
| parameters |-|-| Specifications for job |
| parameters.args | `--update --progress` |NO| rclone arguments/flags to add to the command |
| parameters.command |`copy`| NO | rclone subcommand |
| parameters.frequency | `daily` | NO |  Frequency to run backup job. See [Systemd Time](SystemdTime.md) for details on Valid DateTime Formats |
| parameters.program | `rclone` | NO | Command program to run job with, rclone is default. Rsync is not currently supported. |
| parameters.mirrorcopy | NONE | NO |  MirrorCopy first copies from Source to Destination; then copies from Destination to Source |
| paths |-|-| filepath Specifications for job |
| paths.destination | NONE | YES | Destination - where command is going to copy TO |
| paths.source | NONE | YES| Source - where command is going to copy FROM |
| pathtypes |-|-| filepath Specification types |
| pathtypes.destination | `local` | NO | Type of path for Destination. If destination is remote storage, use the name used in rclone config. |
| pathtypes.source | `local` | NO | Type of path for Source. If source is remote storage, use the name used in rclone config. |
