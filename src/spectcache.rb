# Spectrum in memcached
# Inheritance from Array doesn't seem possible anymore
class SpectCache
  attr_accessor :cache, :name, :meta, :wv, :data

  def initialize(cache, name, options = {}) # optional data input determins init mode
    @cache = cache
    raise "Not a Memcached client!" unless @cache.is_a? Memcached::Client
    @name = name
    @meta = options[:meta]
    @data = options[:data]
    @wv = options[:wv]
    if @data # Only case that warrants a write at init would be data-containing new()
      puts "Data input at init, writing cache"
      write_cache
    end
    self 
  end

  def read_cache
    @meta = JSON.parse(@cache.get("spect_meta_" + @name)).transform_keys {|k| k.to_sym}
    if @meta[:wv_ref]
      @wv = @cache.get("spect_wv_#{meta[:wv_ref]}").unpack("#{meta[:wv_type]}*")
    else
      @wv = @cache.get("spect_wv_#{@name}").unpack("#{meta[:wv_type]}*")
    end
    @data = @cache.get("spect_#{@name}").unpack("#{meta[:type]}*")
    true
  end

  def write_cache
    # Determine datafield type. Save space and time on integers! Default to double.
    type = @meta[:type] ? @meta[:type] : 'D'
    wvtype = @meta[:wv_type] ? @meta[:wv_type] : 'D'
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
    spect = Spectrum.new
    spect.meta = @meta
    spect.wv = @wv if @wv.size > 0
    spect.signal = @data
    spect.cache_host = @cache

    spect
  end

end