require 'nokogiri'

# Princeton Instruments .spe format
class Spe < Array
  attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :framesize, :wv, :spectrum_units,
                :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time, :rois, :bin_to_spect

  def initialize(path, name, options = {})
    debug = options[:debug]
    @path = path
    @name = name
    raise "No such file #{@path}" unless File.exist? path

    @bin_to_spect = options[:bin_to_spect]

    puts "Loading spe file #{@path} at #{Time.now}" if debug
    fin = File.open @path, 'rb'

    # Rewrite while reading PI documentation on SPE 3.0 format
    # And sluuurp (x)
    # perform a civilized segmented reading (o)
    bin_head = fin.read(4100).freeze
    xml_index = bin_head[678..685].unpack1('Q')
    @bin_data = fin.read(xml_index - 4100).freeze
    xml_raw = fin.read.freeze # All the rest goes to xml
    fin.close

    puts "Finished reading spe at #{Time.now}" if debug
    puts "Binary data has a lenght of: #{@bin_data.size}" if debug

    # Starting position of xml part
    @xml = Nokogiri.XML(xml_raw)

    # Data dimensions
    frame_node = @xml.at_xpath('//xmlns:DataBlock[@type="Frame"]')
    @frames = frame_node.attr('count').to_i
    pixelformat = frame_node.attr('pixelFormat')
    raise "Pixel format #{pixelformat} not supported" unless pixelformat == 'MonochromeUnsigned16'

    # Region of Interest parameters
    @rois = []
    @xml.xpath('//xmlns:SensorMapping').each do |roi|
      @rois.push({
                   id: roi.attr('id').to_i,
                   x: roi.attr('x').to_i,
                   y: roi.attr('y').to_i,
                   width: roi.attr('width').to_i,
                   height: roi.attr('height').to_i,
                   xbinning: roi.attr('xBinning').to_i,
                   ybinning: roi.attr('yBinning').to_i,
                   data_width: roi.attr('width').to_i / roi.attr('xBinning').to_i,
                   data_height: roi.attr('height').to_i / roi.attr('yBinning').to_i
                 })
    end
    puts "ROIs:\n" + @rois.join("\n") if debug

    # Cross check ROIs and sensor map
    data_blocks = @xml.xpath('//xmlns:DataBlock[@type="Region"]')
    raise 'Mismatch of number of blocks and number of sensor mapping information' unless data_blocks.size == @rois.size

    # Wavelength mapping
    begin
      wavelengths_mapping = @xml.at_xpath('//xmlns:Calibrations/xmlns:WavelengthMapping/xmlns:Wavelength').text.split(',').map do |x|
        x.to_f
      end
    rescue StandardError
      puts "Normal wavelength mapping not found for #{@name}. Try WavelengthError"
      wavelengths_mapping = @xml.at_xpath('//xmlns:Calibrations/xmlns:WavelengthMapping/xmlns:WavelengthError').text.split(' ').map do |x|
        x.split(',')[0].to_f
      end
    end

    # Calculating framesize and @wv
    @framesize = 0
    wavelengths_nm = []
    data_blocks.each_with_index do |block, i|
      puts "Checking ROI #{i}" if debug
      raise 'Width mismatch' unless block.attr('width').to_i == @rois[i][:data_width]
      raise 'Height mismatch' unless block.attr('height').to_i == @rois[i][:data_height]

      @framesize += @rois[i][:data_width] * @rois[i][:data_height]
      wavelengths_nm += wavelengths_mapping[@rois[i][:x]..@rois[i][:x] + @rois[i][:data_width] - 1]
      puts "W: #{@rois[i][:width]} / #{@rois[i][:xbinning]} H: #{@rois[i][:height]} / #{@rois[i][:ybinning]}" if debug
    end
    unless @bin_data.size == @frames * @framesize * 2
      raise "0_o binary data have a length of #{@bin_data.size} for #{@name}. With framesize #{@framesize} we expect #{frames} * #{@framesize} * 2 bytes/px."
    end

    # @data_creation, @file_creation, @file_modified
    @data_creation = Time.parse(@xml.at_xpath('//xmlns:Origin').attr('created'))
    @file_creation = Time.parse(@xml.at_xpath('//xmlns:FileInformation').attr('created'))
    @file_modified = Time.parse(@xml.at_xpath('//xmlns:FileInformation').attr('lastModified'))

    exp_ns = 'http://www.princetoninstruments.com/experiment/2009'.freeze # exp namespace
    # @grating @center wavelength
    @grating = @xml.at_xpath('//exp_ns:Grating/exp_ns:Selected', { 'exp_ns' => exp_ns }).text
    @center_wavelength = @xml.at_xpath('//exp_ns:Grating/exp_ns:CenterWavelength', { 'exp_ns' => exp_ns }).text
    # @exposure_time
    @exposure_time = @xml.at_xpath('//exp_ns:ShutterTiming/exp_ns:ExposureTime', { 'exp_ns' => exp_ns }).text.to_f

    # Set unit and name
    case options[:spectral_unit]
    when 'wavenumber'
      @wv = wavelengths_nm.map { |nm| 10_000_000.0 / nm } # wavanumber
      @spectrum_units = %w[wavenumber counts]
    when 'eV'
      @wv = wavelengths_nm.map { |nm| 1239.84197 / nm } # wavanumber
      @spectrum_units = %w[eV counts]
    else
      @wv = wavelengths_nm # nm
      @spectrum_units = %w[nm counts]
    end

    # Paralellization: distribution of frames to process among processes
    parallelize = options[:parallelize] || 1

    # Simple: a line of spectrum per frame
    if @rois.all? { |roi| roi[:data_height] == 1 }
      puts 'All rois contain spectra, a spectra containing spe' if debug
    # Frame contains image
    elsif debug
      puts "#{@name} has images in frames of shape #{@rois}\n Loading."
    end
  end

  # Universal accesor for all regardless of spectrum or image containing Spes
  def at(frame, roin)
    raise 'Roi and frame # must be specified' if frame.nil? || roin.nil?

    # Unbinned ROI, output array
    if @rois[roin][:data_height] > 1 && !@bin_to_spect
      result = Array.new(@rois[roin][:data_height]) { Array.new(@rois[roin][:data_width]) { 0 } }
      yi = 0
      while yi < @rois[roin][:data_height]
        result[yi] =
          @bin_data[(frame * @framesize + yi * @rois[roin][:data_width]) * 2..(frame * @framesize + (yi + 1) * @rois[roin][:data_width] - 1) * 2 + 1].unpack('S*')
        yi += 1
      end
      result.transpose

    # Output Spectrum
    else
      result = Spectrum.new
      xi = 0
      roishift = 0

      roii = 0
      while roii < roin
        roishift += @rois[roii][:data_width] * @rois[roii][:data_height]
        roii += 1
      end

      # Binning needed
      if @bin_to_spect
        bin_range = if @bin_to_spect.is_a? Array
                      @bin_to_spect
                    else
                      [0, @rois[roin][:data_height]]
                    end

        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift], 0]
          yi = bin_range[0]
          while yi < bin_range[1]
            unless @bin_data[(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2..(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2 + 1].unpack1('S')
              raise "frame #{frame} #{xi} #{yi}"
            end

            result.signal[xi] += @bin_data[(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2..(frame * @framesize + roishift + yi * @rois[roin][:data_width] + xi) * 2 + 1].unpack1('S')
            yi += 1
          end
          xi += 1
        end
      # No binning
      else
        while xi < @rois[roin][:data_width]
          result[xi] = [@wv[xi + roishift],
                        @bin_data[(frame * @framesize + roishift + xi) * 2..(frame * @framesize + roishift + xi) * 2 + 1].unpack1('S')]
          xi += 1
        end
      end
      result.meta[:name] = "#{@name}-#{frame}-roi#{roin}"

      result.meta[:units] = @spectrum_units
      result.update_info
      result
    end
  end

  def inspect
    # attr_accessor :path, :name, :xml, :frames, :frame_width, :frame_height, :wv, :spectrum_units, :data_creation, :file_creation, :file_modified, :grating, :center_wavelength, :exposure_time
    ["Spe name: #{@name}", "path: #{@path}", "Contining #{@frames} frames of dimension #{@rois.inspect}",
     "Spectral units: #{@spectrum_units}", "Data created: #{@data_creation}, file created: #{@file_creation}, file last modified: #{@file_modified}", "Grating: #{@grating} with central wavelength being #{@center_wavelength} nm", "Exposure time: #{@exposure_time} ms."].join "\n"
  end

  def to_s
    inspect
  end

  def each_frame; end
end

# Andor .sif format
class SIF < Array
  attr_accessor :path, :name, :wv, :raw, :meta, :xml

  def initialize(path, name, options = {})
    debug = options[:debug]
    @path = path
    @name = name
    @wv = [] # This is a direct attr_accessor

    # meta hash manages
    # 
    @meta = {}
    @meta[:spectrum_units] = %w[px counts]
    raise "No such file #{@path}" unless File.exist? path

    @meta[:bin_to_spect] = options[:bin_to_spect]
    @raw = File.open(@path, 'rb') { |f| f.read.freeze }

    puts "Finished reading spe #{@path} at #{Time.now.strftime('%H:%M:%S.%3N')}" if debug
    puts "Raw data has a lenght of: #{@raw.size}" if debug

    ptr = 0
    unless @raw[ptr..ptr + 35] == "Andor Technology Multi-Channel File\n"
      raise "Magic string not matching, #{@path} is no SIF file"
    end

    ptr += 36

    linel = @raw[ptr..-1].index "\n"
    @ln2 = @raw[ptr..ptr + (linel - 1)]
    ptr += (linel + 1)

    delim = @raw[ptr..-1].index(' ')
    @meta[:sif_ver] = @raw[ptr..ptr + delim - 1].to_i
    puts "SIF version #{@meta[:sif_ver]} at ptr=#{ptr}" if debug
    ptr += (delim + 1)

    raise "Expecting '0 0 1 ' but got '#{@raw[ptr..ptr + 5]}'" unless @raw[ptr..ptr + 5] == '0 0 1 '

    ptr += 6

    match = @raw[ptr..-1].match(/^(\d+)\s(\S+)\s/) # Lazy delimination w/o checking for float string fmt
    raise 'Problem extracting exposure time and temp' unless match

    @meta[:data_creation] = Time.at(match[1].to_i)
    @meta[:temperature] = match[2].to_f
    ptr += match[0].size
    puts "done extracting time(#{Time.at(@meta[:data_creation])}) and temp(#{@meta[:temperature]}) at ptr=#{ptr}" if debug

    match = @raw[ptr..-1].match(/^(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    raise "Expecting zero at #{ptr}" unless match[6] == '0'
    ptr += match[0].size
    @meta[:aftertemp_6_fields] = match[0].split(" ")
    puts "6 entries read and arrived #{ptr}" if debug

    match = @raw[ptr..-1].match(/^(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    @meta[:exposure_time] = match[1].to_f
    @meta[:cycle_time] = match[2].to_f
    @meta[:accumulated_cycle_time] = match[3].to_f
    @meta[:accumulated_cycles] = match[4].to_i
    ptr += match[0].size
    puts "4 timing entries and arrived at #{ptr}" if debug

    match = @raw[ptr..-1].match(/^\0\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    # These were not in the original attr_accessor list for meta, keeping as internal ivars
    @meta[:stack_cycle_time] = match[1]
    @meta[:pixel_readout_time] = match[2]
    ptr += match[0].size
    puts "4 more entries (stack_cycle_time, pixel_readout_time, ?, ?) and arrived #{ptr}" if debug

    match = @raw[ptr..-1].match(/^(\S+)\s(\S+)\s(\S+)\s/)
    @meta[:dac_gain] = match[1]
    ptr += match[0].size
    puts "3 more entries (dac_gain, ?, ?) and at #{ptr}" if debug


    match = @raw[ptr..-1].match(/^(\S+)\s/)
    @meta[:gate_width] = match[1] 
    ptr += match[0].size


    # 52 entries spaced by whitespace
    match = @raw[ptr..-1].match(/^(\S+)[^\n]+\n/)
    @meta[:mysterious_entries_52] = match[0].split(' ')
    @meta[:cam_serial] = @meta[:mysterious_entries_52][19]
    @meta[:current_temp] = @meta[:mysterious_entries_52][22]
    ptr += match[0].size
    puts "End of 52 entries before detector info: #{ptr}" if debug

    match = @raw[ptr..-1].match(/^(\S+)\s\n\s(\S+)\s(\S+)\s(\S+)\n/)
    @meta[:detector_name] = match[1]
    @meta[:detector_dimension] = match[2..3].map { |i| i.to_i }
    orig_filename_length = match[4].to_i
    ptr += match[0].size
    puts "End of detector name, dimension, and length of orig filename: #{ptr}" if debug

    @meta[:original_path] = @raw[ptr..ptr + orig_filename_length - 1]
    ptr += orig_filename_length
    puts "End of orig filename: #{ptr}" if debug

    match = @raw[ptr..-1].match(/\s\n65538\s([^\n]+)\n/)
    user_text_l = match[1].to_i
    ptr += match[0].size
    puts "Extracting user_text at #{ptr}, with user_text length of #{user_text_l}" if debug
    # user_text is too mysterious for now and disturbing to see
    # @meta[:user_text] = @raw[ptr..ptr + user_text_l - 1]
    ptr += user_text_l
    match = @raw[ptr..-1].match(/\n/)
    raise "Trouble at #{ptr}" unless match
    ptr += 1 # \n

    ptr += 5 # 65538 and 8 bytes

    # line for shutter times
    match = @raw[ptr..-1].match(/([^\n]+)\n65540/)
    @meta[:shutter_times] = match[1].split(" ")
    ptr += match[0].size

    # Spectrograph secret
    @meta[:spectrograph_secret] = []
    # Skip lines with respect to various SIF version
    if @meta[:sif_ver] > 65_565 # Default case 65567)
      17.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        @meta[:spectrograph_secret].push match[0]
        ptr += match[0].size
      end
      # match = @raw[ptr..-1].match(/([^\n]+)\n/)
      @meta[:spectrograph] = @meta[:spectrograph_secret][3].chomp.split(" ")[1]
      items = @meta[:spectrograph_secret][0].chomp.split(" ")
      @meta[:center_wavelength] = items[2].to_f
      @meta[:grating_lines] = items[5].to_i
      @meta[:grazing] = items[6]
      #9.times do
      #  match = @raw[ptr..-1].match(/[^\n]+\n/)
      #  @meta[:spectrograph_secret].push match[0]
      #  ptr += match[0].size
      #end
    elsif @meta[:sif_ver] >= 65_548 && @meta[:sif_ver] <= 65_557
      match = @raw[ptr..-1].match(/[^\n]+\n[^\n]+\n/)
      ptr += match[0].size
    elsif @meta[:sif_ver] == 65_558
      5.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    elsif @meta[:sif_ver] == 65_559 || @meta[:sif_ver] == 65_564
      8.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    elsif @meta[:sif_ver] == 65_565
      15.times do
        match = @raw[ptr..-1].match(/[^\n]+\n/)
        ptr += match[0].size
      end
    end
    puts "ptr at #{ptr} after spectrograph secret" if debug

    match = @raw[ptr..-1].match(/^(\S+)\s/)
    @meta[:sif_calib_ver] = match[1].to_i # Internal
    ptr += match[0].size
    if @meta[:sif_calib_ver] == 65_540
      match = @raw[ptr..-1].match(/[^\n+]\n/)
      @meta[:calib_line] = match[1] # Internal
      ptr += match[0].size
    else
      raise "I dunno how I calib!"
    end
    puts "#{ptr} after suspected spectrograph" if debug

    raise 'We do not use Mechelle spectrometers, dropping support' if @meta[:spectrograph].match(/Mechelle/)

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    
    @meta[:calibration_string_info] = match[1]
    ptr += match[0].size
    puts "Calibration found. Now ptr = #{ptr}" if debug

    # Calibration lies within here
    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    @meta[:calib] = match[1].split(' ').map { |s| s.to_f } # Calibration comes in polynomial coeffs, raising power
    @meta[:spectrum_units] = %w[nm counts] unless @meta[:calib] == [0.0, 1.0, 0.0, 0.0]
    puts "calib: #{@meta[:calib].join ', '}" if debug
    ptr += match[0].size

    # And two mysterious lines of 0 1 0 0
    match = @raw[ptr..-1].match(/[^\n]+\n[^\n]+\n/)
    puts "#{ptr}: #{match} mysterious two lines of 0 1 0 0" if debug
    ptr += match[0].size

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    @meta[:raman_line] = match[1]
    @meta[:after_raman_3line] = []
    ptr += match[0].size
    3.times do
      match = @raw[ptr..-1].match(/[^\n]+\n/)
      @meta[:after_raman_3line].push match[0]
      ptr += match[0].size
    end
    puts "After Raman line extraction, and three unknown lines to #{ptr}" if debug

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    puts "#{ptr}: #{match}" if debug
    str_l = match[1].to_i
    ptr += match[0].size
    @meta[:frame_axis] = @raw[ptr..ptr + str_l - 1] # Should determine units from here
    ptr += str_l

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    puts "#{ptr}: #{match}" if debug
    str_l = match[1].to_i
    ptr += match[0].size
    @meta[:data_type] = @raw[ptr..ptr + str_l - 1]
    ptr += str_l

    match = @raw[ptr..-1].match(/([^\n]+)\n/)
    puts "#{ptr}: #{match}" if debug
    str_l = match[1].to_i
    ptr += match[0].size
    @meta[:image_axis] = @raw[ptr..ptr + str_l - 1]
    ptr += str_l

    match = @raw[ptr..-1].match(/\S+\s(\S+)\s(\S+)\s(\S+)\s(\S+)\s/)
    @meta[:xrange] = [match[1], match[3]].map { |i| i.to_i }
    @meta[:yrange] = [match[4], match[2]].map { |i| i.to_i }
    ptr += match[0].size

    match = @raw[ptr..-1].match(/(\S+)\s(\S+)\s(\S+)\s(\S+)\s/) # \s matches \n !!!
    # @total_l, @image_l are internal
    @meta[:frames], roi_n, @total_l, @image_l = match[1..4].map { |i| i.to_i } # Guess that roi_n == no_subimages
    ptr += match[0].size
    puts "Got frame and roi info after #{ptr}. frames: #{@meta[:frames]}, number of rois: #{roi_n}, total length #{@total_l}, image length: #{@image_l}" if debug

    # Construct rois
    @meta[:rois] = Array.new(roi_n)
    (0..roi_n - 1).each do |roii|
      match = @raw[ptr..-1].match(/\S+\s(\S+) (\S+) (\S+) (\S+) (\S+) (\S+) (\S+)\n/)
      x0, y1, x1, y0, ybin, xbin = match[1..6].map { |i| i.to_i }
      ptr += match[0].size
      puts "ROI #{roii} ends at #{ptr}: " if debug
      @meta[:rois][roii] = {
        id: roii,
        x: x0 - 1,
        y: y0 - 1,
        width: x1 - x0 + 1,
        height: y1 - y0 + 1,
        xbinning: xbin,
        ybinning: ybin,
        data_width: (x1 - x0 + 1) / xbin,
        data_height: (y1 - y0 + 1) / ybin
      }
      puts "#{roii}th roi: #{@meta[:rois][roii]}" if debug
      # Calibration polynomial
      @wv += ((x0..x1).map { |x| (0..3).map { |pwr| @meta[:calib][pwr] * (x**pwr) }.reduce(:+) })
    end
    puts "ROI construction done. ptr = #{ptr}" if debug

    @meta[:timestamps] = []
    no_of_zero = 0
    (0..@meta[:frames] - 1).each do |frame|
      match = @raw[ptr..-1].match(/^\s*(\S+)\n/)
      ptr += match[0].size
      puts "ptr progressing #{match[0].size} at #{ptr}. match[1] is '#{match[1]}' from #{@raw[ptr-1-match[0].size..ptr-1]}" if debug
      if match[1].to_f == 0.0
        puts "#{match[0]} deemed to be 0.0 at #{ptr}" if debug
        no_of_zero += 1
      end
      @meta[:timestamps][frame] = match[1].to_f
      puts "Timestamp of frame #{frame} is #{@meta[:timestamps][frame]} and found at #{ptr}" if debug
    end

    if @meta[:sif_ver] == 65_567
      ptr += 2 if @raw[ptr..ptr + 1] == "0\n"
      puts 'No Arraycorrection' if debug
      puts "Came to #{ptr}" if debug
    end
    ptr += 2 if @raw[ptr..ptr + 1] == "0\n"
    @data_offset = ptr # Internal
    puts "Raw data offset: #{@data_offset}" if debug
    @meta[:framesize] = @meta[:rois].map { |roi| roi[:data_width] * roi[:data_height] }.sum
    ptr += @meta[:frames] * @meta[:framesize] * 4

    @meta[:final_lines] = []
    4.times do
      match = @raw[ptr..-1].match(/[^\n]+\n/)
      ptr += match[0].size
      @meta[:final_lines].push match[0]
      puts "4 lines eaten. ptr: #{ptr}" if debug
    end

    xml_raw = @raw[ptr..-13]
    unless xml_raw.size == @raw[-12..-9].unpack1('L')
      puts "xml size mismatch: should be #{xml_raw.size} but at the end specified as #{@raw[-12..-9].unpack1('L')}. ptr: #{ptr}"
    end

    # Set unit and name based on options
    case options[:spectral_unit]
    when 'wavenumber'
      @wv = @wv.map { |nm| 10_000_000.0 / nm } # wavenumber
      @meta[:spectrum_units] = %w[wavenumber counts]
    when 'eV'
      @wv = @wv.map { |nm| 1239.84197 / nm } # eV
      @meta[:spectrum_units] = %w[eV counts]
    else # default 'nm'
      @meta[:spectrum_units] = %w[nm counts] # Could already be this, but explicit
    end

    @xml = Nokogiri.XML(xml_raw)

  end


  def at(frame, roin)
    raise 'Roi and frame # must be specified' if frame.nil? || roin.nil?

    # Unbinned ROI, output array
    if @meta[:rois][roin][:data_height] > 1 && !@meta[:bin_to_spect]
      result = Array.new(@meta[:rois][roin][:data_height]) { Array.new(@meta[:rois][roin][:data_width]) { 0 } }
      yi = 0
      while yi < @meta[:rois][roin][:data_height]
        result[yi] =
          @raw[@data_offset + (frame * @meta[:framesize] + yi * @meta[:rois][roin][:data_width]) * 4..@data_offset + (frame * @meta[:framesize] + (yi + 1) * @meta[:rois][roin][:data_width]) * 4 + 1].unpack('F*')
        yi += 1
      end
      result.transpose

    # Output Spectrum
    else
      result = Spectrum.new
      xi = 0
      roishift = 0

      roii = 0
      while roii < roin
        roishift += @meta[:rois][roii][:data_width] * @meta[:rois][roii][:data_height]
        roii += 1
      end

      # Binning needed
      if @meta[:bin_to_spect]
        bin_range = if @meta[:bin_to_spect].is_a? Array
                      @meta[:bin_to_spect]
                    else
                      [0, @meta[:rois][roin][:data_height]]
                    end

        while xi < @meta[:rois][roin][:data_width]
          result[xi] = [@wv[xi + roishift], 0]
          yi = bin_range[0]
          while yi < bin_range[1]
            unpacked = @raw[@data_offset + (frame * @meta[:framesize] + roishift + yi * @meta[:rois][roin][:data_width] + xi) * 4..@data_offset + (frame * @meta[:framesize] + roishift + yi * @meta[:rois][roin][:data_width] + xi) * 4 + 3].unpack1('F')
            raise "frame #{frame} #{xi} #{yi}" unless unpacked

            result.signal[xi] += unpacked
            yi += 1
          end
          xi += 1
        end
      # No binning
      else
        while xi < @meta[:rois][roin][:data_width]
          result[xi] = [@wv[xi + roishift],
                        @raw[@data_offset + (frame * @meta[:framesize] + roishift + xi) * 4..@data_offset + (frame * @meta[:framesize] + roishift + xi) * 4 + 3].unpack1('F')]
          xi += 1
        end
      end
      result.meta[:name] = "#{@name}-#{frame}-roi#{roin}"
      result.meta[:units] = @meta[:spectrum_units]
      result.update_info
      result
    end
  end

  # Return array of spectra from each frame
  def spects
    result = (0..@meta[:frames]-1).map {|frame| (0..@meta[:rois].size-1).map {|roin| at(frame, roin)}}
    if @meta[:rois].size == 1
      return result.flatten
    else
      return result
    end
  end

  def inspect
    keys_to_inspect = [:data_creation, :temperature, :current_temp, :exposure_time, :frames, :spectrograph, :detector_name, :center_wavelength]
    "SIF file #{@path}, name: #{@name}.\n#{(keys_to_inspect.map {|k| "  #{k}: #{@meta[k]}"}).join("\n")}"
  end

  def to_s
    inspect
  end

  def pretty_print
    inspect
  end

  def each_frame; end
end