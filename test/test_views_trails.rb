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
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(1, 0, 0), Vector.new(10, 45))
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(0, 1, 0), Vector.new(20, 135))
		@environment.objects << Creature.new(nil, Location.new(@view.width/2, @view.height/2), Color.new(0, 0, 1), Vector.new(30, 225))
		i = 0
		while i < 1 do
			@environment.objects << Creature.new(
				i,
				Location.new(@view.width * i, @view.height * i),
				Color.new(i, 1 - i, i / 2 + 0.5),
				Vector.new(100 * i, i * 360)
			)
			i += 0.01
		end
		
	end
	
	
	def teardown
		Gtk.main
	end

	
	def animate(frame_count)
		begin
			(1..frame_count).each do |i|
				@view.render(@environment.objects)
				@environment.interact
			end
		rescue Exception => exception
			puts exception
		end
	end
	
	
	def test_render
	
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
	
		thread = Thread.new do
		
			#Test normally.
			animate(10)
			
			#Add gravity.
			gravity = EnvironmentalFactor.new
			accelerate = Behavior.new
			accelerate.actions << lambda {|target| target.vector.y += 9.8}
			gravity.behaviors << accelerate
			@environment.environmental_factors << gravity
			
			#Test again with gravity.
			animate(20)
			
		end
				
	end
	
	
	def test_behaviors
	
		#Add target and have all creatures chase it.
		@environment.objects.each do |creature|
			chase = Behavior.new
			chase.conditions << lambda {|target| target.tags.include?('food')}
			chase.conditions << lambda {|target| Utility.find_distance(creature.location, target.location) > 100}
			chase.actions << lambda do |target|
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
			super(*arguments)
			@behaviors << Behavior.new(
				[
					lambda do |target|
						target.color.red += 0.1 if target.color.red < self.color.red
						target.color.green += 0.1 if target.color.green < self.color.green
						target.color.blue += 0.1 if target.color.blue < self.color.blue
					end
				],
				[
					lambda {|target| self.color < target.color},
					lambda {|target| Utility.find_distance(self.location, target.location) < 25}
				]
			)
		end
	end
	
	def test_change_color

		@environment.objects << Morpher.new(nil, Location.new(0, 100), Color.new(1, 0, 0), Vector.new(100, 0))
		@environment.objects << Morpher.new(nil, Location.new(0, 150), Color.new(0, 1, 0), Vector.new(200, 0))
		@environment.objects << Morpher.new(nil, Location.new(0, 200), Color.new(0, 0, 1), Vector.new(300, 0))
		
		thread = Thread.new {animate(FRAME_COUNT)}
				
	end
	
	
end


# # c:\work\zyps\source\net\sourceforge\zyps\actions\accelerateaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\approachaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\changecoloraction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\destroyaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\fleeaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\followinputdeviceaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\mateaction.java
# c:\work\zyps\source\net\sourceforge\zyps\actions\reviveaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\spawnaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\tagaction.java
# # c:\work\zyps\source\net\sourceforge\zyps\actions\turnaction.java
# c:\work\zyps\source\net\sourceforge\zyps\behavior.java
# # c:\work\zyps\source\net\sourceforge\zyps\clock.java
# # c:\work\zyps\source\net\sourceforge\zyps\color.java
# # c:\work\zyps\source\net\sourceforge\zyps\conditions\agecondition.java
# # c:\work\zyps\source\net\sourceforge\zyps\conditions\proximitycondition.java
# # c:\work\zyps\source\net\sourceforge\zyps\conditions\tagcondition.java
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
