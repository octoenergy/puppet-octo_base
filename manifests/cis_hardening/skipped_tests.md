# CIS Level 1 - Server

## Notes on our test results

###  5.4.4 Ensure default user umask is 027 or more restrictive
We are fixing this.

## Application needs access to /etc/cron.d
* 5.1.7 Ensure permissions on /etc/cron.d are configured

We omit /etc/cron.d from the permission lock down because the application reads
from it to determine the cron jobs that might have stale locks. It should not
be modifiable by the application.

### 5.4.2 Ensure system accounts are non-login and 6.2.7 Ensure all users' home directories exist
We are in the process of fixing this.

### 5.2.12 Ensure SSH Idle Timeout Interval is configured
This has been deliberately left unset on SSH bastions because sometimes
long running jobs with minimal output are run. We are switching over to
using AWS Simple Systems Manager for remote access, which will allow us
to migrate those jobs away from SSH and then enable this setting.

## Protections designed for physical servers that don't translate to cloud hosted VMs
 * 1.4.1 Ensure permissions on bootloader config are configured
 * 1.4.2 Ensure bootloader password is set
 * 1.4.3 Ensure authentication required for single user mode

## Files we don't have, so we don't need to protect
 * 1.7.1.4 Ensure permissions on /etc/motd are configured

## We may want to use IPv6 internally. We accept the larger attack surface.
 * 3.3.3 Ensure IPv6 is disabled

## Internal firewall - Our network security is though AWS security groups
 * 3.4.3 Ensure /etc/hosts.deny is configured
 * 3.6.2 Ensure default deny firewall policy
 * 3.6.3 Ensure loopback traffic is configured
 * 3.6.5 Ensure firewall rules exist for all open ports

## Strange legal paranoia
 * 5.2.15 Ensure SSH warning banner is configured
   * Banners are used to warn connecting users of the particular site's
     policy regarding connection. Presenting a warning message prior to
     the normal user login may assist the prosecution of trespassers on
     the computer system.

## Login is only via SSH, which is key based
 * 5.3.2 Ensure lockout for failed password attempts is configured
 * 5.3.3 Ensure password reuse is limited
 * 5.4.1.1 Ensure password expiration is 365 days or less
 * 5.4.1.2 Ensure minimum days between password changes is 7 or more
 * 5.4.1.4 Ensure inactive password lock is 30 days or less

## Protections for multi user systems (ours are single user)
 * 5.2.14 Ensure SSH access is limited
 * 6.2.8 Ensure users' home directories permissions are 750 or more restrictive

# Level 2 - Server
## 1.1.x Ensure separate partition exists for

* 1.1.2 Ensure separate partition exists for /tmp
* 1.1.6 Ensure separate partition exists for /var/tmp
* 1.1.10 Ensure separate partition exists for /var/log
* 1.1.11 Ensure separate partition exists for /var/log/audit
* 1.1.12 Ensure separate partition exists for /home
* 1.1.5 Ensure separate partition exists for /var

### Rationale
Having separate partitions is intended to guard against two classes of
problems. Firstly resource exhaustion - a full, or nearly full disk can
preventing processes from running. Secondly security protections offered
at mount time.

### Why we aren't doing this
We may look at this in the future. Our infrastructure is deployed regularly
so the chance of any of these file systems filling up is minimal. Since we
deploy with a single login user with passwordless sudo privileges we
can't limit that users actions.

## Internal firewall - Our network security is though AWS security groups
* 3.6.5 Ensure firewall rules exist for all open ports

## We don't run auditd - we should - these will be addressed
* 4.1.3 Ensure auditing for processes that start prior to auditd is enabled
* 4.1.4 Ensure events that modify date and time information are collected
* 4.1.5 Ensure events that modify user/group information are collected
* 4.1.6 Ensure events that modify the system's network environment are collected
* 4.1.7 Ensure events that modify the system's Mandatory Access Controls are collected
* 4.1.8 Ensure login and logout events are collected
* 4.1.9 Ensure session initiation information is collected
* 4.1.10 Ensure discretionary access control permission modification events are collected
* 4.1.11 Ensure unsuccessful unauthorized file access attempts are collected
* 4.1.12 Ensure use of privileged commands is collected
* 4.1.13 Ensure successful file system mounts are collected
* 4.1.14 Ensure file deletion events by users are collected
* 4.1.15 Ensure changes to system administration scope (sudoers) is collected
* 4.1.16 Ensure system administrator actions (sudolog) are collected
* 4.1.17 Ensure kernel module loading and unloading is collected
* 4.1.18 Ensure the audit configuration is immutable
* 4.1.1.1 Ensure audit log storage size is configured
* 4.1.1.2 Ensure system is disabled when audit logs are full
* 4.1.1.3 Ensure audit logs are not automatically deleted
* 4.2.4 Ensure permissions on all logfiles are configured

## Only login is via SSH, which has equivalent restrictions in place
 * 5.4.5 Ensure default user shell timeout is 900 seconds or less


