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
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'
require 'test/unit'


include Zyps


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestGameObject < Test::Unit::TestCase


	def test_constraints
		#Test at initialization.
		object = GameObject.new(:size => -1)
		assert_equal(0, object.size)
		#Test accessors.
		object = GameObject.new
		object.size = -1
		assert_equal(0, object.size)
	end


	def test_move
		#Set up moving object.
		object = GameObject.new
		object.location = Location.new(0, 0)
		object.vector = Vector.new(1.4142, 45)
		#Move for 1 second.
		object.move(1)
		#Check object moved to expected coordinates.
		assert_in_delta(1, object.location.x, 0.001)
		assert_in_delta(1, object.location.y, 0.001)
	end
	
	
	def test_copy
		object = GameObject.new
		object.vector = Vector.new(1, 1)
		object.color = Color.new(0.5, 0.5, 0.5)
		object.location = Location.new(3, 3)
		object.tags = ["1", "2"]
		object.name = "name"
		copy = object.copy
		assert_not_same(object.vector, copy.vector, "Copy's vector should not be same object.")
		assert_equal(object.vector.x, copy.vector.x, "Copy's vector should share attributes.")
		assert_not_same(object.color, copy.color, "Copy's color should not be same object.")
		assert_equal(object.color.red, copy.color.red, "Copy's color should share attributes.")
		assert_not_same(object.location, copy.location, "Copy's location should not be same object.")
		assert_equal(object.location.x, copy.location.x, "Copy's location should share attributes.")
		assert_not_same(object.tags, copy.tags, "Copy's tag list should not be same object.")
		assert_equal(object.tags[0], copy.tags[0], "Copy's tag list should share attributes.")
		assert_not_equal(object.identifier, copy.identifier, "Copy's identifier should not be identical.")
		assert_not_equal(object.name, copy.name, "Copy's name should not be identical.")
	end


end


class TestCreature < Test::Unit::TestCase


	def test_default_initialization
		creature = Creature.new
		assert_not_nil(creature.identifier)
		assert_equal(0, creature.location.x)
		assert_equal(0, creature.location.y)
		assert_equal(1, creature.color.red)
		assert_equal(1, creature.color.green)
		assert_equal(1, creature.color.blue)
		assert_equal(0, creature.vector.speed)
		assert_equal(0, creature.vector.pitch)
		assert_equal(nil, creature.name)
		assert_equal(1, creature.size)
		assert_equal([], creature.tags)
		assert_equal(0, creature.behavior_count)
		#Identifiers should be unique.
		assert_not_equal(creature.identifier, Creature.new.identifier)
	end
	
	
	def test_explicit_initialization
		behavior = Behavior.new
		creature = Creature.new(
			:name => "name",
			:location => Location.new(10, -3),
			:color => Color.new(0.5, 0.6, 0.7),
			:vector => Vector.new(1.5, 225),
			:age => 2.001,
			:size => 5.0, #Size.
			:tags => ["predator", "blue team"],
			:behaviors => [behavior]
		)
		assert_equal("name", creature.name)
		assert_equal(10, creature.location.x)
		assert_equal(-3, creature.location.y)
		assert_equal(0.5, creature.color.red)
		assert_equal(0.6, creature.color.green)
		assert_equal(0.7, creature.color.blue)
		assert_equal(1.5, creature.vector.speed)
		assert_equal(225, creature.vector.pitch)
		assert_equal(5.0, creature.size)
		assert(creature.tags.include?("predator"))
		assert(creature.tags.include?("blue team"))
		assert(creature.behaviors.include?(behavior))
	end
	
	
	def test_copy
		creature = Creature.new
		behavior1 = Behavior.new
		behavior2 = Behavior.new
		creature << behavior1 << behavior2
		copy = creature.copy
		creature.behaviors.each do |behavior|
			assert(! copy.behaviors.find {|o| o.equal?(behavior)}, "Behaviors in list should not be same objects.")
		end
	end
	
	
end



class TestEnvironment < Test::Unit::TestCase

	
	def setup
	
		#Create an environment and add creatures.
		@environment = Environment.new
		@environment.add_object(Creature.new(:name => '1'))
		@environment.add_object(Creature.new(:name => '2'))
		@environment.add_object(Creature.new(:name => '3'))
		
	end
	
	
	#An action that keeps a log of the actor and target.
	class LogAction < Action
		attr_reader :interactions
		def initialize
			#Interactions will be logged here.
			@interactions = []
		end
		def do(actor, targets)
			#Log the interaction.
			targets.each do |target|
				@interactions << "#{actor.name} targeting #{target.name}"
			end
		end
	end
	
	def test_interactions
	
		#Set up behaviors that will log interactions.
		log = LogAction.new
		@environment.objects.each do |creature|
			behavior = Behavior.new
			behavior.add_action log
			creature.add_behavior behavior
		end
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(log.interactions.find_all{|i| i == "2 targeting 1"}.length == 1)
		assert(log.interactions.find_all{|i| i == "1 targeting 2"}.length == 1)
		assert(log.interactions.find_all{|i| i == "1 targeting 1"}.length == 0)
		assert(log.interactions.find_all{|i| i == "2 targeting 2"}.length == 0)
		
	end
	
	
	#An environmental factor that logs its target.
	class LogFactor < EnvironmentalFactor
		attr_reader :interactions
		def initialize
			#Interactions will be logged here.
			@interactions = []
		end
		def act(environment)
			#Log the interaction.
			environment.objects.each {|target| @interactions << "Environment targeting #{target.name}"}
		end
	end
	
	def test_environmental_factors
	
		#Create an environmental factor.
		logger = LogFactor.new
		@environment.add_environmental_factor(logger)
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(logger.interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(logger.interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		
	end
	
	
	#A condition that is false unless actor and target have specific names.
	class NameCondition < Condition
		def select(actor, targets)
			targets.find_all {|target| actor.name == '1' and target.name == '2'}
		end
	end
	
	def test_conditions
	
		#Set up behavior that will log interactions.
		behavior = Behavior.new
		log = LogAction.new
		behavior.add_action log
		name_checker = NameCondition.new
		behavior.add_condition name_checker
		@environment.objects.each {|creature| creature.add_behavior behavior}
				
		#Have environment elements interact.
		@environment.interact

		assert_equal(0, log.interactions.find_all{|i| i == "2 targeting 1"}.length, "Creature '1' should NOT have been acted on.")
		assert_equal(1, log.interactions.find_all{|i| i == "1 targeting 2"}.length, "Creature '2' SHOULD have been acted on.")
		
	end
	
	
end



class TestColor < Test::Unit::TestCase
	
	def test_default_initialization
		color = Color.new
		assert_equal(1, color.red)
		assert_equal(1, color.green)
		assert_equal(1, color.blue)
	end
	
	def test_explicit_initialization
		color = Color.new(0.25, 0.5, 0.75)
		assert_equal(0.25, color.red)
		assert_equal(0.5, color.green)
		assert_equal(0.75, color.blue)
	end
	
	def test_constraints
		#Test at initialization.
		color = Color.new(-1, -1, -1)
		assert_equal(0, color.red)
		assert_equal(0, color.green)
		assert_equal(0, color.blue)
		color = Color.new(2, 2, 2)
		assert_equal(1, color.red)
		assert_equal(1, color.green)
		assert_equal(1, color.blue)
		#Test accessors.
		color = Color.new
		color.red = -1
		assert_equal(0, color.red)
		color.red = 2
		assert_equal(1, color.red)
		color.green = -1
		assert_equal(0, color.green)
		color.green = 2
		assert_equal(1, color.green)
		color.blue = -1
		assert_equal(0, color.blue)
		color.blue = 2
		assert_equal(1, color.blue)
	end
	
	
end



class TestVector < Test::Unit::TestCase


	def test_initialize
	
		vector = Vector.new
		assert_equal(0, vector.speed)
		assert_equal(0, vector.pitch)
		assert_equal(0, vector.x)
		assert_equal(0, vector.y)
		
	end

	
	def test_angles
	
		vector = Vector.new(4, 150)
		assert_in_delta(-3.464, vector.x, 0.001)
		assert_in_delta(2, vector.y, 0.001)

		vector = Vector.new(5, 53.13)
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(4, vector.y, 0.001)

		vector = Vector.new(5, 233.13)
		assert_in_delta(-3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)

		vector = Vector.new(5, 306.87)
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)
		
		#Angles over 360 should 'wrap around' to 0.
		vector = Vector.new(5, 413.13) #360 + 53.13
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(4, vector.y, 0.001)
		
		#Negative angle should be converted to positive equivalent.
		vector = Vector.new(5, -53.13) #360 - 53.13 = 306.87
		assert_in_delta(3, vector.x, 0.001)
		assert_in_delta(-4, vector.y, 0.001)
		
	end
	
	
	def test_components
	
		vector = Vector.new(1.4142, 45)
		assert_in_delta(1, vector.x, 0.001)
		assert_in_delta(1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 135)
		assert_in_delta(-1, vector.x, 0.001)
		assert_in_delta(1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 225)
		assert_in_delta(-1, vector.x, 0.001)
		assert_in_delta(-1, vector.y, 0.001)
		
		vector = Vector.new(1.4142, 315)
		assert_in_delta(1, vector.x, 0.001)
		assert_in_delta(-1, vector.y, 0.001)
				
	end
	
	
	def test_addition
			
		vector = Vector.new(1, 45) + Vector.new(1, 45) #Same angle.
		#Speed should be sum of added vectors' speeds.
		assert_in_delta(2, vector.speed, 0.001)
		#Angle should remain the same.
		assert_in_delta(45, vector.pitch, 0.001)
		
		#Vectors of opposite angles should cancel out.
		vector = Vector.new(2, 0) + Vector.new(1, 180)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(0, vector.pitch, 0.001)
		vector = Vector.new(2, 45) + Vector.new(1, 225)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(45, vector.pitch, 0.001)
		vector = Vector.new(2, 135) + Vector.new(1, 315)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(135, vector.pitch, 0.001)
		vector = Vector.new(2, 225) + Vector.new(1, 45)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(225, vector.pitch, 0.001)
		vector = Vector.new(2, 315) + Vector.new(1, 135)
		assert_in_delta(1, vector.speed, 0.001)
		assert_in_delta(315, vector.pitch, 0.001)
		
	end
	
	
end



class TestUtility < Test::Unit::TestCase

	
	def setup
		Utility.caching_enabled = true
	end
	
	
	def test_to_radians
	
		assert_in_delta(0, Utility.to_radians(0), 0.01)
		assert_in_delta(Math::PI, Utility.to_radians(180), 0.01)
		assert_in_delta(Math::PI * 2, Utility.to_radians(359), 0.1)
		
	end

	
	def test_to_degrees
	
		assert_in_delta(0, Utility.to_degrees(0), 0.01)
		assert_in_delta(180, Utility.to_degrees(Math::PI), 0.01)
		assert_in_delta(359, Utility.to_degrees(Math::PI * 2 - 0.0001), 1)
		
	end
	
	
	def test_find_angle
		origin = Location.new(0, 0)
		assert_in_delta(0, Utility.find_angle(origin, Location.new(1,0)), 0.001)
		assert_in_delta(90, Utility.find_angle(origin, Location.new(0,1)), 0.001)
		assert_in_delta(45, Utility.find_angle(origin, Location.new(1,1)), 0.001)
		assert_in_delta(135, Utility.find_angle(origin, Location.new(-1,1)), 0.001)
		assert_in_delta(225, Utility.find_angle(origin, Location.new(-1,-1)), 0.001)
		assert_in_delta(315, Utility.find_angle(origin, Location.new(1,-1)), 0.001)
	end

	
	def test_find_distance
		origin = Location.new(0, 0)
		assert_in_delta(1, Utility.find_distance(origin, Location.new(1,0)), 0.001)
		assert_in_delta(1, Utility.find_distance(origin, Location.new(0,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(1,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(-1,1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(-1,-1)), 0.001)
		assert_in_delta(1.4142, Utility.find_distance(origin, Location.new(1,-1)), 0.001)
	end
	
	
	def test_find_reflection_angle
		assert_equal(210, Utility.find_reflection_angle(0, 150))
		assert_equal(330, Utility.find_reflection_angle(0, 30))
		assert_equal(150, Utility.find_reflection_angle(90, 30))
		assert_equal(210, Utility.find_reflection_angle(90, 330))
		assert_equal(30, Utility.find_reflection_angle(180, 330))
		assert_equal(150, Utility.find_reflection_angle(180, 210))
		assert_equal(330, Utility.find_reflection_angle(270, 210))
		assert_equal(30, Utility.find_reflection_angle(270, 150))
	end

	
	def test_collided?
		#Objects apart.
		assert(! Utility.collided?(
			GameObject.new(:location => Location.new(0, 0), :size =>0.196), #Radius = 0.25
			GameObject.new(:location => Location.new(1, 0), :size =>0.196)
		))
		#Objects touching (not a collision).
		assert(! Utility.collided?(
			GameObject.new(:location => Location.new(0, 0), :size =>0.785), #Radius = 0.5
			GameObject.new(:location => Location.new(1, 0), :size =>0.785)
		))
		#Objects collided.
		assert(Utility.collided?(
			GameObject.new(:location => Location.new(0, 0), :size =>1.766), #Radius = 0.75
			GameObject.new(:location => Location.new(1, 0), :size =>1.766)
		))
		#Objects in same place.
		assert(Utility.collided?(
			GameObject.new(:location => Location.new(0, 0)),
			GameObject.new(:location => Location.new(0, 0))
		))
	end
	
end


class TestBehavior < Test::Unit::TestCase

	#True for all targets.
	class TrueCondition < Condition
		def select(actor, targets)
			targets #Select all targets.
		end
	end
	#False for all targets.
	class FalseCondition < Condition
		def select(actor, targets)
			[] #Select no targets.
		end
	end
	
	
	def setup
		@actor = Creature.new(:name => 'actor')
		@target = Creature.new(:name => 'target')
		@other = Creature.new(:name => 'other')
		@targets = []
		@targets << @target << @other
	end
	
	
	#Tracks number of times its start, stop, and do methods are called.
	class MockAction < Action
		attr_accessor :start_count, :stop_count, :do_count
		def initialize
			@start_count, @stop_count, @do_count = 0, 0, 0
		end
		def start(actor, targets)
			super
			@start_count += 1
		end
		def do(actor, targets)
			@do_count += 1
		end
		def stop(actor, targets)
			super
			@stop_count += 1
		end
	end
	
	def test_actions
	
		#Set up a behavior with a true condition and a mock action.
		behavior = Behavior.new
		behavior.add_condition TrueCondition.new
		action = MockAction.new
		behavior.add_action action
		
		#Perform the behavior.
		behavior.perform(@actor, @targets)
		assert_equal(1, action.start_count, "start() should have been called on the mock action.")
		assert_equal(1, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Perform the behavior again.
		behavior.perform(@actor, @targets)
		assert_equal(1, action.start_count, "start() should NOT have been called.")
		assert_equal(2, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		
		#Add a false condition to the behavior.
		behavior.add_condition FalseCondition.new
		#Perform the behavior.
		behavior.perform(@actor, @targets)
		assert_equal(1, action.start_count, "start() should NOT have been called.")
		assert_equal(2, action.do_count, "do() should NOT have been called, because conditions are no longer true.")
		assert_equal(1, action.stop_count, "stop() SHOULD have been called.")
				
	end
	
	def test_copy
		original = Behavior.new
		action = TagAction.new("tag")
		original.add_action action
		condition = TagCondition.new("tag")
		original.add_condition condition
		copy = original.copy
		original.actions.each do |action|
			assert(! copy.actions.find {|a| a.equal?(action)}, "Actions in list should not be same objects.")
		end
		original.conditions.each do |condition|
			assert(! copy.conditions.find {|a| a.equal?(condition)}, "Conditions in list should not be same objects.")
		end
	end
	
	def test_no_conditions
		#Set up a behavior with no conditions.
		action = MockAction.new
		behavior = Behavior.new(:conditions => [], :actions => [action])
		#Perform the behavior with no targets.
		behavior.perform(@actor, [])
		assert_equal(1, action.start_count, "start() should have been called on the mock action.")
		assert_equal(1, action.do_count, "do() should have been called.")
		assert_equal(0, action.stop_count, "stop() should NOT have been called.")
		#Add a true condition.
		behavior.add_condition TrueCondition.new
		#Perform the behavior with no targets.
		behavior.perform(@actor, [])
		assert_equal(1, action.stop_count, "stop() should have been called.")
		#Perform the behavior WITH targets.
		behavior.perform(@actor, @targets)
		assert_equal(2, action.start_count, "start() should have been called.")
		assert_equal(2, action.do_count, "do() should have been called.")
		assert_equal(1, action.stop_count, "stop() should NOT have been called.")
	end
	
end


class TestAdditions < Test::Unit::TestCase

	#Add a new behavior to a creature with the given action.
	def add_action(action, creature)
		behavior = Behavior.new
		behavior.add_action action
		creature.add_behavior behavior
	end
	
	def setup
		@environment = Environment.new
		@actor = Creature.new(:name => 'target1', :location => Location.new(1, 1))
		@env_fact = gravity = Gravity.new(200)
	end
	
	def test_environment_double_arrow_objects
		assert_equal(0, @environment.object_count)
		@environment << @actor
		assert_equal(1, @environment.object_count)
		assert_equal(0, @environment.environmental_factor_count)
	end
	
	def test_environment_double_arrow_factors
		assert_equal(0, @environment.environmental_factor_count)
		@environment << @env_fact
		assert_equal(1, @environment.environmental_factor_count)
		assert_equal(0, @environment.object_count)
	end

	def test_game_object_double_arrow
		#test color
		@actor << Color.new(1,1,1)
		assert_equal(Color.new(1,1,1), @actor.color)
		#test vector
		vect =Vector.new(23,13)
		@actor << vect
		assert_equal(vect, @actor.vector)
		#test location
		@actor << Location.new(13,13)
		assert_equal(13, @actor.location.x)
		assert_equal(13, @actor.location.y)
		#test behavior
		behavior = Behavior.new
		behavior.add_action TagAction.new("1")
		@actor << behavior
		assert_equal(1, @actor.behavior_count)
		assert(
			@actor.behaviors.find do |behavior|
				behavior.actions.find {|action| action.tag == "1"}
			end
		)
	end
	
end
