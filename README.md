# octo_base

Puppet module providing common functionality for Octopus Energy machines.

## Publishing

1. Update `metadata.json`
2. Update below changelog
3. Commit
4. Tag with `git tag v1.x`
5. Push everything to Github

## Changelog

### v1.30

- Fix bug with how dimensions are associated with metrics

### v1.29

- Forward system log files to Cloudwatch

### v1.28

- Batch Cloudwatch PutMetricData to a single AWSCLI call for `collect-system-metrics.sh`

### v1.27

- Disable AWS Inspector in Vagrant builds

### v1.26

- Set default umask to 027

### v1.25

- Actually fix CIS hardening problem with `/var/log/`.

### v1.23, v1.24

- Attempts to fix CIS hardening problem with `/var/log/`.

### v1.22

- Exclude `/etc/cron.d/` from CIS permission tightening

### v1.21

- Fix for sysctl not loading late enough in the boot sequence

### v1.20

- CIS Level 1 Server

### v1.19

- Fix broken AWS inspector key

### v1.18

- CIS hardening

### v1.17

- Add SSM agent.

### v1.16

- Add AWS inspector.

### v1.15

- Add region variable to accommodate deployments in other regions.

### v1.14

- Ensure AWS logs nanny is not installed unnecessarily.

### v1.13

- Ensure AWS logs config updates correctly.

### v1.12

- Correct memory calculations for Ubuntu 18.04 in metrics script

### v1.11

- Remove changes from 1.10 (found a better way to solve same problem)
- Use Python 3 for `awscli`

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
