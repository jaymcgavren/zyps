
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'
require 'test/unit'


include Zyps

class TestBehavior < Test::Unit::TestCase


  def setup
    @actor = Creature.new(:name => 'actor')
    @target = Creature.new(:name => 'target')
    @other = Creature.new(:name => 'other')
    @targets = []
    @targets << @target << @other
  end
  
  
  def test_equality
    #Equivalent behaviors have the same actions.
    assert_equal(
      Behavior.new(:actions => [ApproachAction.new(1), TagAction.new('foo')]),
      Behavior.new(:actions => [ApproachAction.new(1), TagAction.new('foo')]),
      "Same actions."
    )
    assert_not_equal(
      Behavior.new(:actions => [ApproachAction.new(1)]),
      Behavior.new(:actions => [ApproachAction.new(2)]),
      "Action attributes differ."
    )
    assert_not_equal(
      Behavior.new(:actions => [ApproachAction.new(1)]),
      Behavior.new(:actions => [ApproachAction.new(1), ApproachAction.new(1)]),
      "Action counts differ."
    )
    #Equivalent behaviors have the same conditions.
    assert_equal(
      Behavior.new(:conditions => [ProximityCondition.new(1), TagCondition.new('foo')]),
      Behavior.new(:conditions => [ProximityCondition.new(1), TagCondition.new('foo')]),
      "Same conditions."
    )
    assert_not_equal(
      Behavior.new(:conditions => [ProximityCondition.new(1)]),
      Behavior.new(:conditions => [ProximityCondition.new(2)]),
      "Condition attributes differ."
    )
    assert_not_equal(
      Behavior.new(:conditions => [ProximityCondition.new(1)]),
      Behavior.new(:conditions => [ProximityCondition.new(1), ProximityCondition.new(1)]),
      "Condition counts differ."
    )
    #Equivalent behaviors have the same condition frequency.
    assert_equal(
      Behavior.new(:condition_frequency => 2),
      Behavior.new(:condition_frequency => 2),
      "Same condition frequency."
    )
    assert_not_equal(
      Behavior.new(:condition_frequency => 2),
      Behavior.new(:condition_frequency => 3),
      "Condition frequencies differ."
    )
    #Test everything at once.
    assert_equal(
      Behavior.new(
        :actions => [ApproachAction.new(1), TagAction.new('foo')],
        :conditions => [ProximityCondition.new(1), TagCondition.new('foo')],
        :condition_frequency => 2
      ),
      Behavior.new(
        :actions => [ApproachAction.new(1), TagAction.new('foo')],
        :conditions => [ProximityCondition.new(1), TagCondition.new('foo')],
        :condition_frequency => 2
      ),
      "Condition frequency and all actions and conditions match."
    )
  end
  
end
