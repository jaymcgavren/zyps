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


class WxCanvas


	#A wxWidgets window that will be painted on.
	attr_reader :drawing_area
	#Dimensions of the drawing area.
	attr_reader :width, :height

	#Takes a hash with these keys and defaults:
	#	:parent => nil
	#	:width => 600
	#	:height => 400
	def initialize (options = {})
	
		options = {
			:width => 600,
			:height => 400,
		}.merge(options)
		@width = options[:width]
		@height = options[:height]

		#Create a drawing area.
		@drawing_area = Wx::Window.new(options[:parent])
		#Set to correct size.
		resize
		
		#Whenever the drawing area needs updating...
		@drawing_area.evt_paint do |event|
			@drawing_area.paint do |dc|
				#Copy the buffer to the viewable window.
				buffer.draw do |buffer_dc|
					dc.blit(
						0, 0, #Copy to upper left of canvas.
						@width, @height,
						buffer_dc, #Source.
						0, 0 #Pull from upper left of source.
					)
				end
			end
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
		buffer.draw do |surface|
			color = convert_color(options[:color])
			surface.pen = Wx::Pen.new(color, 0) #Used for border.
			if options[:filled]
				#For now, only black is implemented.
				#Can't figure out how to make custom brushes with wxRuby.
				if options[:color] == Color.new(0, 0, 0)
					surface.brush = Wx::BLACK_BRUSH
				else
					raise(NotImplementedError, "Only black brushes implemented for now.")
				end
			else
				surface.brush = Wx::TRANSPARENT_BRUSH
			end
			surface.draw_rectangle(
				options[:x], options[:y],
				options[:width], options[:height]
			)
		end
	end

	

	
	def draw_line(options = {})
		buffer.draw do |surface|
			surface.pen = Wx::Pen.new(
				convert_color(options[:color]),
				options[:width].ceil
			)
			surface.pen.cap = options[:round_ends] ? Wx::CAP_ROUND : Wx::CAP_BUTT
			surface.draw_line(
				options[:x1].floor, options[:y1].floor,
				options[:x2].floor, options[:y2].floor
			)
		end
	end
	
	
	def render
		@drawing_area.refresh
		@drawing_area.update
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
	
	
		def resize
			@drawing_area.set_size(Wx::Size.new(@width, @height))
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end
	
		
		def buffer
			@buffer ||= Wx::Bitmap.new(@width, @height)
		end
	
	
end


end #module Zyps