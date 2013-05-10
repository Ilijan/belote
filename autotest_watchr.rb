system 'cls'

watch('test/(.*)_tests.rb') do |md| 
  system 'cls'
  system "echo Modified #{md[0]}"
  #system "ruby -w #{md[0]}"
  system "rspec -r '.\\lib\\#{md[1]}.rb' #{md[0]}"
end

watch('lib/(.*).rb') do |md|
  system 'cls'
  system "echo Modified #{md[0]}"
  system "ruby -w #{md[0]}"
  system "rspec -r '.\\#{md[0]}' .\\test\\#{md[1]}_tests.rb"
end