# Copyright 2007-2008 Jay McGavren, jay@mcgavren.com.
# 
# This file is part of Zyps.
# 
# Zyps is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'zyps'
require 'singleton'


module Zyps

YAML_DOMAIN = "jay.mcgavren.com,2008-03-15"

module Serializable
	def to_yaml_type
		"#{YAML_DOMAIN}/#{self.class}"
	end
end

class Environment
	include Serializable
	#Environment should exclude any observers.
	def to_yaml_properties
		instance_variables.reject{|v| v == "@observer_peers"}
	end
end
#Restore environment attribute of any member GameObjects.
YAML.add_domain_type(YAML_DOMAIN, Zyps::Environment) do |type, value|
puts "*" * 50
	environment = YAML.object_maker(type, value)
	environment.objects.each {|o| o.environment = environment}
end


class GameObject
	#GameObject should exclude its Environment.
	def to_yaml_properties
		instance_variables.reject{|v| v == "@environment"}
	end
end
class EnvironmentalFactor
	#EnvironmentalFactor should exclude its Environment.
	def to_yaml_properties
		instance_variables.reject{|v| v == "@environment"}
	end
end




class Serializer

	include Singleton
	
	#Return serialized representation of object.
	def serialize(object)
		YAML.dump(object)
	end

	#Return object from serialized representation.
	def deserialize(string)
		YAML.load(string)
	end
	
end


end #module Zyps