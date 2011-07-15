
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/serializer'
require 'test/unit'


include Zyps


class TestSerializer < Test::Unit::TestCase
  def setup
    #Create an environment.
    @environment = Environment.new
    #Create an environmental factor and add it to the environment.
    @environmental_factor = Accelerator.new
    @environment << @environmental_factor
    #Create a game object and add it to the environment.
    @game_object = GameObject.new
    @environment << @game_object
    #Create a creature and add it to the environment.
    @creature = Creature.new
    @environment << @creature
    #Create a behavior and add it to the creature.
    @behavior = Behavior.new
    @creature << @behavior
    #Create an action and add it to the behavior.
    @action = TagAction.new("foo")
    @behavior << @action
    #Create an condition and add it to the behavior.
    @condition = TagCondition.new("foo")
    @behavior << @condition
    #Create a Serializer.
    @serializer = Serializer.instance
  end
  def test_behavior_actions
    #Store and retrieve the behavior.
    behavior = @serializer.deserialize(@serializer.serialize(@behavior))
    behavior.actions.each {|action| assert_same(behavior, action.behavior, "Action should refer to the behavior")}
  end
  def test_behavior_conditions
    #Store and retrieve the behavior.
    behavior = @serializer.deserialize(@serializer.serialize(@behavior))
    behavior.conditions.each {|condition| assert_same(behavior, condition.behavior, "Condition should refer to the behavior")}
  end
  def test_creature_behaviors
    #Store and retrieve the creature.
    creature = @serializer.deserialize(@serializer.serialize(@creature))
    creature.behaviors.each {|behavior| assert_same(creature, behavior.creature, "Behavior should refer to the creature")}
  end
  def test_environment_environmental_factors
    #Store and retrieve the environment.
    environment = @serializer.deserialize(@serializer.serialize(@environment))
    environment.environmental_factors.each {|environmental_factor| assert_same(environment, environmental_factor.environment, "Environmental factor should refer to the environment")}
  end
  def test_environment_game_objects
    #Store and retrieve the environment.
    environment = @serializer.deserialize(@serializer.serialize(@environment))
    environment.objects.each {|object| assert_same(environment, object.environment, "Object should refer to the environment")}
  end
#TODO: Re-serialized version loses reset_elapsed_time_called attribute.  Fix.
#   def test_clock
#     clock = Clock.new
#     def clock.reset_elapsed_time
#       @reset_elapsed_time_called = true
#     end
#     def clock.reset_elapsed_time_called
#       @reset_elapsed_time_called
#     end
#     #Store and retrieve the Clock.
#     clock = @serializer.deserialize(@serializer.serialize(clock))
#     assert(clock.reset_elapsed_time_called, "Clock#reset_elapsed_time() should be called.")
#   end
end
