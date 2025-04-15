require 'minitest/autorun'
require './lib'
require 'pry'

class TestSpectrum < Minitest::Test
  def setup
    tsv_files = Dir.glob('./testdata/spectra/*.tsv')
    pick = rand(tsv_files.size)
    @spect_tsv = Spectrum.new(tsv_files[pick])
    @spect_tsv.desc = tsv_files[pick]

    assert_equal @spect_tsv.signal.size, @spect_tsv.wv.size
    assert_equal @spect_tsv.units[1], 'counts'
  end

  def test_write_tsv
    @spect_tsv.write_tsv('./temp.tsv')
    assert_equal true, File.exist?('./temp.tsv') # File written?
    reread_spect = Spectrum.new('./temp.tsv')
    reread_spect.write_tsv('./temp2.tsv')
    assert_equal '', `diff ./temp.tsv ./temp2.tsv` # Content unchanged?
    `rm temp.tsv temp2.tsv`
  end

  def test_indexing
    # Retrieve a point. It should be an Array with size 2, and both entries a Numeric
    assert_kind_of Array, @spect_tsv[rand(@spect_tsv.size)]
    assert_equal 2, @spect_tsv[rand(@spect_tsv.size)].size
    assert_kind_of Numeric, @spect_tsv[rand(@spect_tsv.size)][0]
    assert_kind_of Numeric, @spect_tsv[rand(@spect_tsv.size)][1]

    # Retrieving range
    first, last = [rand(@spect_tsv.size), rand(@spect_tsv.size)].sort
    range = (first..last)
    puts "Randomly taking #{range} from @spect_tsv"
    slice = @spect_tsv[range]
    assert_equal range.size, slice.size
    index_in_slice = rand(slice.size)
    puts "Randomly checking if slice[#{index_in_slice}] == @spect_tsv[#{first+index_in_slice}]"
    assert_equal slice[index_in_slice], @spect_tsv[index_in_slice+first]
  end

  def test_cache
    # Prepare spectrum
    sp1 = Spectrum.new
    (0..99).each do |x|
      sp1.push [x, rand(65536)]
    end
    
    # Set types
    sp1.meta[:type] = 'S'
    sp1.meta[:wv_type] = 'S' # 0 ~ 65535

    # Create SpectCache and type check
    sp1_cached = sp1.to_cache
    puts "Created SpectCache with name #{sp1_cached.name}"
    assert_kind_of SpectCache, sp1_cached
    
    # Convert back to Spectrum and value check
    sp2 = sp1_cached.to_spectrum
    (0..99).each do |i|
      assert_equal sp1[i], sp2[i]
    end
    puts "SpectCache #{sp1_cached.name} transformed back to Spectrum and value was the same"

    # Create valued spectrum
    sp3 = Spectrum.new
    sp3.meta[:name] = 'sp3'
    sp3.meta[:type] = 'S'
    sp3.meta[:wv_type] = 'S'
    sp3.signal= (0..99).to_a.map {rand(65536)}
    sp3.meta[:wv_ref] = sp1.meta[:name]
    sp3_spcache = sp3.to_cache
    sp3 = sp3_spcache.to_spectrum
    puts "SpectCache #{sp3.name} created reusing wavelength of SpectCache #{sp1.name}"

    assert_equal sp3.wv, sp1.wv
    puts "And their wvs are the same"

  end

  def test_resample
    sp1 = Spectrum.new
    sp1.wv = [1,2,3,4]
    sp1.signal = [1, 2, 2, 1]
    sp2 = Spectrum.new
    sp2.wv = [0.5, 2, 2.5, 5]
    sp2.signal = [1, 1, 1, 1]

    sp3 = sp1.resample(sp1.wv.union(sp2.wv), true)
    assert_equal sp3.wv.sort, [0.5, 1,2, 2.5, 3, 4, 5]
    assert_equal sp3.signal, [0.5, 1, 2, 2, 2, 1, 0]
  end

  def test_sif_map
    sif1 = SIF.new 'testdata/Andor/mapping/3-4-3.sif', 'sif1', {bin_to_spect: true}
    scan1 = Scan.new 'testdata/Andor/mapping/3-4-3.sif', 'sifscan', nil, {param_json: 'testdata/Andor/mapping/Scan_param-test-3-4-3-105505.json'}
    scan1.load
    scan1.plot_map('scratch/sifmap', {scale: 10}) {|x| x[0].sum}
    # 顧頭顧尾
    assert_equal sif1.at(0,0).sum, scan1.map_data[0][0][0]
    assert_equal sif1.at(sif1.frames-1,0).sum, scan1.map_data[-1][-1][-1]
  end

  def test_add
    spectrum1 = Spectrum.new
    spectrum2 = Spectrum.new

    spectrum1.push [1.0, 1.0]
    spectrum1.push [2.0, 2.0]
    spectrum2.push [1.0, 2.0]
    spectrum2.push [2.0, 3.0]
    spectrum3 = spectrum1 + spectrum2
    puts spectrum3.signal
    assert_equal [1.0, 3.0], spectrum3[0]
  end

end