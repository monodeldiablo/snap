class Snap
  def import_photo(path)
    dbus_send("ImportDaemon", "ImportPhoto", ["string:'#{path}'"])
  end

  def rotate_photo(path, degrees)
    dbus_send("RotateDaemon", "RotatePhoto", ["string:'#{path}'", "int32:#{degrees}"])
  end

  def delete_photo(path)
    dbus_send("DeleteDaemon", "DeletePhoto", ["string:'#{path}'"])
  end
  
  def tag_photo(path, tag)
    dbus_send("TagDaemon", "TagPhoto", ["string:'#{path}'", "string:'#{tag}'"])
  end

  private

  def dbus_send(interface, method, args = [])
    `dbus-send --print-reply --dest=org.washedup.Snap.#{interface} /org/washedup/Snap/#{interface} org.washedup.Snap.#{interface}.#{method} #{args.join(" ")}`
  end
end
