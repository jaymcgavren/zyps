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
require 'zyps/serializer'


module Zyps


module Protocol
	UDP = 1
end


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

	MAX_PACKET_SIZE = 10240
	
	#sender_info array indices
	DOMAIN = 0
	PORT = 1
	NAME = 2
	ADDRESS = 3

	#Listens for connections on the given port.
	def start
		case @options[:protocol]
		when Protocol::UDP
			@socket = UDPSocket.new
			@socket.bind(nil, @options[:port])
		else
			raise "Unknown protocol #{@options[:protocol]}."
		end
		#Listen for incoming data until stop is called.
		@running = true
		Thread.new do
			while @running
				length, sender_info = @socket.recvfrom(LENGTH_BYTE_COUNT)
				data, sender_info = @socket.recvfrom(length)
				receive(data, sender_info)
			end
		end
	end
	
	
	#Closes connection port.
	def stop
		#Breaks out of listener loop.
		@running = false
	end
	
	
end


#Updates remote EnvironmentClients.
class EnvironmentServer

	include EnvironmentTransmitter
	
	#Takes the environment to serve, and the following options:
	#	:protocol => Zyps::Protocol::UDP
	#	:port => 9977
	def initialize(environment, options = {})
		@environment = environment
		@options = {
			:protocol => Protocol::UDP,
			:port => 9977
		}.merge(options)
	end
	
	
	#Parses incoming data and determines what to do with it.
	def receive(data, sender_info)
		#Reject data unless sender has already joined server (or wants to join).
		if @clients.include?(sender_info[ADDRESS])
			Serializer.instance.deserialize(data).each do |object|
				case object
				when Request::ENVIRONMENT
					send(@environment.objects.to_a + @environment.environmental_factors.to_a, sender_info)
				when GameObject, EnvironmentalFactor
					@environment << object
				when Exception
					raise object
				else
					send(Exception.new("Could not process #{object}."), sender_info)
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
	#	:protocol => Protocol::UDP,
	#	:host => nil,
	#	:port => 9977
	def initialize(environment, options = {})
		@environment = environment
		@options = {
			:protocol => Protocol::UDP,
			:host => nil,
			:port => 9977
		}.merge(options)
	end
	
	#Connect to specified server.
	def connect
		case @options[:protocol]
		when Protocol::UDP
			@socket.connect(@options[:host], @options[:port])
			@socket.send(Request::JOIN.to_s, 0)
		else
			raise "Unknown protocol #{@options[:protocol]}."
		end
	end
	
end


end #module Zyps
