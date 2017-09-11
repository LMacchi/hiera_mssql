# MsSQL backend for Hiera 5

Hiera.yaml:

```
  - name: "MsSQL"
    lookup_key: mssql_lookup_key
    options:
      host: mssql.puppetlabs.com (defaults to localhost)
      user: hiera (defaults to hiera)
      pass: hiera123 (required)
      database: hiera (defaults to hiera)
      port: 12345 (optional)
      # query = select %{value_field} from %{table} where %{key_field}="%{key}"
      table: configdata (defaults to hiera)
      value_field: val (defaults to value)
      key_field: var (defaults to key)
```

Data in configdata table:

```
MsSQL [hiera]> select val from configdata where var = 'message';
+-------+
| val   |
+-------+
| hello |
+-------+
1 row in set (0.01 sec)
```

Result:

```
root@master /root> puppet lookup --node $(facter fqdn) --explain message
Searching for "message"
  Global Data Provider (hiera configuration version 5)
    Using configuration "/etc/puppetlabs/puppet/hiera.yaml"
    Hierarchy entry "MySQL"
      Found key: "message" value: "hello"
```
