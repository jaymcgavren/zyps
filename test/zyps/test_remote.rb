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


require 'test/unit'
require 'zyps/remote' #Require only the remote library, to ensure it requires the others for us.


include Zyps


#Allowed deviation for assert_in_delta.
REQUIRED_ACCURACY = 0.001


#Redefine Clock to return a predictable time.
ELAPSED_TIME = 0.1
class Clock
	def elapsed_time; ELAPSED_TIME; end
end


class TestRemote < Test::Unit::TestCase

	URI = 'drb://lappy486:8989'
	SPEED = 1
	PITCH = 0
	RATE = 1

	def setup
		@environment = Environment.new
		Remote.serve_environment(@environment, URI)
		@client = Remote.get_environment(URI)
	end
	
	def test_uri
		assert_equal(URI, Remote.uri)
	end
	
	#Add an object to local environment and ensure client receives it.
	def test_local_add_object
		object = GameObject.new
		@environment.objects << object
		assert_equal(object, @client.objects.pop)
	end
	
	#Add an object to remote environment and ensure client receives it.
	def test_remote_add_object
		object = GameObject.new
		@environment.objects << object
		assert_equal(object, @client.objects.pop)
	end
	
	#Place GameObjects and ensure they can move.
	def test_objects
		object = GameObject.new
		object.vector = Vector.new(SPEED, PITCH)
		@client.objects << object
		@environment.interact
		assert_in_delta(ELAPSED_TIME * SPEED, @client.objects[0], REQUIRED_ACCURACY)
	end
	
	#Place Creature with Action and ensure it's carried out.
	def test_actions
		creature = Creature.new
		creature.vector = Vector.new(SPEED, PITCH)
		behavior = Behavior.new
		behavior.actions << TurnAction.new(RATE)
		creature.behaviors << behavior
		@client.objects << creature
		@client.objects << Creature.new #Second creature to interact with.
		@environment.interact
		assert_in_delta(PITCH + ELAPSED_TIME * RATE, @client.objects[0].pitch, REQUIRED_ACCURACY)
	end
	
	#Place Creature with Condition and ensure it's followed.
	def test_conditions
		creature = Creature.new
		creature.vector = Vector.new(SPEED, PITCH)
		behavior = Behavior.new
		behavior.actions << TurnAction.new(RATE)
		behavior.conditions << TagCondition('foobar') #Will return false.
		creature.behaviors << behavior
		@client.objects << creature
		@client.objects << Creature.new #Second creature to interact with.
		@environment.interact
		#Ensure pitch is unaltered, as condition was false.
		assert_in_delta(PITCH, @client.objects[0].pitch, REQUIRED_ACCURACY)
	end
	
	#Add EnvironmentalFactors and ensure they're usable.
	def test_environmental_factors
		@client.objects << Creature.new
		@client.environmental_factors << Accelerator.new(Vector.new(SPEED, PITCH))
		@environment.interact
		assert_in_delta(SPEED * ELAPSED_TIME, @client.objects[0].speed, REQUIRED_ACCURACY)
	end
		
end