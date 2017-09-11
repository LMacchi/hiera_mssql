Puppet::Functions.create_function(:mssql_lookup_key) do

  begin
    require 'tiny_tds'
  rescue LoadError => e
    raise Puppet::DataBinding::LookupError, "Must install tiny_tds gem to use hiera-mssql"
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

    answer = result.is_a?(Hash) ? result[key] : result
    context.not_found if answer.nil?
    return answer
  end

  def mssql_get(key, context, options)
    begin
      host  = options['host']        || 'localhost'
      user  = options['user']        || 'hiera'
      db    = options['database']    || 'hiera'
      table = options['table']       || 'hiera'
      value = options['value_field'] || 'value'
      var   = options['key_field']   || 'key'
      port  = options['port']        || nil
      pass  = options['pass']
      query = "select #{value} from #{table} where #{var}=\"#{key}\""

      Puppet.debug("Hiera-mssql: Attempting query #{query}")

      conn = TinyTds::Client.new username: "#{user}", password: "#{pass}", host: "#{host}", database: "#{db}", port: "#{port}"
      Puppet.debug("Hiera-mssql: DB connection to #{host} established")

      rs = conn.execute query
      answer = rs[value_field]

      return answer
    rescue TinyTds::Error => e
      raise Puppet::DataBinding::LookupError, "Hiera-mssql: #{e.to_s}"

    ensure
      conn.close if conn
    end
  end

end
