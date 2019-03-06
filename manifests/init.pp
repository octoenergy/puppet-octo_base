class octo_base (
    $awscli_version = "1.11.136",
) {
    # Validate params
    if !$awscli_version {
        fail("A valid AWSCLI version must be set")
    }

    # Wait for unattended upgrades to finish
    exec { "wait for apt lock":
      command => "/bin/bash -c 'while sudo fuser /var/lib/dpkg/lock-frontend; do sleep .1; done'",
    }

    # First uninstall unattended upgrades as this blocks other apt calls from working.
    package { "unattended-upgrades":
      ensure  => "purged",
      require => Exec["wait for apt lock"],
    }

    # ...then upgrade all installed packages...
    exec { "update apt repositories":
        command   => "time -p /usr/bin/apt-get update --fix-missing",
        # Use a longer timeout as the default of 300 seconds fails more often than
        # we would like.
        timeout   => 600,
        tries     => 3,
        logoutput => on_failure,
        require   => Package["unattended-upgrades"],
    }
    exec { "upgrade installed packages":
        command => "time -p /usr/bin/apt-get -y upgrade --fix-missing --fix-broken",
        # Use a longer timeout as the default of 300 seconds fails more often than
        # we would like.
        timeout => 600,
        tries => 3,
        logoutput => on_failure,
        require => Exec["update apt repositories"],
    }

    # All servers should have NTP running
    class { "::ntp":
        require => Exec["update apt repositories"],
    }

    # Install AWSCLI. This is needed by Cloudwatch monitoring scripts and also
    # for initialisation code that runs in EC2 userdata. It's simpler to just
    # have it available on all EC2 machines.
    package { "python-pip":
        ensure => installed,
        require => Exec["upgrade installed packages"],
    }
    exec { "install awscli":
        command => "pip install 'awscli==$awscli_version'",
        path => ["/bin/", "/sbin/", "/usr/bin/", "/usr/bin/local/"],
        user => "root",
        group => "root",
        unless => "pip freeze | grep awscli",
        require => Package["python-pip"],
    }

    # JQ is also used by monitoring scripts to extract data from JSON
    package { "jq":
        ensure => installed,
        require => Exec["upgrade installed packages"],
    }

    # Default EC2 monitoring - this requires an IAM role that allows putting new metrics
    class { "octo_base::cloudwatch::system":
        require => Exec["install awscli"]
    }
}
