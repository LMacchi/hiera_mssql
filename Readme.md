# MsSQL backend for Hiera 5

## Requirements

- Download [mssql-jdbc-6.2.1.jre8.jar](https://www.microsoft.com/en-us/download/details.aspx?id=55539) 
and place it in `/opt/rubylibs/lib`

```
# ls -l /opt/rubylibs/lib/mssql-jdbc-6.2.1.jre8.jar
-rw-r--r-- 1 root root 1028744 Aug  9 19:11 /opt/rubylibs/lib/mssql-jdbc-6.2.1.jre8.jar
```

- Install jdbc-mssql and java gems with Puppetserver

```
puppetserver gem install jdbc-mssql
puppetserver gem install java
```

- Install tiny\_tds gem with vendored Ruby

```
/opt/puppetlabs/puppet/bin/gem install tiny_tds
```

- Set up a MsSQL database:

```
MsSQL [hiera]> select * from hieradata where var = 'message';
+-------+--------------+--------------+----------------------+
| id    |  variable    |  value       |    scope             |
+-------+--------------+--------------+----------------------+
| 1     | message      | Hello world! | laura.puppetlabs.com |
+-------+--------------+--------------+----------------------+
1 row in set (0.01 sec)
```

Name of columns are customizable. Variable have to be unique for each scope.

Create an user with read permissions to our table.

- Configure hiera.yaml, each level of the hierarchy will have similar data,
the only field that will change will be scope.

Facts and strings can be used for scope, an example with `trusted
certname` and `common`:

```
  - name: "MsSQL Per Node Data"
    lookup_key: mssql_lookup_key
    options:
      host: mssql.puppetlabs.com
      user: hiera
      pass: hiera123
      database: hiera
      port: 12345
      # query = select %{value_field} from %{table} where %{key_field}="%{key}"
      table: configdata
      value_field: val
      key_field: var
      scope_field: scope
      scope: "%{trusted.certname}"
  - name: "MsSQL Common Data"
    lookup_key: mssql_lookup_key
    options:
      host: mssql.puppetlabs.com
      user: hiera
      pass: hiera123
      database: hiera
      port: 12345
      table: configdata
      value_field: val
      key_field: var
      scope_field: scope
      scope: "common"
`
```

- You're all ready to go

## Internals

The hiera backend works by querying the data with this query:

```
select * from %{table} where %{key_field}="%{key}" and %{scope_field}="%{scope}"
```

Using the information in the example above:

```
select * from hieradata where variable="message" and scope="laura.puppetlabs.com"
```

## Defaults

The default values for the options are:

```
host: localhost
user: hiera
database: hiera
port: 1433
table: hiera
value_field: value
key_field: key
scope_field: scope
scope: common
```

Password is required.
