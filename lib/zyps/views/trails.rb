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


require 'zyps'


module Zyps


#A view of game objects.
class TrailsView

	#A GUI toolkit-specific drawing area that will be used to render the view.
	attr_reader :canvas
	#Dimensions of the view.
	attr_reader :width, :height
	#Number of line segments to draw for each object.
	attr_accessor :trail_length
	#Whether view should be erased before re-drawing.
	attr_accessor :erase_flag

	#Takes a hash with these keys and defaults:
	#	:canvas => nil
	#	:width => 600
	#	:height => 400
	#	:trail_length => 5
	#	:erase_flag => true
	def initialize (options = {})
	
		options = {
			:width => 600,
			:height => 400,
			:trail_length => 5,
			:erase_flag => true
		}.merge(options)
		@width = options[:width]
		@height = options[:height]
		@trail_length = options[:trail_length]
		@erase_flag = options[:erase_flag]
		@canvas = options[:canvas]
		
		#Set canvas's size to match view's.
		resize if @canvas
	
		#Track a list of locations for each object.
		@locations = Hash.new {|h, k| h[k] = Array.new}
		
	end

	def width= (pixels) #:nodoc:
		@width = pixels
		resize
	end
	def height= (pixels) #:nodoc:
		@height = pixels
		resize
	end
	def canvas= (canvas) #:nodoc:
		@canvas = canvas
		resize
	end
	
	
	#Takes an Environment, and draws it to the canvas.
	#Tracks the position of each GameObject over time so it can draw a trail behind it.
	#The head will match the object's Color exactly, fading to black at the tail.
	#GameObject.size will be used as the line thickness at the object's head, diminishing to 1 at the tail.
	def update(environment)
	
		#Clear the background on the buffer.
		if @erase_flag
			@canvas.draw_rectangle(
				:color => Color.new(0, 0, 0),
				:filled => true,
				:x => 0, :y => 0,
				:width => @width, :height => @height
			)
		end
		
		#For each GameObject in the environment:
		environment.objects.each do |object|

			object_radius = Math.sqrt(object.size / Math::PI)

			#Add the object's current location to the list.
			@locations[object.identifier] << [object.location.x, object.location.y]
			#If the list is larger than the number of tail segments, delete the first position.
			@locations[object.identifier].shift while @locations[object.identifier].length > @trail_length
			
			#For each location in this object's list:
			@locations[object.identifier].each_with_index do |location, index|
			
				#Skip first location.
				next if index == 0
				
				#Divide the current segment number by trail segment count to get the multiplier to use for brightness and width.
				multiplier = index.to_f / @locations[object.identifier].length.to_f
				
				#Get previous location so we can draw a line from it.
				previous_location = @locations[object.identifier][index - 1]
				
				@canvas.draw_line(
					:color => Color.new(
						object.color.red * multiplier,
						object.color.green * multiplier,
						object.color.blue * multiplier
					),
					:width => object_radius * 2 * multiplier,
					:x1 => previous_location[0], :y1 => previous_location[1],
					:x2 => location[0], :y2 => location[1]
				)
				
			end
			
		end
		
		@canvas.render
		
	end
	
	
	private
	

		def resize
			@canvas.width = @width
			@canvas.height = @height
		end

	
end


end #module Zyps
