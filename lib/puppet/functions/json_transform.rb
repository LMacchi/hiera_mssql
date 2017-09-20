# json_transform
require 'json'

Puppet::Functions.create_function(:'json_transform') do
# Function that transforms a string in JSON format to its intended Data Type
# @param my_str String in JSON format
# @return Variant[Array, Hash, String] Returns a Data Type parsed by JSON
# @example The String '["one", "two"]' turns into an Array with 2 elements
  dispatch :up do
    param 'String', :my_str
  end

  def up(my_str)
    JSON.parse(my_str)
  end
end
