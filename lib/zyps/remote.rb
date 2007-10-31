# Copyright 2007 Jay McGavren, jay@mcgavren.com.
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


module Zyps


require 'drb'
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'



class EnvironmentServer


	#The URI on which the server is operating.
	attr_reader :uri
	
	
	def initialize(environment = Environment.new, uri = nil)
		@environment, @uri = environment, uri
	end
	
	
	#Offer the given environment for remote connections.
	def start
	
		#Ensure GameObject and EnvironmentalFactor lists stay on server side.
		@environment.objects.extend DRbUndumped
		@environment.environmental_factors.extend DRbUndumped
		
		#Ensure Environment stays on server side.
		class <<@environment
			include DRbUndumped
			alias old_objects= objects=
			def objects=(value)
				old_objects=(value)
				@objects.extend DRbUndumped
			end
			alias old_environmental_factors= environmental_factors=
			def environmental_factors=(value)
				old_environmental_factors=(value)
				@environmental_factors.extend DRbUndumped
			end
		end
		
		#Start a network service.
		@server = DRb::DRbServer.new(
			@uri,
			@environment
		)
		@uri ||= @server.uri
		
		#Disable file system access and other unsafe operations.
# 		$SAFE = 2
				
	end

	
	#Wait until the server is finished running.
	def wait
		@server.thread.join
	end
	
	
	#Stop the server.
	def stop
		@server.stop_service
	end
	
	
end


module EnvironmentClient

	#Get an environment proxy from the given URI.
	def EnvironmentClient.get_environment(uri)
		DRb.start_service()
		DRbObject.new_with_uri(uri)
	end
	
end


# module Remote


# 	#Offer the given environment for remote connections.
# 	def Remote.serve_environment(environment, uri = nil)
# 	
# 		#Ensure GameObject and EnvironmentalFactor lists stay on server side.
# 		environment.objects.extend DRbUndumped
# 		environment.environmental_factors.extend DRbUndumped
# 		
# 		#Ensure Environment stays on server side.
# 		class <<environment
# 			include DRbUndumped
# 			alias old_objects= objects=
# 			def objects=(value)
# 				old_objects=(value)
# 				@objects.extend DRbUndumped
# 			end
# 			alias old_environmental_factors= environmental_factors=
# 			def environmental_factors=(value)
# 				old_environmental_factors=(value)
# 				@environmental_factors.extend DRbUndumped
# 			end
# 		end
# 		
# 		#Start a network service.
# 		DRb.start_service(
# 			uri,
# 			environment
# 		)
# 		
# 		#Disable file system access and other unsafe operations.
# # 		$SAFE = 2
# 		
# 		return DRb.uri
# 		
# 	end
# 	
# 	
# 	#Stop serving environments.
# 	def Remote.stop_service
# 		DRb.stop_service
# 	end
# 	
# 	
# 	#Get an environment proxy from the given URI.
# 	def Remote.get_environment(uri)
# 		DRb.start_service()
# 		DRbObject.new(nil, uri)
# 	end
# 	

# end


end #module Zyps