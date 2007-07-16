require 'observer'
require 'gtk2'

#Various methods for working with Vectors, etc.
module Utility
	PI2 = Math::PI * 2.0
	#Get the angle (in degrees) from one Location to another.
	def Utility.find_angle(origin, target)
		#Get vector from origin to target.
		x_difference = target.x - origin.x
		y_difference = target.y - origin.y
		#Get vector's angle.
		radians = Math.atan2(y_difference, x_difference)
		#Result will range from negative Pi to Pi, so correct it.
		radians += PI2 if radians < 0
		#Convert to degrees.
		to_degrees(radians)
	end
	#Get the distance from one Location to another.
	def Utility.find_distance(origin, target)
		#Get vector from origin to target.
		x_difference = origin.x - target.x
		y_difference = origin.y - target.y
		#Get distance.
		Math.sqrt(x_difference ** 2 + y_difference ** 2)
	end
	#Convert radians to degrees.
	def Utility.to_degrees(radians)
		radians / PI2 * 360
	end
	#Convert degrees to radians.
	def Utility.to_radians(degrees)
		radians = degrees / 360.0 * PI2
		radians = radians % PI2
		radians += PI2 if radians < 0
		radians
	end
	#Reduce a number to within an allowed maximum (or minimum, if the number is negative).
	def Utility.constrain_value(value, absolute_maximum)
		if (value.abs > absolute_maximum) then
			if value >= 0 then
				value = absolute_maximum
			else
				value = absolute_maximum * -1
			end
		end
		value
	end
end
#A virtual environment.
class Environment
	include Observable
	attr_accessor :objects, :environmental_factors
	def initialize (objects = [], environmental_factors = [])
		@objects, @environmental_factors = objects, environmental_factors
		@clock = Clock.new
	end
	#Allow everything in the environment to interact with each other.
	def interact
		#Get time since last interaction.
		elapsed_time = @clock.elapsed_time
		objects.each do |object|
			#Move each object according to its vector.
			object.location.x += object.vector.x * elapsed_time
			object.location.y += object.vector.y * elapsed_time
			#Have all objects interact with each other.
			objects.each do |target|
				next if target.equal?(object) #Ensure object does not act on itself.
				object.act(object, target)
			end
			#Have all environmental factors interact with each object.
			environmental_factors.each {|factor| factor.act(factor, object)}
		end
		#Mark environment as changed.
		changed
	end
end
#An object in the virtual environment.
class GameObject
	attr_accessor :location, :color, :vector, :name, :tags
	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0, tags = [])
		@name, @location, @color, @vector, @tags = name, location, color, vector, tags
		self.age = age
	end
	def age; Time.new.to_f - @birth_time; end
	def age=(age); @birth_time = Time.new.to_f - age; end
end
#Mixin to have an object act on other objects.
module Responsive
	def act(subject, target)
		behaviors.each {|behavior| behavior.perform(subject, target)}
	end
end
#A creature.
class Creature < GameObject
	include Responsive
	attr_accessor :behaviors

	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0, tags = [], behaviors = [])
		super(name, location, color, vector, age, tags)
		@behaviors = behaviors
	end
end
#A behavior creatures or environmental factors engage in.
class Behavior
	attr_accessor :actions, :conditions
	def initialize (actions = [], conditions = [])
		@actions, @conditions = actions, conditions
	end
	def perform(subject, target)
		conditions.each {|condition| return nil unless condition.call(subject, target)}
		actions.each {|action| action.call(subject, target)}
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
	include Comparable
	attr_accessor :red, :green, :blue
	def initialize (red = 1, green = 1, blue = 1)
		@red, @green, @blue = red, green, blue
	end
	#Constrain components to the range 0 - 1.
	def red=(v); v = 0 if v < 0; v = 1 if v > 1; @red = v; end
	def green=(v); v = 0 if v < 0; v = 1 if v > 1; @green = v; end
	def blue=(v); v = 0 if v < 0; v = 1 if v > 1; @blue = v; end
	def <=>(other)
		@red + @green + @blue <=> other.red + other.green + other.blue
	end
	#When adding colors, average each of their components.
	def +(color2)
		Color.new(
			self.red + color2.red / 2.0,
			self.green + color2.green / 2.0,
			self.blue + color2.blue / 2.0
		)
	end
end
#An object's location.
class Location
	attr_accessor :x, :y
	def initialize (x = 0, y = 0)
		@x, @y = x, y
	end
end
#An object or force's velocity.
class Vector
	attr_accessor :speed
	def initialize (speed = 0, pitch = 0)
		self.speed = speed
		self.pitch = pitch
	end
	#The angle along the X/Y axes.
	def pitch; Utility.to_degrees(@pitch); end
	def pitch=(degrees)
		#Constrain degrees to 0 to 360.
		value = degrees % 360
		value += 360 if value < 0
		#Store as radians internally.
		@pitch = Utility.to_radians(value)
	end
	#The X component.
	def x; @speed.to_f * Math.cos(@pitch); end
	def x=(value)
		@speed, @pitch = Math.sqrt(value ** 2 + y ** 2), Math.atan(y / value)
	end
	#The Y component.
	def y; @speed.to_f * Math.sin(@pitch); end
	def y=(value)
		@speed, @pitch = Math.sqrt(x ** 2 + value ** 2), Math.atan(value / x)
	end
	#Vector addition.
	def +(vector2)
		#Get the x and y components of the new vector.
		new_x = (self.x + vector2.x)
		new_y = (self.y + vector2.y)
		new_length_squared = new_x ** 2 + new_y ** 2
		new_length = (new_length_squared == 0 ? 0 : Math.sqrt(new_length_squared))
		new_angle = (new_x == 0 ? 0 : Utility.to_degrees(Math.atan2(new_y, new_x)))
		#Calculate speed and angle of new vector with components.
		Vector.new(new_length, new_angle)
	end
end
#A clock to use for timing actions.
class Clock
	def initialize
		@last_check_time = Time.new.to_f
	end
	def elapsed_time
		time = Time.new.to_f
		elapsed_time = time - @last_check_time
		@last_check_time = time
		elapsed_time
	end
end
