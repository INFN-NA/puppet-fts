# @summary A short summary of the purpose of this class
#
# @example
#   include fts::server
#
# This class defines the configuration for the FTS server.
# It takes in parameters for configuring the server and sets up the necessary resources.
# 
# Example usage:
# 
# class { 'fts::server':
#   fts_user => 'fts3',
#   fts_db_type => 'mysql',
#   fts_db_username => 'root',
#   fts_db_password => 'ftstestpassword',
#   fts_db_threads_num => 24,

# }
#
# ==== Parameters
# [*fts_user*] (string)
#   The user that will run the FTS server
# 
# [*fts_db_type*] (string)
#   The type of database backend to use
#
# [*db_host*] (string)
#   The hostname of the database server
#
# [*fts_db_username*] (string)
#   The username to use to connect to the database
#
# [*fts_db_password*] (string)
#   The password to use to connect to the database
#
# [*fts_db_threads_num*] (integer)
#   The number of threads to use for the database backend
#
# [*fts_server_alias*] (string)
#   The alias to use for the FTS server
#
# [*configure_firewall*] (boolean)
#   Whether to configure the firewall or not
#
class fts::server (
  String  $fts_user                 = 'fts3',
  String  $fts_db_type              = 'mysql',
  String  $db_host                   = 'fts-db.infn.it',
  String  $fts_db_username          = 'root',
  String  $fts_db_password          = 'ftstestpassword',
  Integer $fts_db_threads_num       = 24,
  String  $fts_server_alias         = 'fts3-server',
  Boolean $configure_firewall       = true,
) {
  $fts_db_connection_string = "${db_host}:3306/${fts_user}"
  #include cron
  class { 'selinux':
    mode => 'enforcing',
  }
  class { 'apache':
    trace_enable     => 'Off',
    default_ssl_key  => '/etc/grid-security/hostkey.pem',
    default_ssl_cert => '/etc/grid-security/hostcert.pem',
  }
  # Set SSLCipherSuite
  class { 'apache::mod::ssl':
    ssl_cipher => "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
  }
  package {
    default:
      ensure   => present,
      provider => yum,
      ;

    # Base packages
    ['zeromq', 'zeromq-devel', 'fts-server', 'fts-rest-server', 'fts-monitoring']:
      ;

    # Database backend
    'fts-mysql':
      ;

    # SELinux rules
    ['fts-server-selinux', 'fts-rest-server-selinux', 'fts-monitoring-selinux']:
      ;

    # Extras
    ['fts-msg', 'fts-infosys']:
      ;
  }
  include fts::client
  file { '/etc/httpd/conf.d/fts3rest.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/httpd/fts3rest.conf',
    require => [Package['fts-rest-server'], Package['httpd']],
  }

  file { '/etc/httpd/conf.d/ftsmon.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/httpd/ftsmon.conf',
    require => [Package['fts-monitoring'], Package['httpd']],
  }
  if $configure_firewall {
    include firewall
    firewall {
      '00000 accept all icmp':
        proto => 'icmp',
        jump  => 'accept',
        ;
      '00001 accept all to lo interface':
        proto   => 'all',
        iniface => 'lo',
        jump    => 'accept',
        ;
      '00002 reject local traffic not on loopback interface':
        iniface     => '! lo',
        proto       => 'all',
        destination => '127.0.0.1/8',
        jump        => 'reject',
        ;
      '00003 accept related established rules':
        proto => 'all',
        state => ['RELATED', 'ESTABLISHED'],
        jump  => 'accept',
        ;
    }
    firewall {
      '08446 REST API':
        dport => 8446,
        proto => 'tcp',
        jump  => 'accept',
        ;
      '08449 Web Monitoring':
        dport => 8449,
        proto => 'tcp',
        jump  => 'accept',
    }
    firewall { '99999 drop all':
      proto  => 'all',
      jump   => 'drop',
      before => undef,
    }
  }
  cron::hourly { 'fts-info-publisher':
    ensure  => 'present',
    command => '/etc/cron.hourly/fts-info-publisher',
    user    => 'root',
  }

  cron::daily {
    default:
      ensure => 'present',
      user   => 'root',
      ;

    'fts-bdii-cache-updater':
      command  => '/etc/cron.daily/fts-bdii-cache-updater'
      ;

    'fts-record-publisher':
      command => '/etc/cron.daily/fts-record-publisher'
      ;
}
  $fts_settings_array = [
    ['User=*',"User=${fts_user}"],
    ['Group=*',"Group=${fts_user}"],
    ['DbType=*',"DbType=${fts_db_type}"],
    ['DbUserName=*',"DbUserName=${fts_db_username}"],
    ['DbPassword=*',"DbPassword=${fts_db_password}"],
    ['DbConnectString=*', "DbConnectString=${$fts_db_connect_string}"],
    ['DbThreadsNum=*',"DbThreadsNum=${fts_db_threads_num}"],
    ['Alias=*',"Alias=${fts_server_alias}"]
  ]
  $fts_settings_array.each |$iterate_array| {
    file_line { $iterate_array[1]:
      ensure  => 'present',
      path    => '/etc/fts3/fts3config',
      require => Package['fts-server'],
      match   => $iterate_array[0],
      line    => $iterate_array[1],
    }
  }
  service {
    default:
      ensure   => 'running',
      enable   => 'true',
      provider => 'systemd',
      ;

    'fts-server':
      ;

    'fts-qos':
      ;

    'fetch-crl-cron':
      ;

    'fts-msg-bulk':
      ;
  }
}
