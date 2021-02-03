class octo_base::cloudwatch::system {

    # Install system packages
    $system_packages = [ "lockfile-progs", "bc" ]
    package { $system_packages:
        ensure => "installed",
    }

    # Run a script every minute that collects metrics missing from the default
    # Cloudwatch EC2 group and submits them
    $script_path = "/usr/local/sbin/collect-system-metrics.sh"
    $metrics_json_path = "/usr/local/sbin/metrics.json"
    file { "system metrics script":
        path => $script_path,
        source => "puppet:///modules/octo_base/cloudwatch/collect-system-metrics.sh",
        owner => "root",
        group => "root",
        mode => "0755",
    }
    file { "system metrics json":
        path   => $metrics_json_path,
        source => "puppet:///modules/octo_base/cloudwatch/metrics.json",
        owner  => "root",
        group  => "root",
        mode   => "0755",
    }
    cron { "system metrics cron":
        ensure => present,
        command => $script_path,
        user => "root",
        minute =>  "*",
    }

}
