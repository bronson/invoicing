#!/usr/bin/env ruby

require 'bundler/setup'
require 'wkhtmltopdf/heroku'
require 'pdfkit'

# apparently wkhtmltopdf does try to support page-break-inside: avoid

title = 'Invoice NUM'

stylesheets = %w[
  pocketgrid.css
  styles.css
]

html = <<EOL
<!doctype html>
<html>
<head>
  <title>#{title}</title>
  <meta name='viewport' content='width=device-width, initial-scale=1.0'/>
#{ stylesheets.map do |sheet|
     "  <link rel='stylesheet' href='#{sheet}'/>"
   end.join("\n") }
</head>
<body>

<div class='block-group'>
  <div class='metadata block'>
    <div class='invoice'>Invoice 13</div>
    <div class='date'>Sep 28, 2014</div>
  </div>

  <div class='sender block'>
    <div class='name'>AUTHOR NAME<div>
    <div class='address'>AUTHOR ADDRESS</div>
    <div class='address2'>AUTHOR CITY, STATE ZIP</div>
    <div class='phone'>AUTHOR PHONE</div>
  </div>

  <div class='recipient block'>
    <div class='name'>CLIENT NAME</div>
    <div class='address'>CLIENT ADDRESS</div>
    <div class='address2'>CLIENT CITY, STATE ZIP</div>
  </div>

</div>

</body>
</html>
EOL

File.write('inv.html', html)

# can also pass params in meta tags: <head><meta name="pdfkit-page_size" content="Letter">...
kit = PDFKit.new(html, page_size: 'Letter', title: title, outline: true)
kit.stylesheets.concat stylesheets
file = kit.to_file('/tmp/tt.pdf')

puts "Output in #{file.path}"
