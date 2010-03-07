/*
 * snap_thumbnail_daemon.vala
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
using DBus;

namespace Snap
{
	public errordomain ThumbnailError
	{
		SPAWN,
		EXIV2,
		MOVE
	}

	[DBus (name = "org.washedup.Snap.Thumbnail")]
	public class ThumbnailDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.Thumbnail";
		private string dbus_object_path = "/org/washedup/Snap/Thumbnail";

		/**********
		* SIGNALS *
		**********/

		public signal void request_succeeded (uint request_id, string new_path);
		public signal void request_failed (uint request_id, string reason);

		/************
		* OPERATION *
		************/

		public string photo_directory = null;

		public ThumbnailDaemon (string[] args)
		{
			this.processing_method = this.handle_thumbnail_request;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
			this.run ();
		}

		/**********
		* METHODS *
		**********/

		public uint[] thumbnail (string[] paths)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		private bool handle_thumbnail_request (Request req) throws GLib.Error
		{
			string path = req.get_string (0);
			string preview_path = this.generate_preview_path (path);
			string thumb_path = this.generate_thumbnail_path (path);

			try
			{
				bool success = this.extract_thumbnail (path) && this.move_thumbnail (preview_path, thumb_path);

				if (success)
				{
					this.request_succeeded (req.request_id, thumb_path);

					return success;
				}

				else
				{
					this.request_failed (req.request_id, "Unknown error");
				}
			}

			catch (Snap.ThumbnailError e)
			{
				this.request_failed (req.request_id, e.message);
			}

			return false;
		}

		// NOTE: exiv2 -ep1 will extract a 160x120px thumbnail.
		// FIXME: remember to move the resulting thumbnail to the proper location.
		private bool extract_thumbnail (string path) throws Snap.ThumbnailError
		{
			Invocation extract_thumb = new Invocation("exiv2 -ep1 '%s'".printf (path));

			if (!extract_thumb.clean)
			{
				throw new ThumbnailError.SPAWN ("Error spawning '%s': %s".printf (extract_thumb.command, extract_thumb.error));
			}

			if (extract_thumb.return_value < 0)
			{
				throw new ThumbnailError.EXIV2 ("Error extracting thumbnail from '%s' (return code: %d)".printf (path, extract_thumb.return_value));
			}

			return true;
		}

		private bool move_thumbnail (string from_path, string to_path) throws Snap.ThumbnailError
		{
			bool success = false;

			try
			{
				var vfs = GLib.Vfs.get_default ();
				var src = vfs.get_file_for_path (from_path);
				var dest = vfs.get_file_for_path (to_path);
				
				// If the directory tree doesn't exist, make it.
				success = dest.get_parent ().make_directory_with_parents (null) &&
					src.move (dest, GLib.FileCopyFlags.BACKUP, null, null);
			}

			catch (GLib.Error e)
			{
				throw new Snap.ThumbnailError.MOVE (e.message);
			}

			return success;
		}

		// FIXME: Splitting is probably C-style splitting... this may require the
		//        GLib.Regex.split_simple () method to do correctly.
		private string generate_thumbnail_path (string photo_path)
		{
			string thumb_path = "";
			string[] split = photo_path.split ("high");

			// If the "high" keyword isn't found in the path, someone's trying to use
			// this daemon to thumbnail images not in the proper tree, which is naughty
			// and unsupported.
			if (split.length == 1)
			{
				return "";
			}

			for (int i = 0; i < split.length; ++i)
			{
				if (i == split.length - 1)
				{
					thumb_path += "thumb";
				}

				thumb_path += split[i];
			}

			return thumb_path;
		}

		private string generate_preview_path (string photo_path)
		{
			string preview_path = "";
			string[] split = photo_path.split (".jpg");

			for (int i = 0; i < split.length; ++i)
			{
				if (i == split.length - 1)
				{
					preview_path += "-preview1.jpg";
				}

				preview_path += split[i];
			}

			return preview_path;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new ThumbnailDaemon (args);

			return 0;
		}
	}
}
