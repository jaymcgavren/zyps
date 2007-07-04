require 'zyps'
require 'test/unit'

class TestCreature < Test::Unit::TestCase
	def test_creation
		creature = Creature.new
		assert_equal(0, creature.location.x)
		assert_equal(0, creature.location.y)
		assert_equal(0, creature.location.z)
		assert_equal(1, creature.color.red)
		assert_equal(1, creature.color.green)
		assert_equal(1, creature.color.blue)
		assert_equal(0, creature.vector.speed)
		assert_equal(0, creature.vector.pitch)
		assert_equal(0, creature.vector.yaw)
		assert_equal(nil, creature.name)
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

		#Test results.
		assert(interactions.find_all{|i| i == "Environment targeting 1"}.length == 1)
		assert(interactions.find_all{|i| i == "Environment targeting 2"}.length == 1)
		assert(interactions.find_all{|i| i == "Targeting 1"}.length == 1)
		assert(interactions.find_all{|i| i == "Targeting 2"}.length == 1)
		
	end
	
end

class TestTrailsView < Test::Unit::TestCase

	WIDTH = 400
	HEIGHT = 300
	
	def test_render
	
		view = TrailsView.new(WIDTH, HEIGHT)
	
		#Create a window, and set program up to quit when it is closed.
		window = Gtk::Window.new
		window.signal_connect("delete_event") {false}
		window.signal_connect("destroy") {Gtk.main_quit}
		
		#Add view to window.
		window.add(view.canvas)
		window.show_all
		
		#Create environment with objects.
		environment = Environment.new(
			[
				Creature.new(nil, Location.new(10, 10, 0), Color.new(1, 0, 0)),
				Creature.new(nil, Location.new(40, 40, 0), Color.new(0, 1, 0))
			]
		)
		
		thread = Thread.new do
			loop do
				view.render(environment.objects)
			end
		end
		
		Gtk.main
		
	end
	
end