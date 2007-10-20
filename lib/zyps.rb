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


require 'observer'

module Zyps

#A virtual environment.
class Environment

	include Observable
	
	#An array of GameObject objects that reside in the Environment.
	attr_accessor :objects
	#An array of EnvironmentalFactor objects that act on any GameObject in the Environment.
	attr_accessor :environmental_factors
	
	def initialize (objects = [], environmental_factors = [])
		self.objects, self.environmental_factors = objects, environmental_factors
		@clock = Clock.new
	end
	
	#Allow everything in the environment to interact with each other.
	#Objects are first moved according to their preexisting vectors and the amount of time since the last call.
	#Then each EnvironmentalFactor is allowed to act on each object.
	#Finally, each GameObject with an act() method is allowed to act on the environment.
	def interact
	
		#Get time since last interaction.
		elapsed_time = @clock.elapsed_time
		
		objects.each do |object|
		
		
			#Move each object according to its vector.
			begin
				object.move(elapsed_time)
			#Remove misbehaving objects.
			rescue Exception => exception
				puts exception, exception.backtrace
				objects.delete(object)
				next
			end
			
			#Have all environmental factors interact with each object.
			environmental_factors.each do |factor|
				begin
					factor.act(object)
				#Remove misbehaving environmental factors.
				rescue Exception => exception
					environmental_factors.delete(factor)
					puts exception, exception.backtrace
					next
				end
			end
			
			#Have all creatures interact with the environment.
			if object.respond_to?(:act)
				begin
					object.act(self)
				#Remove misbehaving objects.
				rescue Exception => exception
					puts exception, exception.backtrace
					objects.delete(object)
					next
				end
			end
				
			
		end
		
		#Mark environment as changed.
		changed
		
		#Alert observers.
		notify_observers(self)
		
	end
	
end



#An object in the virtual environment.
class GameObject

	#A universal identifier for the object.
	#Needed for DRb transmission, etc.
	attr_reader :identifier
	#The object's Location in space.
	attr_accessor :location
	#A Color that will be used to draw the object.
	attr_accessor :color
	#Radius of the object.
	attr_accessor :size
	#A Vector with the object's current speed and direction of travel.
	attr_accessor :vector
	#A String with the object's name.
	attr_accessor :name
	#An array of Strings with tags that determine how the object will be treated by Creature and EnvironmentalFactor objects in its environment.
	attr_accessor :tags
	
	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0, size = 1, tags = [])
		self.name, self.location, self.color, self.vector, self.age, self.size, self.tags = name, location, color, vector, age, size, tags
		@identifier = rand(99999999) #TODO: Current setup won't necessarily be unique.
	end
	
	#Size must be positive.
	def size=(v); v = 0 if v < 0; @size = v; end
	
	#Move according to vector over the given number of seconds.
	def move (elapsed_time)
		@location.x += @vector.x * elapsed_time
		@location.y += @vector.y * elapsed_time
	end
	
	#Time since the object was created, in seconds.
	def age; Time.new.to_f - @birth_time; end
	def age=(age); @birth_time = Time.new.to_f - age; end
	
end



#A Creature is a GameObject that can sense and respond to other GameObjects (including other Creature objects).
class Creature < GameObject

	#A list of Behavior objects that determine the creature's response to its environment.
	attr_accessor :behaviors
	
	#Identical to the GameObject constructor, except that it also takes a list of Behavior objects.
	def initialize (name = nil, location = Location.new, color = Color.new, vector = Vector.new, age = 0, size = 1, tags = [], behaviors = [])
		super(name, location, color, vector, age, size, tags)
		self.behaviors = behaviors
	end
	
	#Call Behavior.perform(self, environment) on each of the creature's assigned Behaviors.
	def act(environment)
		behaviors.each {|behavior| behavior.perform(self, environment)}
	end
	
end



#Something in the environment that acts on creatures.
#EnvironmentalFactors must implement an act(target) instance method.
class EnvironmentalFactor
end



#An action that one Creature takes on another.
class Action

	#Whether the action was previously started.
	attr_reader :started
	
	def initialize
		@started = false
	end
	
	#Start the action.
	#Overriding subclasses must either call "super" or set the @started attribute to true.
	def start(actor, target)
		@started = true
	end
	
	#Perform the action.
	#Subclasses should override this.
	def do(actor, target)
	end
	
	#Stop the action.
	#Overriding subclasses must either call "super" or set the @started attribute to false.
	def stop(actor, target)
		@started = false
	end
	
end



#A condition for one Creature to act on another.
#Conditions must implement a met?(actor, target) instance method.
class Condition
end



#A behavior that a Creature engages in.
#The target can have its tags or colors changed, it can be "herded", it can be destroyed, or any other action the library user can dream up.
#Likewise, the subject can change its own attributes, it can approach or flee from the target, it can spawn new Creatures or GameObjects (like bullets), or anything else.
class Behavior

	#A list of Condition objects, which are called with the object itself and its target.  A condition can consider the tags on the target, the distance from the subject, or any other criteria.  If any condition returns false, the behavior will not be carried out (or stopped if it has begun).
	attr_accessor :conditions
	#A list of Action objects, which are called with the object and its target when all conditions are met.  An action can act on the subject or its target.
	attr_accessor :actions
	
	#Optionally takes an array of actions and one of conditions.
	def initialize (actions = [], conditions = [])
		self.actions, self.conditions = actions, conditions
		#Tracks current target.
		@active_target = nil
	end
	
	#Test all conditions against each object in the evironment.
	#For the first object that meets all of them, mark it active (and operate on it first next time).
	#Then call start() (if applicable) and perform() for all actions against the active target.
	#If any action or condition returns false, stop all actions, and deselect the active target.
	def perform(actor, environment)
		
		begin
			#Select a target.
			target = select_target(actor, environment.objects)
			#Do the actions on the target.
			actions.each do |action|
				action.start(actor, target) unless action.started
				action.do(actor, target)
			end
		rescue NoMatchException => exception
			#If the behavior can no longer be performed, halt it.
			stop(actor, target)
		end
		
	end
	
	
	private

		#Stop all actions and de-select the active target.
		def stop(actor, target)
			actions.each do |action|
				action.stop(actor, target) if action.started
			end
			@active_target = nil
		end
		
		#Select a target that matches all conditions.
		def select_target(actor, targets)
			#If a target is already active, still present in the environment, and all conditions are true for it, simply re-select it.
			if @active_target and targets.include?(@active_target) and conditions.all?{|condition| condition.met?(actor, @active_target)}
				return @active_target 
			end
			#For each object in environment:
			targets.each do |target|
				#Don't let actor target itself.
				next if target == actor
				#If all conditions match (or there are no conditions), select the object.
				if conditions.all?{|condition| condition.met?(actor, target)}
					@active_target = target
					return target
				end
			end
			#If there were no matches, throw an exception.
			raise NoMatchException, "No matching targets found."
		end
	
	
end



#An object's color.  Has red, green, and blue components, each ranging from 0 to 1.
#* Red: <tt>Color.new(1, 0, 0)</tt>
#* Green: <tt>Color.new(0, 1, 0)</tt>
#* Blue: <tt>Color.new(0, 0, 1)</tt>
#* White: <tt>Color.new(1, 1, 1)</tt>
#* Black: <tt>Color.new(0, 0, 0)</tt>
class Color

	include Comparable
	
	#Components which range from 0 to 1, which combine to form the Color.
	attr_accessor :red, :green, :blue
	
	def initialize (red = 1, green = 1, blue = 1)
		self.red, self.green, self.blue = red, green, blue
	end
	
	#Automatically constrains value to the range 0 - 1.
	def red=(v); v = 0 if v < 0; v = 1 if v > 1; @red = v; end
	#Automatically constrains value to the range 0 - 1.
	def green=(v); v = 0 if v < 0; v = 1 if v > 1; @green = v; end
	#Automatically constrains value to the range 0 - 1.
	def blue=(v); v = 0 if v < 0; v = 1 if v > 1; @blue = v; end
	
	#Compares this Color with another to see which is brighter.
	#The sum of all components (red + green + blue) for each color determines which is greater.
	def <=>(other)
		@red + @green + @blue <=> other.red + other.green + other.blue
	end
	
	#Averages each component of this Color with the corresponding component of color2, returning a new Color.
	def +(color2)
		Color.new(
			(self.red + color2.red) / 2.0,
			(self.green + color2.green) / 2.0,
			(self.blue + color2.blue) / 2.0
		)
	end
	
end



#An object's location, with x and y coordinates.
class Location

	#Coordinates can be negative, and don't have to be integers.
	attr_accessor :x, :y
	
	def initialize (x = 0, y = 0)
		self.x, self.y = x, y
	end
	
end



#An object or force's velocity.
#Has speed and angle components.
class Vector

	#The length of the Vector.
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
	
	#Add this Vector to vector2, returning a new Vector.
	#This operation is useful when calculating the effect of wind or thrust on an object's current heading.
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
		reset_elapsed_time
	end
	
	#Returns the time in (fractional) seconds since this method was last called (or on the first call, time since the Clock was created).
	def elapsed_time
		time = Time.new.to_f
		elapsed_time = time - @last_check_time
		@last_check_time = time
		elapsed_time
	end
	
	def reset_elapsed_time
		@last_check_time = Time.new.to_f
	end
	
end



#Various methods for working with Vectors, etc.
module Utility
	
	PI2 = Math::PI * 2.0 #:nodoc:
	
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
	
	#Given a normal and an angle, find the reflection angle.
	def Utility.find_reflection_angle(normal, angle)
		incidence_angle = normal - angle
		reflection_angle = normal + incidence_angle
		reflection_angle %= 360
		reflection_angle
	end

	#Given two GameObjects, determine if the boundary of one crosses the boundary of the other.
	def Utility.collided?(object1, object2)
		object1_radius = Math.sqrt(object1.size / Math::PI)
		object2_radius = Math.sqrt(object2.size / Math::PI)
		return true if find_distance(object1.location, object2.location) < object1_radius + object2_radius
		false
	end
	
end


class NoMatchException < RuntimeError; end

end #module Zyps
