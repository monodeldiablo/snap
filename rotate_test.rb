require 'dbus_helper'

s = Snap.new
dir = '/home/brian/test_photos'

Dir.foreach(dir) do |file|
  unless ['.', '..'].include?(file)
    path = dir + '/' + file
    s.rotate_photo(path, 90)
  end
end
