require 'tk'
require "#{__dir__}/../lib"

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
    $spectral_unit = TkVariable.new

    # Mappings
    @map = nil
    @map_style = ''
    @z = 0
    @roi = 0 # No UI selector yet
    # Spects 
    @baseline = nil
    @spect_plot = nil
    @section_style = nil

    # Initialize scratch space
    Dir.mkdir './plotter_scratch' unless Dir.exist? './plotter_scratch'

    # Map widget
    @map_canvas = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0, 'sticky':'nsew', rowspan: 3)}
    @map_canvas.bind("Configure") {
      geom = @map_canvas.winfo_geometry.split('+')[0].split('x').map {|n| n.to_i}
      @map_canvas.width = geom[0]-2 # Ugly fix, Sth. better is needed.
      @map_canvas.height = geom[1]-2
      @map.plot_to @map_canvas if @map
    }

    # Selection state and binding
    @map_clicked = false
    @map_selections = []
    @map_annot = []
    @rect_colors = ['red', 'orange', 'yellow', 'green', 'blue', 'violet']
    @map_canvas.bind("Button-1") {|e|
      selection_on_map(e, :mousedown)
    }
    @map_canvas.bind("Motion") do |e| 
      selection_on_map(e, :motion)
    end
    @map_canvas.bind("ButtonRelease-1") {|e|
      selection_on_map(e, :mouseup)
    }


    # Map operations
    @map_op_frame = Tk::Tile::LabelFrame.new(tkroot) {
      text 'Mapping selection mode:';
      grid('row':3, 'column': 0, 'sticky': 'ew')
    }

    # Map selection modes
    map_mode_frame = TkFrame.new(@map_op_frame){grid('row':0, 'column':0, columnspan: 3, sticky: 'ew')}

    #@map_select_mode = 'pixel'
    $map_select_mode = TkVariable.new
    @select_sum = TkRadioButton.new(map_mode_frame){
      grid('row':0, 'column': 0);
      text 'sum';
      value 'sum';
      variable $map_select_mode
    }

    @select_px = TkRadioButton.new(map_mode_frame){
      grid('row':0, 'column': 1);
      text 'px';
      value 'px';
      variable $map_select_mode
    }
    
    @select_section = TkRadioButton.new(map_mode_frame){
      grid('row':0, 'column': 2);
      text 'section';
      value 'section';
      variable $map_select_mode
    }
    
    @select_section_bin = TkRadioButton.new(map_mode_frame){
      grid('row':0, 'column': 3);
      text 'binned section';
      value 'binned section';
      variable $map_select_mode
    }
    @select_px.select

    # remap
    @remap_butn = TkButton.new(@map_op_frame){
      grid('row':1, 'column': 0);
      text 'remap';
    }
    @remap_butn.command {remap}

    @z_selector = Tk::Tile::Combobox.new(@map_op_frame){
      textvariable @tk_z;
      grid('row': 1, 'column':1)
    }
    @z_selector.bind("<ComboboxSelected>") {
      puts "Combobox set to #{@z_selector.get}"
      @z = @z_selector.get.to_i
    }

    @save_map = TkButton.new(@map_op_frame){
      grid('row': 1, 'column': 2);
      text 'Save mapping'
    }
    @save_map.command {save_map}

    # File opening parameters
    @file_param_frame = Tk::Tile::LabelFrame.new(@tkroot){
      grid(row: 4, column:0, sticky: 'ew')
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
      variable $spectral_unit;
      value 'nm'
    }
    @unit_nm.command {
      @spectral_unit = 'nm'
    }
    @unit_wavenumber = TkRadiobutton.new(@spect_unit){
      text 'wavenumber';
      grid('row':0, 'column': 2);
      variable $spectral_unit;
      value 'wavenumber'
    }
    @unit_wavenumber.command {
      @spectral_unit = 'wavenumber'
    }
    @unit_ev = TkRadiobutton.new(@spect_unit){
      text 'eV';
      grid('row':0, 'column': 3);
      variable $spectral_unit;
      value 'eV'
    }
    @unit_ev.command {
      @spectral_unit = 'eV'
    }

    @load_scan = TkButton.new(@file_param_frame){
      grid('row': 1, 'column': 2, 'sticky': 'ew');
      text 'open scan'
    }
    @load_scan.command {open_scan}

    # Spect_canvas
    @spect_canvas = TkCanvas.new(tkroot) {
      grid('row': 0, 'column': 1, 'sticky': 'nsew', rowspan: 3)
    }
    # Spect operations
    @spect_op_frame = Tk::Tile::LabelFrame.new(tkroot) {
      grid(row: 3, column: 1, sticky: 'ew');
      text 'Spectrum operations'
    }
    @spect_range_mode = TkCheckButton.new(@spect_op_frame) {
      grid(row: 0, column: 0);
      text 'pick range'
    }
    @spect_pt_mode = TkCheckButton.new(@spect_op_frame) {
      grid(row: 0, column: 1);
      text 'pick points'
    }
    @spect_clear = TkButton.new(@spect_op_frame) {
      grid(row: 0, column: 2);
      text 'clear spectra'
    }
    @spect_clear.command {clear_spectra}
    @spect_save = TkButton.new(@spect_op_frame){
      grid(row: 0, column: 3);
      text 'Save spectrum'
    }
    @spect_save.command {save_spect}

    # Selection state and binding
    @spect_clicked = nil
    @spect_selection = [nil, nil]
    @spect_points = []
    @spect_canvas.bind("Configure") {
      geom = @spect_canvas.winfo_geometry.split('+')[0].split('x').map {|n| n.to_i}
      @spect_canvas.width = geom[0]-2 # Ugly fix, Sth. better is needed.
      @spect_canvas.height = geom[1]-2
      if @spect_plot
        case $map_select_mode
        when 'px', 'sum'
          update_spectra_plot
        when 'section'
          section_plot
        end
      end
    }
    @spect_canvas.bind("Button-1") {|e|
      mouse_on_spect(e, :mouseldown)
    }
    @spect_canvas.bind("Button-3") {|e|
      mouse_on_spect(e, :mouserdown)
    }
    @spect_canvas.bind("Motion") {|e|
      if @spect_ranging == true
        mouse_on_spect(e, :ranging)
      end
    }
    @spect_canvas.bind("ButtonRelease-1") {|e|
      mouse_on_spect(e, :mouseup)
    }

    
    # Bottom right tabs
    @second_quad = Tk::Tile::Notebook.new(tkroot){grid('column': 1, 'row': 4, 'sticky': 'nsew')}

    # Mapping function
    @mapping_func_frame = TkFrame.new(@second_quad)
    @mapping_func = TkText.new(@mapping_func_frame) {
      height 7;
      pack
    }
    @mapping_func.insert('0.0', 'spects[0].sum')
    
    # Terminal
    @term_frame = TkFrame.new(@second_quad)
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

    # Spectra lsit
    @spectra_frame = TkFrame.new(@second_quad)
    # List and apply operation
    # Such as show and hide
    
    # Baseline function
    @baseline_frame = TkFrame.new(@second_quad)
    # Propose and plot

    # Fitting
    @fitting_frame = TkFrame.new(@second_quad)
    # Propose and plot

    # Add the tabs
    @second_quad.add(@mapping_func_frame, text: 'Mapping function')
    @second_quad.add(@term_frame, text: 'Terminal')
    @second_quad.add(@spectra_frame, text: 'Spectra')
    @second_quad.add(@baseline_frame, text: 'Baseline')
    @second_quad.add(@fitting_frame, text: 'Fitting')
    
    
  end

  def remap
    map_func = @mapping_func.get('0.0', 'end')
    @map = RbTkCanvas.new(@scan.plot_map('plotter_scratch', {plot_term: 'tkcanvas-rb', plot_width: @map_canvas.width, plot_height: @map_canvas.height, z: @z, plot_style: @map_style}) {|spects| eval(map_func) });
    @map.plot_to @map_canvas
  end

  # Plot spects
  # Invoke color style injection
  def update_spectra_plot
    raise "@linestyle size and @spects size mismatch" unless @linestyle.size == @spects.size

    # Inject coloring here!!
    spect_style = @spect_style + "set linetype cycle #{@rect_colors.size}\n" # Danger!!
    @rect_colors.each_with_index do |color, i|
      spect_style += "set linetype #{i+1} lc rgb \"#{color}\" \n"
    end
    @spect_plot = RbTkCanvas.new(plot_spectra(@spects, {out_dir: "./plotter_scratch/#{@scan.name}spect", plot_term: 'tkcanvas-rb', plot_style: spect_style, plot_width: @spect_canvas.width, plot_height: @spect_canvas.height, linestyle: @linestyle}))
    @spect_plot.plot_to @spect_canvas
  end

  def update_section_plot
    @spect_plot = RbTkCanvas.new(plot_section(@spects, {out_dir: "./plotter_scratch/#{@scan.name}-section", plot_term: 'tkcanvas-rb', plot_style: @spect_style, plot_width: @spect_canvas.width, plot_height: @spect_canvas.height}))
    @spect_plot.plot_to @spect_canvas
  end
  

  def clear_spectra
    @spects = []
    @map_selections = []
    @map_annot.each do |shape|
      shape.delete
      shape.destroy
    end
    @map_annot = []
    @linestyle = []
  end

  # Calculate and update spects
  def accumulate_spect
    # Coordinate conversion
    # Extract to reuse with spect selection?
    # RCanvs will then own its RbTkCanvas?
    
    @selection_on_scan = @map.canvas_coord_to_plot_coord(@map_selections.last[0..1]) + @map.canvas_coord_to_plot_coord(@map_selections.last[2..3])
    # Watchout! Danger of @selection_on_scan not updated!
    
    @selection_on_scan.map! {|e| (e+0.5).to_i}
    puts @selection_on_scan.join '-'

    case $map_select_mode
    when 'sum'
      points = @scan.select_points(@selection_on_scan[0..1]+ [@z], @selection_on_scan[2..3]+ [@z])
      @spects += [(points.map {|pt| @scan[pt[0]][pt[1]][@z][@roi]}).reduce(:+)]
      @spects.last.name = "sum-#{@selection_on_scan.join('-')}"
      @linestyle.push "lt #{@map_selections.size}"
      update_spectra_plot
    when 'px'
      points = @scan.select_points(@selection_on_scan[0..1]+ [@z], @selection_on_scan[2..3]+ [@z])
      newspects = points.map {|pt| @scan[pt[0]][pt[1]][@z][@roi]}
      @spects += newspects
      @linestyle += ["lt #{@map_selections.size}"] * newspects.size
      # Check: spectrum naming?
      update_spectra_plot
    when 'section'
      points = @scan.section(@selection_on_scan[0..1], @selection_on_scan[2..3])
      newspects = points.map{|pt| @scan[pt[0]][pt[1]][@z][@roi]}
      newspects.each_index do |i|
        newspects[i].name = "section-#{@selection_on_scan.join('-')}-#{i}"
        @linestyle += ["lt #{i}"]
      end
      # Perform uniform t sampling to newspects here
      @spects = newspects
      update_section_plot
    when 'binned section'
      # Return spects but not set of points for now
      axis_on_map = @map.canvas_coord_to_plot_coord(@map_selections.last[0..1]) + @map.canvas_coord_to_plot_coord(@map_selections.last[2..3])
      span = section_vector(axis_on_map, @map.canvas_coord_to_plot_coord(@map_annot.last.coords[0..1]))
      @spects = @scan.binned_section(axis_on_map, span, {roi: @roi, z: @z})
      update_section_plot
    else
    end


  end
  
  # Update selection square
  def selection_on_map(event, state) #Is state somewhat embedded in event? This for now.
    case state
    when :mousedown
        @map_clicked = true
      if ['sum', 'px'].include? $map_select_mode
        @map_selections.push [event.x, event.y, 0, 0]
        rect = TkcRectangle.new(@map_canvas, event.x, event.y, event.x, event.y, outline: @rect_colors[(@map_selections.size-1) % @rect_colors.size])
        @map_annot.push(rect)
      elsif $map_select_mode == 'section'
        @map_selections.push [event.x, event.y, 0, 0]
        line = TkcLine.new(@map_canvas, event.x, event.y, event.x, event.y, fill: @rect_colors[(@map_selections.size-1) % @rect_colors.size])
        @map_annot.push(line)
      elsif $map_select_mode == 'binned section'
        if @sideways_selection
          coords = (0..3).map {|i| @map.canvas_coord_to_plot_coord(@map_annot.last.coords[2*i..2*i+1])}
          axis = @map.canvas_coord_to_plot_coord(@map_selections.last[0..1]) + @map.canvas_coord_to_plot_coord(@map_selections.last[2..3])
        else
          @map_selections.push [event.x, event.y, 0, 0]
          line = TkcLine.new(@map_canvas, event.x, event.y, event.x, event.y, fill: @rect_colors[(@map_selections.size-1) % @rect_colors.size])
          @map_annot.push(line)
        end
      end
    when :motion
      # Update selection in the go
      # Select cross section binning wing 
      if $map_select_mode == 'binned section' && @sideways_selection
        @vec = section_vector(@map_selections.last, [event.x, event.y])
        @map_annot.last.coords(@map_selections.last[2] + @vec[0], @map_selections.last[3] + @vec[1],
                              @map_selections.last[0] + @vec[0], @map_selections.last[1] + @vec[1], 
                              @map_selections.last[0] - @vec[0], @map_selections.last[1] - @vec[1],
                              @map_selections.last[2] - @vec[0], @map_selections.last[3] - @vec[1])
      # Update other dragging
      elsif @map_clicked
        @map_annot.last.coords(@map_selections.last[0], @map_selections.last[1], event.x,event.y)
      end
    when :mouseup
      @map_clicked = false
      if $map_select_mode == 'binned section'
        if @sideways_selection
          #@section_box = (0..3).map {|i| @map.canvas_coord_to_plot_coord(@map_annot.last.coords[2*i..2*i+1])}
          @sideways_selection = false
          accumulate_spect
        else
          @map_selections.last[2..3]=[event.x, event.y]
          @sideways_selection = true
        end
      else
        @map_selections.last[2..3]=[event.x, event.y]
        accumulate_spect
      end
    end
  end

  def mouse_on_spect(event, state)
      coord = @spect_plot.canvas_coord_to_plot_coord([event.x, event.y])
    case state
    when :mouseldown
      if @spect_pt_mode.get_value == '1'
        @spect_points.push coord
      elsif @spect_range_mode.get_value == '1'
        @spect_ranging = true
        @spect_selection[0] = coord
        @spect_range_highlight.delete if defined? @spect_range_highlight
        @spect_range_highlight = TkcRectangle.new(@spect_canvas, event.x, 10, event.x, @spect_canvas.height, outline: 'red')
        @orig=[event.x, event.y]
      end
    when :mouserdown
      @spect_selection[1] = coord
      @mapping_func.insert('end', "\nspects[0].from_to(#{@spect_selection[0][0]},#{@spect_selection[1][0]}).sum")
      @spect_ranging = false
    when :ranging
      @spect_selection[1] = coord
      @spect_range_highlight.coords(@orig[0], 10, event.x, @spect_canvas.height)
    when :mouseup
    end
  end

  def open_scan
    @spe_path = Tk.getOpenFile {title 'Open spe'};
    @spepath.text = File.basename(@spe_path)
    @json_path = Tk.getOpenFile {title 'Open param'};
    @jsonpath.text = File.basename(@json_path)

    @spect_style = "unset ylabel\n"
    clear_spectra
    
    if !(File.exist? @spe_path) 
      puts "Spe file not found"
      return
    end
    if !(File.exist? @json_path)
      puts "Json file not found"
      return
    end

    @scan = Scan.new(@spe_path, File.basename(@spe_path, '.spe'), nil, {param_json: @json_path})
    @scan.load({spectral_unit: $spectral_unit.to_s})
    # Generate z selection radiobuttons in @z_selector here
    @z_selector.configure('values', (0..@scan.depth-1).map {|z| z.to_s})
    
    # Raman?
    @spect_style += "set xrange [#{@scan[0][0][0][0][0][0]}:#{@scan[0][0][0][0][-1][0]}]\n" if $spectral_unit == 'wavenumber'
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

  def save_map
    Dir.mkdir('export') unless Dir.exist? 'export'
    map_func = @mapping_func.get('0.0', 'end')
    @scan.plot_map("./export/#{@scan.name}-map", {plot_term: 'svg',z: @z, plot_style: @map_style, scale: 5, plot_height: 800, dry_run: true}) {|spects| eval(map_func) }
  end

  def save_spect
    Dir.mkdir('export') unless Dir.exist? 'export'
    plot_spectra(@spects, {out_dir: "./export/#{@scan.name}-spect", plot_term: 'svg', plot_style: @spect_style, linestyle: @linestyle, dry_run: true})
  end
end

tkroot = TkRoot.new {title 'Spectral mapping plotter'}
plotter = MappingPlotter.new(tkroot)

# Resizing behaviour
TkGrid.columnconfigure(tkroot, 'all', :weight => 1)
TkGrid.rowconfigure(tkroot, 0, :weight => 1)
tkroot.mainloop
