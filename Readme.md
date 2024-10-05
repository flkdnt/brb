# Bash Rclone Backup(BRB)

BRB is a simple, yet powerful, backup solution for Linux written in bash. 

BRB is an [Rclone](https://rclone.org/) scheduler that uses systemd timers to run backup jobs that are defined in a simple yaml configuration. 

### Features

The most powerful features of BRB are actually the features of Rclone. What BRB does is enable scheduling of rclone jobs, on a per-user basis, using a configuration file.

- Read about [Rclone](https://rclone.org/#about)  
- Read about Rclone [Capabilities](https://rclone.org/#what).  
- Read about Rclone [Features](https://rclone.org/#features).  
- Read about Rclone [Cloud and Non-Cloud Providers](https://rclone.org/#providers)  
- Read about Rclone [Virtual Providers](https://rclone.org/#virtual-providers)  

### Open-Source Credits

BRB couldn't have been built without the following tools:

- [Bash](https://www.gnu.org/software/bash/)
- [Rclone](https://rclone.org/)
- [rsync](https://rsync.samba.org/)
- [systemd](https://systemd.io/)
- [yq](https://github.com/mikefarah/yq)

## Documentation

### User Documentation

1. For instructions on how to Install BRB, see the [Installation Guide](Documentation/Install.md)

2. For instructions on how to use BRB, see the [User Guide](Documentation/UserGuide.md).

3. For information on the configuration file options, see the [YAML  Configuration Guide](Documentation/Configuration.md).

### Developer Documentation

For Detailed Developer Documentation, see the [Architecture Documentation](Documentation/Architecture.md)

## Found a Bug? Have a Request? Want to get involved?

Please open a pull request or open a github issue if you want to contribute, thanks.
