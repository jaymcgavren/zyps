require 'observer'
require 'gtk2'

#A virtual environment.
class Environment
	include Observable
	attr_accessor :objects, :environmental_factors
	def initialize (objects = [], environmental_factors = [])
		@objects, @environmental_factors = objects, environmental_factors
	end
	#Allow everything in the environment to interact with each other.
	def interact
		objects.each do |target|
			#Have all objects interact with each other.
			objects.find_all{|object| ! object.equal?(target)}.each{|object| object.act(target)} #Ensure object does not act on itself.
			#Have all environmental factors interact with each object.
			environmental_factors.each {|factor| factor.act(target)}
		end
		#Mark environment as changed.
		changed
	end
end
#An object in the virtual environment.
class GameObject
	attr_accessor :location, :color, :vector, :name
	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0)
		@name, @location, @color, @vector = name, location, color, vector
		self.age = age
	end
	def age; Time.new.to_f - @birth_time; end
	def age=(age); @birth_time = Time.new.to_f - age; end
end
#Mixin to have an object act on other objects.
module Responsive
	def act(target)
		behaviors.each {|behavior| behavior.perform(target)}
	end
end
#A creature.
class Creature < GameObject
	include Responsive
	attr_accessor :behaviors
	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0, behaviors = [])
		super(name, location, color, vector, age)
		@behaviors = behaviors
	end
end
#A behavior creatures engage in.
class Behavior
	attr_accessor :actions, :conditions
	def initialize (actions = [], conditions = [])
		@actions, @conditions = actions, conditions
	end
	def add_action (&action); @actions << action; end
	def add_condition (&condition); @conditions << condition; end
	def perform(target)
		conditions.each {|condition| return nil unless condition.call(target)}
		actions.each {|action| action.call(target)}
	end
end
#Something in the environment that acts on creatures.
class EnvironmentalFactor
	include Responsive
	attr_accessor :behaviors
	def initialize (behaviors = [])
		@behaviors = behaviors
	end
end
#An object's color.
class Color
	attr_accessor :red, :green, :blue
	def initialize (red = 1, green = 1, blue = 1)
		@red, @green, @blue = red, green, blue
	end
end
#An object's location.
class Location
	attr_accessor :x, :y, :z
	def initialize (x = 0, y = 0, z = 0)
		@x, @y, @z = x, y, z
	end
end
#An object or force's velocity.
class Vector
	PI2 = Math::PI * 2
	attr_accessor :speed
	def initialize (speed = 0, pitch = 0, yaw = 0)
		@speed, @pitch, @yaw = speed, pitch, yaw
	end
	def to_degrees(radians); radians / PI2 * 360; end
	def to_radians(degrees)
		radians = degrees / 360 * PI2
		radians = radians % PI2
		radians += PI2 if radians < 0
		radians
	end
	#The angle along the X/Y axes.
	def pitch; to_degrees(@pitch); end
	def pitch=(degrees); @pitch = to_radians(degrees); end
	#The angle along the X/Z axes.
	def yaw; to_degrees(@yaw); end
	def yaw=(degrees); @yaw = to_radians(degrees); end
	#The X component.
	def x; @speed * Math.cos(@pitch); end
	#The Y component.
	def y; @speed * Math.sin(@pitch); end
	#The Z component.
	def x; @speed * Math.cos(@yaw); end
end
#A clock to use for timing actions.
class Clock
	def initialize
		last_check_time = Time.new.to_f
	end
	def elapsed_time
		time = Time.new.to_f
		elapsed_time = time - last_check_time
		last_check_time = time
		elapsed_time
	end
end
#A view of game objects.
class TrailsView

	attr_reader :canvas, :width, :height
	attr_accessor :segment_count, :trail_width, :background

	def initialize (window, width = 600, height = 400, segment_count = 5, trail_width = segment_count, background = Gdk::Color.new(0, 65535, 0))
	
		@width, @height, @segment_count, @trail_width, @background = width, height, segment_count, trail_width, background
	
		#Create a drawing area.
		@canvas = Gtk::DrawingArea.new
		@canvas.set_size_request(@width, @height)
		window.add(canvas)
		window.show_all
		
		#Set canvas size and create buffer to draw to.
		@buffer = Gdk::Pixmap.new(@canvas.window, @width, @height, -1)

		#Whenever the drawing area needs updating...
		@canvas.signal_connect("expose_event") do
			#Copy buffer bitmap to canvas.
			@canvas.window.draw_drawable(
				@canvas.style.fg_gc(@canvas.state), #Gdk::GC (graphics context) to use when drawing.
				@buffer, #Gdk::Drawable source to copy onto canvas.
				0, 0, #Pull from upper left of source.
				0, 0, #Copy to upper left of canvas.
				-1, -1 #-1 width and height signals to copy entire source over.
			)
		end
		
		#Track a list of locations for each object.
		@locations = Hash.new {|h, k| h[k] = Array.new}
		
	end
	
	#Draw the objects.
	def render(objects)
		graphics_context = Gdk::GC.new(@buffer)
		#Clear the background on the buffer.
		@buffer.draw_rectangle(
			@canvas.style.bg_gc(@canvas.state),
			true, #Filled.
			0, 0, #Upper-left corner.
			@width, @height #Lower-right corner.
		)
		#For each GameObject in the environment:
		objects.each do |object|
			#Get the list of locations for this object.
			current_locations = @locations[object]
			#Add the object's current location to the list.
			@locations[object] << object.location
			#If the list is larger than the number of tail segments, delete the first position.
			@locations[object].shift if @locations[object].length > @segment_count
			#For each location in this object's list:
			@locations[object].each_with_index do |location, index|
				#Skip first location.
				next if index == 0
				#Divide the current segment number by trail segment count to get the multiplier to use for brightness and width.
				multiplier = index.to_f / @locations[object].length.to_f
				#Set the drawing color to use the object's colors, adjusted by the multiplier.
				graphics_context.foreground = Gdk::Color.new(
					object.color.red * multiplier * 65535,
					object.color.green * multiplier * 65535,
					object.color.blue * multiplier * 65535
				)
				#Multiply the actual drawing width by the current multiplier to get the current drawing width.
				graphics_context.set_line_attributes(
					@trail_width * multiplier,
					Gdk::GC::LINE_SOLID,
					Gdk::GC::CAP_ROUND, #Line ends drawn as semicircles.
					Gdk::GC::JOIN_MITER #Only used for polygons.
				)
				#Get previous location so we can draw a line from it.
				previous_location = @locations[object][index - 1]
				#Draw a line with the current width from the prior location to the current location.
				@buffer.draw_line(
					graphics_context,
					previous_location.x, previous_location.y,
					location.x, location.y
				)
			end
		end
		@canvas.queue_draw_area(0, 0, @width, @height)
	end
	
end