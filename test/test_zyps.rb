require 'zyps'
require 'test/unit'


class TestCreature < Test::Unit::TestCase


	def test_default_initialization
		creature = Creature.new
		assert_equal(0, creature.location.x)
		assert_equal(0, creature.location.y)
		assert_equal(1, creature.color.red)
		assert_equal(1, creature.color.green)
		assert_equal(1, creature.color.blue)
		assert_equal(0, creature.vector.speed)
		assert_equal(0, creature.vector.pitch)
		assert_equal(nil, creature.name)
		assert_in_delta(0, creature.age, 0.1)
		assert_equal([], creature.tags)
	end
	
	
	def test_explicit_initialization
		creature = Creature.new(
			"name",
			Location.new(10, -3),
			Color.new(0.5, 0.6, 0.7),
			Vector.new(1.5, 225),
			2.001, #Age.
			["predator", "blue team"]
		)
		assert_equal("name", creature.name)
		assert_equal(10, creature.location.x)
		assert_equal(-3, creature.location.y)
		assert_equal(0.5, creature.color.red)
		assert_equal(0.6, creature.color.green)
		assert_equal(0.7, creature.color.blue)
		assert_equal(1.5, creature.vector.speed)
		assert_equal(225, creature.vector.pitch)
		assert_in_delta(2.001, creature.age, 0.01)
		assert(creature.tags.include?("predator"))
		assert(creature.tags.include?("blue team"))
	end
	
	
end



class TestEnvironment < Test::Unit::TestCase

	def setup
	
		#Interactions will be logged here.
		@interactions = []
		
		#Create creatures.
		creature1 = Creature.new('1')
		creature2 = Creature.new('2')
		creature_behavior = Behavior.new
		creature_behavior.actions << lambda {|target| @interactions << "Targeting #{target.name}"}
		creature1.behaviors << creature_behavior
		creature2.behaviors << creature_behavior
		
		#Create an environment and add the creatures.
		@environment = Environment.new([creature1, creature2])
		
	end
	
	
	def test_interactions
	
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(@interactions.find_all{|i| i == "Targeting 1"}.length == 1)
		assert(@interactions.find_all{|i| i == "Targeting 2"}.length == 1)
		
	end
	
	
	def test_environmental_factors
	
		#Create an environmental factor.
		behavior = Behavior.new
		behavior.actions << lambda {|target| @interactions << "Environment targeting #{target.name}"}
		@environment.environmental_factors << EnvironmentalFactor.new([behavior])
		
		#Have environment elements interact.
		@environment.interact

		#Look for expected interactions (each should only occur once).
		assert(@interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(@interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		
	end
	
	
	def test_conditions
	
		#Change behaviors to only occur if the target's name is '2'.
		@environment.objects.each do |creature|
			behavior = Behavior.new
			behavior.conditions << lambda do |target|
				return true if creature.name == '1' and target.name == '2'
			end
			behavior.actions << lambda do |target|
				@interactions << "#{creature.name} is targeting #{target.name}"
			end
			creature.behaviors << behavior
		end
		
		#Have environment elements interact.
		@environment.interact

		#Creature '1' should not have been acted on.
		assert(@interactions.find_all{|i| i == "2 is targeting 1"}.length == 0)
		#Creature '2' *should* have been acted on.
		assert(@interactions.find_all{|i| i == "1 is targeting 2"}.length == 1)
		
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
		
		vector = Vector.new
		vector.x = 1
		vector.y = 1
		assert_in_delta(1.4142, vector.speed, 0.001)
		assert_in_delta(45, vector.pitch, 0.001)
		
	end
	
	
end



class TestClock < Test::Unit::TestCase


	def test_elapsed_time
	
		#Create a clock, wait a moment, then see how much time has elapsed since its creation.
		clock = Clock.new
		sleep 0.1
		assert_in_delta(0.1, clock.elapsed_time, 0.02)
		
	end
	
	
end



class TestUtility < Test::Unit::TestCase
	
	
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
	
	
	def test_get_angle_to_location
		origin = Location.new(0, 0)
		assert_in_delta(0, Utility.get_angle_to_location(origin, Location.new(1,0)), 0.001)
		assert_in_delta(90, Utility.get_angle_to_location(origin, Location.new(0,1)), 0.001)
		assert_in_delta(45, Utility.get_angle_to_location(origin, Location.new(1,1)), 0.001)
		assert_in_delta(135, Utility.get_angle_to_location(origin, Location.new(-1,1)), 0.001)
		assert_in_delta(225, Utility.get_angle_to_location(origin, Location.new(-1,-1)), 0.001)
		assert_in_delta(315, Utility.get_angle_to_location(origin, Location.new(1,-1)), 0.001)
	end

	
end


# c:\work\zyps\source\net\sourceforge\zyps\actions\accelerateaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\approachaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\changecoloraction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\changeopacityaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\destroyaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\fleeaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\followinputdeviceaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\mateaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\reviveaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\spawnaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\tagaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\turnaction.java
# c:\work\zyps\source\net\sourceforge\zyps\behavior.java
# c:\work\zyps\source\net\sourceforge\zyps\clock.java
# c:\work\zyps\source\net\sourceforge\zyps\color.java
# c:\work\zyps\source\net\sourceforge\zyps\conditions
# c:\work\zyps\source\net\sourceforge\zyps\conditions\agecondition.java
# c:\work\zyps\source\net\sourceforge\zyps\conditions\condition.java
# c:\work\zyps\source\net\sourceforge\zyps\conditions\nocondition.java
# c:\work\zyps\source\net\sourceforge\zyps\conditions\proximitycondition.java
# c:\work\zyps\source\net\sourceforge\zyps\conditions\tagcondition.java
# c:\work\zyps\source\net\sourceforge\zyps\creature.java
# c:\work\zyps\source\net\sourceforge\zyps\environment.java
# c:\work\zyps\source\net\sourceforge\zyps\environmentalfactors
# c:\work\zyps\source\net\sourceforge\zyps\environmentalfactors\boundary.java
# c:\work\zyps\source\net\sourceforge\zyps\environmentalfactors\environmentalfactor.java
# c:\work\zyps\source\net\sourceforge\zyps\environmentalfactors\populationcontroller.java
# c:\work\zyps\source\net\sourceforge\zyps\gameobject.java
# c:\work\zyps\source\net\sourceforge\zyps\generators
# c:\work\zyps\source\net\sourceforge\zyps\generators\randomcreaturegenerator.java
# c:\work\zyps\source\net\sourceforge\zyps\generators\rolegenerator.java
# c:\work\zyps\source\net\sourceforge\zyps\inputdevicelocation.java
# c:\work\zyps\source\net\sourceforge\zyps\location.java
# c:\work\zyps\source\net\sourceforge\zyps\main.java
# c:\work\zyps\source\net\sourceforge\zyps\simulation.java
# c:\work\zyps\source\net\sourceforge\zyps\tag.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\demonstration.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\rolemanager.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\selectionpanel.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\userinterface.java
# c:\work\zyps\source\net\sourceforge\zyps\velocity.java
# c:\work\zyps\source\net\sourceforge\zyps\views
# c:\work\zyps\source\net\sourceforge\zyps\views\basicgraphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\debuggraphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\graphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\panelview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\trailsgraphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\view.java
