/*
 * tag_viewer.vala
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
using Gtk;
using DBus;

namespace Snap
{
	public enum TagViewerColumns
	{
		NAME,
		IS_APPLIED,
		IS_ALL,
		NUM_COLUMNS
	}

	public bool array_equal_func (string[] a, string[] b)
	{
		if (a.length == b.length)
		{
			for (int i = 0; i < a.length; i++)
			{
				if (a[i] != b[i])
					return false;
			}
		}

		else
			return false;

		return true;
	}

	public bool list_equal_func (GLib.List<string> a, GLib.List<string> b)
	{
		debug ("in list_equal_func");

		if (a.length () == b.length ())
		{
			debug ("in if block");
			for (int i = 0; i < a.length (); i++)
			{
				debug ("in for block");
				if (a.nth_data (i) != b.nth_data (i))
					return false;
			}
		}

		else
			return false;

		return true;
	}

	class TagViewer : GLib.Object
	{
		public Gtk.TreeView tag_view;
		private Gtk.ListStore tag_store;
		private GLib.HashTable<string, GLib.List<string>> tags = new GLib.HashTable<string, GLib.List<string>> (GLib.str_hash, GLib.direct_equal);
		private GLib.HashTable<string, string> index = new GLib.HashTable<string, string> (GLib.str_hash, GLib.str_equal);
		private GLib.List<string> photos = new GLib.List<string> ();
		private dynamic DBus.Object metadata_daemon;

		public TagViewer ()
		{
			this.set_up_ui ();
			this.set_up_connections ();
		}

		private void set_up_ui ()
		{
			try
			{
				this.tag_store = new Gtk.ListStore (TagViewerColumns.NUM_COLUMNS,
					typeof (string),
					typeof (bool),
					typeof (bool),
					-1);
				this.tag_view = new Gtk.TreeView.with_model (this.tag_store);

				Gtk.CellRendererText text_renderer = new Gtk.CellRendererText ();
				Gtk.CellRendererToggle toggle_renderer = new Gtk.CellRendererToggle ();
				Gtk.TreeViewColumn name_column;
				Gtk.TreeViewColumn is_applied_column;

				text_renderer.ellipsize = Pango.EllipsizeMode.END;
				toggle_renderer.radio = false;

				name_column = new Gtk.TreeViewColumn.with_attributes ("Tag",
					text_renderer,
					"text",
					TagViewerColumns.NAME);
				name_column.expand = true;
				name_column.sizing = Gtk.TreeViewColumnSizing.FIXED;

				is_applied_column = new Gtk.TreeViewColumn.with_attributes ("is applied?",
					toggle_renderer,
					"active",
					TagViewerColumns.IS_APPLIED,
					"inconsistent",
					TagViewerColumns.IS_ALL);
				is_applied_column.expand = false;

				this.tag_view.append_column (name_column);
				this.tag_view.append_column (is_applied_column);
			}

			catch (GLib.Error e)
			{
				critical (e.message);
			}
		}

		private void set_up_connections ()
		{
			try
			{
				DBus.Connection conn;

				conn = DBus.Bus.get (DBus.BusType.SESSION);
				this.metadata_daemon = conn.get_object ("org.washedup.Snap.Metadata",
					"/org/washedup/Snap/Metadata",
					"org.washedup.Snap.Metadata");
			}
			
			catch (DBus.Error e)
			{
				critical (e.message);
			}
		}

		// Update each of *new_tags* to reflect recent changes in their path lists.
		private void refresh_tag_store (string[] new_tags)
		{
			foreach (string tag in new_tags)
			{
				unowned GLib.List<string> paths = this.tags.lookup (tag);
				unowned string path_string = this.index.lookup (tag);

				debug ("refreshing %s (%s, %u)", tag, path_string, paths.length ());
				Gtk.TreeIter iter;
				this.tag_store.get_iter_from_string (out iter, path_string);

				if (paths.length () < this.photos.length ())
				{
					// Set the check box to be inconsistent, since not all the selected photos
					// have this tag.
					this.tag_store.set (iter, TagViewerColumns.IS_ALL, false, -1);
				}

				else
				{
					// Set the check box to be active, since all the selected photos have this
					// tag.
					this.tag_store.set (iter, TagViewerColumns.IS_ALL, true, -1);
				}
			}
		}

		public void add_photo (string path)
		{
			int list_index = this.photos.index (path);

			if (list_index == -1)
			{
				// Fetch tags from the photo, which are stored in the 'DC.Subject'
				// field of the photo's XMP payload.
				string tag_string = this.metadata_daemon.get_metadata (path, "subject");
				string[] new_tags = tag_string.split (",");
				debug ("tags for %s: '%s'", path, tag_string);

				// Add the photo and its tags to the global tag hash.
				foreach (string tag in new_tags)
				{
					unowned GLib.List<string> paths = this.tags.lookup (tag);

					if (paths == null)
					{
						Gtk.TreeIter iter;

						this.tag_store.append (out iter);

						if (this.tag_store.iter_is_valid (iter))
						{
							this.tag_store.set (iter,
								TagViewerColumns.NAME,
								tag,
								TagViewerColumns.IS_APPLIED,
								true,
								TagViewerColumns.IS_ALL,
								true,
								-1);
						}

						else
							critical ("shit just broke here");

						string path_string = this.tag_store.get_string_from_iter (iter);
						this.index.insert (tag, path_string);

						var new_paths = new GLib.List<string> ();
						new_paths.append (path);
						this.tags.insert (tag, new_paths.copy ());
					}

					else
					{
						paths.append (path);
					}
				}

				this.photos.append (path);
				this.refresh_tag_store (new_tags);
			}
		}

		//public void remove_photo (string path) {}
		//public void clear () {}
	}

	class TagViewerTest : Gtk.Window
	{
		public TagViewerTest (string[] args)
		{
			this.set_default_size (800, 600);
			var tv = new TagViewer ();

			this.add (tv.tag_view);
			this.destroy += this.quit;

			for (int i = 1; i < args.length; ++i)
			{
				tv.add_photo (args[i]);
			}
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		public static void main (string[] args)
		{
			Gtk.init (ref args);
			var tv = new TagViewerTest (args);
			tv.show_all ();
			Gtk.main ();
		}
	}
}
