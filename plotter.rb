require 'tk'
require 'lib'

class MappingPlotter

  def initialize(tkroot)
    # Paths and data
    @spe_path = ""
    @json_path = ""
    @scan = nil

    # Mappings
    @map = nil
    @map_style = ''
    @z = 0
    # Spects 
    @spects = []
    @baseline = nil

    # Map widgets
    @map_canvas = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0)}
    @mapping_func = TkText.new(tkroot) {
    grid('row': 1, 'column': 0);
    height '1';
    text 'spects[0].sum'
    }

    # Map operations
    @map_op_frame = TkFrame.new(tkroot) {
      grid('row':2, 'column': 0);
    }
    # remap
    @remap_butn = TkButton.new(map_op_frame){
      grid('row':0, 'column': 0);
      text 'remap';
      command {remap}
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
    # TODO: select z

  end



  def remap
    map_func = @mapping_func.get('0.0', 'end')
    puts map_func if debug
    puts "Style: #{@map_style}" if debug
    @map = RbTkCanvas.new(@scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: @map_canvas.width, plot_height: @map_canvas.height, z: @z, plot_style: @map_style}) {|spects| eval(get_tktext(@mapping_func))});
    @map.plot_to @map_canvas
  end
end
