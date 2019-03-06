# octo_base

Puppet module providing common functionality for Octopus Energy machines.

## Publishing

1. Update `metadata.json` 
2. Update below changelog
3. Commit
4. Tag with `git tag v1.x`
5. Push everything to Github

## Changelog

### v1.10

- Purge unattended updates at start (to allow other apt commands to not get
  locked out).

### v1.9.2

- Use lower min versions in dependency version ranges

### v1.9.1

- Use version ranges in dependencies

### v1.9

- Fix (another) bug in metrics script around disk usage
- Install packages required for monitoring script in Ubuntu 16:04 and later

### v1.8

- Fix bug in metrics script around disk usage

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
