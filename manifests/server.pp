# @summary
#   This class defines the configuration for the FTS server.
#   It takes in parameters for configuring the server and sets up the necessary resources.
#
# @example
#   class { 'fts::server':
#     fts_user => 'fts3',
#     fts_db_type => 'mysql',
#     db_host => 'fts-db.infn.it',
#     fts_db_name => 'fts',
#     fts_db_password => 'ftstestpassword',
#     fts_db_threads_num => 24,
#     fts_server_alias => 'fts3-server',
#     configure_firewall => true,
#  }
#
# @param fts_user
#   (required) The user that will run the FTS server
# 
# @param fts_db_type
#   (optional) The type of database backend to use
#
# @param db_host
#   (required) The hostname or IPV4 of the database server
#
# @param fts_db_name
#   (optional) The name of the database to use
#
# @param fts_db_password
#   (optional) The password to use to connect to the database
#
# @param fts_db_threads_num
#   (optional) The number of threads to use for the database backend
#
# @param fts_server_alias
#   (optional) The alias to use for the FTS server
#
# @param configure_firewall
#   (optional) Whether to configure the firewall or not
#
# @param configure_selinux
#   (optional) Whether to configure SELinux or not
#
# @param build_fts_tables
#   (optional) Whether to build the FTS tables or not. Defaults to true.
#   In order to build the tables, the MySQL database, and user must already exist.
# 
class fts::server (
  String  $fts_user                 = 'fts3',
  String  $fts_db_type              = 'mysql',
  String  $db_host                  = 'fts-db.infn.it',
  String  $fts_db_name              = 'fts',
  String  $fts_db_password          = 'ftstestpassword',
  Integer $fts_db_threads_num       = 24,
  String  $fts_server_alias         = 'fts3-server',
  Boolean $configure_firewall       = true,
  Boolean $configure_selinux        = true,
  Boolean $build_fts_tables         = true,
) {
  $fts_db_connect_string = "${db_host}:3306/${fts_db_name}"
  include cron
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
    source  => 'puppet:///modules/fts/fts3rest.conf',
    require => [Package['fts-rest-server'], Package['httpd']],
  }

  file { '/etc/httpd/conf.d/ftsmon.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/fts/ftsmon.conf',
    require => [Package['fts-monitoring'], Package['httpd']],
  }

# Build the FTS tables remotely
  if $build_fts_tables {
    notify { "Building FTS tables on ${db_host}": }
    include mysql::client
    exec { 'fts-mysql-schema':
      command => "/usr/bub/mysql --user='${fts_user}' --password='${fts_db_password}' --host='${db_host}' --database='${fts_db_name}' < /usr/share/fts-mysql/fts-schema-8.0.1.sql",
      path    => ['/usr/bin', '/usr/sbin'],
      require => Package['fts-mysql'],
    }
  }
  if $configure_firewall {
    notify { 'Configuring firewall': }
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
    ['DbUserName=*',"DbUserName=${fts_user}"],
    ['DbPassword=*',"DbPassword=${fts_db_password}"],
    ['DbConnectString=*', "DbConnectString=${fts_db_connect_string}"],
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

  $fts_rest_settings_array = [
    ['DbUserName = *',"DbUserName=${fts_user}"],

    ['DbPassword = *',"DbPassword=${fts_db_password}"],

    ['DbConnectString = *', "DbConnectString=${$fts_db_connect_string}"],
  ]

  $fts_rest_settings_array.each |$iterate_array| {
    file_line { "'${iterate_array[1]}'_rest":
      ensure  => 'present',
      path    => '/etc/fts3/fts3restconfig',
      require => Package['fts-rest-server'],
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
  notify { 'FTS server installed, please run fetch-crl - 99 and restart httpd': }
}
