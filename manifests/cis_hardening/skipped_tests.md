# CIS Level 1 - Server

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

* /tmp
* /var
* /var/tmp
* /var/log
* /var/log/audit
* /home

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
