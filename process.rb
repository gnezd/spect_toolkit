require './lib.rb'
require 'benchmark'
# Indicate what data to plot!
scans = [['./microPL - 12Apr-2566-5/mappings/2022 四月 12 15_27_19.csv', '12Apr-2566-5-scan1', 40, 40],
['microPL - 12Apr-2566-1/2022 四月 12 16_52_17.csv', '12Apr-2566-1-scan1', 40, 40],
['microPL - 12Apr-2566-1/2022 四月 12 18_19_01.csv', '12Apr-2566-1-scan2', 40, 40]
]

#scans = [['13Apr-microPL/microPL - 2022 四月 13 23_25_47.csv', '13Apr-ZB_bake_1-scan1', 50, 50]]
#scans = [['15Apr-survey-scans/2566-1-survey-scan 2022 四月 15 16_11_51 microPL.csv', '2561-survey', 95, 90]]
scans = [['18A-2566-5-scan/2566-5-survey-scan.csv', '2566-5-survey', 90, 90, 3]]
scans = [['20Apr-2566-5-survey-scan/survey1-70-70-1 19_07_02 microPL.csv', '2566-5-survey', 70, 70, 1]]
scans = [['20Apr-2566-5-zoom_in/zoom-in-1 21_50_08 microPL.csv', '2566-5-zoom_in', 16, 16, 3]]
scans = [['20Apr-2566-5-zoom_in/zoom_in_2 22_35_03 microPL.csv', '2566-5-zoom_in-2', 16, 16, 3]]
scans = [['18Apr-2566-5-scan/2566-5-survey-scan.csv', '2566-5-survey', 90, 90, 3]]
scans = [['../Workspace/Q2/28Apr-microPL/zoom_in_1_scan -buffercorected.csv', '2566-5-zoomin-28Apr', 15, 15, 1]]
scans = [['../Workspace/Q2/28Apr-microPL/survey-2 14_11_48 microPL.csv', '2566-5-survey-28Apr', 180, 180, 1]]
scans = [['../Workspace/Q2/28Apr-microPL/10-34-w30h30d20-90-90-3-scan 00_45_19 microPL.csv', '28Apr-2566-5-zoomin-2', 90, 90, 3]]
scans = [['../Workspace/Q2/28Apr-microPL/zoomin2-1945-trimmed.csv', '28Apr-2566-5-zoomin-1', 50, 50, 3]]
scans = [['../Workspace/Q2/29Apr-microPL/mapping/64-84.9-w15h15d5-45x45x3 10_36_52 microPL.csv', '29Apr-2566-5-zoomin-3', 45, 45, 3]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/30Apr/mapping/2561-a random sphere 2022 五月 01 00_01_12 microPL.csv', '29Apr-2561-3 random sphere 1', 32, 32, 4],
['/mnt/h/Dropbox/RCAS/Workspace/Q2/01May/mappings/2561-a random sphere2 2022 五月 01 07_28_34 microPL.csv', '01May-2561-3-random sphere 2', 64, 64, 4],
['/mnt/h/Dropbox/RCAS/Workspace/Q2/01May/mappings/2561-a random sphere2 2022 五月 01 13_18_28 microPL.csv', '01May-2561-3-random sphere 3', 30, 30, 1]
]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/02-May/mappings/2564-1-survey-9.944-14.691-3.465 09_16_44 microPL.csv', '02May-2564-1-survey', 180, 180, 1]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/02-May/mappings/2564-1-zoomin-50-50-3-pz12-61-10x10 13_10_44 microPL.csv', '02May-2564-1-zoom_in_1', 50, 50, 3]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/02-May/mappings/Zoom_in_2/2564-1-zoomin-50-50-3-pz49-29-10x10 16_06_04 microPL.csv', '02May-2564-1-zoom_in_2', 50, 50, 3]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/02-May/mappings/sampling area2-10.85-14.665 microPL/2564-1-sampling-area-2 19_53_59.csv', '02May-2564-1-survey-2', 180, 180, 1]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/03-May/mappings/2564-1-area-2-zoomin1-68-25 15_56_39 microPL.csv', '03May-zoom_in_3', 80, 80, 3]]
scans = [['/mnt/h/Dropbox/RCAS/Workspace/Q2/03-May/mappings/2564-1-area-2-zoomin2-9-38 19_17_31 microPL.csv', '03May-zoom_in_4', 100, 100, 3]]
time = Benchmark.realtime {
scans.each do |scan|
  z_slices = sum_up(scan)
  z_slices.each do |slice|
    plot_map(slice, scan[2], scan[3])
  puts "-----"
  end
end
}

puts "Time used: #{time} seconds."