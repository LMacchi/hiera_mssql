Puppet::Functions.create_function(:mssql_lookup_key) do

  mssql_jar = '/opt/rubylibs/lib/mssql-jdbc-6.2.1.jre8.jar'

  begin
    require 'jdbc/sqlserver'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Must install jdbc_sqlserver gem to use hiera-mssql"
  end

  begin
    require '/opt/rubylibs/lib/mssql-jdbc-6.2.1.jre8.jar'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Cannot load file #{mssql_jar}"
  end

  begin
    require 'java'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Must install java gem to use hiera-mssql"
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

    if result.empty?
      context.not_found
    else
      answer = result.is_a?(Hash) ? result[options['value']] : result
      return answer
    end
  end

  def mssql_get(key, context, options)
#    begin
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
        data[res.getObject(var)] = res.getObject(value)
      end

      Puppet.debug("Hiera-mssql: Value found is #{data[key]}")
  
      return data

#    rescue TinyTds::Error => e
#      raise Puppet::DataBinding::LookupError, "Hiera-mssql: #{e.to_s}"

#    ensure
      conn.close if conn
#    end
  end

end
