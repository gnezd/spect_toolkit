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

spects = []
spects.push scan[scan.width/2][scan.height/2][0][0]
spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb'}))


tkroot = TkRoot.new {width '1200'; height '800'; title 'Plotter'}


# Canvas map
canvas_map = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0)}
map_func_text = TkText.new(tkroot) {
  grid('row': 1, 'column': 0);
  height '3'
}
remap = TkButton.new(tkroot){
  grid('row':2, 'column': 0);
  text 'remap';
  command proc {
    map = RbTkCanvas.new(scan.plot_map {eval(get_tktext(map_func_text))});
    map.plot_to canvas_map
  }
}
map.plot_to canvas_map
map_func_text.insert('end', 'proc {|spect| spect[0].sum}')


# Canvas spect
spectra_canvas = TkCanvas.new(tkroot) {grid('row': 1, 'column': 1, 'rowspan': 1)}
spect_plot.plot_to spectra_canvas
clr_spect = TkButton.new(tkroot) {
  grid('row': 2, 'column': 1);
  text('Clear plot to last');
  command proc {
    spects = [spects[-1]];
    spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb'}));
    spect_plot.plot_to spectra_canvas
  }
}



# Terminal
term_output = TkText.new(tkroot) {grid('row': 0, 'column': 2)}
cmd_frame = TkFrame.new(tkroot) {grid('row':1, 'column': 2)}
cmd_input = TkText.new(cmd_frame) {grid('row': 0, 'column': 0, 'rowspan': 2)}
cmd_input.bind('Control-KeyPress-r', proc {exec_command(cmd_input, term_output)})
cmd_input.bind('Control-KeyPress-c', proc {term_output.delete('1.0', 'end')})


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

selection = [0,0,0,0]
canvas_origin = [0,0]
mouse_down = false
rect = nil
canvas_map.bind('ButtonPress') do |clicked|
  mouse_down = true
  x = (clicked.x.to_f/clicked.widget.width * 1000 - map.plotarea[0]) / (map.plotarea[1] - map.plotarea[0]) * map.xrange + map.axisranges[0] +0.5
  y = (map.plotarea[3] - clicked.y.to_f/clicked.widget.height * 1000) / (map.plotarea[3] - map.plotarea[2]) * map.yrange + map.axisranges[2] +0.5
  selection[0] = x.to_i;
  selection[1] = y.to_i;
  canvas_origin = [clicked.x, clicked.y]
end

canvas_map.bind('Motion') do |dragged|
  if mouse_down == true
    #puts "draw box from #{selection[0..1].join '-'} to #{dragged.x} - #{dragged.y}"
    rect.delete if rect
    rect = TkcRectangle.new(canvas_map, canvas_origin[0], canvas_origin[1], dragged.x, dragged.y, outline: 'red')
    #puts rect
  end
end
canvas_map.bind('ButtonRelease') {|clicked| 
  x = (clicked.x.to_f/clicked.widget.width * 1000 - map.plotarea[0]) / (map.plotarea[1] - map.plotarea[0]) * map.xrange + map.axisranges[0] +0.5
  y = (map.plotarea[3] - clicked.y.to_f/clicked.widget.height * 1000) / (map.plotarea[3] - map.plotarea[2]) * map.yrange + map.axisranges[2] +0.5
  selection[2] = x.to_i
  selection[3] = y.to_i
  
  #puts selection.join ','
  points = scan.select_points(selection[0..1] + [0], selection[2..3]+[0])
  #puts points.size
  spects += points.map {|pt| scan[pt[0]][pt[1]][0][0]}
  spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb'}))
  spect_plot.plot_to spectra_canvas
  mouse_down = false
}

Tk.mainloop
