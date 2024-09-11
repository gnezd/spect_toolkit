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

end