# laura/hiera_mssql::hiera_mssql
#
# A description of what this class does
#
# @summary Install packages for MsSQL Hiera 5 Backend
#
# @example
#   include ::hiera_mssql
class hiera_mssql {
  package { ['jdbc-sqlserver','java']:
    ensure   => present,
    provider => 'puppetserver_gem',
  }

  package { 'tiny_tds':
    ensure   => present,
    provider => 'puppet_gem',
  }
}
