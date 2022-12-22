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

    # Mappings
    @map = nil
    @map_style = ''
    @z = 0
    # Spects 
    @spects = []
    @baseline = nil
    @spect_style = "unset ylabel\n"

    # Map widget
    @map_canvas = TkCanvas.new(tkroot) {grid('row': 0, 'column': 0, 'sticky':'nsew'); background('red')}
    @map_canvas.bind("Configure") {
      geom = @map_canvas.winfo_geometry.split('+')[0].split('x').map {|n| n.to_i}
      @map_canvas.width = geom[0]-2 # Ugly fix, Sth. better is needed.
      @map_canvas.height = geom[1]-2
    }

    # Selection state and binding
    @map_clicked = false
    @map_selctions = [[0,0,0,0]]
    @map_rects = []
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

    @mapping_func = TkText.new(tkroot) {
    grid('row': 1, 'column': 0, 'sticky': 'ew');
    height '1';
    }
    @mapping_func.insert('0.0', 'spects[0].sum')

    # Map operations
    @map_op_frame = TkFrame.new(tkroot) {
      grid('row':2, 'column': 0, 'sticky': 'ew');
    }
    # remap
    @remap_butn = TkButton.new(@map_op_frame){
      grid('row':0, 'column': 0, 'sticky': 'ew');
      text 'remap';
    }
    @remap_butn.command {remap}
    
    @sum_or_pick = TkCheckButton.new(@map_op_frame){
      grid('row':0, 'column': 1, 'sticky': 'ew');
      text 'sum or not'
    }

    @spepath = TkLabel.new(@map_op_frame){
      grid('row': 1, 'column': 0, 'sticky': 'ew');
    }

    @jsonpath = TkLabel.new(@map_op_frame){
      grid('row': 2, 'column': 0, 'sticky': 'ew');
    }
    
    @spect_unit = TkFrame.new(@map_op_frame){
      grid('row': 1, 'column': 1, 'sticky': 'ew')
    }
    TkLabel.new(@spect_unit){
      text 'Spectral unit: ';
      grid('row':0, 'column': 0, 'sticky': 'ew')
    }
    @unit_nm = TkRadiobutton.new(@spect_unit){
      text 'nm';
      grid('row':0, 'column': 1, 'sticky': 'ew')
    }

    @unit_wavenumber = TkRadiobutton.new(@spect_unit){
      text 'wavenumber';
      grid('row':0, 'column': 2)
    }

    @load_scan = TkButton.new(@map_op_frame){
      grid('row': 2, 'column': 1, 'sticky': 'ew');
      text 'open scan';
    }
    @load_scan.command {open_scan}
    # TODO: select z construction when opening

    @z_frame = TkFrame.new(@map_op_frame){
      grid('row': 0, 'column':2, 'sticky': 'ew')
    }

    # Spect_canvas
    @spect_canvas = TkCanvas.new(tkroot) {
      grid('row': 0, 'column': 1, 'rowspan': 2, 'sticky': 'nsew');
      background('#FF5500')
    }

    # Terminal
    @term_frame = TkFrame.new(tkroot) {grid('column': 1, 'row': 2, 'sticky': 'ew'); borderwidth(5)}
    @term_output = TkText.new(@term_frame) {grid('row': 0, 'column': 0, 'sticky': 'ew'); height '5'}
    @cmd_frame = TkFrame.new(@term_frame) {grid('row':1, 'column': 0, 'sticky': 'ew')}
    @cmd_input = TkText.new(@cmd_frame) {grid('row': 0, 'column': 0, 'rowspan': 2, 'sticky': 'ew'); height '3'}
    @cmd_input.bind('Control-KeyPress-r', proc {exec_command})
    @cmd_input.bind('Control-KeyPress-c', proc {@term_output.delete('1.0', 'end')})


    run = TkButton.new(@cmd_frame) {
      text 'Run';
      grid('row': 0, 'column': 1, 'sticky': 'ew')
      command {
        exec_command(cmd_input, term_output)
      }
    }
    clear = TkButton.new(@cmd_frame) {
      text 'Clear'
      grid('row':1, 'column': 1, 'sticky': 'ew')
      command {
        term_output.delete('1.0', 'end')
      }
    }
    
    
  end

  def remap
    map_func = @mapping_func.get('0.0', 'end')
    #puts map_func if debug
    #puts "Style: #{@map_style}" if debug
    @map = RbTkCanvas.new(@scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: @map_canvas.width, plot_height: @map_canvas.height, z: @z, plot_style: @map_style}) {|spects| eval@mapping_func.get('0.0', 'end') });
    @map.plot_to @map_canvas
  end

  # Plot spects
  # Invoke color style injection
  def plot_spectra
  end

  # Calculate and update spects
  def accumulate_spect
    puts @map_selctions.last.join '-'
  end

  # Update selection square
  def selection_on_map(event, state) #Is state somewhat embedded in event? This for now.
    case state
    when :mousedown
      @map_clicked = true
      puts @map_selctions.last
      @map_selctions.last[0..1] = [event.x, event.y]
      rect = TkcRectangle.new(@map_canvas, event.x, event.y, event.x, event.y, outline: 'black')
      @map_rects.push(rect)
    when :dragging
      @map_rects.last.coords(@map_selctions.last[0], @map_selctions.last[1], event.x,event.y)
    when :mouseup
      @map_clicked = false
      @map_selctions.last[2..3]=[event.x, event.y]
      accumulate_spect
    end
  end

  def selection_on_spect
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
    @scan.load
    # Generate z selection radiobuttons in @z_frame here
    
    @map = RbTkCanvas.new(@scan.plot_map('map', {plot_term: 'tkcanvas-rb', plot_width: @map_canvas.width, plot_height: @map_canvas.height}) {|spects| eval @mapping_func.get('0.0', 'end')});
    @map.plot_to @map_canvas

  end


  def exec_command
      cmd = @cmd_input.get('0.0', 'end')
      cmd.chomp
      #result = TOPLEVEL_BINDING.eval(cmd).to_s
      result = eval(cmd).to_s
      @term_output.insert('end', result)
      @term_output.insert('end', "\n-----\n")
  end
end

tkroot = TkRoot.new {title 'Spectral mapping plotter'}
plotter = MappingPlotter.new(tkroot)

# Resizing behaviour
TkGrid.columnconfigure(tkroot, 'all', :weight => 1)
TkGrid.rowconfigure(tkroot, 0, :weight => 1)
tkroot.mainloop
