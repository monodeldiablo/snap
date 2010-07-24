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

	public class TagRequest : GLib.Object
	{
		public string tag;
		public string path;

		public TagRequest (string tag, string path)
		{
			this.tag = tag;
			this.path = path;
		}
	}

	public class TagViewer : GLib.Object
	{
		public Gtk.TreeView view;
		private Gtk.ListStore store;
		private Gee.HashMap<string, Gee.ArrayList<string>> tags = new Gee.HashMap<string, Gee.ArrayList<string>> (GLib.str_hash);
		private Gee.HashMap<uint, TagRequest> add_list = new Gee.HashMap<uint, TagRequest> (GLib.direct_hash);
		private Gee.HashMap<uint, TagRequest> remove_list = new Gee.HashMap<uint, TagRequest> (GLib.direct_hash);
		private Gee.ArrayList<string> photos = new Gee.ArrayList<string> ();
		private dynamic DBus.Object preferences_daemon;
		private dynamic DBus.Object metadata_daemon;

		public TagViewer ()
		{
			this.set_up_connections ();
			this.set_up_ui ();
			this.sync_tag_list ();
			this.refresh_store ();

			// FIXME: Write a signal hookup method, too!
			this.metadata_daemon.RequestSucceeded.connect (handle_tagging_request_succeeded);
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
				this.metadata_daemon = conn.get_object ("org.washedup.Snap.Metadata",
					"/org/washedup/Snap/Metadata",
					"org.washedup.Snap.Metadata");
			}

			catch (DBus.Error e)
			{
				critical (e.message);
			}
		}

		private void sync_tag_list ()
		{
			string tag_string = this.preferences_daemon.get_preference ("tag-list");
			Gee.ArrayList<string> tag_array = new Gee.ArrayList<string> ();

			foreach (string tag in tag_string.split (","))
			{
				tag_array.add (tag);

				if (!this.tags.has_key (tag))
				{
					this.tags [tag] = new Gee.ArrayList<string> ();
				}
			}

			// If there's a tag in the local list that's not in the global list, add it.
			if (tag_array.size < this.tags.size)
			{
				foreach (string tag in this.tags.keys)
				{
					if (!tag_array.contains (tag))
					{
						tag_array.add (tag);
					}
				}

				string [] new_tag_array = tag_array.to_array ();
				new_tag_array += null;
				bool ret = this.preferences_daemon.set_preference ("tag-list", string.joinv (",", new_tag_array));
			}
		}


		private void set_up_ui ()
		{
			this.store = new Gtk.ListStore (TagViewerColumns.NUM_COLUMNS,
				typeof (string),
				typeof (bool),
				typeof (bool),
				-1);
			this.view = new Gtk.TreeView.with_model (this.store);
			this.view.rules_hint = true;
			this.view.search_column = 0;
			this.view.tooltip_column = 0;

			Gtk.CellRendererText text_renderer = new Gtk.CellRendererText ();
			Gtk.CellRendererToggle toggle_renderer = new Gtk.CellRendererToggle ();
			Gtk.TreeViewColumn name_column;
			Gtk.TreeViewColumn is_applied_column;

			text_renderer.ellipsize = Pango.EllipsizeMode.END;
			toggle_renderer.toggled.connect (this.handle_toggled);

			name_column = new Gtk.TreeViewColumn.with_attributes ("Tag",
				text_renderer,
				"text",
				TagViewerColumns.NAME);
			name_column.expand = true;

			is_applied_column = new Gtk.TreeViewColumn.with_attributes ("applies?",
				toggle_renderer,
				"active",
				TagViewerColumns.IS_APPLIED,
				"inconsistent",
				TagViewerColumns.IS_PARTIAL);
			is_applied_column.expand = false;

			this.view.append_column (name_column);
			this.view.append_column (is_applied_column);
		}

		// Update the tag store to reflect recent changes in the path lists.
		// FIXME: Don't clear and repopulate the list... that's stupid.
		private void refresh_store ()
		{
			// Disconnect the ListStore from the TreeView to speed up operations.
			this.view.model = null;
			this.store.clear ();

			foreach (string tag in this.tags.keys)
			{
				Gtk.TreeIter iter;
				this.store.append (out iter);
				Gee.ArrayList<string> paths = this.tags [tag];

				this.store.set (iter, TagViewerColumns.NAME, tag, -1);

				// If fewer than all of the photos bear this tag, mark it as partially
				// applicable.
				if (paths.size < this.photos.size || this.photos.size == 0)
				{
					if (paths.size == 0)
					{
						this.store.set (iter, TagViewerColumns.IS_APPLIED, false, -1);
						this.store.set (iter, TagViewerColumns.IS_PARTIAL, false, -1);
					}

					else
					{
						this.store.set (iter, TagViewerColumns.IS_APPLIED, true, -1);
						this.store.set (iter, TagViewerColumns.IS_PARTIAL, true, -1);
					}
				}
				else
				{
					this.store.set (iter, TagViewerColumns.IS_APPLIED, true, -1);
					this.store.set (iter, TagViewerColumns.IS_PARTIAL, false, -1);
				}
			}

			// Reattach the ListStore to the TreeView.
			this.view.model = this.store;
			this.view.show_all ();
		}

		private void handle_toggled (string path)
		{
			Gtk.TreeIter iter;
			GLib.Value tag;
			GLib.Value applied;
			GLib.Value partial;

			this.store.get_iter_from_string (out iter, path);
			this.store.get_value (iter, TagViewerColumns.NAME, out tag);
			this.store.get_value (iter, TagViewerColumns.IS_APPLIED, out applied);
			this.store.get_value (iter, TagViewerColumns.IS_PARTIAL, out partial);

			if ((bool) applied && !(bool) partial)
			{
				this.untag ((string) tag);
			}

			else
			{
				this.tag ((string) tag);
			}
		}

		// this.add_list and this.remove_list need to also capture the path in order
		// to be useful!
		private void handle_tagging_request_succeeded (dynamic DBus.Object daemon, uint request_id)
		{

			if (this.add_list.has_key (request_id))
			{
				TagRequest tr = this.add_list [request_id];
				Gee.ArrayList<string> paths = this.tags [tr.tag];

				if (!paths.contains (tr.path))
				{
					paths.add (tr.path);
					this.tags [tr.tag] = paths;
				}

				this.add_list.unset (request_id);
			}

			else if (this.remove_list.has_key (request_id))
			{
				TagRequest tr = this.remove_list [request_id];
				Gee.ArrayList<string> paths = this.tags [tr.tag];

				if (paths.contains (tr.path))
				{
					paths.remove (tr.path);
					this.tags [tr.tag] = paths;
				}

				this.remove_list.unset (request_id);
			}

			this.refresh_store ();
		}

		public void add_photo (string path)
		{
			if (!this.photos.contains (path))
			{
				// Fetch tags from the photo, which are stored in the 'DC.Subject'
				// field of the photo's XMP payload.
				string tag_string = this.metadata_daemon.get_metadata (path, "subject");
				string [] new_tags = tag_string.split (",");

				// Add the photo and its tags to the global tag hash.
				foreach (string tag in new_tags)
				{
					Gee.ArrayList<string> paths = this.tags [tag];

					if (paths == null)
						paths = new Gee.ArrayList<string> ();

					paths.add (path);
					this.tags [tag] = paths;
				}

				this.photos.add (path);
				this.sync_tag_list ();
				this.refresh_store ();
			}
		}

		public void remove_photo (string path)
		{
			foreach (string tag in this.tags.keys)
			{
				Gee.ArrayList<string> paths = this.tags [tag];
				paths.remove (path);
				this.tags [tag] = paths;
			}

			this.photos.remove (path);
			this.sync_tag_list ();
			this.refresh_store ();
		}

		public void clear_photos ()
		{
			string [] keys = this.tags.keys.to_array ();

			foreach (string tag in keys)
			{
				this.tags [tag] = new Gee.ArrayList<string> ();
			}

			this.photos.clear ();
			this.sync_tag_list ();
			this.refresh_store ();
		}

		public void tag (string tag)
		{
			string [] paths = {};

			foreach (string path in this.photos)
			{
				if (!this.tags [tag].contains (path))
				{
					paths += path;
				}
			}

			paths += null;
			uint [] request_ids = this.metadata_daemon.append_metadata (paths, "subject", tag);

			for (int i = 0; i < request_ids.length; i++)
			{
				TagRequest tr = new TagRequest (tag, paths [i]);
				this.add_list [request_ids [i]] = tr;
			}
		}

		public void untag (string tag)
		{
			string [] paths = this.photos.to_array ();
			paths += null;
			uint [] request_ids = this.metadata_daemon.remove_metadata (paths, "subject", tag);

			for (int i = 0; i < request_ids.length; i++)
			{
				TagRequest tr = new TagRequest (tag, paths [i]);
				this.remove_list [request_ids [i]] = tr;
			}
		}

	}
/*
	class TagViewerTest : Gtk.Window
	{
		public TagViewer viewer;

		public TagViewerTest (string [] args)
		{
			this.set_default_size (800, 600);
			this.viewer = new TagViewer ();

			this.add (this.viewer.view);
			this.destroy.connect (this.quit);

			for (int i = 1; i < args.length; ++i)
			{
				this.viewer.add_photo (args [i]);
			}

			this.show_all ();
			this.viewer.view.show_all ();
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		public static void main (string [] args)
		{
			Gtk.init (ref args);

			new TagViewerTest (args);

			Gtk.main ();
		}
	}*/
}
