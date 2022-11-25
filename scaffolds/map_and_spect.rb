require_relative '../lib'
require 'tk'

def get_tktext(tktext)
  # Dump the text contents on a line based basis
  dumparr = tktext.dump('text', '1.0', 'end')
  # The lines come as ["text/image/whatever", "<text content>", "l.c index"]
  # Collect, stitch up and return
  (dumparr.map {|line| line[1]}).join
end

def exec_command(cmd_text, output)
    cmd = get_tktext(cmd_text)
    cmd.chomp
    result = TOPLEVEL_BINDING.eval(cmd).to_s
    output.insert('end', result)
    output.insert('end', "\n-----\n")
end


spe = File.expand_path('../testdata/2564-1-polar-scan.spe')
json = File.expand_path('../testdata/2564-1-polar-scan.param')


scan = Scan.new(spe, '2564-1', nil, {param_json: json})
scan.load
puts scan.inspect
plot = scan.plot_map('map', {plot_term: 'tkcanvas-rb'}) {|spect| spect[0].sum}
puts "Mapping plotted to #{plot}"
map = RbTkCanvas.new plot

tkroot = TkRoot.new {width '1200'; height '800'; title 'Plotter'}

# Canvas map
canvas_map = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0)}
map_func_text = TkText.new(tkroot) {
  grid('row': 1, 'column': 0);
  height '3'
}
map.plot_to canvas_map
map_func_text.insert('end', 'proc {|spect| spect[0].sum}')


# Canvas spect
spectra_plot = TkCanvas.new(tkroot) {grid('row': 1, 'column': 1, 'rowspan': 2)}



# Terminal
term_output = TkText.new(tkroot) {grid('row': 0, 'column': 2)}
cmd_frame = TkFrame.new(tkroot) {grid('row':1, 'column': 2)}
cmd_input = TkText.new(cmd_frame) {grid('row': 0, 'column': 0, 'rowspan': 2)}
cmd_input.bind('Control-KeyPress-r', proc {exec_command(cmd_input, term_output)})
cmd_input.bind('Control-KeyPress-c', proc {term_output.delete('1.0', 'end')})
puts map.xrange
canvas_map.bind('ButtonRelease') {|clicked| 
  x = (clicked.x.to_f/clicked.widget.width * 1000 - map.plotarea[0]) / (map.plotarea[1] - map.plotarea[0]) * map.xrange + map.axisranges[0] +0.5
  y = (map.plotarea[3] - clicked.y.to_f/clicked.widget.height * 1000) / (map.plotarea[3] - map.plotarea[2]) * map.yrange + map.axisranges[2] +0.5
  puts "clicked #{x} #{y}"
}

run = TkButton.new(cmd_frame) {
  text 'Run';
  grid('row': 0, 'column': 1)
  command {
    exec_command(cmd_input, term_output)
  }
}
clear = TkButton.new(cmd_frame) {
  text 'Clear'
  grid('row':1, 'column': 1)
  command {
    term_output.delete('1.0', 'end')
  }
}


Tk.mainloop
