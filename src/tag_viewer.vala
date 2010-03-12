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
using Gee;
using Gtk;
using DBus;

namespace Snap
{
	public enum TagViewerColumns
	{
		NAME,
		IS_APPLIED,
		IS_PARTIAL,
		NUM_COLUMNS
	}

	class TagViewer : GLib.Object
	{
		public Gtk.TreeView tag_view;
		private Gtk.ListStore tag_store;
		private Gee.HashMap<string, Gee.ArrayList<string>> tags = new Gee.HashMap<string, Gee.ArrayList<string>> (GLib.str_hash);
		private Gee.HashMap<string, string> index = new Gee.HashMap<string, string> (GLib.str_hash, GLib.str_equal);
		private Gee.ArrayList<string> photos = new Gee.ArrayList<string> ();
		private dynamic DBus.Object metadata_daemon;

		public TagViewer ()
		{
			this.set_up_ui ();
			this.set_up_connections ();
		}

		private void set_up_ui ()
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
				TagViewerColumns.IS_PARTIAL);
			is_applied_column.expand = false;

			this.tag_view.append_column (name_column);
			this.tag_view.append_column (is_applied_column);
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

		// Update the tag store to reflect recent changes in the path lists.
		private void refresh_tag_store ()
		{
			foreach (string tag in this.tags.keys)
			{
				Gee.ArrayList<string> paths = this.tags.get (tag);
				string path_string = this.index.get (tag);

				Gtk.TreeIter iter;
				this.tag_store.get_iter_from_string (out iter, path_string);

				if (paths.size < this.photos.size)
				{
					// Set the check box to be inconsistent, since not all the selected photos
					// have this tag.
					this.tag_store.set (iter, TagViewerColumns.IS_PARTIAL, true, -1);
				}

				else
				{
					// Set the check box to be active, since all the selected photos have this
					// tag.
					this.tag_store.set (iter, TagViewerColumns.IS_PARTIAL, false, -1);
				}
			}
		}

		public void add_photo (string path)
		{
			int list_index = this.photos.index_of (path);

			if (list_index == -1)
			{
				// Fetch tags from the photo, which are stored in the 'DC.Subject'
				// field of the photo's XMP payload.
				string tag_string = this.metadata_daemon.get_metadata (path, "subject");
				string[] new_tags = tag_string.split (",");

				// Add the photo and its tags to the global tag hash.
				foreach (string tag in new_tags)
				{
					Gee.ArrayList<string> paths = this.tags.get (tag);

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
								TagViewerColumns.IS_PARTIAL,
								false,
								-1);
						}

						else
							critical ("shit just broke here");

						string path_string = this.tag_store.get_string_from_iter (iter);
						this.index.set (tag, path_string);

						var new_paths = new Gee.ArrayList<string> ();
						new_paths.add (path);
						this.tags.set (tag, new_paths);
					}

					else
					{
						paths.add (path);
						this.tags.set (tag, paths);
					}
				}

				this.photos.add (path);
				this.refresh_tag_store ();
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
