require 'minitest/autorun'
require './lib'

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
end