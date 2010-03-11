using Gtk;

namespace Snap
{
	class PhotoViewerWindow : Gtk.Window
	{
		private Gtk.HBox hbox;
		private GLib.SList<PhotoViewer> viewers;

		PhotoViewerWindow (string[] args)
		{
			this.hbox = new Gtk.HBox (false, 0);
			this.add (this.hbox);
			this.set_default_size (800, 600);
			this.set_default_icon_name ("camera-photo");
			this.title = "Photo view widget test";
			this.destroy += this.quit;

			for (int i = 1; i < args.length; ++i)
			{
				GLib.File file = GLib.File.new_for_commandline_arg (args[i]);
				PhotoViewer pv = new PhotoViewer (file.get_path ());
				viewers.append (pv);
				this.hbox.pack_start (pv.container, true, true, 0);
				pv.error += this.handle_error;
				pv.loaded += this.handle_loaded;
			}
		}

		private void handle_error (string message)
		{
			Gtk.MessageDialog explanation = new Gtk.MessageDialog (
				(Gtk.Window) this,
				Gtk.DialogFlags.MODAL,
				Gtk.MessageType.ERROR,
				Gtk.ButtonsType.OK,
				"%s\n\n The application must die now.".printf (message));
			explanation.response += this.quit;
			explanation.run ();
		}

		private void handle_loaded ()
		{
			debug ("LOADED!");
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		static void main (string[] args)
		{
			Gtk.init (ref args);

			var p = new PhotoViewerWindow (args);
			p.show_all ();

			Gtk.main ();
		}
	}
}
