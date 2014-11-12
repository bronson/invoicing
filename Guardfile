# Add files and commands to this file, like the example:
#   watch(%r{file/path}) { `command(s)` }
#

guard :shell do
  watch(/(.*).(css|hours|json|mbox|rb|slim)|TOTALS/) { |m| `./run` }
end

guard :bundler do
  watch('Gemfile')
end
