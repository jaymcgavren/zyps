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


require 'observer'

module Zyps

#A virtual environment.
class Environment

	include Observable
	
	#An array of GameObject objects that reside in the Environment.
	attr_accessor :objects
	#An array of EnvironmentalFactor objects that act on any GameObject in the Environment.
	attr_accessor :environmental_factors
	
	#Takes a hash with these keys and defaults:
	#	:objects => [], 
	#	:environmental_factors => []
	def initialize (options = {})
		options = {
			:objects => [], 
			:environmental_factors => []
		}.merge(options)
		self.objects, self.environmental_factors = options[:objects], options[:environmental_factors]
		@clock = Clock.new
	end
	
	#Make a deep copy.
	def copy
		copy = self.clone #Currently, we overwrite everything anyway, but we may add some clonable attributes later.
		#Make a deep copy of all objects.
		copy.objects = []
		@objects.each {|object| copy.objects << object.copy}
		#Make a deep copy of all environmental_factors.
		copy.environmental_factors = []
		@environmental_factors.each {|environmental_factor| copy.environmental_factors << environmental_factor.copy}
		copy
	end
	
	#Allow everything in the environment to interact with each other.
	#Objects are first moved according to their preexisting vectors and the amount of time since the last call.
	#Then, each GameObject with an act() method is allowed to act on the environment.
	#Finally, each EnvironmentalFactor is allowed to act on the Environment.
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
			
			#Have all creatures interact with the environment.
			if object.respond_to?(:act)
				begin
					#Have creature act on all GameObjects other than itself.
					object.act(objects.reject{|target| target.equal?(object)})
				#Remove misbehaving objects.
				rescue Exception => exception
					puts exception, exception.backtrace
					objects.delete(object)
					next
				end
			end
				
			
		end
		
		#Have all environmental factors interact with environment.
		environmental_factors.each do |factor|
			begin
				factor.act(self)
			#Remove misbehaving environmental factors.
			rescue Exception => exception
				environmental_factors.delete(factor)
				puts exception, exception.backtrace
				next
			end
		end
			
		#Mark environment as changed.
		changed
		
		#Alert observers.
		notify_observers(self)
		
	end
	
	#Overloads the << operator to put the new item into the correct list.
	#This allows one to simply call env << <valid_object> instead of 
	#having to choose a specific list, such as objects or environmental factors.
	def <<(item)
		if(item.kind_of? Zyps::GameObject)
			self.objects << item
		elsif(item.kind_of? Zyps::EnvironmentalFactor)
			self.environmental_factors << item
		else
			raise "Invalid item: #{item.class}" 
		end
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
	
	#Takes a hash with these keys and defaults:
	#	:name => nil,
	#	:location => Location.new,
	#	:color => Color.new,
	#	:vector => Vector.new,
	#	:age => 0,
	#	:size => 1,
	#	:tags => []
	def initialize (options = {})
		options = {
			:name => nil,
			:location => Location.new,
			:color => Color.new,
			:vector => Vector.new,
			:age => 0,
			:size => 1,
			:tags => []
		}.merge(options)
		self.name, self.location, self.color, self.vector, self.age, self.size, self.tags = options[:name], options[:location], options[:color], options[:vector], options[:age], options[:size], options[:tags]
		@identifier = generate_identifier
	end
	
	#Make a deep copy.
	def copy
		copy = self.clone
		copy.vector = @vector.copy
		copy.color = @color.copy
		copy.location = @location.copy
		copy.tags = @tags.clone
		copy.identifier = generate_identifier
		copy.name = @name ? "Copy of " + @name.to_s : nil
		copy
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
	
	#Set identifier.
	#Not part of API; copy() needs this to make copy's ID unique.
	def identifier=(value) #:nodoc:
		@identifier = value
	end
	
	#Overloads the << operator to put the new item into the correct
	#list or assign it to the correct attribute.
	#Assignment is done based on item's class or a parent class of item.
	def <<(item)
		if item.kind_of? Zyps::Location:
			self.location = item
		elsif item.kind_of? Zyps::Color:
			self.color = item
		elsif item.kind_of? Zyps::Vector:
			self.vector = item
		else
			raise "Invalid item: #{item.class}"
		end
	end
	
	private
	
		#Make a unique GameObject identifier.
		def generate_identifier
			rand(99999999) #TODO: Current setup won't necessarily be unique.
		end
	
end



#A Creature is a GameObject that can sense and respond to other GameObjects (including other Creature objects).
class Creature < GameObject

	#A list of Behavior objects that determine the creature's response to its environment.
	attr_accessor :behaviors
	
	#Identical to the GameObject constructor, except that it also takes a list of Behavior objects.
	#Takes a hash with these keys and defaults:
	#	:name => nil
	#	:location => Location.new
	#	:color => Color.new
	#	:vector => Vector.new
	#	:age => 0
	#	:size => 1
	#	:tags => []
	#	:behaviors => []
	def initialize (options = {})
		options = {
			:behaviors => []
		}.merge(options)
		super
		self.behaviors = options[:behaviors]
	end
	
	#Make a deep copy.
	def copy
		copy = super
		#Make deep copy of each behavior.
		copy.behaviors = []
		@behaviors.each {|behavior| copy.behaviors << behavior.copy}
		copy
	end
	
	#Performs all assigned behaviors on the targets.
	def act(targets)
		behaviors.each {|behavior| behavior.perform(self, targets)}
	end
	
	#See GameObject#<<.
	#Adds ability to stream in behaviors as well.
	def <<(item)
		begin
			super
		rescue 
			if(item.kind_of? Zyps::Behavior)
				self.behaviors << item
			else
				raise "invalid item: #{item.class}"
			end
		end
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
	
	#Make a deep copy.
	def copy; self.clone; end
	
	#Start the action.
	#Overriding subclasses must either call "super" or set the @started attribute to true.
	def start(actor, target)
		@started = true
	end
	
	def do(actor, target)
		raise NotImplementedError.new("Action subclasses must implement a do(actor, target) instance method.")
	end
	
	#Stop the action.
	#Overriding subclasses must either call "super" or set the @started attribute to false.
	def stop(actor, target)
		@started = false
	end
	
	#Synonym for started
	def started?; started; end
	
end



#A condition for one Creature to act on another.
class Condition

	#Make a deep copy.
	def copy; self.clone; end
	
	def select(actor, targets)
		raise NotImplementedError.new("Condition subclasses must implement a select(actor, target) instance method.")
	end
	
end



#A behavior that a Creature engages in.
#The target can have its tags or colors changed, it can be "herded", it can be destroyed, or any other action the library user can dream up.
#Likewise, the subject can change its own attributes, it can approach or flee from the target, it can spawn new Creatures or GameObjects (like bullets), or anything else.
class Behavior

	#An array of Condition subclasses.
	#Condition#select(actor, targets) will be called on each.
	attr_accessor :conditions
	#An array of Action subclasses.
	#Action#start(actor, targets) and action.do(actor, targets) will be called on each when all conditions are true.
	#Action#stop(actor, targets) will be called when any condition is false.
	attr_accessor :actions
	#Number of updates before behavior is allowed to select a new group of targets to act on.
	attr_accessor :condition_frequency
	
	#Will be used to distribute condition processing time between all Behaviors with the same condition_frequency.
	@@condition_order = Hash.new {|h, k| h[k] = 0}
	
	#Takes a hash with these keys and defaults:
	#	:actions => []
	#	:conditions => []
	#	:condition_frequency => 1
	def initialize (options = {})
		options = {
			:actions => [],
			:conditions => [],
			:condition_frequency => 1
		}.merge(options)
		self.actions = options[:actions]
		self.conditions = options[:conditions]
		self.condition_frequency = options[:condition_frequency]
		#Tracks number of calls to perform() so conditions can be evaluated with appropriate frequency.
		@condition_evaluation_count = 0
		#Targets currently selected to act upon.
		@current_targets = []
	end
	
	def condition_frequency= (value)
		#Condition frequency must be 1 or more.
		@condition_frequency = (value >= 1 ? value : 1)
		#This will be used to distribute condition evaluation time among all behaviors with this frequency.
		@condition_order = @@condition_order[@condition_frequency]
		@@condition_order[@condition_frequency] += 1
	end
	
	#Make a deep copy.
	def copy
		copy = self.clone #Currently, we overwrite everything anyway, but we may add some clonable attributes later.
		#Make a deep copy of all actions.
		copy.actions = []
		@actions.each {|action| copy.actions << action.copy}
		#Make a deep copy of all conditions.
		copy.conditions = []
		@conditions.each {|condition| copy.conditions << condition.copy}
		copy
	end
	
	#Finds targets that meet all conditions, then acts on them.
	#Calls select(actor, targets) on each Condition, each time discarding targets that fail.
	#Then on each Action, calls Action#start(actor, targets) (if not already started) followed by Action#do(actor, targets).
	#If no matching targets are found, calls Action#stop(actor, targets) on each Action.
	#If there are no conditions, actions will occur regardless of targets.
	def perform(actor, targets)
		
		if condition_evaluation_turn?
			@current_targets = targets.clone
			conditions.each {|condition| @current_targets = condition.select(actor, @current_targets)}
		end
		actions.each do |action|
			if @current_targets.empty? and ! @conditions.empty?
				action.stop(actor, targets) #Not @current_targets; that array is empty.
			else
				action.start(actor, @current_targets) unless action.started?
				action.do(actor, @current_targets)
			end
		end
		
		
	end
	
	private
		
		#Return true if it's our turn to choose targets, false otherwise.
		def condition_evaluation_turn?
			#Every condition_frequency turns (plus our turn order within the group), return true.
			our_turn = ((@condition_evaluation_count + @condition_order) % @condition_frequency == 0) ? true : false
			#Track number of calls to perform() for staggering condition evaluation.
			@condition_evaluation_count += 1
			our_turn
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
	
	#Make a deep copy.
	def copy; self.clone; end
	
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
	
	#Pre-defined color value.
	def self.red; Color.new(1, 0, 0); end
	def self.orange; Color.new(1, 0.63, 0); end
	def self.yellow; Color.new(1, 1, 0); end
	def self.green; Color.new(0, 1, 0); end
	def self.blue; Color.new(0, 0, 1); end
	def self.indigo; Color.new(0.4, 0, 1); end
	def self.violet; Color.new(0.9, 0.5, 0.9); end
	def self.white; Color.new(1, 1, 1); end
	def self.black; Color.new(0, 0, 0); end
	def self.grey; Color.new(0.5, 0.5, 0.5); end

		
end



#An object's location, with x and y coordinates.
class Location

	#Coordinates can be negative, and don't have to be integers.
	attr_accessor :x, :y
	
	def initialize (x = 0, y = 0)
		self.x, self.y = x, y
	end

	#Make a deep copy.
	def copy; self.clone; end
	
	#True if x and y coordinates are the same.
	def ==(other); self.x == other.x and self.y == other.y; end
	
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
	
	#Make a deep copy.
	def copy; self.clone; end
	
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
	
	#True if x and y coordinates are the same.
	def ==(other); self.speed == other.speed and self.pitch == other.pitch; end
	
end



#A clock to use for timing actions.
class Clock

	def initialize
		@@speed = 1
		reset_elapsed_time
	end
	
	#Make a deep copy.
	def copy; self.clone; end
	
	#Returns the time in (fractional) seconds since this method was last called (or on the first call, time since the Clock was created).
	def elapsed_time
		time = Time.new.to_f
		elapsed_time = time - @last_check_time
		@last_check_time = time
		elapsed_time * @@speed
	end
	
	def reset_elapsed_time
		@last_check_time = Time.new.to_f
	end
	
	#Speed at which all Clocks are operating.
	def Clock.speed; @@speed; end
	#Set speed at which all Clocks will operate.
	#1 is real-time, 2 is double speed, 0 is paused.
	def Clock.speed=(value); @@speed = value; end

end



#Various methods for working with Vectors, etc.
module Utility
	
	PI2 = Math::PI * 2.0 #:nodoc:
	
	#Empty cached return values.
	def Utility.clear_caches
		@@angles = Hash.new {|h, k| h[k] = {}}
		@@distances = Hash.new {|h, k| h[k] = {}}
	end
	
	#Initialize caches for return values.
	Utility.clear_caches
	
	#Turn caching of return values on or off.
	@@caching_enabled = false
	def Utility.caching_enabled= (value)
		@@caching_enabled = value
		Utility.clear_caches if ! @@caching_enabled
	end
	
	#Get the angle (in degrees) from one Location to another.
	def Utility.find_angle(origin, target)
		if @@caching_enabled
			#Return cached angle if there is one.
			return @@angles[origin][target] if @@angles[origin][target]
			return @@angles[target][origin] if @@angles[target][origin]
		end
		#Get vector from origin to target.
		x_difference = target.x - origin.x
		y_difference = target.y - origin.y
		#Get vector's angle.
		radians = Math.atan2(y_difference, x_difference)
		#Result will range from negative Pi to Pi, so correct it.
		radians += PI2 if radians < 0
		#Convert to degrees.
		angle = to_degrees(radians)
		#Cache angle if caching enabled.
		if @@caching_enabled
			@@angles[origin][target] = angle
			#angle + 180 = angle from target to origin.
			@@angles[target][origin] = (angle + 180 % 360)
		end
		#Return result.
		angle
	end
	
	#Get the distance from one Location to another.
	def Utility.find_distance(origin, target)
		if @@caching_enabled
			#Return cached distance if there is one.
			return @@distances[origin][target] if @@distances[origin][target]
		end
		#Get vector from origin to target.
		x_difference = origin.x - target.x
		y_difference = origin.y - target.y
		#Get distance.
		distance = Math.sqrt(x_difference ** 2 + y_difference ** 2)
		#Cache distance if caching enabled.
		if @@caching_enabled
			#Origin to target distance = target to origin distance.
			#Cache such that either will be found.
			@@distances[origin][target] = distance
			@@distances[target][origin] = distance
		end
		#Return result.
		distance
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


end #module Zyps
