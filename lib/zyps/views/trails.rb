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


require 'gtk2'


module Zyps


#A view of game objects.
class TrailsView

	#A Gtk::DrawingArea to render objects on.
	attr_reader :canvas
	#Dimensions of the view.
	attr_reader :width, :height
	#Number of line segments to draw for each object.
	attr_accessor :trail_length

	#Takes a hash with these keys and defaults:
	#	:width => 600
	#	:height => 400
	#	:trail_length => 5
	def initialize (options = {})
	
		options = {
			:width => 600,
			:height => 400,
			:trail_length => 5
		}.merge(options)
		@width, @height, @trail_length, = options[:width], options[:height], options[:trail_length]
	
		#Create a drawing area.
		@canvas = Gtk::DrawingArea.new
		#Set to correct size.
		resize
		
		#Whenever the drawing area needs updating...
		@canvas.signal_connect("expose_event") do
			#Copy buffer bitmap to canvas.
			@canvas.window.draw_drawable(
				@canvas.style.fg_gc(@canvas.state), #Gdk::GC (graphics context) to use when drawing.
				buffer, #Gdk::Drawable source to copy onto canvas.
				0, 0, #Pull from upper left of source.
				0, 0, #Copy to upper left of canvas.
				-1, -1 #-1 width and height signals to copy entire source over.
			)
		end
		
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

	#Takes an Environment, and draws it to the canvas.
	#Tracks the position of each GameObject over time so it can draw a trail behind it.
	#The head will match the object's Color exactly, fading to black at the tail.
	#GameObject.size will be used as the line thickness at the object's head, diminishing to 1 at the tail.
	def update(environment)
	
		#Clear the background on the buffer.
		graphics_context = Gdk::GC.new(buffer)
		graphics_context.rgb_fg_color = Gdk::Color.new(0, 0, 0)
		buffer.draw_rectangle(
			graphics_context,
			true, #Filled.
			0, 0, #Lower-left corner.
			@width, @height #Upper-right corner.
		)
		
		#For each GameObject in the environment:
		environment.objects.each do |object|

			object_radius = Math.sqrt(object.size / Math::PI)

			#Add the object's current location to the list.
			@locations[object.identifier] << [object.location.x, object.location.y]
			#If the list is larger than the number of tail segments, delete the first position.
			@locations[object.identifier].shift if @locations[object.identifier].length > @trail_length
			
			#For each location in this object's list:
			@locations[object.identifier].each_with_index do |location, index|
			
				#Skip first location.
				next if index == 0
				
				#Divide the current segment number by trail segment count to get the multiplier to use for brightness and width.
				multiplier = index.to_f / @locations[object.identifier].length.to_f
				
				#Set the drawing color to use the object's colors, adjusted by the multiplier.
				graphics_context.rgb_fg_color = Gdk::Color.new( #Don't use Gdk::GC.foreground= here, as that requires a color to be in the color map already.
					object.color.red * multiplier * 65535,
					object.color.green * multiplier * 65535,
					object.color.blue * multiplier * 65535
				)
				
				#Multiply the actual drawing width by the current multiplier to get the current drawing width.
				graphics_context.set_line_attributes(
					(object_radius * 2 * multiplier).ceil,
					Gdk::GC::LINE_SOLID,
					Gdk::GC::CAP_ROUND, #Line ends drawn as semicircles.
					Gdk::GC::JOIN_MITER #Only used for polygons.
				)
				
				#Get previous location so we can draw a line from it.
				previous_location = @locations[object.identifier][index - 1]
				
				#Draw a line with the current width from the prior location to the current location.
				buffer.draw_line(
					graphics_context,
					previous_location[0], previous_location[1],
					location[0], location[1]
				)
				
			end
			
		end
		
		@canvas.queue_draw_area(0, 0, @width, @height)
		
	end
	
	
	private
	
		def resize
			@canvas.set_size_request(@width, @height)
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end
		
		def buffer
			@buffer ||= Gdk::Pixmap.new(@canvas.window, @width, @height, -1)
		end
	
end


end #module Zyps
