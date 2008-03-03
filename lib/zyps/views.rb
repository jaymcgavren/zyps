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


#Base class of views in Zyps.
class View
	
	#A GUI toolkit-specific drawing area that will be used to render the view.
	#See WxCanvas and GTK2Canvas.
	attr_accessor :canvas
	#Dimensions of the view.
	attr_accessor :width, :height
	#Scale of the view, with 1.0 being actual size.
	attr_accessor :scale
	#A Location which objects will be drawn relative to.
	attr_accessor :origin
	#Whether view should be erased before re-drawing.
	attr_accessor :erase_flag 
	#Color that background should be drawn with.
	attr_accessor :background_color
	
	#Takes a hash with these keys and defaults:
	#	:canvas => nil,
	#	:width => 600,
	#	:height => 400,
	#	:scale => 1,
	#	:origin => Location.new(0.0),
	#	:erase_flag => true,
	#	:background_color => Color.black
	def initialize(options = {})
	
		options = {
			:canvas => nil,
			:width => 600,
			:height => 400,
			:scale => 1,
			:origin => Location.new(0.0),
			:erase_flag => true,
			:background_color => Color.black
		}.merge(options)
		@width = options[:width]
		@height = options[:height]
		@canvas = options[:canvas]
		self.scale = options[:scale]
		self.origin = options[:origin]
		self.erase_flag = options[:erase_flag]
		
		#Set canvas's size to match view's.
		resize if @canvas
		
	end
	
	#Base update method to be overridden in subclass.
	#This method clears the canvas in preparation of drawing to the canvas.
	#It then iterates over each object in the environment and yields the object.
	#This allows the child class to update each object in its own specific manner,
	# by calling super and passing a block that performs the actual update
	def update(environment)
	
		clear_view if @erase_flag
		
		#For each GameObject in the environment:
		#yields this object to the calling block
		environment.objects.each do |object|
			yield object
		end #environment.objects.each
		#render the canvas
		@canvas.render
		
	end #update
	
	
	#Convert a Location to x and y drawing coordinates, compensating for view's current scale and origin.
	def drawing_coordinates(location)
		[
			(location.x - origin.x) * scale,
			(location.y - origin.y) * scale
		]
	end
	
	
	#Convert a width to a drawing width, compensating for view's current scale.
	def drawing_width(units)
		units * scale
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
	
	
	private


		def resize
			@canvas.width = @width
			@canvas.height = @height
		end

		
		#Clear view.
		def clear_view
			@canvas.draw_rectangle(
				:color => Color.new(0, 0, 0),
				:filled => true,
				:x => 0, :y => 0,
				:width => @width, :height => @height
			)
		end
	
	
end #View class

end #Zyps module