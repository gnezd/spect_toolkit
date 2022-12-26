require 'tk'
require './lib'

# Resizable Tk canvas
class RCanvas < TkCanvas
  def resize
  end
end

class MappingPlotter

  def initialize(tkroot)
    # Paths and data
    @spe_path = ""
    @json_path = ""
    @scan = nil
    @spectral_unit = ''

    # Mappings
    @map = nil
    @map_style = ''
    @z = 0
    # Spects 
    @spects = []
    @baseline = nil
    @spect_style = "unset ylabel\n"
    @linestyle = []

    # Map widget
    @map_canvas = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0, 'sticky':'nsew')}
    @map_canvas.bind("Configure") {
      geom = @map_canvas.winfo_geometry.split('+')[0].split('x').map {|n| n.to_i}
      @map_canvas.width = geom[0]-2 # Ugly fix, Sth. better is needed.
      @map_canvas.height = geom[1]-2
    }

    # Selection state and binding
    @map_clicked = false
    @map_selections = []
    @map_rects = []
    @rect_colors = ['red', 'orange', 'yellow', 'green', 'blue', 'violet']
    @map_canvas.bind("Button-1") {|e|
      selection_on_map(e, :mousedown)
    }
    @map_canvas.bind("Motion") do |e| 
      if @map_clicked
        selection_on_map(e, :dragging)
      end
    end
    @map_canvas.bind("ButtonRelease-1") {|e|
      selection_on_map(e, :mouseup)
    }

    mapping_func_frame = Tk::Tile::LabelFrame.new(tkroot) {text 'Mapping function';
    grid('row': 1, 'column': 0, 'sticky': 'ew')}
    @mapping_func = TkText.new(mapping_func_frame) {
    height '2';
    pack
    }
    @mapping_func.insert('0.0', 'spects[0].sum')

    # Map operations
    @map_op_frame = Tk::Tile::LabelFrame.new(tkroot) {
      text 'Mapping operations';
      grid('row':2, 'column': 0, 'sticky': 'ew', columnspan: 2)
    }
    # remap
    @remap_butn = TkButton.new(@map_op_frame){
      grid('row':0, 'column': 0);
      text 'remap';
    }
    @remap_butn.command {remap}
    @sum_or_pick = TkCheckButton.new(@map_op_frame){
      grid('row':0, 'column': 1);
      text 'sum or not'
    }
    @z_selector = Tk::Tile::Combobox.new(@map_op_frame){
      textvariable @tk_z;
      grid('row': 0, 'column':2, 'sticky': 'ew')
    }
    @z_selector.bind("<ComboboxSelected>") {
      puts "Combobox set to #{@z_selector.get}"
      @z = @z_selector.get_to_i
    }

    # File opening parameters
    @file_param_frame = Tk::Tile::LabelFrame.new(@tkroot){
      grid(row: 3, column:0, sticky: 'ew', rowspan: 2)
      text 'File parameter'
    }

    @spepath = TkLabel.new(@file_param_frame){
      grid('row': 0, 'column': 0, 'sticky': 'ew');
      text '<Spe path>'
    }

    @jsonpath = TkLabel.new(@file_param_frame){
      grid('row': 1, 'column': 0, 'sticky': 'ew');
      text '<JSON parameter file path>'
    }
    
    @spect_unit = Tk::Tile::LabelFrame.new(@file_param_frame){
      text 'Spectral unit';
      grid('row': 0, 'column': 2, 'sticky': 'ew')
    }
    TkLabel.new(@spect_unit){
      text 'Spectral unit: ';
      grid('row':0, 'column': 0, 'sticky': 'ew')
    }
    @unit_nm = TkRadiobutton.new(@spect_unit){
      text 'nm';
      grid('row':0, 'column': 1, 'sticky': 'ew');
      variable @spectral_unit;
      value 'nm'
    }
    @unit_nm.command {
      @spectral_unit = 'nm'
    }
    @unit_wavenumber = TkRadiobutton.new(@spect_unit){
      text 'wavenumber';
      grid('row':0, 'column': 2);
      variable @spectral_unit;
      value 'wavenumber'
    }
    @unit_wavenumber.command {
      @spectral_unit = 'wavenumber'
    }
    @unit_ev = TkRadiobutton.new(@spect_unit){
      text 'eV';
      grid('row':0, 'column': 3);
      variable @spectral_unit;
      value 'eV'
    }
    @unit_ev.command {
      @spectral_unit = 'eV'
    }

    @load_scan = TkButton.new(@file_param_frame){
      grid('row': 1, 'column': 2, 'sticky': 'ew');
      text 'open scan';
    }
    @load_scan.command {open_scan}

    # Spect_canvas
    @spect_canvas = TkCanvas.new(tkroot) {
      grid('row': 0, 'column': 1, 'sticky': 'nsew')
    }
    # Spect operations
    @spect_op_frame = TkFrame.new(tkroot) {
      grid(row: 1, column: 1, sticky: 'ew')
    }
    @spect_range_mode = TkCheckButton.new(@spect_op_frame) {
      grid(row: 0, column: 0)
      text 'pick range'
    }
    @spect_pt_mode = TkCheckButton.new(@spect_op_frame) {
      grid(row: 0, column: 1)
      text 'pick points'
    }
    @spect_clear = TkButton.new(@spect_op_frame) {
      grid(row: 0, column: 2)
      text 'clear spectra'
    }
    @spect_clear.command {clear_spectra}

    # Selection state and binding
    @spect_clicked = nil
    @spect_selection = [nil, nil]
    @spect_points = []
    @spect_canvas.bind("Configure") {
      geom = @spect_canvas.winfo_geometry.split('+')[0].split('x').map {|n| n.to_i}
      @spect_canvas.width = geom[0]-2 # Ugly fix, Sth. better is needed.
      @spect_canvas.height = geom[1]-2
    }
    @spect_canvas.bind("Button-1") {|e|
      mouse_on_spect(e, :mouseldown)
    }
    @spect_canvas.bind("Button-3") {|e|
      mouse_on_spect(e, :mouserdown)
    }
    @spect_canvas.bind("Motion") {|e|
      if @spect_clicked
        mouse_on_spect(e, :dragging)
      end
    }
    @spect_canvas.bind("ButtonRelease-1") {|e|
      mouse_on_spect(e, :mouseup)
    }

    @spect_plot = nil

    # Terminal
    @term_frame = Tk::Tile::LabelFrame.new(tkroot) {grid('column': 1, 'row': 2, 'sticky': 'ew', rowspan: 3);
    text 'terminal'}
    @term_output = TkText.new(@term_frame) {grid('row': 0, 'column': 0, 'sticky': 'ew'); height '5'}
    @cmd_frame = TkFrame.new(@term_frame) {grid('row':1, 'column': 0, 'sticky': 'ew')}
    @cmd_input = TkText.new(@cmd_frame) {grid('row': 0, 'column': 0, 'rowspan': 2, 'sticky': 'ew'); height '3'}
    @cmd_input.bind('Control-KeyPress-r', proc {exec_command})
    @cmd_input.bind('Control-KeyPress-c', proc {clear_terminal_output})


    run = TkButton.new(@cmd_frame) {
      text 'Run';
      grid('row': 0, 'column': 1, 'sticky': 'ew')
    }
    run.command {exec_command}
    clear = TkButton.new(@cmd_frame) {
      text 'Clear';
      grid('row':1, 'column': 1, 'sticky': 'ew')
    }
    clear.command {clear_terminal_output}
    
    
  end

  def remap
    map_func = @mapping_func.get('0.0', 'end')
    @map = RbTkCanvas.new(@scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: @map_canvas.width, plot_height: @map_canvas.height, z: @z, plot_style: @map_style}) {|spects| eval(map_func) });
    @map.plot_to @map_canvas
  end

  # Plot spects
  # Invoke color style injection
  def update_spectra
  end

  def clear_spectra
    @spects = []
    @map_selections = []
    @map_rects.each do |rect|
      rect.delete
      rect.destroy
    end
    @map_rects = []
    @linestyle = []
  end

  # Calculate and update spects
  def accumulate_spect
    # Coordinate conversion
    # Extract to reuse with spect selection?
    # RCanvs will then own its RbTkCanvas?
    selection_on_scan = @map.canvas_coord_to_plot_coord(@map_selections.last[0..1]) + @map.canvas_coord_to_plot_coord(@map_selections.last[2..3])
    selection_on_scan.map! {|e| (e+0.5).to_i}
    puts selection_on_scan.join '-'
    points = @scan.select_points(selection_on_scan[0..1]+ [@z], selection_on_scan[2..3]+ [@z])
    if @sum_or_pick.get_value == '1'
      @spects += [(points.map {|pt| @scan[pt[0]][pt[1]][@z][0]}).reduce(:+)]
      @spects.last.name = "sum-#{selection_on_scan.join('-')}"
      @linestyle.push "lt #{@map_selections.size}"
    else
      newspects = points.map {|pt| @scan[pt[0]][pt[1]][@z][0]}
      @spects += newspects
      @linestyle += ["lt #{@map_selections.size}"] * newspects.size
      # Check: spectrum naming?
    end

    raise "@linestyle size and @spects size mismatch" unless @linestyle.size == @spects.size

    # Inject coloring here!!
    @spect_style += "set linetype cycle #{@rect_colors.size}\n"
    @rect_colors.each_with_index do |color, i|
      @spect_style += "set linetype #{i+1} lc rgb \"#{color}\" \n"
    end
    @spect_plot = RbTkCanvas.new(plot_spectra(@spects, {out_dir: "./#{@scan.name}spect", plot_term: 'tkcanvas-rb', plot_style: @spect_style, plot_width: @spect_canvas.width, plot_height: @spect_canvas.height, linestyle: @linestyle}))
    @spect_plot.plot_to @spect_canvas

  end


  # Update selection square
  def selection_on_map(event, state) #Is state somewhat embedded in event? This for now.
    case state
    when :mousedown
      @map_clicked = true
      @map_selections.push [event.x, event.y, 0, 0]
      rect = TkcRectangle.new(@map_canvas, event.x, event.y, event.x, event.y, outline: @rect_colors[(@map_selections.size-1) % @rect_colors.size])
      @map_rects.push(rect)
    when :dragging
      @map_rects.last.coords(@map_selections.last[0], @map_selections.last[1], event.x,event.y)
    when :mouseup
      @map_clicked = false
      @map_selections.last[2..3]=[event.x, event.y]
      accumulate_spect
    end
  end

  def mouse_on_spect(event, state)
      coord = @spect_plot.canvas_coord_to_plot_coord([event.x, event.y])
    case state
    when :mouseldown
      if @spect_pt_mode.get_value == '1'
        @spect_points.push coord
      elsif @spect_range_mode.get_value == '1'
        @spect_selection[0] = coord
      end
    when :mouserdown
      @spect_selection[1] = coord
      @mapping_func.delete('0.0', 'end')
      @mapping_func.insert('end', "spects[0].from_to(#{@spect_selection[0][0]},#{@spect_selection[1][0]})")
    when :dragging
    when :mouseup
    end
  end

  def open_scan
    @spe_path = Tk.getOpenFile {title 'Open spe'};
    @spepath.text = File.basename(@spe_path)
    @json_path = Tk.getOpenFile {title 'Open param'};
    @jsonpath.text = File.basename(@json_path)
    
    if !(File.exist? @spe_path) 
      puts "Spe file not found"
      return
    end
    if !(File.exist? @json_path)
      puts "Json file not found"
      return
    end

    @scan = Scan.new(@spe_path, File.basename(@spe_path, '.spe'), nil, {param_json: @json_path})
    @scan.load({spectral_unit: @spectral_unit})
    # Generate z selection radiobuttons in @z_selector here
    @z_selector.configure('values', (0..@scan.depth-1).map {|z| z.to_s})
    
    remap
  end


  def exec_command
      cmd = @cmd_input.get('0.0', 'end')
      cmd.chomp
      #result = TOPLEVEL_BINDING.eval(cmd).to_s
      result = eval(cmd).to_s
      @term_output.insert('end', result)
      @term_output.insert('end', "\n-----\n")
  end

  def clear_terminal_output
    @term_output.delete('1.0', 'end')
  end
end

tkroot = TkRoot.new {title 'Spectral mapping plotter'}
plotter = MappingPlotter.new(tkroot)

# Resizing behaviour
TkGrid.columnconfigure(tkroot, 'all', :weight => 1)
TkGrid.rowconfigure(tkroot, 0, :weight => 1)
tkroot.mainloop
