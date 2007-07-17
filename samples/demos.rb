require 'zyps'
require 'zyps/views/trails'
require 'test/unit'


class TestTrailsView < Test::Unit::TestCase


	WIDTH = 400
	HEIGHT = 300
	FRAME_COUNT = 40

	
	def setup
	
		#Create a window, and set GTK up to quit when it is closed.
		@window = Gtk::Window.new
		@window.signal_connect("delete_event") {false}
		@window.signal_connect("destroy") {Gtk.main_quit}
		
		#Add view to window.
		@view = TrailsView.new(WIDTH, HEIGHT)
		@window.add(@view.canvas)
		@window.show_all
		
		#Create environment with objects.
		@environment = Environment.new
		
	end
	
	
	def teardown
		Gtk.main
	end

	
	def animate(frame_count)
		begin
			(1..frame_count).each do |i|
				@view.render(@environment.objects)
				@environment.interact
				sleep 1.0 / 60.0
			end
		rescue Exception => exception
			puts exception, exception.backtrace
		end
	end
	
	
	def populate(environment, count = 50)
		count.times do |i|
			multiplier = i / count.to_f
			environment.objects << Creature.new(
				i,
				Location.new(multiplier * @view.width, multiplier * @view.height),
				Color.new(multiplier, 1 - multiplier, multiplier / 2 + 0.5),
				Vector.new(100 * multiplier, multiplier * 360)
			)
		end
	end
	
	
	def test_render
	
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(1, 0, 0), Vector.new(10, 45))
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(0, 1, 0), Vector.new(20, 135))
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(0, 0, 1), Vector.new(30, 225))
		populate(@environment)
		
		thread = Thread.new do
		
			#Test rendering.
			animate(FRAME_COUNT)
			
			#Change view size and widen trails.
			@view.width += 100
			@view.height += 100
			@view.trail_width = 10
			@view.trail_length = 10
			
			#Test at new size.
			animate(FRAME_COUNT)
			
		end
				
	end
	
	
	def test_environmental_factors
	
		populate(@environment)
		
		thread = Thread.new do
		
			#Test normally.
			animate(10)
			
			#Add gravity.
			gravity = EnvironmentalFactor.new
			accelerate = Behavior.new
			accelerate.actions << lambda {|gravity, target| target.vector.y += 9.8}
			gravity.behaviors << accelerate
			@environment.environmental_factors << gravity
			
			#Test again with gravity.
			animate(20)
			
		end
				
	end
	
	
	def test_behaviors
	
		populate(@environment, 50)
		
		#Add target and have all creatures chase it.
		@environment.objects.each do |creature|
			chase = Behavior.new
			chase.conditions << lambda {|creature, target| target.tags.include?('food')}
			chase.conditions << lambda {|creature, target| Utility.find_distance(creature.location, target.location) > 100}
			chase.actions << lambda do |creature, target|
				angle_to_target = Utility.find_angle(creature.location, target.location)
				creature.vector.pitch = angle_to_target
			end
			creature.behaviors << chase
		end
		@environment.objects << Creature.new(
			"target",
			Location.new(@view.width / 2, @view.height / 2),
			Color.new(1, 1, 1),
			Vector.new(3, 0),
			0, #Age.
			["food"] #Tags.
		)
			
		thread = Thread.new {animate(FRAME_COUNT)}
		
	end
	
	
	class Morpher < Creature
		def initialize(*arguments)
			super
			@behaviors << Behavior.new(
				[
					lambda do |creature, target|
						target.color.red += 0.1 if target.color.red < creature.color.red
						target.color.green += 0.1 if target.color.green < creature.color.green
						target.color.blue += 0.1 if target.color.blue < creature.color.blue
					end
				],
				[
					lambda {|creature, target| creature.color < target.color},
					lambda {|creature, target| Utility.find_distance(creature.location, target.location) < 25}
				]
			)
		end
	end
	
	def test_change_color

		populate(@environment)
		
		@environment.objects << Morpher.new(nil, Location.new(0, 100), Color.new(1, 0, 0), Vector.new(100, 0))
		@environment.objects << Morpher.new(nil, Location.new(0, 150), Color.new(0, 1, 0), Vector.new(200, 0))
		@environment.objects << Morpher.new(nil, Location.new(0, 200), Color.new(0, 0, 1), Vector.new(300, 0))
		
		thread = Thread.new {animate(FRAME_COUNT)}
				
	end
	
	
	def test_accelerate
	
		populate(@environment)
		
		#Keep a separate clock for each object.
		clocks = Hash.new {|h, k| h[k] = Clock.new}
		accelerate = Behavior.new
		accelerate.actions << lambda do |creature, target|
			#Accelerate the appropriate amount for the elapsed time.
			creature.vector.speed += 100 * clocks[creature].elapsed_time
		end
		
		#Add behavior to creatures.
		@environment.objects.each {|creature| creature.behaviors << accelerate}
		
		thread = Thread.new {animate(FRAME_COUNT)}
		
	end
	
	
	def test_turn
	
		populate(@environment, 20)
		
		#Keep a separate clock for each object.
		clocks = Hash.new {|h, k| h[k] = Clock.new}
		#Create a behavior.
		turn = Behavior.new
		turn.actions << lambda do |creature, target|
			#Turn the appropriate amount for the elapsed time.
			creature.vector.pitch += 100 * clocks[creature].elapsed_time
		end
		
		#Add behavior to creatures.
		@environment.objects.each {|creature| creature.behaviors << turn}
		
		thread = Thread.new {animate(FRAME_COUNT)}
		
	end
	
	
	def test_approach
	
		populate(@environment, 20)
		
		#Keep a separate heading for each object.
		headings = Hash.new {|h, k| h[k] = Vector.new(k.vector.speed, k.vector.pitch)}
		
		#Create a behavior.
		max_turn_angle = 20
		approach = Behavior.new
		approach.actions << lambda do |creature, target|
		
			#Find the difference between the current heading and the angle to the target.
			turn_angle = Utility.find_angle(creature.location, target.location) - headings[creature].pitch
			
			#If the angle is the long way around from the current heading, change it to the smaller angle.
			if turn_angle > 180 then
				turn_angle -= 360.0
			elsif turn_angle < -180 then
				turn_angle += 360.0
			end
			
			#If turn angle is greater than allowed turn speed, reduce it.
			turn_angle = Utility.constrain_value(turn_angle, max_turn_angle)
			
			#Turn the appropriate amount for the elapsed time.
			headings[creature].pitch += turn_angle
			
			#Apply the heading to the creature's movement vector.
			creature.vector += headings[creature]
			
		end
		
		#Target only the creature's prey.
		approach.conditions << lambda do |creature, target|
			target.tags.include?('prey')
		end
		
		#Add behavior to creatures.
		@environment.objects.each {|creature| creature.behaviors << approach}
		
		#Add a target.
		@environment.objects << Creature.new(
			"target",
			Location.new(@view.width / 2, @view.height / 2),
			Color.new(1, 1, 1),
			Vector.new(3, 0),
			0, #Age.
			["prey"] #Tags.
		)
		
		thread = Thread.new {animate(FRAME_COUNT)}
		
	end
	
	
	def test_flee
	
		populate(@environment, 20)
		
		#Keep a separate heading for each object.
		headings = Hash.new {|h, k| h[k] = Vector.new(k.vector.speed, k.vector.pitch)}
		
		#Create a behavior.
		max_turn_angle = 20
		flee = Behavior.new
		flee.actions << lambda do |creature, target|
		
			#Find the difference between the current heading and the angle AWAY from the target.
			turn_angle = Utility.find_angle(creature.location, target.location) - headings[creature].pitch + 180
			
			#If the angle is the long way around from the current heading, change it to the smaller angle.
			if turn_angle > 180 then
				turn_angle -= 360.0
			elsif turn_angle < -180 then
				turn_angle += 360.0
			end
			
			#If turn angle is greater than allowed turn speed, reduce it.
			turn_angle = Utility.constrain_value(turn_angle, max_turn_angle)
			
			#Turn the appropriate amount for the elapsed time.
			headings[creature].pitch += turn_angle
			
			#Apply the heading to the creature's movement vector.
			creature.vector += headings[creature]
			
		end
		
		#Flee from only the creature's predator.
		flee.conditions << lambda do |creature, target|
			target.tags.include?('predator')
		end
		
		#Add behavior to creatures.
		@environment.objects.each {|creature| creature.behaviors << flee}
		
		#Add a target.
		@environment.objects << Creature.new(
			"lion",
			Location.new(@view.width / 2, @view.height / 2),
			Color.new(1, 1, 1),
			Vector.new(3, 0),
			0, #Age.
			["predator"] #Tags.
		)
		
		thread = Thread.new {animate(FRAME_COUNT)}
		
	end
	
	
	class Destroy < Behavior
		#Environment from which targets will be removed.
		attr_accessor :environment
		def initialize(actions = [], conditions = [], environment = Environment.new)
			super(actions, conditions)
			@environment = environment
			#"Kill" target.
			self.actions << lambda do |creature, target|
				@environment.objects.delete(target)
			end
			#Act only if target is close.
			self.conditions << lambda do |creature, target|
				Utility.find_distance(creature.location, target.location) < 25
			end
		end
	end
	
	def test_destroy
		populate(@environment)
		destroy = Destroy.new
		destroy.environment = @environment
		@environment.objects << Creature.new(nil, Location.new(0, 150), Color.new(0, 1, 0), Vector.new(200, 0), 0, [], [destroy])
		thread = Thread.new {animate(FRAME_COUNT)}
	end
	
	
end


# c:\work\zyps\source\net\sourceforge\zyps\actions\followinputdeviceaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\mateaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\spawnaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\tagaction.java
# c:\work\zyps\source\net\sourceforge\zyps\environmentalfactors\boundary.java
# c:\work\zyps\source\net\sourceforge\zyps\generators\randomcreaturegenerator.java
# c:\work\zyps\source\net\sourceforge\zyps\generators\rolegenerator.java
# c:\work\zyps\source\net\sourceforge\zyps\inputdevicelocation.java
# # c:\work\zyps\source\net\sourceforge\zyps\simulation.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\demonstration.java
# c:\work\zyps\source\net\sourceforge\zyps\userinterfaces\selectionpanel.java
# c:\work\zyps\source\net\sourceforge\zyps\views\basicgraphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\views\debuggraphicview.java
# c:\work\zyps\source\net\sourceforge\zyps\main.java
