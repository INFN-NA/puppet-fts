# FTS Server
node 'fts3-server.example.org', 'fts3-db.example.org' {
# ---------------------------------------------------------------------------- #
#                                   Packages                                   #
# ---------------------------------------------------------------------------- #
  file {
    default:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      ;
    '/etc/grid-security':
      ;
  }

  file {
    default:
      owner   => 'root',
      group   => 'root',
      require => File['/etc/grid-security']
      ;
    '/etc/grid-security/hostcert.pem':
      ensure  => file,
      mode    => '0644',
      source  => 'file:///root/certificates/hostcert.pem',
      replace => false,
      ;
    '/etc/grid-security/hostkey.pem':
      ensure  => file,
      mode    => '0400',
      source  => 'file:///root/certificates/hostkey.pem',
      replace => false,
      ;
  }

  # FTS Class Configuration that builds the FTS Server only
  class { 'fts':
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_name            => 'fts',
    db_root_user       => 'root',
    db_root_password   => 'roottestpassword',
    fts_db_password    => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    admin_list         => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
    fts_db_threads_num => 24,
    configure_db       => false,
    configure_fts      => true,
    configure_firewall => true,
    configure_selinux  => true,
    build_mysql_server => false,
    build_fts_tables   => false, # true if you want to build the FTS tables on the DB hosted on fts3-db.example.org
    grant_privileges   => false,
    configure_admins   => false,
    configure_lsc      => true,
    vo_list            => ['datacloud', 'cygno'],
  }
  # FTS Class Configuration that builds the MySQL database
  class { 'fts':
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_name            => 'fts',
    db_root_user       => 'root',
    db_root_password   => 'roottestpassword',
    fts_db_password    => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    admin_list         => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
    fts_db_threads_num => 24,
    configure_db       => true,
    configure_fts      => false,
    configure_firewall => true,
    configure_selinux  => true,
    build_mysql_server => true,
    build_fts_tables   => true,
    grant_privileges   => true, # if you want to grant privileges you need to have root username and password
    configure_admins   => true,
    configure_lsc      => false,
    vo_list            => ['datacloud', 'cygno'],
  }
}
