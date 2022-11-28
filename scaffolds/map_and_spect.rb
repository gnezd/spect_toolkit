require_relative '../lib'
require 'tk'

def get_tktext(tktext)
  # Dump the text contents on a line based basis
  #dumparr = tktext.dump('text', '1.0', 'end')
  # The lines come as ["text/image/whatever", "<text content>", "l.c index"]
  # Collect, stitch up and return
  #(dumparr.map {|line| line[1]}).join
  tktext.get('0.0', 'end')
end

def exec_command(cmd_text, output)
    cmd = get_tktext(cmd_text)
    cmd.chomp
    result = TOPLEVEL_BINDING.eval(cmd).to_s
    output.insert('end', result)
    output.insert('end', "\n-----\n")
end


#spe = File.expand_path('../testdata/2564-1-polar-scan.spe')
#json = File.expand_path('../testdata/2564-1-polar-scan.param')
spe = ""
json = ""
map = nil
scan = nil

#scan = Scan.new(spe, '2564-1', nil, {param_json: json})
#scan.load
#puts scan.inspect
spects = []


tkroot = TkRoot.new do
  title 'Plotter'
end


# Canvas map
canvas_map = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0)}
map_func_text = TkText.new(tkroot) {
  grid('row': 1, 'column': 0);
  height '3'
}

map_op_frame = TkFrame.new(tkroot) {
  grid('row':2, 'column': 0);
}
remap = TkButton.new(map_op_frame){
  grid('row':0, 'column': 0);
  text 'remap';
  command proc {
    map_func = get_tktext(map_func_text);
    puts map_func;
    map = RbTkCanvas.new(scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: canvas_map.width, plot_height: canvas_map.height}) {|spects| eval(get_tktext(map_func_text))});
    #plot = scan.plot_map('map', {plot_term: 'tkcanvas-rb'}) {|spect| spect[0].sum}
    map.plot_to canvas_map
  }
}
sum_or_not = TkCheckButton.new(map_op_frame){
  grid('row':0, 'column': 1);
  text 'sum or not'
}

fin = TkLabel.new(map_op_frame){
  grid('row': 1, 'column': 0);
  text File.basename(spe)
}

jsonin = TkLabel.new(map_op_frame){
  grid('row': 2, 'column': 0);
  text File.basename(json)
}
scanload = TkButton.new(map_op_frame){
  grid('row': 1, 'column': 1);
  text 'open scan';
  command proc {
    spe = Tk.getOpenFile {title 'Open spe'};
    fin.text = File.basename(spe)
    json = Tk.getOpenFile {title 'Open param'};
    jsonin.text = File.basename(json)
    
    scan = Scan.new(spe, 'xxx', nil, {param_json: json})
    scan.load
    
    map = RbTkCanvas.new(scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: canvas_map.width, plot_height: canvas_map.height}) {|spects| eval(get_tktext(map_func_text))});
    map.plot_to canvas_map
  }
}

# Mapping selection sum/individual
# Mapping scaling


# Canvas spect
spectra_canvas = TkCanvas.new(tkroot) {grid('row': 0, 'column': 1, 'rowspan': 2)}
spect_style = "unset ylabel\n"

# Create plots
#plot = scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: canvas_map.width, plot_height: canvas_map.height}) {|spect| spect[0].sum}
#puts "Mapping plotted to #{plot}"
#map = RbTkCanvas.new plot
#map.plot_to canvas_map
map_func_text.insert('end', 'spects[0].sum')

#spects.push scan[scan.width/2][scan.height/2][0][0]
#spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb', plot_width: spectra_canvas.width, plot_height: spectra_canvas.height, plot_style: spect_style}))
#spect_plot.plot_to spectra_canvas

# Terminal
term_frame = TkFrame.new(tkroot) {grid('column': 1, 'row': 2)}
term_output = TkText.new(term_frame) {grid('row': 0, 'column': 0); height '5'}
cmd_frame = TkFrame.new(term_frame) {grid('row':1, 'column': 0)}
cmd_input = TkText.new(cmd_frame) {grid('row': 0, 'column': 0, 'rowspan': 2); height '3'}
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

# Pixel selector
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
  
  if sum_or_not.get_value == '1'
    spects += [(points.map {|pt| scan[pt[0]][pt[1]][0][0]}).reduce(:+)]
    spects.last.name = "sum-#{selection.join('-')}"
  else
  spects += points.map {|pt| scan[pt[0]][pt[1]][0][0]}
  end
  spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb', plot_style: spect_style, plot_width: spectra_canvas.width, plot_height: spectra_canvas.height}))
  spect_plot.plot_to spectra_canvas
  mouse_down = false
}

# Clear spectra
clr_spect = TkButton.new(map_op_frame) {
  grid('row': 0, 'column': 3);
  text('Clear plot to last');
  command proc {
    spects = [spects[-1]];
    spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb', plot_width: spectra_canvas.width, plot_height: spectra_canvas.height, plot_style: spect_style}));
    spect_plot.plot_to spectra_canvas
  }
}


# Resizer
tkroot.bind('Configure') { |config|
  #puts config.methods.inspect
  #puts config.width
}
resize = TkButton.new(map_op_frame){
  grid('row': 0, 'column': 2)
  text 'resize';
  command proc {
    wnwidth = tkroot.geometry.split('x')[0].to_i;
    puts wnwidth/2;
    canvas_map.width = wnwidth/2; 
    canvas_map.height= wnwidth/2; 
    spectra_canvas.width = wnwidth/2;
    spectra_canvas.height = wnwidth/2;
    map = RbTkCanvas.new(scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: canvas_map.width, plot_height: canvas_map.height}) {|spects| eval(get_tktext(map_func_text))});
    map.plot_to canvas_map;
    spect_plot = RbTkCanvas.new(plot_spectra(spects, {out_dir: './spect_plot', plot_term: 'tkcanvas-rb', plot_width: spectra_canvas.width, plot_height: spectra_canvas.height, plot_style: "set ylabel top\n"}));
    spect_plot.plot_to spectra_canvas
}
}

Tk.mainloop
