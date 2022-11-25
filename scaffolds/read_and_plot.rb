require 'tk'
require '../lib'

# Reads tkcanvas ruby output and parses the three functions: gnuplot(cv), plotarea() and axisranges()
# Todo: pack into class instead of array?
  
p1 = RbTkCanvas.new('../testdata/2564-1-0.rb')
p2 = RbTkCanvas.new('../testdata/spect-plot.rb')

tkroot = TkRoot.new()
canvas1 = TkCanvas.new(tkroot) {pack}

lb1 = TkLabel.new(tkroot) {text 'plot p1'; pack}
lb2 = TkLabel.new(tkroot) {text 'plot p2'; pack}
lb1.bind('ButtonRelease') {p1.plot_to(canvas1)}
lb2.bind('ButtonRelease') {p2.plot_to(canvas1)}

canvas1.bind('ButtonRelease') {|event| puts "#{event.x} #{event.y}"}
canvas1.bind('ButtonRelease') {|event| puts event.widget.inspect.methods}

Tk.mainloop