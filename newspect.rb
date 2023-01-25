# New datastructure for Spectrm
require 'gsl'
require 'objspace'
class NewSpect
  attr_accessor :wv, :values
  def initialize(length, options = {})
    @wv = GSL::Vector.alloc(length.times {0.0})
    @values = GSL::Vector.alloc(length.times {0.0})
  end

  def [](index)
    [@wv[index], @values[index]]
  end
end

ns = NewSpect.new(10)
ns2 = NewSpect.new(10)
puts ns[1]
puts ns.wv.object_id
puts ns2.wv.object_id
newwv = GSL::Vector.alloc(10.times{0.0})
puts "newwv: #{newwv.object_id}"
puts "taking up #{ObjectSpace.memsize_of(ns)}"
ns.wv = newwv
puts "nswv becomes: #{ns.wv.object_id}"
puts "taking up #{ObjectSpace.memsize_of(ns)}"