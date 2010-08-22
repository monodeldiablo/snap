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
		MOVE,
		REGEX
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
			bool success = true;

			try
			{
				// Figure out how many (if any) thumbs this photo has.
				Invocation thumbs = new Invocation("exiv2 -pp '%s'".printf (path));

				if (!thumbs.clean)
				{
					throw new ThumbnailError.SPAWN ("Error spawning '%s': %s".printf (thumbs.command, thumbs.error));
				}

				if (thumbs.return_value < 0)
				{
					throw new ThumbnailError.EXIV2 ("Error dumping thumbnail information from '%s' (return code: %d)".printf (path, thumbs.return_value));
				}

				debug("thumbs: '%s'".printf(thumbs.stdout.chomp ()));
				string[] thumb_info = thumbs.stdout.chomp ().split("\n");
				int thumb_count = thumb_info.length;

				for (int i = 0; i < thumb_count; i++)
				{
					debug("thumb info: '%s'".printf(thumb_info[i]));
					string preview_path = this.generate_preview_path (path, i + 1);
					debug ("preview path: %s".printf(preview_path));

					string thumb_path = this.generate_thumbnail_path (path, thumb_info[i]);
					debug ("thumb path: %s".printf(thumb_path));

					success = success && this.extract_thumbnail (path, i + 1) && this.move_thumbnail (preview_path, thumb_path);
				}

				if (success)
				{
					this.request_succeeded (req.request_id, "Thumbnail(s) successfully written!");

					return success;
				}

				else
				{
					this.request_failed (req.request_id, "Unknown error");
				}
			}

			catch (ThumbnailError e)
			{
				this.request_failed (req.request_id, e.message);
			}

			return false;
		}

		// NOTE: exiv2 -pp will dump available thumbnails, one per line.
		// NOTE: exiv2 -ep1 will extract a 160x120px thumbnail.
		// NOTE: exiv2 -ep2 will extract a 570x375px thumbnail.
		private bool extract_thumbnail (string path, int thumb_id) throws ThumbnailError
		{
			Invocation extract_thumb = new Invocation("exiv2 -ep%d '%s'".printf (thumb_id, path));

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

		private bool move_thumbnail (string from_path, string to_path) throws ThumbnailError
		{
			bool success = false;

			try
			{
				var src = GLib.File.new_for_path (from_path);
				var dest = GLib.File.new_for_path (to_path);
				
				// If the directory tree doesn't exist, make it.
				if (!dest.get_parent ().query_exists ())
				{
					dest.get_parent ().make_directory_with_parents (null);
				}

				success = src.move (dest, GLib.FileCopyFlags.BACKUP, null, null);
			}

			catch (GLib.Error e)
			{
				throw new ThumbnailError.MOVE (e.message);
			}

			return success;
		}

		// Photos are sorted, based on their dimensions, into three groups:
		//  * high - native resolution
		//  * low - lower resolution, web quality
		//  * thumb - very low resolution, useful for bird's-eye comparisons
		//
		// This method inspects the thumb_info for the image provided and generates
		// the appropriate path. The thumbnail information is assumed to be derived
		// from a native resolution image, so it's assumed that the photo_path
		// variable references the "high" group.
		private string generate_thumbnail_path (string photo_path, string thumb_info) throws ThumbnailError
		{
			// If the "high" keyword isn't found in the path, someone's trying to use
			// this daemon to thumbnail images not in the proper tree, which is naughty
			// and unsupported.
			// 
			// FIXME: This is not terribly internationalized.
			if (!photo_path.contains("high"))
			{
				return "";
			}

			try
			{
				GLib.Regex dimensions_regex = new GLib.Regex ("(?<width>\\d+)x(?<height>\\d+) pixels");
				GLib.MatchInfo dimensions_match;

				dimensions_regex.match (thumb_info, 0, out dimensions_match);
				int width = dimensions_match.fetch_named ("width").to_int ();
				int height = dimensions_match.fetch_named ("height").to_int ();

				// We only care about the largest dimension, since the photo might be
				// rotated or a strange format.
				int reference = (width > height ? width : height);

				// I've arbitrarily chosen 240px to be the cutoff for thumbnails. Any larger
				// than that and they're officially considered web quality.
				string quality = (reference > 240 ? "low" : "thumb");

				// FIXME: This is pretty stupid, since it can really punish someone for
				//        having the substring "high" anywhere else in their path. This
				//        should, instead, tear out the photo_directory first, so that we're
				//        guaranteed to be in safe territory.
				return photo_path.replace ("high", quality);
			}

			catch (GLib.RegexError e)
			{
				throw new ThumbnailError.REGEX ("Error creating the regular expression to parse the file name for '%s'".printf (photo_path));
			}
		}

		// FIXME: Obviously, this depends on exiv2's thumbnail extraction naming
		//        behavior, which is brittle as all hell.
		private string generate_preview_path (string photo_path, int thumb_id)
		{
			return photo_path.down ().replace (".jpg", "-preview%d.jpg".printf(thumb_id));
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
