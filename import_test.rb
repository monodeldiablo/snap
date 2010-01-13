require 'dbus_helper'

s = Snap.new
dir = '/home/brian/test_photos'

Dir.foreach(dir) do |file|
  unless ['.', '..'].include?(file)
    path = dir + '/' + file
    s.import_photo(path)
  end
end
