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


class GTK2Canvas


	#A Gtk::DrawingArea that will be painted on.
	attr_reader :drawing_area
	#Dimensions of the drawing area.
	attr_reader :width, :height

	def initialize
	
		#Will be resized later.
		@width = 1
		@height = 1

		#Create a drawing area.
		@drawing_area = Gtk::DrawingArea.new
		#Set to correct size.
		resize
		
		#Whenever the drawing area needs updating...
		@drawing_area.signal_connect("expose_event") do
			#Copy buffer bitmap to canvas.
			@drawing_area.window.draw_drawable(
				@drawing_area.style.fg_gc(@drawing_area.state), #Gdk::GC (graphics context) to use when drawing.
				buffer, #Gdk::Drawable source to copy onto canvas.
				0, 0, #Pull from upper left of source.
				0, 0, #Copy to upper left of canvas.
				-1, -1 #-1 width and height signals to copy entire source over.
			)
		end
		
	end

	def width= (pixels) #:nodoc:
		@width = pixels
		resize
	end
	
	def height= (pixels) #:nodoc:
		@height = pixels
		resize
	end
	
	
	def draw_rectangle(options = {})
		options = {
			:filled => true
		}.merge(options)
		graphics_context = Gdk::GC.new(buffer)
		graphics_context.rgb_fg_color = convert_color(options[:color])
		buffer.draw_rectangle(
			graphics_context,
			options[:filled],
			options[:x], options[:y],
			options[:width], options[:height]
		)
	end

	
	def draw_line(options = {})
		graphics_context = Gdk::GC.new(buffer)
		graphics_context.rgb_fg_color = convert_color(options[:color])
		graphics_context.set_line_attributes(
			options[:width].ceil,
			Gdk::GC::LINE_SOLID,
			Gdk::GC::CAP_ROUND,
			Gdk::GC::JOIN_MITER #Only used for polygons.
		)
		buffer.draw_line(
			graphics_context,
			options[:x1], options[:y1],
			options[:x2], options[:y2]
		)
	end
	
	
	def render
		@drawing_area.queue_draw_area(0, 0, @width, @height)
	end
				
	
	private
	
		#Converts a Zyps Color to a Gdk::Color.
		def convert_color(color)
			Gdk::Color.new(
				color.red * 65535,
				color.green * 65535,
				color.blue * 65535
			)
		end
	
	
		def resize
			@drawing_area.set_size_request(@width, @height)
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end
	
		
		def buffer
			@buffer ||= Gdk::Pixmap.new(@drawing_area.window, @width, @height, -1)
		end
	
	
end


end #module Zyps