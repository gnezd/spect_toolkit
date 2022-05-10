require './lib.rb'

plotlines = []


spect1 = Spectrum.new 'fft_contest/10-spect.tsv'
spect2 = Spectrum.new 'fft_contest/24_11_0.tsv'

spects = [spect1, spect2]
spects.each do |spect|
    ma = []
    fts = []
    plotlines = []
    puts "Doint #{spect.name}. ma.size = #{ma.size}"
    (0..5).each do |i|
        radius = 2 * i 
        sp1ma = spect.ma(radius)

        ft = GSL::Vector.alloc(sp1ma.map{|pt| pt[1]}).fft
        ft = ft[0..199] #cutoff ^.<
        ft = ft.to_complex2.abs
        fts.push ft

        ma.push sp1ma

        sp1ma.write_tsv "fft_contest/#{spect.name}-ma-#{radius}.tsv"

        ftout = File.new "fft_contest/#{spect.name}-ma-#{radius}-ft.tsv" , 'w'
        ft.each_index do |i|
            ftout.puts "#{i}\t#{ft[i]}"
        end
        ftout.close

        plotlines.push "'fft_contest/#{spect.name}-ma-#{radius}.tsv' with lines t 'ma radius #{radius}' lt #{i+1}"
        plotlines.push "'fft_contest/#{spect.name}-ma-#{radius}-ft.tsv' u 1:($2) with lines t 'ft #{radius}' axes x2y2 lt #{i+1}"

    end

    # Try ft[0] - ft[9]
    puts "fts[0] * fts[0]: #{fts[0]*fts[0]}"
    puts "fts[5] * fts[5]: #{fts[5]*fts[5]}"
    diff = fts[0] - fts[5]
    diff = diff.to_complex2.abs
    diff_out = File.new "fft_contest/diff-#{spect.name}.tsv", 'w'
    fts[0].each_index do |i|
        diff_out.puts "#{i}\t#{fts[0][i]-fts[5][i]}"
    end
    diff_out.close
    plotlines.push "'fft_contest/diff-#{spect.name}.tsv' u 1:($2) with lines t 'ft diff #0-#4' axes x2y2 lt 11"

    plotline = "plot " + plotlines.join(", \\\n")
    ft_plot_directive = <<GPLOT
    set terminal svg size 800,600 mouse enhanced standalone
    set linetype 1 lc rgb "black"
    set linetype 2 lc rgb "dark-red"
    set linetype 3 lc rgb "olive"
    set linetype 4 lc rgb "navy"
    set linetype 5 lc rgb "red"
    set linetype 6 lc rgb "dark-turquoise"
    set linetype 7 lc rgb "dark-blue"
    set linetype 8 lc rgb "dark-violet"
    set linetype cycle 8
    set output 'fft_contest/#{spect.name}-ft.svg'
    set title 'FT'
    set ylabel 'Spectrum counts'
    set y2label 'Normalized FFT intensity'
    set y2tics
    set x2tics
    set yrange [0:*]
    set y2range [0:40000]
    set x2range [3:*]
GPLOT
    gplot_out = File.open "fft_contest/fft-#{spect.name}.gplot", 'w'
    gplot_out.puts ft_plot_directive
    gplot_out.puts plotline
    gplot_out.close
    `gnuplot fft_contest/fft-#{spect.name}.gplot`

end
