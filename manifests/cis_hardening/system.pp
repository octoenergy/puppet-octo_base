class octo_base::cis_hardening::system {

  # CIS Level 1 - Server
  file_line { "noexec /dev/shm":
    path => "/etc/fstab",
    line =>
      "none     /dev/shm     tmpfs     rw,noexec,nosuid,nodev     0     0",
  }

  file { "disable unused filesystems":
    path   => "/etc/modprobe.d/unused_fs.conf",
    source =>
      "puppet:///modules/octo_base/cis_hardening/etc/modprobe.d/unused_fs.conf"
  }

  # 1.5.1 Ensure core dumps are restricted
  file { "/etc/security/limits.d/cores.conf":
    source =>
      "puppet:///modules/octo_base/cis_hardening/etc/security/limits.d/cores.conf"
  }
  file { "/etc/sysctl.d/60-limit_cores.conf":
    source =>
      "puppet:///modules/octo_base/cis_hardening/etc/sysctl.d/60-limit_cores.conf"
  }
  cron::job { "reload-sysctl":
    command => "/bin/sleep 60; /sbin/sysctl --system",
    special => "reboot",
  }

  # 1.5.3 Ensure address space layout randomization (ASLR) is enabled
  file { "ensure ASLR is enabled":
    path    => "/etc/sysctl.d/60-aslr.conf",
    content => "kernel.randomize_va_space = 2"
  }

  # 3.1.1 Ensure IP forwarding is disabled
  # 3.1.2 Ensure packet redirect sending is disabled
  # 3.2.1 Ensure source routed packets are not accepted
  # 3.2.2 Ensure ICMP redirects are not accepted
  # 3.2.3 Ensure secure ICMP redirects are not accepted
  # 3.2.4 Ensure suspicious packets are logged
  # 3.2.5 Ensure broadcast ICMP requests are ignored
  # 3.2.6 Ensure bogus ICMP responses are ignored
  # 3.3.1 Ensure IPv6 router advertisements are not accepted
  # 3.3.2 Ensure IPv6 redirects are not accepted
  file { "CIS networking recommendations - features":
    path   => "/etc/sysctl.d/60-cis_networking.conf",
    source =>
      "puppet:///modules/octo_base/cis_hardening/etc/sysctl.d/60-cis_networking.conf"
  }

  # 3.4.1 Ensure TCP Wrappers is installed
  package { "tcpd":
    ensure => "installed",
  }

  # 3.5.1 Ensure DCCP is disabled
  # 3.5.2 Ensure SCTP is disabled
  # 3.5.3 Ensure RDS is disabled
  # 3.5.4 Ensure TIPC is disabled
  file { "CIS networking recommendations - protocols":
    path   => "/etc/modprobe.d/unused_network_protocols.conf",
    source =>
      "puppet:///modules/octo_base/cis_hardening/etc/modprobe.d/unused_network_protocols.conf"
  }

  # 4.2.4 Ensure permissions on all logfiles are configured
  cron::daily { "CIS_log_file_permissions":
    command => "/bin/chmod -R u+rwX,g+X,g-wx,o-rwx /var/log/*",
  }

  # 5.6 Ensure access to the su command is restricted
  file_line { "Ensure access to the su command is restricted":
    path => "/etc/pam.d/su",
    line => "auth required pam_wheel.so"
  }

  # 5.1.[2-7] Ensure permissions on /etc/crontab and related files are configured
  file { [
    "/etc/crontab",
    "/etc/cron.hourly",
    "/etc/cron.daily",
    "/etc/cron.weekly",
    "/etc/cron.monthly",
    # We omit /etc/cron.d as the application reads from it to determine the cron jobs
    # that might have stale locks.
  ]:
    mode => "og-rwx"
  }

  # 5.1.8 Ensure at/cron is restricted to authorized users
  #  - we specify none, so this is root only
  file { [
    "/etc/cron.allow",
    "/etc/at.allow",
  ]:
    mode   => "0600",
    ensure => "present",
  }

  # 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured
  file { "/etc/ssh/sshd_config":
    mode => "0600",
  }

  # 5.2.2 Ensure SSH Protocol is set to 2
  file_line { "Ensure SSH protocol V2":
    path => "/etc/ssh/sshd_config",
    line => "Protocol 2",
  }

  # 5.2.3 Ensure SSH LogLevel is set to INFO
  file_line { "Ensure SSH LogLevel is set to INFO":
    path => "/etc/ssh/sshd_config",
    line => "LogLevel INFO",
  }

  # 5.2.4 Ensure SSH X11 forwarding is disabled
  file_line { "Ensure SSH X11 forwarding is disabled":
    path  => "/etc/ssh/sshd_config",
    line  => "X11Forwarding no",
    match => "^X11Forwarding",
  }

  # 5.2.5 Ensure SSH MaxAuthTries is set to 4 or less
  file_line { "Ensure SSH MaxAuthTries is set to 4 or less":
    path  => "/etc/ssh/sshd_config",
    line  => "MaxAuthTries 4",
    match => "MaxAuthTries",
  }

  # 5.2.6 Ensure SSH IgnoreRhosts is enabled
  file_line { "Ensure SSH IgnoreRhosts is enabled":
    path  => "/etc/ssh/sshd_config",
    line  => "IgnoreRhosts yes",
    match => "IgnoreRhosts",
  }

  # 5.2.7 Ensure SSH HostbasedAuthentication is disabled
  file_line { "Ensure SSH HostbasedAuthentication is disabled":
    path  => "/etc/ssh/sshd_config",
    line  => "HostbasedAuthentication no",
    match => "#HostbasedAuthentication",
  }

  # 5.2.8 Ensure SSH root login is disabled
  file_line { "Ensure SSH root login is disabled":
    path  => "/etc/ssh/sshd_config",
    line  => "PermitRootLogin no",
    match => "#PermitRootLogin",
  }

  # 5.2.9 Ensure SSH PermitEmptyPasswords is disabled
  file_line { "Ensure SSH PermitEmptyPasswords is disabled":
    path  => "/etc/ssh/sshd_config",
    line  => "PermitEmptyPasswords no",
    match => "#PermitEmptyPasswords",
  }

  # 5.2.10 Ensure SSH PermitUserEnvironment is disabled
  file_line { "Ensure SSH PermitUserEnvironment is disabled":
    path  => "/etc/ssh/sshd_config",
    line  => "PermitUserEnvironment no",
    match => "PermitUserEnvironment",
  }

  # 5.2.11 Ensure only approved MAC algorithms are used
  file_line { "Ensure only approved MAC algorithms are used":
    path => "/etc/ssh/sshd_config",
    line =>
      "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com"
    ,
  }

  # 5.2.12 Ensure SSH Idle Timeout Interval is configured
  file_line { "Ensure SSH Idle Timeout Interval is configured":
    path  => "/etc/ssh/sshd_config",
    line  => "ClientAliveInterval 300",
    match => "ClientAliveInterval",
  }

  file_line { "Ensure SSH Idle Timeout Interval (count max) is configured":
    path  => "/etc/ssh/sshd_config",
    line  => "ClientAliveCountMax 0",
    match => "ClientAliveCountMax",
  }

  # 5.2.13 Ensure SSH LoginGraceTime is set to one minute or less
  file_line { "Ensure SSH LoginGraceTime is set to one minute or less":
    path  => "/etc/ssh/sshd_config",
    line  => "LoginGraceTime 60",
    match => "LoginGraceTime",
  }

  # 5.4.2 Ensure system accounts are non-login
  user { ["lxd", "pollinate"]:
    shell => "/usr/sbin/nologin",
  }

  # 5.4.4 Ensure default user umask is 027 or more restrictive
  file_line { "Ensure default user umask is 027 or more restrictive":
    path => "/etc/profile",
    line => "umask 022",
  }
}
