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


require 'logger'
require 'socket'
require 'zyps'
require 'zyps/serializer'


LOG_HANDLE = STDOUT
LOG_LEVEL = Logger::DEBUG


module Zyps


#Holds requests from a remote system.
module Request
	#A request to observe an Environment.
	class Join
		#The port the host will be listening on.
		attr_accessor :listen_port
		def initialize(listen_port); @listen_port = listen_port; end
	end
	#A request to update the object IDs already in the host's Environment.
	class SetObjectIDs
		#A list of GameObject identifiers.
		attr_accessor :ids
		def initialize(ids); @ids = ids; end
	end
	#A request to update the locations and vectors of specified objects.
	class UpdateObjectMovement
		#A hash with GameObject identifiers as keys and arrays with x coordinate, y coordinate, speed, and pitch as values.
		attr_accessor :movement_data
		def initialize(movement_data); @movement_data = movement_data; end
	end
	#A request for all objects and environmental factors within an Environment.
	class Environment; end
	#A request to add a specified object to an Environment.
	class AddObject
		#The object to add.
		attr_accessor :object
		def initialize(object); @object = object; end
	end
	#A request for a complete copy of a specified GameObject.
	class GetObject
		#Identifier of the object being requested.
		attr_accessor :identifier
		def initialize(identifier); @identifier = identifier; end
	end
	#A request to update all attributes of a specified GameObject.
	class ModifyObject
		#The object to update.
		attr_accessor :object
		def initialize(object); @object = object; end
	end
end
#Holds acknowledgements of requests from a remote system.
module Response
	class Join; end
	class Environment
		attr_accessor :objects, :environmental_factors
		def initialize(objects, environmental_factors); @objects, @environmental_factors = objects, environmental_factors; end
	end
	class AddObject
		#Identifier of the object that was added.
		attr_accessor :identifier
		def initialize(identifier); @identifier = identifier; end
	end
	class GetObject
		#The requested object.
		attr_accessor :object
		def initialize(object); @object = object; end
	end
	class ModifyObject
		#Identifier of the object that was modified.
		attr_accessor :identifier
		def initialize(identifier); @identifier = identifier; end
	end
end
class BannedError < Exception; end


class EnvironmentTransmitter

	
	#A list with the IPs of banned hosts.
	attr_accessor :banned_hosts
	#A hash with the IPs of allowed hosts as keys, and their listen ports as values.
	attr_accessor :allowed_hosts
	#A hash with the host IPs as keys, and lists of objects known to be in their environments as values.
	attr_accessor :known_objects

	#Takes the environment to serve.
	def initialize(environment)
		@log = Logger.new(LOG_HANDLE)
		@log.level = LOG_LEVEL
		@log.progname = self
		@environment = environment
		@environment.add_observer(self)
		@banned_hosts = []
		@allowed_hosts = {}
	end
	
	#The maximum allowed transmission size.
	MAX_PACKET_SIZE = 65535

	
	#Binds the given port.
	def open_socket
		@log.debug "Binding port #{@options[:listen_port]}."
		@socket = UDPSocket.open
		@socket.bind(nil, @options[:listen_port])
	end
	
	
	#Listen for an incoming packet, and process it.
	def listen
		@log.debug "Waiting for packet on port #{@socket.addr[1]}."
		data, sender_info = @socket.recvfrom(MAX_PACKET_SIZE)
		@log.debug "Got #{data} from #{sender_info.join('/')}."
		receive(data, sender_info[3])
	end
	
	
	#Closes connection port.
	def close_socket
		@log.debug "Closing @{socket}."
		@socket.close
	end

	
	#True if host is on allowed list.
	def allowed?(host)
		raise BannedError.new if banned?(host)
		allowed_hosts.include?(host)
	end
	#Add host and port to allowed list.
	def allow(host, port)
		allowed_hosts[host] = port
	end
	#Get listen port for host.
	def port(host)
		allowed_hosts[host]
	end
	
	
	#True if address is on banned list.
	def banned?(host)
		banned_hosts.include?(host)
	end
	#Add host to banned list.
	def ban(host)
		ip_address = (host =~ /^[\d\.]+$/ ? host : IPSocket.getaddress(host))
		banned_hosts << ip_address
	end
	
	
	#Compare environment state to previous state and send updates to listeners.
	def update(environment)
		#For each area of interest for the environment:
		areas_of_interest(environment).each do |area|
			#If it is not this area's turn to be evaluated, skip to the next.
			next unless evaluation_turn?(area)
			#For each object this transmitter has movement authority over:
			movable_objects(environment, area).each do |object|
				#Get its location and vector for inclusion in movement update.
			end
			#For each object this transmitter has creation authority over:
			created_objects(environment, area).each do |object|
				#For each listener:
					#Send each object not present in remote environment.
					#Add request to queue awaiting response.
			end
			#For each object this transmitter has destruction authority over:
			destructible_objects(environment, area).each do |object|
				#For each listener:
					#Remove objects that are in remote environment but not this one.
					#Add removal request to queue awaiting response.
			end
		end
		#Flush transmission buffers.
	end
	
	
	private
		
		
		#Parses incoming data.
		def receive(data, sender)
			begin
				#Reject data unless sender has already joined server (or wants to join).
				if allowed?(sender)
					#Deserialize and process data.
					Serializer.instance.deserialize(data).each {|object| process(object, sender)}
				#If sender wants to join, process request.
				else
					@log.debug "#{sender} not currently allowed."
					object = Serializer.instance.deserialize(data)
					if object.instance_of?(Request::Join)
						process(object, sender)
					else
						raise "#{sender} has not joined game but is transmitting data."
					end
				end
			#Send exceptions back to sender.
			rescue RuntimeError => exception
				@log.warn exception
				send([exception], sender)
			end
		end
		
		
		#Determines what to do with a received object.
		def process(transmission, sender)
			case transmission
			when Request::Join
				process_join_request(transmission, sender)
			when Response::Join
				#TODO
			when Request::SetObjectIDs
				known_objects[sender] += transmission.ids
			when Request::UpdateObjectMovement
				transmission.movement_data.each do |id, data|
					object = @environment.get_object(id)
					object.location.x, object.location.y = data[0], data[1]
					object.vector.speed, object.vector.pitch = data[2], data[3]
				end
			when Request::Environment
				send(Response::Environment.new(@environment.objects.to_a, @environment.environmental_factors.to_a), sender)
			when Response::Environment
				@log.debug "Adding #{transmission} to environment."
				transmission.objects.each {|o| @environment << o}
				transmission.environmental_factors.each {|o| @environment << o}
			when Request::AddObject
				@environment << transmission.object
				send(Response::AddObject.new(transmission.object.identifier))
			when Response::AddObject
				response_received(transmission.identifier)
			when Request::GetObject
				send(Response::GetObject.new(@environment.get_object(transmission.identifier)))
			when Response::GetObject
				@environment << transmission.object
				response_received(transmission.object.identifier)
			when Request::ModifyObject
				@environment.update_object(transmission.object.identifier, transmission.object)
			when Response::ModifyObject
				response_received(transmission.identifier)
			when Exception
				@log.warn transmission
			else
				raise "Could not process #{transmission}."
			end
		end

	
		#Sends data.
		def send(data, host)
			string = Serializer.instance.serialize(data)
			raise "#{string.length} is over maximum packet size of #{MAX_PACKET_SIZE}." if string.length > MAX_PACKET_SIZE
			@log.debug "Sending '#{string}' to #{host} on #{allowed_hosts[host]}."
			UDPSocket.open.send(string, 0, host, allowed_hosts[host])
		end
	
	
end


#Updates remote EnvironmentClients.
class EnvironmentServer < EnvironmentTransmitter
	
	
	#Takes the environment to serve, and the following options:
	#	:listen_port => 9977
	def initialize(environment, options = {})
		super(environment)
		@options = {
			:listen_port => 9977
		}.merge(options)
		@log.debug "Hosting Environment #{@environment.object_id} with #{@options.inspect}."
	end

	
	#Add sender to client list and acknowledge.
	def process_join_request(request, sender)
		raise BannedError.new if banned?(sender)
		@log.debug "Adding #{sender} to client list with port #{request.listen_port}."
		allow(sender, request.listen_port)
		send([Response::Join.new, @environment.objects.to_a + @environment.environmental_factors.to_a].flatten, sender)
	end


end


#Updates local Environment based on instructions from EnvironmentServer.
class EnvironmentClient < EnvironmentTransmitter

	
	#Takes a hash with the following keys and defaults:
	#	:host => nil,
	#	:host_port => 9977,
	#	:listen_port => nil,
	def initialize(environment, options = {})
		super(environment)
		@options = {
			:host => nil,
			:host_port => 9977,
			:listen_port => nil
		}.merge(options)
		@environment.add_observer(self)
		#All transmissions to server should go to server's listen port.
		@options[:host] = IPSocket.getaddress(@options[:host])
		allowed_hosts[@options[:host]] = @options[:host_port]
	end

	
	#Connect to specified server.
	def connect
		@log.debug "Sending join request to #{@options[:host]}."
		send(Request::Join.new(@options[:listen_port]), @options[:host])
	end

	
end


end #module Zyps
