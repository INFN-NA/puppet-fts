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
# @param db_root_password
# (required) the root password for the mysql server
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
# @param fts_db_password
# (required) the password of the fts database user
#
# @param admin_list
# (required) the list of the admin users for the fts database
#
# @param configure_firewall
# (optional) whether to configure the firewall or not
#
# @param configure_selinux
# (optional) whether to configure selinux or not
#
# @param build_database
# (optional) whether to build the database or not\
#
# @param build_fts_tables
#   (optional) Whether to build the FTS tables or not. Defaults to true.
#   In order to build the tables, the MySQL database, and user must already exist.
#
class fts::database (
  String  $db_root_password   = 'roottestpassword',
  String  $db_name            = 'fts',
  String  $fts_host           = 'fts-server.infn.it',
  String  $fts_db_user        = 'fts3',
  String  $fts_db_password    = 'ftstestpassword',
  Array   $admin_list         = ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
  Boolean $configure_firewall = true,
  Boolean $configure_selinux  = true,
  Boolean $build_database     = true,
  Boolean $build_fts_tables   = true,
) {
  # ------------------------------- SELinux ------------------------------- #
  if $configure_selinux {
    case $facts['os']['name'] {
      'RedHat': {
        class { 'selinux':
          mode => 'permissive',
        }
      }
      default: {
        warning('Skipping Selinux Configuration, unsupported OS for selinux configuration')
      }
    }
  }

  # instantiate the mysql server
  if $build_database {
    class { 'mysql::server':
      root_password    => $db_root_password,
      override_options => {
        'mysqld' => {
          'bind-address' => $::ipaddress,
        },
      },
    }
  }
  # ------------------------------ MariaDB / MySQL ----------------------------- #
  # create the fts database and user  
  # ------------------------------- Dependencies ------------------------------- #
  if $build_fts_tables {
    case $facts['os']['name'] {
      'RedHat': {
        case $facts['os']['release']['major'] {
          '7': {
            package { 'fts-mysql':
              ensure  => present,
            }
            mysql::db { $db_name:
              ensure   => 'present',
              user     => $fts_db_user,
              grant    => ['ALL', 'SUPER'],
              password => $fts_db_password,
              name     => $db_name,
              host     => $::ipaddress,
              sql      => ['/usr/share/fts-mysql/fts-schema-8.0.1.sql'],
            }
          }
          default: {
            warning("Database ${db_name} has been created but the tables have not been populated")
            warning("${facts['os']['name']} ${facts['os']['release']['major']} is an unsupported OS to populate the FTS tables, only RHEL 7 is supported")
            mysql::db { $db_name:
              ensure   => 'present',
              user     => $fts_db_user,
              grant    => ['ALL', 'SUPER'],
              password => $fts_db_password,
              name     => $db_name,
              host     => $::ipaddress,
            }
          }
        }
      }
      default: {
        warning("Database ${db_name} has been created but the tables have not been populated")
        warning("${facts['os']['name']} ${facts['os']['release']['major']} is an unsupported OS to populate the FTS tables, only RHEL 7 is supported")
        mysql::db { $db_name:
          ensure   => 'present',
          user     => $fts_db_user,
          grant    => ['ALL', 'SUPER'],
          password => $fts_db_password,
          name     => $db_name,
          host     => $::ipaddress,
        }
      }
    }
  }
  else {
    mysql::db { $db_name:
      ensure   => 'present',
      user     => $fts_db_user,
      grant    => ['ALL', 'SUPER'],
      password => $fts_db_password,
      name     => $db_name,
      host     => $::ipaddress,
    }
  }
  $admin_list.each |$admin| {
    exec { "fts-admins-'${admin}'":
      command => "/usr/bin/mysql --user='${fts_db_user}' --password='${fts_db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"INSERT INTO t_authz_dn  (dn, operation) VALUES ('${admin}', 'config')\"",
      unless  => "/usr/bin/mysql --user='${fts_db_user}' --password='${fts_db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"SELECT * FROM t_authz_dn WHERE dn='${admin}' AND operation='config'\" | grep '${admin}'",
      require => Mysql::Db['fts'],
    }
  }
  if $build_database {
    exec { 'fts-grant':
      command => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO '${fts_db_user}'@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
      unless  => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user='${fts_db_user}'@'${fts_host}'\" | grep fts@'${fts_host}'",
      require => Mysql::Db['fts'],
    }

    exec { 'fts-super':
      command => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"GRANT SUPER ON *.* TO '${fts_db_user}'@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
      require => Exec['fts-grant']
    }

    exec { 'root-grant':
      command => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO root@'${fts_host}' IDENTIFIED BY '${db_password}'\"",
      unless  => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user=root@'${fts_host}'\" | grep root@'${fts_host}'",
      require => Mysql::Db['fts'],
    }

    exec { 'flush privileges':
      command => "/usr/bin/mysql --user='root' --password='${fts_db_password}' --database='${db_name}'  --execute \"FLUSH PRIVILEGES\"",
      require => [Exec['fts-grant'], Exec['root-grant']],
    }
  }
  # ------------------------------ Firewall ----------------------------- #
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
