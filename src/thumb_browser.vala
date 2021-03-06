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
	public int THUMB_SIZE = 128;
	public int EMBLEM_SIZE = 24;

	public enum ThumbBrowserColumns
	{
		PATH,
		PIXBUF,
		HAS_RAW,
		NUM_COLUMNS
	}

	public class ThumbBrowser : GLib.Object
	{
		public Gtk.ScrolledWindow container;
		public Gtk.IconView view;
		private Gtk.ListStore store;
		private dynamic DBus.Object preferences_daemon;
		private string photo_directory;
		private string high_directory;
		private string thumb_directory;
		private string raw_directory;

		public signal void selected (string [] paths);
		public signal void activated (string path);

		public ThumbBrowser ()
		{
			this.set_up_connections ();
			this.set_up_ui ();

			this.photo_directory = this.preferences_daemon.get_preference ("photo-directory");
			this.high_directory = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				this.photo_directory,
				"high");
			this.thumb_directory = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				this.photo_directory,
				"thumb");
			this.raw_directory = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				this.photo_directory,
				"raw");
			
			this.load_thumbs (this.high_directory);
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
				typeof (bool),
				-1);
			this.view = new Gtk.IconView.with_model (this.store);
			this.view.tooltip_column = ThumbBrowserColumns.PATH;
			this.view.pixbuf_column = ThumbBrowserColumns.PIXBUF;
			this.view.selection_mode = Gtk.SelectionMode.MULTIPLE;

			this.container = new Gtk.ScrolledWindow (null, null);
			this.container.hscrollbar_policy = Gtk.PolicyType.NEVER;
			this.container.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			this.container.add (this.view);

			this.view.selection_changed.connect (this.handle_selection_changed);
			this.view.item_activated.connect (this.handle_item_activated);
		}

		// Recursively load thumbs.
		// FIXME: Instead of just browsing the thumbs, browse the "high" directory.
		//        If a thumb is not present for a given photo, generate it on the
		//        fly. Also, if a raw version of the current file is present, attach
		//        some emblem or halo to this effect.
		private void load_thumbs (string path)
		{
			GLib.File dir = GLib.File.new_for_path (path);
			GLib.FileEnumerator iter = dir.enumerate_children ("*",
				GLib.FileQueryInfoFlags.NONE);
                        GLib.FileInfo info = iter.next_file ();

                        while (info != null)
                        {
                                string name = info.get_name ();

                                // If this is a directory, recursively call this method on that path.
                                if (info.get_file_type () == GLib.FileType.DIRECTORY)
                                {
                                        this.load_thumbs (dir.get_child (name).get_path ());
                                }

				else
				{
					string full_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR.to_string (),
                                                        dir.get_path (), name);
					this.add_photo (full_path);
				}

				info = iter.next_file ();
			}
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

		// Given a high resolution photo path, this locates the thumbnail
		// (generating one if it doesn't exist) and, if a corresponding raw file
		// is present, indicates this by superimposing a graphic on the thumbnail.
		// FIXME: This should just put data in the store. The renderer should
		//        conditionally add the emblem based on the value of the HAS_RAW
		//        column.
		public void add_photo (string path)
		{
			Gtk.TreeIter iter;
			bool has_raw = this.find_raw (path);

			try
			{
				this.store.append (out iter);
				this.store.set (iter,
					ThumbBrowserColumns.PATH,
					path,
					ThumbBrowserColumns.PIXBUF,
					this.make_thumb (path, has_raw),
					ThumbBrowserColumns.HAS_RAW,
					has_raw,
					-1);
			}

			// FIXME: Rescue specific PixbufErrors here, displaying the "broken" image
			//        or some other appropriate messaging (e.g. "This image is corrupt.
			//        Please make sure you have a backup.").
			catch (GLib.Error e)
			{
				error (e.message);
			}
		}

		private bool find_raw (string path)
		{
			// FIXME: Remove the common prefix, drop the next level from the path
			//        (in this case, "high") and replace with "raw".
			string raw_path = path.replace (this.high_directory, this.raw_directory);

			return GLib.FileUtils.test (raw_path, GLib.FileTest.EXISTS);
		}

		private Gdk.Pixbuf make_thumb (string path, bool has_raw)
		{
			string thumb_path = path.replace (this.high_directory, this.thumb_directory);

			Gdk.Pixbuf thumb = new Gdk.Pixbuf.from_file_at_scale (thumb_path,
				THUMB_SIZE,
				THUMB_SIZE,
				true);

			if (has_raw)
			{
				string emblem_path = GLib.Path.build_filename (Config.PACKAGE_DATADIR,
					"film_strip.png");
				Gdk.Pixbuf emblem = new Gdk.Pixbuf.from_file_at_scale (emblem_path,
					EMBLEM_SIZE,
					EMBLEM_SIZE,
					true);

				emblem.composite (thumb,
					0,
					0,
					thumb.width,
					thumb.height,
					thumb.width - emblem.width,
					0.0,
					1.0,
					1.0,
					Gdk.InterpType.BILINEAR,
					255);
			}

			return thumb;
		}
	}
}
