# spect_toolkit
  A collection of scripts to deal with spectroscopy experiments and result visualization, especially:
  1. Micro PL image mapping
  1. Angle dependent PL
  1. Raman mapping

## Requirements
  Ruby 3.0; Ruby gems gsl/rb-gsl, nokogiri, json; Gnuplot.

## Usage
  ```Ruby
  require 'lib'
  ```
  Please see `test.rb` for usage examples.

## Files
- `lib.rb`: The main library.
- `test.rb`: Accumulated test usages during development.
- `testdata/`: Data for testing.
- `scaffolds/`: Functionalities under construction.

## Licensing
  [GPLv3](LICENSE)