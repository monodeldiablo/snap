/*
 * thumb_browser.vala
 *
 * This file is part of Snap, the simple photo workflow manager.
 *
 * Copyright (C) 2008-2010 by Brian Davis <brian.william.davis@gmail.com>
 *
 * Snap is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Snap is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Snap; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, 
 * Boston, MA  02110-1301  USA
 */

using GLib;
using Gee;
using Gtk;
using DBus;

namespace Snap
{
	public enum ThumbBrowserColumns
	{
		PATH,
		PIXBUF,
		NUM_COLUMNS
	}

	public class ThumbBrowser : GLib.Object
	{
		public Gtk.IconView view;
		public Gtk.ListStore store;
		private dynamic DBus.Object preferences_daemon;

		public signal void selected (string [] paths);
		public signal void activated (string path);

		public ThumbBrowser ()
		{
			this.set_up_connections ();
			this.set_up_ui ();

			// FIXME: WTF?!
			/*
			string photo_directory = this.preferences_daemon.get_preference ("photo-directory");
			string thumb_dir = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				photo_directory,
				"thumb");

			GLib.FileEnumerator thumbs = GLib.File.new_for_path (thumb_dir).enumerate_children ("*",
				GLib.FileQueryInfoFlags.NONE,
				null);
			*/
		}

		private void set_up_connections ()
		{
			try
			{
				DBus.Connection conn;

				conn = DBus.Bus.get (DBus.BusType.SESSION);
				this.preferences_daemon = conn.get_object ("org.washedup.Snap.Preferences",
					"/org/washedup/Snap/Preferences",
					"org.washedup.Snap.Preferences");
			}

			catch (DBus.Error e)
			{
				critical (e.message);
			}
		}

		private void set_up_ui ()
		{
			this.store = new Gtk.ListStore (ThumbBrowserColumns.NUM_COLUMNS,
				typeof (string),
				typeof (Gdk.Pixbuf),
				-1);
			this.view = new Gtk.IconView.with_model (this.store);
			this.view.tooltip_column = ThumbBrowserColumns.PATH;
			this.view.pixbuf_column = ThumbBrowserColumns.PIXBUF;
			this.view.selection_mode = Gtk.SelectionMode.MULTIPLE;

			this.view.selection_changed += this.handle_selection_changed;
			this.view.item_activated += this.handle_item_activated;
		}

		private void handle_selection_changed ()
		{
			GLib.List<Gtk.TreePath> selection = this.view.get_selected_items ();
			string [] paths = {};
			Gtk.TreeIter iter;
			GLib.Value file;

			foreach (Gtk.TreePath path in selection)
			{
				this.store.get_iter (out iter, path);
				this.store.get_value (iter, ThumbBrowserColumns.PATH, out file);

				paths += (string) file;
			}

			this.selected (paths);
		}

		private void handle_item_activated (Gtk.TreePath path)
		{
			Gtk.TreeIter iter;
			GLib.Value file;

			this.store.get_iter (out iter, path);
			this.store.get_value (iter, ThumbBrowserColumns.PATH, out file);

			this.activated ((string) file);
		}

		// FIXME: Think this out a little more and make it work for thumbs, while
		//        you're at it.
		public void add_photo (string path)
		{
			Gtk.TreeIter iter;
			// FIXME: CONSTANT ALERT!! 128 => THUMB_SIZE
			Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, 128, 128, true);

			this.store.append (out iter);
			this.store.set (iter,
				ThumbBrowserColumns.PATH,
				path,
				ThumbBrowserColumns.PIXBUF,
				pixbuf,
				-1);
		}
	}
}
