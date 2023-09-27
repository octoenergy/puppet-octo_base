# octo_base

Puppet module providing common functionality for Octopus Energy machines.

## Making changes

After any change made to the base manifest, there's three things that need to be done to push the change to production.

0. The change needs to be committed and pushed to the `octo_base` repo.
1. The [version number](https://github.com/octoenergy/puppet-octo_base/blob/master/metadata.json#L3) in the `metadata.json` file needs to be incremented.
2. The octo_base repository needs to have a new release created. Once your change has been merged, including the version number change, you can create a release [here](https://github.com/octoenergy/puppet-octo_base/releases/new).

   The tag should match the version you specified in the `metadata.json` file, _including_ the `v.`, so if you incremented the version to `v1.38` you need to tag it as `v1.38`. The same applies to the release title. The assets are generated automatically, so no need to zip / upload anything.

3. In the `kraken-core` repo, you need to change the version for the `octoenergy-octo_base` module to match the version specified above. There's two places this change is made:
   In the [Puppetfile](https://github.com/octoenergy/kraken-core/blob/master/packer/puppet/vendor/Puppetfile#L8), only the version line needs to change.
   In the [Puppetfile.lock](https://github.com/octoenergy/kraken-core/blob/master/packer/puppet/vendor/Puppetfile.lock#L73), the version number _and_ the SHA need to change. You can get the SHA of the release on the [releases page](https://github.com/octoenergy/puppet-octo_base/releases) of the octo_base repo.

## Changelog

### v1.46

- Add option to include/exclude ssm-agent

### v1.45

- Update unnecessary package list to not remove snapd on newer ubuntu images

### v1.44

- Add puppet tooling
- $vagrant must be set to 1 to work

### v1.42

- Fix pip install of awscli

### v1.41

- Update awscli from v1.16.119 to v1.25.46
- Update libssl from v1.1 to v3

### v1.40

- Ensure AWS Inspector installs on Ubuntu 22.04

### v1.39

- Fix broken CW agent config

### v1.38

- Switch CW agent to run as root

### v1.37

- Fixed missing comma

### v1.36

- Change CW Agent logfile location
- Change dpkg.log to apt logfile
- Add `omit hostname` and aggregate based on `InstanceName`

### v1.35

- Fix namespace and CW dimensions

### v1.34

- Remove awslogs and replace it with CW Agent

### v1.33

- Add another DiskUsedPercentage Cloudwatch metric with new dimensions

### v1.32

- Ensure AWS Inspector installs on Ubuntu 20.04

### v1.31

- Allow AWS Inspector to be optional

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
