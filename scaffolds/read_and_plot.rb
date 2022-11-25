require 'tk'

# Reads tkcanvas ruby output and parses the three functions: gnuplot(cv), plotarea() and axisranges()
# Todo: pack into class instead of array?
class RbTkCanvas
  attr_reader :plot, :plotarea, :axisranges
  def initialize(rbin)
    read_tkcanvas(rbin)
  end
  def read_tkcanvas(rbin)
    raw = File.open(rbin, 'r').read
    str_result = (raw.split /^\s*def[^\n]+\n/)
    .map {|part| part.chomp "\nend\n"}[1..]
    @plot = str_result[0]
    @plotarea = eval(str_result[1].split('return ')[1])
    @axisranges = eval(str_result[2].split('return ')[1])
  end
    
  def plot_to(cv)
    eval(@plot)
  end
end
  
p1 = RbTkCanvas.new('./testdata/2564-1-0.rb')
p2 = RbTkCanvas.new('./testdata/spect-plot.rb')

tkroot = TkRoot.new()
canvas1 = TkCanvas.new(tkroot) {pack}

lb1 = TkLabel.new(tkroot) {text 'plot p1'; pack}
lb2 = TkLabel.new(tkroot) {text 'plot p2'; pack}
lb1.bind('ButtonRelease') {p1.plot_to(canvas1)}
lb2.bind('ButtonRelease') {p2.plot_to(canvas1)}

Tk.mainloop