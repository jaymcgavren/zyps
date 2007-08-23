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
	def do(actor, target)
		actor.vector.pitch += @clock.elapsed_time * rate
	end
end


#Approaches the target, but obeys law of inertia.
class ApproachAction < Action
	def initialize(heading = Vector.new)
		@heading = heading
		@clock = Clock.new
	end
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
		turn_angle = turn_angle * (@clock.elapsed_time * 5)
		#Turn the appropriate amount.
		@heading.pitch += turn_angle
		#Apply the heading to the creature's movement vector.
		actor.vector += @heading
	end
end


#Flees from the target, but obeys law of inertia.
class FleeAction < Action
	def initialize(heading = Vector.new)
		@heading = heading
		@clock = Clock.new
	end
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
		turn_angle = turn_angle * (@clock.elapsed_time * 5)
		#Turn the appropriate amount.
		@heading.pitch += turn_angle
		#Apply the heading to the creature's movement vector.
		actor.vector += @heading
	end
end


#Destroy the target.
class DestroyAction < Action
	def initialize(environment)
		@environment = environment
	end
	def do(actor, target)
		#Remove the target from the environment.
		@environment.objects.delete(target)
	end
end


#Destroy the target and grow in size.
class EatAction < DestroyAction
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
	def do(actor, target)
		target.color += @color
	end
end
