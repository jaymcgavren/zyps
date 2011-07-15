

gems_loaded = false
begin
  require 'spec/story'
  require 'zyps'
  require 'zyps/actions'
rescue LoadError
  if gems_loaded == false
    require 'rubygems'
    gems_loaded = true
    retry
  else
    raise
  end
end

load File.join(File.dirname(__FILE__), 'steps', 'all.rb')

include Zyps

steps_for(:actions) do
end

with_steps_for :actions, :all do
  run File.expand_path(__FILE__).sub(/.rb$/, ".txt")
end
