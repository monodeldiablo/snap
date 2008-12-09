/* snap.vala
 *
 * Copyright (C) 2008  Brian Davis
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Brian Davis <brian.william.davis@gmail.com>
 */

using GLib;
using DBus;
/*
   FIXME: This should be Xesam.
*/
//using Tracker;
using Gdk;
/* 
   FIXME: This belongs elsewhere. Separate UI from logic.
*/
using Gtk;

//[DBusInterface (name = "org.freedesktop.Tracker.Search")]
//interface Tracker.Search;

//[DBusInterface (name = "org.freedesktop.Tracker.Keywords")]
//interface Tracker.Keywords;

/* 
   FIXME: This should contain more fields to reduce code and complexity later.
*/
public enum MAIN_COLS {
	THUMB_URI,
	THUMB,
	/*
	URI,
	IMAGE,
	*/
	NUM
}

public enum TAG_COLS {
	/*
	DISPLAY_NAME,
	*/
	TAG_NAME,
	NUM
}

public class Snap.Client : GLib.Object {
	private DBus.Connection conn;
	private dynamic DBus.Object text_search;
	private dynamic DBus.Object tag_search;
	private Gtk.Builder ui;

	/*
	   FIXME: These variables need more descriptive names. Think: What they do, 
	          not what they are.
	*/
	Gtk.Window window;
	Gtk.IconView icon_view;
	Gtk.ListStore icon_store;
	Gtk.TreeView tag_view;
	Gtk.ListStore tag_store;
	Gtk.Entry search_entry;
	Gtk.ToolButton search_button;
	Gtk.Label status_label;
	Gtk.ProgressBar progress_bar;
	
	/* 
	   Build the user interface.
	*/
	construct {
		ui = new Gtk.Builder ();
		
		try {
			//ui.add_from_file (Path.build_filename(Config.PACKAGE_DATADIR, "main.ui"));
			ui.add_from_file (Path.build_filename("data", "main.ui"));
		} catch (GLib.Error e) {
			critical ("Error while initializing Snap: %s", e.message);
		}
		
		/* 
		   Set up the UI and connect the relevant structures.
		*/
		icon_store = new Gtk.ListStore (MAIN_COLS.NUM, typeof(string), typeof(Pixbuf));
		icon_view = (Gtk.IconView) ui.get_object ("icon_view");
		icon_view.set_model (icon_store);

		tag_store = new Gtk.ListStore (TAG_COLS.NUM, typeof(string));
		tag_view = (Gtk.TreeView) ui.get_object ("tree_view");
		tag_view.insert_column_with_attributes (0, "Tags", new Gtk.CellRendererText ());
		
		status_label = (Gtk.Label) ui.get_object ("status_label");
		progress_bar = (Gtk.ProgressBar) ui.get_object ("progress_bar");
		
		search_entry = (Gtk.Entry) ui.get_object ("search_entry");
		search_button = (Gtk.ToolButton) ui.get_object ("search_button");
		search_button.clicked += search_button_clicked;
		
		window = (Gtk.Window) ui.get_object ("window");
		window.destroy += Gtk.main_quit;

		/*
		   Initialize the Tracker session.
		*/
		conn = DBus.Bus.get (DBus.BusType .SESSION);
		text_search = conn.get_object ("org.freedesktop.Tracker", "/org/freedesktop/tracker", "org.freedesktop.Tracker.Search");
		tag_search = conn.get_object ("org.freedesktop.Tracker", "/org/freedesktop/tracker", "org.freedesktop.Tracker.Keywords");

		/*
		   Pre-populate the tag sidebar with values.
		   FIXME: Vala doesn't seem to like arrays of arrays of strings, but the
		          GetList() method returns an array of results in the form of
		          [keyword, keyword count].
		*/
		string[,] tags;

		try {
			tags = tag_search.GetList ("Images");
		} catch (GLib.Error e) {
			critical ("Error while fetching tags: %s", e.message);
		}
		
		foreach (string tag in tags) {
			Gtk.TreeIter iter;
			
			tag_store.append (out iter);
			tag_store.set (iter, TAG_COLS.TAG_NAME, tag[0]);
		}
		
		tag_view.set_model (tag_store);

		/*
		   Finish up the initialization sequence.
		*/
		window.show_all ();
		progress_bar.hide ();
	}
	
	private void search_button_clicked (Gtk.ToolButton button) {
		string filter = "Images";
		string query;
		int offset = 0;
		int max_hits = 1024;
		string[] files;
		int count = 0;
		
		message ("Search activated!");

		/* 
		   FIXME: Remove timing code.
		*/
		//GLib.TimeVal start;
		//GLib.TimeVal end;
		
		//start.get_current_time ();
		
		message ("Initiating search...");
		
		query = search_entry.get_text ();
		files = text_search.Text (1, filter, query, offset, max_hits);

		message ("Search complete!");
		
		/* 
		   FIXME: Remove the store and populate it separately from the icon_view (is this
		          necessary?). 
		*/
		icon_view.set_model (null);
		icon_store = new Gtk.ListStore (MAIN_COLS.NUM, typeof(string), typeof(Pixbuf));
		
		/* 
		   Reset the status bar label and show the progress bar in preparation for 
		   the load. 
		*/
		status_label.set_text ("");
		progress_bar.show ();
		
		foreach (string file in files) {			
			add_file_to_store (file);
			
			count += 1;
			
			progress_bar.fraction = ((double) count / (double) files.length);
			progress_bar.text = "Loading %d of %d images...".printf (count, files.length);
			
			/* 
			   FIXME: This is completely arbitrary, albeit fast. 3 is not significant.
			*/
			if (count % 3 == 0) {
				flush ();
			}
		}
		
		/* 
		   FIXME: Reattach the store from the previous hack.
		*/
		icon_view.set_model (icon_store);
		
		//end.get_current_time ();		
		//message ("Search and population took %d sec.", end.tv_sec - start.tv_sec);
		
		progress_bar.hide ();
		status_label.set_text ("Found %d images matching '%s'.".printf (count, query));
	}
	
	/* 
	   Flush pending events to the screen to give the illusion of snappy UI. In 
	   truth, this is actually slower than a few threads or even a single 
	   straightforward thread, with no flushing. 
	*/
	private void flush () {
		while (Gtk.events_pending ()) {
			Gtk.main_iteration ();
		}
	}
	
	private void add_file_to_store (string file) {
		Gtk.TreeIter iter;
		Gdk.Pixbuf pix;
		string path;
		
		message ("Adding %s to store...", file);
		
		try {
			path = get_thumb_path(file);

			/* 
			   FIXME: Substitute a stock image if 'path' doesn't exist. Start a new 
			          thread that checks the 'large' thumbs dir first. If it finds 
			          nothing, it can attempt to build a thumb. If that fails, it 
			          quits, leaving 'pix' as the stock image.
			*/
			if (GLib.FileUtils.test (path, FileTest.EXISTS)) {
				pix = new Gdk.Pixbuf.from_file (path);
			} else {
				Gtk.IconTheme theme = new Gtk.IconTheme ();
				theme = Gtk.IconTheme.get_default ();
				
				/*
				   FIXME: 128 pixels shouldn't be hard-coded here. This is the size of a
				          FDO "normal" thumbnail, though.
				*/
				pix = theme.load_icon ("gnome-mime-image", 128, Gtk.IconLookupFlags.FORCE_SVG).copy ();
			}

			icon_store.append (out iter);
			icon_store.set (iter, MAIN_COLS.THUMB, pix, MAIN_COLS.THUMB_URI, GLib.Filename.display_basename (file));
		} catch (GLib.Error e) {
			critical ("Error while loading %s: %s", file, e.message);
		}
	}

	private string get_thumb_path (string image_path) {
		string uri;
		string digest;
		string path;

		/*
		   FIXME: This is the only function we require from libgnome and, as of GLib
		          2.16, we no longer actually need it. Kill it and replace with:
		*/
		
		uri = GLib.Filename.to_uri (image_path);
		digest = GLib.Checksum.compute_for_string(GLib.ChecksumType.MD5, uri, -1);
		path = GLib.Path.build_filename(GLib.Environment.get_home_dir(), ".thumbnails/normal", digest + ".png");
	
		return path;	
	}

	static int main (string[] args) {
		Gdk.threads_init ();
		
		Gtk.init (ref args);

		var snap = new Snap.Client ();
		
		Gtk.main ();
		
		return 0;
	}
}
