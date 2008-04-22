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


module Request
	class Join
		attr_accessor :listen_port
		def initialize(listen_port); @listen_port = listen_port; end
	end
	class Environment; end
end
module Acknowledge
	class Join; end
	class Environment; end
end
class BannedError < Exception; end


module EnvironmentTransmitter


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
		@log.debug "Waiting for packet."
		data, sender_info = @socket.recvfrom(MAX_PACKET_SIZE)
		@log.debug "Got #{data} from #{sender_info.join('/')}."
		receive(data, sender_info[2])
	end
	
	
	#Closes connection port.
	def close_socket
		@log.debug "Closing @{socket}."
		@socket.close
	end

	
	#True if hostname is on allowed list.
	def allowed?(host)
		raise BannedError.new("#{host} is banned!") if banned?(host)
		@listen_ports.include?(host)
	end
	
	
	#True if address is on banned list.
	def banned?(host)
		@banned_hosts.include?(host)
	end
	#Add host to banned list.
	def ban(host)
		@banned_hosts << host
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
		def process(object, sender)
			case object
			when Request::Join
				process_join_request(object, sender)
			when Acknowledge::Join
				#TODO
			when Request::Environment
				send(@environment.objects.to_a + @environment.environmental_factors.to_a, sender)
			when GameObject, EnvironmentalFactor
				@environment << object
			when Exception
				@log.warn object
			else
				raise "Could not process #{object}."
			end
		end

	
		#Sends data.
		def send(data, host)
			string = Serializer.instance.serialize(data)
			raise "#{string.length} is over maximum packet size of #{MAX_PACKET_SIZE}." if string.length > MAX_PACKET_SIZE
			@log.debug "Sending '#{string}' to #{host} on #{@listen_ports[host]}."
			UDPSocket.open.send(string, 0, host, @listen_ports[host])
		end
	
	
end


#Updates remote EnvironmentClients.
class EnvironmentServer


	include EnvironmentTransmitter
	
	
	#Takes the environment to serve, and the following options:
	#	:listen_port => 9977
	def initialize(environment, options = {})
		@log = Logger.new(LOG_HANDLE)
		@log.level = LOG_LEVEL
		@log.progname = self
		@environment = environment
		@options = {
			:listen_port => 9977
		}.merge(options)
		@log.debug "Hosting Environment #{@environment.object_id} with #{@options.inspect}."
		@banned_hosts = []
		#Hash with client host names as keys, ports as values.
		@listen_ports = {}
	end

	
	#Add sender to client list and acknowledge.
	def process_join_request(request, sender)
		raise BannedError.new("#{sender} is banned!") if banned?(sender)
		@log.debug "Adding #{sender} to client list with port #{request.listen_port}."
		@listen_ports[sender] = request.listen_port
		send([Acknowledge::Join.new], sender)
	end


end


#Updates local Environment based on instructions from EnvironmentServer.
class EnvironmentClient


	include EnvironmentTransmitter

	
	#Takes a hash with the following keys and defaults:
	#	:host => nil,
	#	:host_port => 9977,
	#	:listen_port => nil,
	def initialize(environment, options = {})
		@log = Logger.new(LOG_HANDLE)
		@log.level = LOG_LEVEL
		@log.progname = self
		@environment = environment
		@options = {
			:host => nil,
			:host_port => 9977,
			:listen_port => nil
		}.merge(options)
		@banned_hosts = []
		#All transmissions to server should go to server's listen port.
		@listen_ports = {@options[:host] => @options[:host_port]}
	end

	
	#Connect to specified server.
	def connect
		@log.debug "Sending join request to #{@options[:host]}."
		send(Request::Join.new(@options[:listen_port]), @options[:host])
	end

	
end


end #module Zyps
