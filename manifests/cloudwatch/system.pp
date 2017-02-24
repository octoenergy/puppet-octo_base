class octo_base::cloudwatch::system {

    # Run a script every minute that collects metrics missing from the default 
    # Cloudwatch EC2 group and submits them
    $script_path = "/usr/local/sbin/collect-system-metrics.sh"
    file { "system metrics script":
        path => $script_path,
        source => "puppet:///modules/octo_base/cloudwatch/collect-system-metrics.sh",
        owner => "root",
        group => "root",
        mode => "0755",
    }
    cron { "system metrics cron":
        ensure => present,
        command => $script_path,
        user => "root", 
        minute =>  "*", 
    }

}
