# @summary: this class configures the fts database
#
# @example Configure the fts database
#   class { 'fts::database':
#      db_password => 'ftstestpassword',
#      db_name     => 'fts',
#      fts_host    => 'fts-server.infn.it',
#      fts_db_user => 'fts3',
#      admin_list  => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri, 
#                       '/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Massimo Sgaravatto sgaravat@infn.it'],
#     configure_firewall => true,
#   }
# === Parameters:
# @param db_password
# (required) the password for the fts database user
#
# @param db_name
# (required) the name of the fts database
#
# @param fts_host
# (required) the hostname of the fts server
#
# @param fts_db_user
# (required) the name of the fts database user
#
# @param admin_list
# (required) the list of the admin users for the fts database
#
# @param configure_firewall
# (optional) whether to configure the firewall or not
#
class fts::database (
  String  $db_password        = 'ftstestpassword',
  String  $db_name            = 'fts',
  String  $fts_host           = 'fts-server.infn.it',
  String  $fts_db_user        = 'fts3',
  Array   $admin_list         = ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
  Boolean $configure_firewall = true,
) {
  class { 'selinux':
    mode => 'permissive',
  }
  # instantiate the mysql server
  class { 'mysql::server':
    root_password    => $db_password,
    override_options => {
      'mysqld' => {
        'bind-address' => $::ipaddress,
      },
    },
  }
# ------------------------------- Dependencies ------------------------------- #
  package { 'fts-mysql':
    ensure  => present,
  }
  # ------------------------------ MariaDB / MySQL ----------------------------- #
  # create the fts database and user
  mysql::db { 'fts':
    ensure   => 'present',
    user     => 'fts',
    grant    => ['ALL', 'SUPER'],
    password => $db_password,
    name     => 'fts',
    host     => $::ipaddress,
    sql      => ['/usr/share/fts-mysql/fts-schema-8.0.1.sql'],
  }
  $admin_list.each |$admin| {
    exec { "fts-admins-'${admin}'":
      command => "/usr/bin/mysql --user='${fts_db_user}' --password='${db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"INSERT INTO t_authz_dn  (dn, operation) VALUES ('${admin}', 'config')\"",
      unless  => "/usr/bin/mysql --user='${fts_db_user}' --password='${db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"SELECT * FROM t_authz_dn WHERE dn='${admin}' AND operation='config'\" | grep '${admin}'",
      require => Mysql::Db['fts'],
    }
  }
  exec { 'fts-grant':
    command => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO fts@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
    unless  => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user=fts@'${fts_host}'\" | grep fts@'${fts_host}'",
    require => Mysql::Db['fts'],
  }

  exec { 'fts-super':
    command => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"GRANT SUPER ON *.* TO fts@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
    require => Exec['fts-grant']
  }

  exec { 'root-grant':
    command => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO root@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
    unless  => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user=root@'${fts_host}'\" | grep root@'${fts_host}'",
    require => Mysql::Db['fts'],
  }

  exec { 'flush privileges':
    command => "/usr/bin/mysql --user='root' --password='${db_password}' --database='${db_name}'  --execute \"FLUSH PRIVILEGES\"",
    require => [Exec['fts-grant'], Exec['root-grant']],
  }
  if $configure_firewall {
    firewall {
      '03306 MariaDB':
        dport => 3306,
        proto => 'tcp',
        jump  => 'accept',
    }
    firewall { '99999 drop all':
      proto  => 'all',
      jump   => 'drop',
      before => undef,
    }
  }
}
