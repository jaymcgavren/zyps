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


require 'test/unit'
require 'zyps/remote' #Require only the remote library, to ensure it requires the others for us.


include Zyps


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestRemote < Test::Unit::TestCase

	def setup
		@server_environment = Environment.new
		@server = EnvironmentServer.new(
			@server_environment,
			:protocol => Protocol::UDP,
			:port => 8989
		)
		@client_environment = Environment.new
		@client = EnvironmentClient.new(
			@client_environment,
			:protocol => Protocol::UDP,
			:port => 8989
		)
		@object = Creature.new(:color => Color.blue, :vector => Vector.new(1, 45))
	end
	
	def teardown
		@client.disconnect
		@server.stop
	end
	
	def find_matching_object(object, environment)
		environment.objects.each {|o| return o if o.identifier == object.identifier}
		return nil
	end
	
	#Ensure client receives objects that were already on server.
	def test_receive_old_server_objects
		@server_environment << @object
		@server.start
		@client.connect
		assert(find_matching_object(@object, @client_environment))
	end
	
	#Ensure client receives objects as they're added to server.
	def test_receive_new_server_objects
		@server.start
		@client.connect
		@server_environment << @object
		assert(find_matching_object(@object, @client_environment))
	end
	
	#Ensure server receives objects that were already on client.
	def test_receive_old_client_objects
		@client_environment << @object
		@server.start
		@client.connect
		assert(find_matching_object(@object, @server_environment))
	end
	
	#Ensure server receives objects as they're added to client.
	def test_receive_new_client_objects
		@server.start
		@client.connect
		@client_environment << @object
		assert(find_matching_object(@object, @server_environment))
	end
	
	#Ensure server is authority on object movement by default.
	def test_server_movement_authority
		@server.start
		@client.connect
		@client_environment << @object
		server_object = find_matching_object(@object, @server_environment)
		#Move client object one way, server object another.
		@object.vector.pitch = 90
		server_object.vector.pitch = 180
		#Interact.
		@server_environment.interact
		#Ensure client location/vector matches server's anyway.
		assert_equal(@object.vector, server_object.vector)
		assert_equal(@object.location, server_object.location)
	end
	
	#Ensure client is authority on object movement when assigned to client.
	def test_client_movement_authority
		@server.start
		@client.connect
		@server_environment << @object
		client_object = find_matching_object(@object, @client_environment)
		@server.set_manager(@object, @client) #TODO: Server won't have @client; will it use an ID?
		#Move client object one way, server object another.
		@object.vector.pitch = 90
		client_object.vector.pitch = 180
		#Interact.
		@server_environment.interact
		@client_environment.interact
		#Ensure server location/vector matches client's anyway.
		assert_equal(@object.vector, client_object.vector)
		assert_equal(@object.location, client_object.location)
	end
	
	#Ensure server is authority on object removal.
	def test_server_removal_authority
		@server.start
		@client.connect
		@client_environment << @object
		server_object = find_matching_object(@object, @server_environment)
		#Remove object from client.
		@client_environment.remove_object(@object)
		@server_environment.interact
		#Object should have been re-added to client environment, because it wasn't removed from server.
		assert(find_matching_object(@object, @client_environment))
		#Remove object from server.
		@server_environment.remove_object(@object)
		@server_environment.interact
		#Object should have been removed from client environment.
		assert_nil(find_matching_object(@object, @client_environment))
	end
	
	#Ensure server keeps updating other clients if one disconnects.
	def test_client_disconnect
		@server.start
		@client.connect
		client_environment_2 = Environment.new
		client_2 = EnvironmentClient.new(
			Environment.new
			:protocol => Protocol::UDP,
			:port => 8989
		)
		client_2.connect
		@server_environment << @object
		assert(find_matching_object(@object, @client_environment))
		assert(find_matching_object(@object, client_environment_2))
		@client.disconnect
		@server_environment.interact
		assert_equal(find_matching_object(@object, client_environment_2).location, @object.location)
	end
	
	#Ensure new clients can connect and get world if others are already connected.
	def test_multiple_clients_connect
		@server.start
		@client.connect
		@server_environment << @object
		assert(find_matching_object(@object, @client_environment))
		@server_environment.interact
		client_environment_2 = Environment.new
		client_2 = EnvironmentClient.new(
			Environment.new
			:protocol => Protocol::UDP,
			:port => 8989
		)
		client_2.connect
		assert(find_matching_object(@object, client_environment_2))
	end
	
	#Ensure server doesn't send new object to client if a rule tells it not to.
	
	#Ensure client doesn't send new object to server if a rule tells it not to.
	
	#Ensure server keeps telling client about object creation until client acknowledges it.
	#Ensure client keeps telling server about object creation until server acknowledges it.
	
	#Ensure banned clients are rejected.
	
end
