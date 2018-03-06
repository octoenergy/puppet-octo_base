class octo_base (
    $awscli_version = "1.11.136",
) {
    # Validate params
    if !$awscli_version {
        fail("A valid AWSCLI version must be set") 
    }

    # Upgrade all installed packages...
    exec { "update apt repositories":
        command => "/usr/bin/apt-get update",
    }
    exec { "upgrade installed packages": 
        command => "/usr/bin/apt-get -y upgrade", 
        require => Exec["update apt repositories"],
    }

    # ...and set-up unattended upgrades
    include unattended_upgrades

    # All servers should have NTP running
    include "::ntp"

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
