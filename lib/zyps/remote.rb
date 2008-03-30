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

module Zyps


#Updates remote EnvironmentClients.
class EnvironmentServer
	
	LENGTH_BYTE_COUNT = 3
	
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
	
	
	#Listens for connections on the given port.
	def start
		case @options[:protocol]
		when Protocol::UDP
			socket = UDPSocket.new
			socket.bind("localhost", @options[:port])
		end
		#Listen for incoming data until stop is called.
		@running = true
		Thread.new do
			while @running
				length, info = socket.recvfrom(LENGTH_BYTE_COUNT)
				data, info = socket.recvfrom(length)
			end
		end
	end
	
	
	#Closes connection port.
	def stop
		#Breaks out of listener loop.
		@running = false
	end
	

end


end #module Zyps
