# Script for the processing of micro-PL scann data
VERSION = '2025Sep28-test'.freeze
require 'time'
require 'json'
require 'fileutils'
require 'memcached' if Gem.find_files('memcached') != []

$LOAD_PATH.push __dir__
require 'src/scan'
require 'src/spectrum'
require 'src/spect_data_formats'
require 'src/alignment'
require 'src/plot_fit'