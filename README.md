# octo_base

Puppet module providing common functionality for Octopus Energy machines.

## Changelog

### v1.7

- Fix issue with `apt-get upgrade` returning a exit code of 100

### v1.6

- Use `--fix-missing` when calling `apt-get upgrade`.

### v1.5

- Call `autoremove` after `update` and `upgrade`
- Make `upgrade` call more robust using a timeout and retrying

### v1.4

- Extend system monitoring script to work in Ubuntu 16.04

### v1.3

- Add locking to the system metrics file

### v1.2

- AWSCLI version bump
- Cloudwatch logs integration

### v1.1

- AWSCLI version bump
- Unattended upgrades installed by default.

### v1.0

Initial version
