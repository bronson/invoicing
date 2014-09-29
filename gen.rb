#!/usr/bin/env ruby

require 'bundler/setup'
require 'wkhtmltopdf/heroku'
require 'pdfkit'
require 'slim'
require 'tilt'

# apparently wkhtmltopdf does try to support page-break-inside: avoid

title = 'Invoice NUM'

stylesheets = %w[
  pocketgrid.css
  styles.css
]

html = Tilt.new('invoice.slim').render(nil, title: title, stylesheets: stylesheets)
File.write('inv.html', html)

# can also pass params in meta tags: <head><meta name="pdfkit-page_size" content="Letter">...
kit = PDFKit.new(html, page_size: 'Letter', title: title, outline: true)
kit.stylesheets.concat stylesheets
file = kit.to_file('/tmp/tt.pdf')

puts "Output in #{file.path}"
