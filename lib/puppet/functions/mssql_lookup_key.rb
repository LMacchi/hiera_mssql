Puppet::Functions.create_function(:mssql_lookup_key) do

  mssql_jar = '/opt/rubylibs/lib/mssql-jdbc-6.2.1.jre8.jar'
  $use_jdbc = defined?(JRUBY_VERSION) ? true : false 

  if $use_jdbc

    begin
      require 'jdbc/sqlserver'
    rescue LoadError => e
      raise Puppet::DataBinding::LookupError, "Must install jdbc_sqlserver gem to use hiera-mssql"
    end

    begin
      require mssql_jar
    rescue LoadError => e
      raise Puppet::DataBinding::LookupError, "Cannot load file #{mssql_jar}"
    end

    begin
      require 'java'
    rescue LoadError => e
      raise Puppet::DataBinding::LookupError, "Must install java gem to use hiera-mssql"
    end
  else

    begin
      require 'tiny_tds'
    rescue LoadError => e
      raise Puppet::DataBinding::LookupError, "Must install tiny_tds gem to use hiera-mssql"
    end
  end

  dispatch :mssql_lookup_key do
    param 'Variant[String, Numeric]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def mssql_lookup_key(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)

    unless options.include?('pass')
      raise ArgumentError, "'mssql_lookup_key': 'pass' must be declared in hiera.yaml when using this lookup_key function"
    end
    
    result = mssql_get(key, context, options)
    Puppet.debug("Found #{result.length} results for #{key}")

    if result.empty?
      context.not_found
    else
      answer = result.is_a?(Hash) ? result[options['key_field']] : result
      return answer
    end
  end

  def mssql_get(key, context, options)
    host  = options['host']        || 'localhost'
    user  = options['user']        || 'hiera'
    db    = options['database']    || 'hiera'
    table = options['table']       || 'hiera'
    value = options['value_field'] || 'value'
    var   = options['key_field']   || 'key'
    port  = options['port']        || '1433'
    pass  = options['pass']
    query = "select * from #{table} where #{var}='#{key}'"
    data = {}

    Puppet.debug("Hiera-mssql: Attempting query #{query}")

    if $use_jdbc
      begin
        Jdbc::Sqlserver.load_driver
        url = "jdbc:sqlserver://#{host}:#{port};DatabaseName=#{db}"

        props = java.util.Properties.new
        props.set_property :user, user
        props.set_property :password, pass
        driver = Java::com.microsoft.sqlserver.jdbc.SQLServerDriver.new

        conn = driver.connect(url, props)
        st = conn.create_statement

        Puppet.debug("Hiera-mssql: DB connection to #{host} established")
      
        res = st.execute_query(query)

        while (res.next) do
          data[key] = res.getObject(value)
        end
        
        Puppet.debug("Hiera-mssql: For #{key}, data is #{data}")
        return data

      rescue Java::ComMicrosoftSqlserverJdbc::SQLServerException => e
        raise Puppet::DataBinding::LookupError, "Hiera-mssql: #{e.to_s}"

      ensure
        conn.close if conn
      end
    else
      # Not using jdbc
      begin
        conn = TinyTds::Client.new username: user, password: pass, host: host, database: db, port: port
        
        Puppet.debug("Hiera-mssql: DB connection to #{host} established")
        
        res = conn.execute query

        res.each do |row|
           data[key] = row[value]
        end

        Puppet.debug("Hiera-mssql: For #{key}, data is #{data}")
        return data

      rescue TinyTds::Error => e
        raise Puppet::DataBinding::LookupError, "Hiera-mssql: #{e.to_s}"

      ensure
        conn.close if conn
      end
    end
  end

end
