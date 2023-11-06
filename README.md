# fts

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with fts](#setup)
1. [Usage - Configuration options](#usage)
1. [Limitations - OS compatibility](#limitations)

## Description

A module to install and configure an FTS3 server and its MySQL database 
on a couple of Hosts. 

## Setup

* Setup two machines with CentOS 7 (puppet agents, not constrained to CentOS 7);
* Install puppet agent on both machines:
    1. add the puppet repo `rpm -Uvh https://yum.puppetlabs.com/puppet7/puppet7-release-el-7.noarch.rpm`;
    2. install the puppet agent and vim packages (`yum install -y puppet-agent vim`)
    3. Reload your /etc/profile to update $PATH or run puppet agent by absolute path
    4. create the `certificates` folder in the root path and copy there your site `hostcert.pem` and `hostkey.pem`;
* Employ the `fts` class to configure the FTS server and the MySQL database on the nodes, see the `fts=db.pp` and `fts-server.pp` in examples for some reference;
* Add the following modules in your puppetfile:

``` .puppet
mod 'cnafsd-voms', '0.8.0'
mod "puppetlabs-stdlib",'9.4.0'
mod 'puppet-cron', '4.1.0'
mod 'puppet-selinux', '4.0.0'
mod 'puppetlabs-inifile', '6.1.0'
mod 'puppet-systemd', '6.0.0'
mod 'puppetlabs-firewall', '7.0.2'
mod 'puppet/yum', '7.1.0'
mod 'puppetlabs/apache', '11.1.0'
mod 'puppetlabs/mysql', '15.0.0'
mod 'bradipoeremita-concat', '9.0.0'
mod 'fts', 
    :git => 'https://github.com/INFN-NA/puppet-fts.git',
    :branch => 'main'
```

* Modify the puppet.conf (`vim /etc/puppetlabs/puppet/puppet.conf`) file in both servers to point to your puppet server with the fts_development environment

``` .bash
[main]
        server = yourpuppetserver.infn.it

[agent]
        pluginsync  = true
        report      = true
        environment = fts_development
```

* execute `puppet agent -t -v` on both servers (db first, fts server second);
* execute `fetch-crl` (it is possible to use `-p` parameter to parallelize download);
* restart httpd: `systemctl restart httpd`

## Test your installation

1. Check your monitoring webpage at `https://{fts_fqdn}:8449/fts3/ftsmon/#/`;
2. Execute the following command on your server ` curl --capath /etc/grid-security/certificates -E /etc/grid-security/hostcert.pem --key /etc/grid-security/hostkey.pem https://hostname:8446/whoami`;

## Usage
The module can be used to configure both the database and fts server on the same machine, or on two different
machines. For the latter use case, to configure the fts server only, set `configure_db` to false, and to configure
the mysql database only, set `configure_fts` to false. Check the examples to see two .pp files configuring both the server
and the database.

``` .puppet
# On the fts server 
fts {'creating-fts-server'
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_root_password   => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    fts_db_threads_num => 24,
    configure_db       => false,
    configure_fts      => true,
    configure_firewall => true,
    configure_lsc      => true,
    vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
}
# On the fts database
fts {'creating the database'
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_root_password   => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    fts_db_threads_num => 24,
    configure_db       => true,
    configure_fts      => false,
    configure_firewall => true,
    configure_lsc      => true,
    vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
}
```

## Limitations

It works only on CentOS 7 distributions.
