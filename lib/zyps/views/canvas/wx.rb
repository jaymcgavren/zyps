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


require 'wx'


module Zyps


#Called by View objects for use in wxRuby applications.
#Assign an instance to a View, then add the drawing_area attribute to a GUI container object.
#The drawing area will be updated whenever the View is.
class WxCanvas


	#A wxWidgets window that will be painted on.
	attr_reader :drawing_area
	#Dimensions of the drawing area.
	#Control should normally be left to the owner View object.
	attr_reader :width, :height

	#Takes the wxRuby GUI object that will be its parent.
	def initialize (parent)
	
		#Will be resized later.
		@width = 1
		@height = 1

		#Create a drawing area.
		@drawing_area = Wx::Window.new(parent)
		@drawing_area.min_size = [0, 0]
		#Set to correct size.
		resize
		
		#Whenever the drawing area needs updating...
		@drawing_area.evt_paint do |event|
			render
		end
		
		#Arrays of shapes that will be painted when render() is called.
		@rectangle_queue = []
		@line_queue = []
		
		#Hash of Wx::Pens used to draw in various colors and widths.
		@pens = Hash.new {|h, k| h[k] = Hash.new}
		#Hash of Wx::Brushes for various colors.
		@brushes = Hash.new
		
	end

	def width= (pixels) #:nodoc:
		@width = pixels
		resize
	end
	
	def height= (pixels) #:nodoc:
		@height = pixels
		resize
	end
	
	
	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:border_width => 1
	#	:filled => true
	#	:x => nil
	#	:y => nil
	#	:width => nil
	#	:height => nil
	def draw_rectangle(options = {})
		options = {
			:filled => true,
			:border_width => 1
		}.merge(options)
		@rectangle_queue << options
	end

	
	
	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:width => nil
	#	:x1 => nil
	#	:y1 => nil
	#	:x2 => nil
	#	:y2 => nil
	def draw_line(options = {})
		@line_queue << options
	end
		
	
	#Draw all objects to the drawing area.
	def render
		buffer.draw do |surface|
			#Draw all queued rectangles.
			render_rectangles(surface)
			#Draw all queued lines.
			render_lines(surface)
		end
		#Copy offscreen bitmap to screen.
		@drawing_area.paint do |dc|
			#Copy the buffer to the viewable window.
			dc.draw_bitmap(buffer, 0, 0, false)
		end
	end
				
	
	private

	
		#Converts a Zyps Color to the toolkit's color class.
		def convert_color(color)
			Wx::Colour.new(
				(color.red * 255).floor,
				(color.green * 255).floor,
				(color.blue * 255).floor
			)
		end
	
	
		#Resize buffer and drawing area.
		def resize
			@drawing_area.set_size(Wx::Size.new(@width, @height))
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end
	
		
		#The Wx::Bitmap to draw to.
		def buffer
			@buffer ||= Wx::Bitmap.new(@width, @height)
		end

		
		#Draw all queued rectangles to the given GC.
		def render_rectangles(surface)
			while options = @rectangle_queue.shift do
				surface.pen = get_pen(options[:color], options[:border_width]) #Used for border.
				if options[:filled]
					surface.brush = get_brush(options[:color])
				else
					surface.brush = Wx::TRANSPARENT_BRUSH
				end
				surface.draw_rectangle(
					options[:x], options[:y],
					options[:width], options[:height]
				)
			end
		end

			
		#Draw all queued lines to the given GC.
		def render_lines(surface)
			surface.pen.cap = Wx::CAP_ROUND
			while options = @line_queue.shift do
				surface.pen = get_pen(options[:color], options[:width])
				surface.draw_line(
					options[:x1].floor, options[:y1].floor,
					options[:x2].floor, options[:y2].floor
				)
			end
		end
		
		
		def get_pen(color, width)
			@pens[[color.red, color.green, color.blue]][width] ||= Wx::Pen.new(convert_color(color), width.ceil)
		end


		def get_brush(color)
			@brushes[[color.red, color.green, color.blue]] ||= Wx::Brush.new(convert_color(color), Wx::SOLID)
		end

		
end


end #module Zyps