class Alignment
  attr_accessor :name, :coords, :control_pts

  # Record alignment with OM pictures named with microstage coordinate: c1-xx.xxx-yy.yyy-zz.zzz.bmp
  def initialize(name, alignment_dir)
    coords_arr = []
    @control_pts = []
    @name = name
    raise "Not valid path: #{alignment_dir}" unless Dir.exist? alignment_dir

    control_point_files = Dir.glob alignment_dir + '/*.bmp'
    control_point_files.sort_by! { |fname| File.basename(fname).split('_')[0].to_f }
    control_point_files.each do |fn|
      # Old alignment name convention
      if match = File.basename(fn).match(/^([^-]+)-(\d+\.\d\d\d)-(\d+\.\d\d\d)-(\d+\.\d\d\d)/)
        # coords_arr.push [match[2].to_f, match[3].to_f, match[4].to_f]
        # 2-dim for now for 3-dim requires more testing. rotator_solve might yet be incompatible
        coords_arr.push [match[2].to_f, match[3].to_f]
        @control_pts.push [match[1], fn]
      elsif match = File.basename(fn, '.bmp').match(/_(-?\d+)_(-?\d+)_?(-?\d\.?\d*)?/)
        coords_arr.push [match[1].to_f, match[2].to_f]
        @control_pts.push [File.basename(fn, '.bmp'), fn]
      end
    end
    @coords = GSL::Matrix.alloc(coords_arr.flatten, coords_arr.size, 2)
  end

  # Express position recorded in alignment x_0 in this alignment coordinate
  def express(x_0, pos)
    rotator, displacement = relative_to(x_0)
    pos * rotator + displacement
  end

  # x1.relative_to(x0) gives the rotation and displacement so that x0*rotation + displacement = x1
  def relative_to(x_0)
    raise 'x_0 is not an Alignment' unless x_0.is_a? Alignment
    raise 'x_0 is not an Alignment' unless x_0.is_a? Alignment
    raise 'Size mismatch' unless x_0.coords.size == coords.size

    (0..x_0.coords.size1 - 1).each do |i|
      raise 'Control points mismatch' unless x_0.control_pts[i][0] == control_pts[i][0]
    end
    rotator = rotator_solve(row_diff(x_0.coords.size1) * x_0.coords) * row_diff(@coords.size1) * @coords
    displacement = center_of_mass(@coords) - center_of_mass(x_0.coords * rotator)
    [rotator, displacement]
  end
end

# Gives the rotation matrix needed to rotate origin to a resulting point set, when acted on that point set
# Quick 'n dirty func. to convert plot coord. to piezo coord.
def coord_conv(pl_scan_orig, orig_dim, map_dimension, coord)
  [coord[0].to_f / map_dimension[0] * orig_dim[0] + pl_scan_orig[0],
   coord[1].to_f / map_dimension[1] * orig_dim[1] + pl_scan_orig[1]]
end

def rotator_solve(origin)
  (origin.transpose * origin).invert * origin.transpose
end

def rotator(angle)
  GSL::Matrix.alloc([Math.cos(angle), Math.sin(angle)], [-Math.sin(angle), Math.cos(angle)]).transpose
end

def row_diff(size)
  result = GSL::Matrix.I(size)
  (0..size - 2).each { |j| result.swap_rows!(j, j + 1) }
  GSL::Matrix.I(size) - result
end

def center_of_mass(x)
  # In form of:
  # [[x1 y1]
  # [x2 y2]]
  # ...
  result = GSL::Vector.alloc(x.size2)
  x.each_row do |row|
    result += row
  end
  result / x.size1
end

def plot_alignments(alignments)
  raise 'Input Alignments!' unless alignments.is_a? Array && alignments.all? { |a| a.is_a? Alignment }

  points_data = ''
  alignments.each do |_alignment|
    points_data
  end
end