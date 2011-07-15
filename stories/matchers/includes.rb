
class IncludesMatcher
  def initialize(item); @item = item; end
  def matches?(collection); collection.include?(@item); end
  def failure_message; "did not include #{@item}"; end
  def negative_failure_message; "included #{@item}"; end
end
def contain(required_items)
  IncludesMatcher.new(required_items)
end

