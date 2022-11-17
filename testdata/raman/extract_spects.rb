require '~/microPL_scan.git/lib.rb'


scan_param = JSON::parse(File.open('./Scan_param165942_261_1 microPL').read)
scan = Scan.new './261_1 11-11-2022 16_59_36 19 microPL.spe', '261_1', [scan_param['Points X'], scan_param['Points Y'], scan_param['Points Z']]
scan.load({s_scan: scan_param['S-shape scan'], spectral_unit: 'wavenumber'})

plot_spectra [scan[4][0][0][0], scan[4][14][0][0], scan[3][8][0][0], scan[11][9][0][0], scan[18][10][0][0]], {out_dir: 'representative_pts'}