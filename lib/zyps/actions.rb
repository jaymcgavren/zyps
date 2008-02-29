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


#Superclass for actions that need to happen at a specific rate.
class TimedAction < Action

	#A Clock that tracks time between actions.
	attr_accessor :clock
	#Units per second for action.
	attr_accessor :rate
	
	def initialize(rate, *arguments)
		self.rate = rate
		@clock = Clock.new
	end
	
	#Make a deep copy.
	def copy
		copy = super
		#Copies should have their own Clock.
		copy.clock = Clock.new
		copy
	end
	
	#Units to add to the attribute being changed.
	def delta
		@clock.elapsed_time * rate
	end
	
	#Begin tracking time between actions.
	def start(actor, targets)
		super
		@clock.reset_elapsed_time
	end
	
	#Halt tracking time between actions.
	def stop(actor, targets)
		super
		@clock.reset_elapsed_time
	end
	
end


#Head toward a target.
class FaceAction < Action
	#Set the actor's heading to point directly at first target.
	def do(actor, targets)
		return if targets.empty?
		actor.vector.pitch = Utility.find_angle(actor.location, targets[0].location)
	end
end


#Increase/decrease speed over time.
class AccelerateAction < TimedAction
	#Units per second to accelerate.
	#Can be negative to slow down or go in reverse.
	attr_accessor :rate
	#Increase or decrease speed according to elapsed time.
	def do(actor, targets)
		actor.vector.speed += delta
	end
end


#Apply a thrust that turns actor.
class TurnAction < TimedAction
	#Angle to turn at.
	attr_accessor :angle
	def initialize(rate, angle)
		super
		@angle = angle
	end
	def do(actor, targets)
		actor.vector += Vector.new(
			delta,
			actor.vector.pitch + @angle
		)
	end
end


#Approaches the target, but obeys law of inertia.
class ApproachAction < TimedAction
	#Accelerate toward the first target, but limited by rate.
	def do(actor, targets)
		return if targets.empty?
		#Apply thrust to the creature's movement vector, adjusted by elapsed time.
		actor.vector += Vector.new(
			delta,
			Utility.find_angle(actor.location, targets[0].location)
		)
	end
end


#Flees from the target, but obeys law of inertia.
class FleeAction < TimedAction
	#Accelerate away from the first target, but limited by turn rate.
	def do(actor, targets)
		return if targets.empty?
		#Apply thrust to the creature's movement vector, adjusted by elapsed time.
		actor.vector += Vector.new(
			delta,
			Utility.find_angle(actor.location, targets[0].location) + 180
		)
	end
end


#Destroy the targets.
class DestroyAction < Action
	#The environment to remove objects from.
	attr_accessor :environment
	def initialize(environment)
		self.environment = environment
	end
	#Remove the target from the environment.
	def do(actor, targets)
		targets.each do |target|
			@environment.objects.delete(target)
		end
	end
end


#Destroy the targets and grow in size.
class EatAction < DestroyAction
	#Remove the targets from the environment, and increase actor's size by size of targets.
	def do(actor, targets)
		#Grow in size.
		targets.each do |target|
			actor.size += target.size
		end
		#Remove the targets from the environment.
		super
	end
end


#Add a tag to the target.
class TagAction < Action
	#Tag to apply to targets.
	attr_accessor :tag
	def initialize(tag)
		self.tag = tag
	end
	#Apply the given tag to the targets.
	def do(actor, targets)
		targets.each do |target|
			target.tags << tag unless target.tags.include?(tag)
		end
	end
end


#Blend the actor's color with another color.
class BlendAction < TimedAction
	#Color to apply to actor.
	attr_accessor :color
	def initialize(rate, color)
		super
		@color = color
	end
	#Blend the actor's color with the assigned color.
	def do(actor, targets)
		actor.color.red += (@color.red - actor.color.red) * delta
		actor.color.green += (@color.green - actor.color.green) * delta
		actor.color.blue += (@color.blue - actor.color.blue) * delta
	end
end


#Pushes target away.
class PushAction < TimedAction
	#Units/second to accelerate targets by.
	attr_accessor :rate
	#Push the targets away from the actor, with force limited by elapsed time.
	def do(actor, targets)
		#Acceleration will be limited by elapsed time.
		push_force = delta
		targets.each do |target|
			#Angle to target is also angle of push force.
			push_angle = Utility.find_angle(actor.location, target.location)
			#Apply the force to the creature's movement vector.
			target.vector += Vector.new(push_force, push_angle)
		end
	end
end


#Pulls target toward actor.
class PullAction < TimedAction
	#Units/second to accelerate target by.
	attr_accessor :rate
	#Pull the targets toward the actor, with force limited by elapsed time.
	def do(actor, targets)
		#Acceleration will be limited by elapsed time.
		pull_force = delta
		targets.each do |target|
			#Angle from target to actor is also angle of pull force (opposite of that for push).
			pull_angle = Utility.find_angle(target.location, actor.location)
			#Apply the force to the creature's movement vector.
			target.vector += Vector.new(pull_force, pull_angle)
		end
	end
end


class BreedAction < Action
	DEFAULT_DELAY = 60
	#Environment to place children into.
	attr_accessor :environment
	#Delay between actions.
	attr_accessor :delay
	def initialize(environment, delay = DEFAULT_DELAY)
		self.environment, self.delay = environment, delay
		@clock = Clock.new
		@time_since_last_action = 0
	end
	def do(actor, targets)
		targets.each do |target|
			#Skip action if target is not a Creature.
			next unless target.is_a?(Creature)
			#Get time since last action, and skip if it hasn't been long enough.
			@time_since_last_action += @clock.elapsed_time
			return unless @time_since_last_action >= @delay
			#Create a child.
			child = Creature.new
			#Combine colors.
			child.color = actor.color + target.color
			#Combine behaviors EXCEPT those with BreedActions.
			behaviors = (actor.behaviors + target.behaviors).find_all do |behavior|
				! behavior.actions.any?{|action| action.is_a?(BreedAction)}
			end
			behaviors.each {|behavior| child.behaviors << behavior.copy}
			#Location should equal actor's.
			child.location = actor.location.copy
			#Add parents' vectors to get child's vector.
			child.vector = actor.vector + target.vector
			#Child's size should be half the average size of the parents'.
			child.size = ((actor.size + target.size) / 2) / 2
			#Add child to environment.
			@environment.objects << child
			#Reset elapsed time.
			@time_since_last_action = 0
		end
	end
end


#Copies the given GameObject prototypes into the environment.
class SpawnAction < Action
	#Environment to place children into.
	attr_accessor :environment
	#Array of GameObjects to copy into environment.
	attr_accessor :prototypes
	def initialize(environment, prototypes = [])
		self.environment = environment
		self.prototypes = prototypes
	end
	#Add children to environment.
	def do(actor, targets)
		prototypes.each do |prototype|
			environment.objects << generate_child(actor, prototype)
		end
	end
	#Copy prototype to actor's location.
	def generate_child(actor, prototype)
		#Copy prototype so it can be spawned repeatedly if need be.
		child = prototype.copy
		child.location = actor.location.copy
		child
	end
end


#Copies the given GameObject prototypes into the environment and destroys actor.
#Shrapnel's original vector will be added to actor's vector.
#Shrapnel's size will be actor's size divided by number of shrapnel pieces.
class ExplodeAction < SpawnAction
	#Calls super method.
	#Also removes actor from environment.
	def do(actor, targets)
		super
		environment.objects.delete(actor)
	end
	#Calls super method.
	#Also adds actor's vector to child's.
	#Finally, reduces child's size to actor's size divided by number of shrapnel pieces.
	def generate_child(actor, prototype)
		child = super
		child.vector += actor.vector
		child.size = actor.size / prototypes.length
		child
	end
end



#Copies the given GameObject prototypes into the environment.
#Bullet's vector angle will be added to angle to target.
class ShootAction < SpawnAction
	#Collection of GameObjects to copy into environment.
	#First element will be copied on first call, subsequent elements on subsequent calls, wrapping back to start once end is reached.
	#If an element is a collection, all its members will be copied in at once.
	attr_accessor :prototypes
	def initialize(*arguments)
		super
		@prototype_index = 0
		@target_index = 0
	end
	#Copies next prototype into environment.
	def do(actor, targets)
		return if targets.empty?
		#If next item is a collection of prototypes, copy them all in at once.
		if prototypes[@prototype_index].respond_to?(:each)
			prototypes[@prototype_index].each do |prototype|
				environment.objects << generate_child(actor, prototype, targets[@target_index])
			end
		#Otherwise copy the single prototype.
		else
			environment.objects << generate_child(actor, prototypes[@prototype_index], targets[@target_index])
		end
		#Move to next target and prototype group, wrapping to start of array if need be.
		@target_index = (@target_index + 1) % targets.length
		@prototype_index = (@prototype_index + 1) % prototypes.length
	end
	#Calls super method.
	#Also adds angle to target to child's vector angle.
	def generate_child(actor, prototype, target)
		child = super(actor, prototype)
		child.vector.pitch = Utility.find_angle(actor.location, target.location) + child.vector.pitch
		child
	end
end



end #module Zyps
