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


#Head toward a target.
class FaceAction < Action
	#Set the actor's heading to point directly at target.
	def do(actor, target)
		actor.vector.pitch = Utility.find_angle(actor.location, target.location)
	end
end

#Increase/decrease speed over time.
class AccelerateAction < Action
	#Units per second to accelerate.
	#Can be negative to slow down or go in reverse.
	attr_accessor :rate
	def initialize(rate = 0)
		self.rate = rate
		@clock = Clock.new
	end
	#Increase or decrease speed according to elapsed time.
	def do(actor, target)
		actor.vector.speed += @clock.elapsed_time * rate
	end
end


#Turn over time.
class TurnAction < Action
	#Degrees per second to turn.
	#Positive turns clockwise, negative turns counter-clockwise.
	attr_accessor :rate
	def initialize(rate = 0)
		self.rate = rate
		@clock = Clock.new
	end
	#Turn according to elapsed time.
	def do(actor, target)
		actor.vector.pitch += @clock.elapsed_time * rate
	end
end


#Approaches the target, but obeys law of inertia.
class ApproachAction < Action
	#Direction/speed actor is accelerating in.
	attr_accessor :heading
	#Degrees per second the direction of acceleration can change.
	attr_accessor :turn_rate
	def initialize(heading = Vector.new, turn_rate = 360)
		self.heading, self.turn_rate = heading, turn_rate
		@clock = Clock.new
	end
	#Accelerate toward the target, but limited by turn rate.
	def do(actor, target)
		#Find the difference between the current heading and the angle to the target.
		turn_angle = Utility.find_angle(actor.location, target.location) - @heading.pitch
		#If the angle is the long way around from the current heading, change it to the smaller angle.
		if turn_angle > 180 then
			turn_angle -= 360.0
		elsif turn_angle < -180 then
			turn_angle += 360.0
		end
		#The creature can only turn as fast as the elapsed time, of course.
		maximum_turn = turn_rate * @clock.elapsed_time
		if turn_angle.abs > maximum_turn
			if turn_angle > 0
				turn_angle = maximum_turn
			else
				turn_angle = maximum_turn * -1
			end
		end
		#Turn the appropriate amount.
		@heading.pitch += turn_angle
		#Apply the heading to the creature's movement vector.
		actor.vector += @heading
	end
end


#Flees from the target, but obeys law of inertia.
class FleeAction < Action
	#Direction/speed actor is accelerating in.
	attr_accessor :heading
	#Degrees per second the direction of acceleration can change.
	attr_accessor :turn_rate
	def initialize(heading = Vector.new, turn_rate = 360)
		self.heading, self.turn_rate = heading, turn_rate
		@clock = Clock.new
	end
	#Accelerate away from the target, but limited by turn rate.
	def do(actor, target)
		#Find the difference between the current heading and the angle to the target.
		turn_angle = Utility.find_angle(actor.location, target.location) - @heading.pitch + 180
		#If the angle is the long way around from the current heading, change it to the smaller angle.
		if turn_angle > 180 then
			turn_angle -= 360.0
		elsif turn_angle < -180 then
			turn_angle += 360.0
		end
		#The creature can only turn as fast as the elapsed time, of course.
		maximum_turn = turn_rate * @clock.elapsed_time
		if turn_angle.abs > maximum_turn
			if turn_angle > 0
				turn_angle = maximum_turn
			else
				turn_angle = maximum_turn * -1
			end
		end
		#Turn the appropriate amount.
		@heading.pitch += turn_angle
		#Apply the heading to the creature's movement vector.
		actor.vector += @heading
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
		#Remove the target from the environment.
		super
		#Grow in size.
		actor.size += target.size
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
