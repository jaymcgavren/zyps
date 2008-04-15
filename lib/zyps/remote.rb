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
	REQUEST_OFFSET = 0
	JOIN = REQUEST_OFFSET + 1
	ENVIRONMENT = REQUEST_OFFSET + 2
end
module Acknowledge
	ACKNOWLEDGE_OFFSET = 16
	JOIN = ACKNOWLEDGE_OFFSET + 1
	ENVIRONMENT = ACKNOWLEDGE_OFFSET + 2
end


module EnvironmentTransmitter


	#The maximum allowed transmission size.
	MAX_PACKET_SIZE = 65535
	#Number of seconds the listener thread should take to stop.
	LISTENER_THREAD_STOP_DURATION = 1

	
	#Listens for connections on the given port.
	def start
		@log.debug "Binding port #{@options[:listen_port]}."
		@socket = UDPSocket.open
		@socket.bind(nil, @options[:listen_port])
		#Listen for incoming data until stop is called.
		@running = true
		Thread.new do
			begin
				while @running
					@log.debug "Waiting for packet."
					data, sender_info = @socket.recvfrom(MAX_PACKET_SIZE)
					@log.debug "Got #{data} from #{sender_info.join('/')}."
					receive(data, sender_info[2], sender_info[1])
				end
			rescue IOError => exception
				raise exception unless exception.message == "stream closed"
			rescue Exception => exception
				@log.warn exception
				raise exception
			end
			@log.debug "Exiting listener thread."
		end
	end
	
	
	#Closes connection port.
	def stop
		@log.debug "Halting listener thread."
		#Breaks out of listener loop.
		@running = false
		@log.debug "Closing @{socket}."
		@socket.close
	end

	
	private
		
		
		#Parses incoming data and determines what to do with it.
		def receive(data, sender, port)
			begin
				#Reject data unless sender has already joined server (or wants to join).
				if sender_allowed?(sender)
					Serializer.instance.deserialize(data).each do |object|
						case object
						when Request::ENVIRONMENT
							send(@environment.objects.to_a + @environment.environmental_factors.to_a, sender, port)
						when GameObject, EnvironmentalFactor
							@environment << object
						when Exception
							@log.warn object
						else
							raise "Could not process #{object}."
						end
					end
				#If sender wants to join, process request.
				else
					@log.debug "#{sender} not currently allowed."
					if data.to_i == Request::JOIN
						process_join_request(sender, port)
					else
						raise "#{sender} has not joined game but is transmitting data."
					end
				end
			#Send exceptions back to sender.
			rescue Exception => exception
				@log.warn exception
				send([exception], sender, port)
			end
		end

	
		#Sends data.
		def send(data, host, port)
			string = data.to_s
			raise "#{string.length} is over maximum packet size of #{MAX_PACKET_SIZE}." if string.length > MAX_PACKET_SIZE
			@log.debug "Sending '#{string}' to #{host} on #{port}."
			UDPSocket.open.send(string, 0, host, port)
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
		#Hash with client host names as keys, ports as values.
		@clients = {}
	end
	
	#True if address is on client list.
	def sender_allowed?(hostname)
		@clients.include?(hostname)
	end
	
	#Add sender to client list and acknowledge.
	def process_join_request(sender, port)
		#TODO: Reject banned clients.
		@log.debug "Adding #{sender} to client list with port #{port}."
		@clients[sender] = port
		send(Acknowledge::JOIN, sender, port)
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
	end

	
	#Connect to specified server.
	def connect
		@log.debug "Sending join request to #{@options[:host]} on #{@options[:host_port]}."
		send(Request::JOIN, @options[:host], @options[:host_port])
	end
	
	#True if address matches host's.
	def sender_allowed?(hostname)
		hostname == @options[:host]
	end

end


end #module Zyps
