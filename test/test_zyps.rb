require 'zyps'
require 'zyps/views/trails'
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

	def test_interact
	
		#Interactions will be logged here.
		interactions = []
		
		#Create creatures.
		creature1 = Creature.new('1')
		creature2 = Creature.new('2')
		creature_behavior = Behavior.new([lambda {|target| interactions << "Targeting #{target.name}"}])
		creature1.behaviors << creature_behavior
		creature2.behaviors << creature_behavior
		
		#Create an environmental factor.
		environment_behavior = Behavior.new([lambda {|target| interactions << "Environment targeting #{target.name}"}])
		environmental_factor = EnvironmentalFactor.new([environment_behavior])
		
		#Create an environment and have its elements interact.
		environment = Environment.new([creature1, creature2], [environmental_factor])
		environment.interact

		#Look for expected interactions (each should only occur once).
		assert(interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		assert(interactions.find_all{|i| i == "Targeting 1"}.length == 1)
		assert(interactions.find_all{|i| i == "Targeting 2"}.length == 1)
		
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
	def test_to_radians
		vector = Vector.new
		assert_in_delta(0, vector.to_radians(0), 0.01)
		assert_in_delta(Math::PI, vector.to_radians(180), 0.01)
		assert_in_delta(Math::PI * 2, vector.to_radians(359), 0.1)
	end
	def test_to_degrees
		vector = Vector.new
		assert_in_delta(0, vector.to_degrees(0), 0.01)
		assert_in_delta(180, vector.to_degrees(Math::PI), 0.01)
		assert_in_delta(359, vector.to_degrees(Math::PI * 2 - 0.0001), 1)
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


class TestTrailsView < Test::Unit::TestCase

	WIDTH = 400
	HEIGHT = 300
	
	def test_render
	
		#Create a window, and set program up to quit when it is closed.
		window = Gtk::Window.new
		window.signal_connect("delete_event") {false}
		window.signal_connect("destroy") {Gtk.main_quit}
		
		#Add view to window.
		view = TrailsView.new(WIDTH, HEIGHT)
		window.add(view.canvas)
		window.show_all
		
		#Create environment with objects.
		environment = Environment.new
		environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(1, 0, 0), Vector.new(10, 45))
		environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(0, 1, 0), Vector.new(20, 135))
		environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(0, 0, 1), Vector.new(30, 225))
		i = 0
		while i < 1 do
			environment.objects << Creature.new(
				i,
				Location.new(WIDTH * i, HEIGHT * i),
				Color.new(i, 1 - i, i / 2 + 0.5),
				Vector.new(100 * i, i * 360)
			)
			i += 0.01
		end
		
		
		thread = Thread.new do
		
			animate = lambda do |i|
				view.render(environment.objects)
				environment.interact
			end
			
			(1..40).each {|i| animate.call(i)}
			
			#Change view size and widen trails.
			view.width += 100
			view.height += 100
			view.trail_width = 10
			view.trail_length = 10
			(1..40).each {|i| animate.call(i)}
			
			#Add gravity.
			gravity = EnvironmentalFactor.new
			accelerate = Behavior.new
			accelerate.add_action {|target| target.vector.y += 9.8}
			gravity.behaviors << accelerate
			environment.environmental_factors << gravity
			(1..40).each {|i| animate.call(i)}
			
		end
		
#TODO: Re-enable!
		Gtk.main
		
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
