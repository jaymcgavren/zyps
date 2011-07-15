
def convert(value)
  value =~ /^\-?[\d\.]+$/ ? value.to_f : value
end
