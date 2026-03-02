# Spectrum in memcached
# Inheritance from Array doesn't seem possible anymore
class SpectCache
  attr_accessor :cache, :name, :meta, :wv, :data

  def initialize(cache, name, options = {}) # optional data input determins init mode
    @cache = cache
    raise "Not a Memcached client!" unless @cache.is_a? Memcached::Client
    @options = options
    @name = name
    if @options[:data] # Only case that warrants a write at init would be data-containing new()
      puts "Data input at init, writing cache"
      write_cache
    else
      read_cache
    end
    self 
  end

  def read_cache
    @meta = JSON.parse(@cache.get("spect_meta_" + @name)).transform_keys {|k| k.to_sym}

    # Assuming that all rois will have the same @wv for now
    if @meta[:spect_meta]&.[]('wv_ref')
      @wv = @cache.get("spect_wv_#{@meta[:spect_meta]['wv_ref']}").unpack("#{@meta[:spect_meta]['wv_type']}*")
    else
      @wv = @cache.get("spect_wv_#{@name}").unpack("#{@meta[:spect_meta]['wv_type']}*")
    end

    begin
      time = Time.parse(@meta[:time])
    rescue
      time = nil
    end
    @meta[:time] = time
    @meta[:spect_meta].transform_keys!(&:to_sym)

    raw_data = @cache.get("spect_#{@name}").unpack("#{@meta[:spect_meta][:type]}*")
    case @meta[:acq_type]
    when 'spectrum'
      @data = Spectrum.new
      @data.meta = @meta[:spect_meta]
      @data.wv = @wv if @wv.size > 0
      @data.signal = raw_data
      @data.cache_host = @cache
    when 'tracks'
      @data = Array.new(@meta[:tracks].size) {Spectrum.new}
      @data.each_with_index do |spect, i|
        spect.meta = @meta[:spect_meta].transform_keys {|k| k.to_sym} 
        spect.wv = @wv if @wv.size > 0
        spect.signal = raw_data[i*@wv.size .. (i+1)*@wv.size - 1]
        spect.cache_host = @cache
      end
    when 'image'
      width = (@meta[:ImageROI]["hend"] - @meta[:ImageROI]["hstart"] + 1) / @meta[:ImageROI]["hbin"]
      height = (@meta[:ImageROI]["vend"] - @meta[:ImageROI]["vstart"] + 1) / @meta[:ImageROI]["vbin"]
      @data = (0..height-1).map {|y| raw_data[y*width .. (y+1)*width - 1]}
    end
    true
  end

  def write_cache
    # Determine datafield type. Save space and time on integers! Default to double.
    type = @meta[:spect_meta][:type] ? @meta[:spect_meta][:type] : 'D'
    wvtype = @meta[:spect_meta][:wv_type] ? @meta[:spect_meta][:wv_type] : 'D'
    @cache.set "spect_" + @name, @data.pack("#{type}*")
    @cache.set "spect_meta_" + @name, @meta.to_json

    # See if wv needs to be set
    # Assume wavelength type to always be double
    if @meta[:wv_ref] == nil
      @cache.set "spect_wv_"+ @name, wv.pack("#{wvtype}*")
    end
    true
  end

  def to_spectrum
    read_cache

    spect
  end

end