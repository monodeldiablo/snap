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

	class ThumbBrowser : GLib.Object
	{
		public Gtk.IconView view;
		public Gtk.ListStore store;

		public ThumbBrowser ()
		{
			this.set_up_ui ();
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
		}

		// FIXME: Think this out a little more and make it work for thumbs, while
		//        you're at it.
		public void add_photo (string path)
		{
			Gtk.TreeIter iter;
			Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, 72, 72, true);

			this.store.append (out iter);
			this.store.set (iter,
				ThumbBrowserColumns.PATH,
				path,
				ThumbBrowserColumns.PIXBUF,
				pixbuf,
				-1);
		}
	}

	class ThumbBrowserTest : Gtk.Window
	{
		public Gtk.HPaned hpaned;
		public ThumbBrowser thumb_browser;
		public TagViewer tag_viewer;

		public ThumbBrowserTest (string [] args)
		{
			this.thumb_browser = new ThumbBrowser ();
			this.tag_viewer = new TagViewer ();
			this.hpaned = new Gtk.HPaned ();
			this.hpaned.pack1 (this.tag_viewer.view, true, true);
			this.hpaned.pack2 (this.thumb_browser.view, true, true);
			this.add (this.hpaned);
			this.set_default_size (800, 600);

			for (int i = 1; i < args.length; ++i)
			{
				thumb_browser.add_photo (args [i]);
			}

			this.show_all ();
			this.thumb_browser.view.show_all ();
			this.thumb_browser.view.selection_changed += this.handle_selection_changed;
			this.destroy += this.quit;
		}

		private void handle_selection_changed ()
		{
			this.tag_viewer.clear_photos ();

			GLib.List<Gtk.TreePath> selection = this.thumb_browser.view.get_selected_items ();

			foreach (Gtk.TreePath path in selection)
			{
				Gtk.TreeIter iter;
				GLib.Value file;

				this.thumb_browser.store.get_iter (out iter, path);
				this.thumb_browser.store.get_value (iter, ThumbBrowserColumns.PATH, out file);
				this.tag_viewer.add_photo ((string) file);
			}
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		public static void main (string [] args)
		{
			Gtk.init (ref args);

			new ThumbBrowserTest (args);

			Gtk.main ();
		}
	}
}
