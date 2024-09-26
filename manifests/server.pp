# @summary
#   This class defines the configuration for the FTS server.
#   It takes in parameters for configuring the server and sets up the
#   necessary resources.
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
#   (required) The user that will run the FTS server.
#   defaults to fts3.
# 
# @param fts_db_type
#   (optional) The type of database backend to use.
#   defaults to mysql which is the only supported backend.
#
# @param db_host
#   (required) The hostname or IP of the machine hosting the mysql database..
#   defaults to fts-db.infn.it. This host must be accessible from the FTS server.
#
# @param fts_db_name
#   (optional) The name of the mysql database hosted on the database server.
#   defaults to fts.
#
# @param fts_db_password
#   (optional) The password for the fts user to connect to the database.
#   defaults to ftstestpassword.
#
# @param fts_db_threads_num
#   (optional) The number of threads to use for the database backend.
#   defaults to 24.
#
# @param fts_server_alias
#   (optional) The alias to use for the FTS server
#   defaults to fts3-server.
#
# @param fts_broker_host
#   (optional) The hostname or IP of the machine hosting the FTS broker.
#   defaults to fts-broker.infn.it. This host must be accessible from the FTS server.
#
# @param fts_broker_user
#   (optional) The user to connect to the FTS broker.
#   defaults to ftsuser.
#
#
# @param configure_firewall
#   (optional) Whether to configure the firewall or not. 
#   defaults to true. If set to false, the firewall must be configured manually.
#   If set to true, the firewall module opens the following ports:
#   8446 for the REST API, 8449 for the web monitoring.
#
# @param configure_selinux
#   (optional) Whether to configure SELinux or not. 
#   defaults to true. If set to true, it sets SELinux to enforcing mode.
#
# @param build_fts_tables
#   (optional) Whether to build the FTS tables or not. 
#   defaults to true.
#   In order to build the tables, the MySQL fts database, 
#   and user must already exist. It can only be done if the mysql server is hosted
# o n a CentOS machine, otherwise building the tables must be done manually or by running
# t he module on the database machine.
# 
class fts::server (
  String  $fts_user                 = 'fts3',
  String  $fts_db_type              = 'mysql',
  String  $db_host                  = 'fts-db.infn.it',
  String  $fts_db_name              = 'fts',
  String  $fts_db_password          = 'ftstestpassword',
  Integer $fts_db_threads_num       = 24,
  String  $fts_server_alias         = 'fts3-server',
  String  $fts_broker_host          = 'fts-broker.infn.it',
  String  $fts_broker_user          = 'ftsuser',
  Boolean $configure_firewall       = true,
  Boolean $configure_selinux        = true,
  Boolean $build_fts_tables         = true,
) {
  $fts_db_connect_string = "${db_host}:3306/${fts_db_name}"
  $fts_broker_connect_string = "${fts_broker_host}:61613"
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
      provider => dnf,
      ;
    # Core
    ['fts-server', 'fts-mysql', 'fts-rest-server', 'fts-monitoring']:
      ;
    # Selinux
    ['fts-server-selinux', 'fts-rest-server-selinux', 'fts-monitoring-selinux']:
      ;
    # FTS Message
    ['fts-msg']:
      ;
  }
  include fts::client
  file { '/etc/httpd/conf.d/fts3rest.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/fts/fts3rest.conf',
    #require => [Package['fts-rest-server'], Package['httpd']],
  }

  file { '/etc/httpd/conf.d/ftsmon.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/fts/ftsmon.conf',
    #require => [Package['fts-monitoring'], Package['httpd']],
  }

# Build the FTS tables remotely
  if $build_fts_tables {
    notify { "Building FTS tables on ${db_host}": }
    include mysql::client
    exec { 'fts-mysql-schema':
      command => "/usr/bin/mysql --user='${fts_user}' --password='${fts_db_password}' --host='${db_host}' --database='${fts_db_name}' < '/usr/share/fts-mysql/fts-schema-9.0.0.sql'",
      path    => ['/usr/bin', '/usr/sbin'],
      #require => Package['fts-mysql'],
    }
  }
  if $configure_firewall {
    notify { 'Configuring firewall fts ports': }
    include firewalld
    firewalld_port {
      '08446 REST API':
        ensure   => present,
        zone     => 'public',
        port     => 8446,
        protocol => 'tcp',
        ;
      '08449 Web Monitoring':
        ensure   => present,
        zone     => 'public',
        port     => 8449,
        protocol => 'tcp',
        ;
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
  cron { 'fetch-crl-and-restart-services':
    ensure  => 'present',
    command => '/usr/sbin/fetch-crl -p 99; /bin/systemctl restart httpd fts-*',
    user    => 'root',
    minute  => '0',
    hour    => '3',
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

  $fts_msg_settings_array = [
    ['^ACTIVE=.*','ACTIVE=true'],
    ['^BROKER=.*',"BROKER=${fts_broker_connect_string}"],
    ['^PASSWORD=.*',"PASSWORD=${fts_db_password}"],
    ['^USERNAME=.*',"USERNAME=${fts_broker_user}"],
    ['^TOPIC=.*','TOPIC=false'],
  ]

  $fts_msg_settings_array.each |$iterate_array| {
    file_line { $iterate_array[1]:
      ensure  => 'present',
      path    => '/etc/fts3/fts-msg-monitoring.conf',
      require => Package['fts-msg'],
      match   => $iterate_array[0],
      line    => $iterate_array[1],
    }
  }
  file { '/etc/httpd/conf.d/zgridsite.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/fts/zgridsite.conf',
    #require => [Package['fts-monitoring'], Package['httpd']],
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

    'fts-msg-bulk':
      ;
  }
}
