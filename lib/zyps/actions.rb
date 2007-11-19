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
	def start(actor, target)
		super
		@clock.reset_elapsed_time
	end
	
	#Halt tracking time between actions.
	def stop(actor, target)
		super
		@clock.reset_elapsed_time
	end
	
end


#Head toward a target.
class FaceAction < Action
	#Set the actor's heading to point directly at target.
	def do(actor, target)
		actor.vector.pitch = Utility.find_angle(actor.location, target.location)
	end
end


#Increase/decrease speed over time.
class AccelerateAction < TimedAction
	#Units per second to accelerate.
	#Can be negative to slow down or go in reverse.
	attr_accessor :rate
	#Increase or decrease speed according to elapsed time.
	def do(actor, target)
		actor.vector.speed += delta
	end
end


#Turn over time.
class TurnAction < TimedAction
	#Degrees per second to turn.
	#Positive turns clockwise, negative turns counter-clockwise.
	attr_accessor :rate
	#Turn according to elapsed time.
	def do(actor, target)
		actor.vector.pitch += delta
	end
end


#Approaches the target, but obeys law of inertia.
class ApproachAction < TimedAction
	#Accelerate toward the target, but limited by rate.
	def do(actor, target)
		#Apply thrust to the creature's movement vector, adjusted by elapsed time.
		actor.vector += Vector.new(
			delta,
			Utility.find_angle(actor.location, target.location)
		)
	end
end


#Flees from the target, but obeys law of inertia.
class FleeAction < TimedAction
	#Accelerate away from the target, but limited by turn rate.
	def do(actor, target)
		#Apply thrust to the creature's movement vector, adjusted by elapsed time.
		actor.vector += Vector.new(
			delta,
			Utility.find_angle(actor.location, target.location) + 180
		)
	end
end


#Destroy the target.
class DestroyAction < Action
	#The environment to remove objects from.
	attr_accessor :environment
	def initialize(environment)
		self.environment = environment
	end
	#Remove the target from the environment.
	def do(actor, target)
		@environment.objects.delete(target)
	end
end


#Destroy the target and grow in size.
class EatAction < DestroyAction
	#Remove the target from the environment, and increase actor's size by size of target.
	def do(actor, target)
		#Grow in size.
		actor.size += target.size
		#Remove the target from the environment.
		super
	end
end


#Add a tag to the target.
class TagAction < Action
	#Tag to apply to target.
	attr_accessor :tag
	def initialize(tag)
		self.tag = tag
	end
	#Apply the given tag to the target.
	def do(actor, target)
		target.tags << tag unless target.tags.include?(tag)
	end
end


#Blend the target's color with another color.
class BlendAction < Action
	#Color to apply to target.
	attr_accessor :color
	def initialize(color)
		self.color = color
	end
	#Blend the target's color with the assigned color.
	def do(actor, target)
		target.color += @color
	end
end


#Pushes target away.
class PushAction < TimedAction
	#Units/second to accelerate target by.
	attr_accessor :rate
	#Accelerate the target away from the actor, but limited by elapsed time.
	def do(actor, target)
		#Angle to target is also angle of push force.
		push_angle = Utility.find_angle(actor.location, target.location)
		#Acceleration will be limited by elapsed time.
		push_force = delta
		#Apply the force to the creature's movement vector.
		target.vector += Vector.new(push_force, push_angle)
	end
end


#Pulls target toward actor.
class PullAction < TimedAction
	#Units/second to accelerate target by.
	attr_accessor :rate
	#Accelerate away from the target, but limited by turn rate.
	def do(actor, target)
		#Angle from target to actor is also angle of pull force (opposite of that for push).
		pull_angle = Utility.find_angle(target.location, actor.location)
		#Acceleration will be limited by elapsed time.
		pull_force = delta
		#Apply the force to the creature's movement vector.
		target.vector += Vector.new(pull_force, pull_angle)
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
	def do(actor, target)
		#Skip action if target is not a Creature.
		return unless target.is_a?(Creature)
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


end #module Zyps
