$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spec'
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'
require 'zyps/views'
require 'zyps/views/canvas'

gems_loaded = false
begin
  require 'spec'
rescue LoadError
  if gems_loaded == false
    require 'rubygems'
    gems_loaded = true
    retry
  else
    raise
  end
end
