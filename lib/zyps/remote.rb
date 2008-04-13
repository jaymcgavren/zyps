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
module Deny
	DENY_OFFSET = 32
	JOIN = DENY_OFFSET + 1
	ENVIRONMENT = DENY_OFFSET + 2
end


module EnvironmentTransmitter


	MAX_PACKET_SIZE = 65535
	LENGTH_BYTE_COUNT = 2
	
	#sender_info array indices
	DOMAIN = 0
	PORT = 1
	NAME = 2
	ADDRESS = 3


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
					length, sender_info = @socket.recvfrom(LENGTH_BYTE_COUNT)
					@log.debug "Receiving #{length} bytes from #{sender_info.join('/')}."
					data, sender_info = @socket.recvfrom(length.to_i)
					@log.debug "Got #{data}."
					receive(data, sender_info)
				end
			rescue Exception => exception
				puts exception, exception.message, exception.backtrace.join("\n")
			end
		end
	end
	
	
	#Closes connection port.
	def stop
		@log.debug "Halting listener thread."
		#Breaks out of listener loop.
		@running = false
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
	end
	
	
	#Parses incoming data and determines what to do with it.
	def receive(data, sender_info)
		#Reject data unless sender has already joined server (or wants to join).
		if @clients.include?(sender_info[ADDRESS])
			Serializer.instance.deserialize(data).each do |object|
				case object
				when Request::ENVIRONMENT
					send(@environment.objects.to_a + @environment.environmental_factors.to_a, sender_info[NAME], sender_info[PORT])
				when GameObject, EnvironmentalFactor
					@environment << object
				when Exception
					raise object
				else
					send(Exception.new("Could not process #{object}."), sender_info[NAME], sender_info[PORT])
				end
			end
		#If sender wants to join, process request.
		else
			if data == Request::JOIN.to_s
				add_client(sender_info)
			end
		end
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
	
end


end #module Zyps
