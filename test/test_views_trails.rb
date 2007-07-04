require 'zyps'
require 'zyps/views/trails'
require 'test/unit'


class TestTrailsView < Test::Unit::TestCase

	WIDTH = 400
	HEIGHT = 300
	
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
		@environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(1, 0, 0), Vector.new(10, 45))
		@environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(0, 1, 0), Vector.new(20, 135))
		@environment.objects << Creature.new(nil, Location.new(WIDTH/2, HEIGHT/2), Color.new(0, 0, 1), Vector.new(30, 225))
		i = 0
		while i < 1 do
			@environment.objects << Creature.new(
				i,
				Location.new(WIDTH * i, HEIGHT * i),
				Color.new(i, 1 - i, i / 2 + 0.5),
				Vector.new(100 * i, i * 360)
			)
			i += 0.01
		end
		
	end
	
	
	def teardown
		Gtk.main
	end
	
	
	def test_render
	
		thread = Thread.new do
		
			#Test rendering.
			(1..40).each do |i|
				@view.render(@environment.objects)
				@environment.interact
			end
			
			#Change view size and widen trails.
			@view.width += 100
			@view.height += 100
			@view.trail_width = 10
			@view.trail_length = 10
			
			#Test at new size.
			(1..40).each do |i|
				@view.render(@environment.objects)
				@environment.interact
			end
			
		end
				
	end
	
	def test_environmental_factors
	
		thread = Thread.new do
		
			#Test normally.
			(1..10).each do |i|
				@view.render(@environment.objects)
				@environment.interact
			end
			
			#Add gravity.
			gravity = EnvironmentalFactor.new
			accelerate = Behavior.new
			accelerate.actions << lambda {|target| target.vector.y += 9.8}
			gravity.behaviors << accelerate
			@environment.environmental_factors << gravity
			
			#Test again with gravity.
			(1..20).each do |i|
				@view.render(@environment.objects)
				@environment.interact
			end
			
		end
				
	end
	
	def test_behaviors
	
		thread = Thread.new do
		
			#Add target and have all creatures chase it.
			@environment.objects.each do |creature|
				chase = Behavior.new
				chase.conditions << lambda {|target| return true if target.tags.include?('food')}
				chase.actions << lambda do |target|
					x = target.location.x - creature.location.x
					y = target.location.y - creature.location.y
					vector_to_target = Vector.new
					vector_to_target.x = x
					vector_to_target.y = y
					vector_to_target.speed = creature.vector.speed if creature.vector.speed > vector_to_target.speed
					creature.vector = vector_to_target
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
			
			(1..40).each do |i|
				begin
					@view.render(@environment.objects)
					@environment.interact
				rescue Exception => exception
					puts exception
				end
			end

		end
				
	end
	
end


