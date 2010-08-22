/*
 * snap_import_daemon.vala
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
	public errordomain ImportError
	{
		SUFFIX,
		SPAWN,
		EXIV2,
		REGEX,
		COPY,
		INVALID_PREFERENCE
	}

	[DBus (name = "org.washedup.Snap.Import")]
	public class ImportDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.Import";
		private string dbus_object_path = "/org/washedup/Snap/Import";

		/**********
		* SIGNALS *
		**********/

		public signal void request_succeeded (uint request_id, string new_path);
		public signal void request_failed (uint request_id, string reason);

		/************
		* OPERATION *
		************/

		public string photo_directory = null;

		public ImportDaemon (string[] args)
		{
			this.processing_method = this.handle_import_request;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
			this.run ();
		}

		/**********
		* METHODS *
		**********/

		public void set_photo_directory (string dir)
		{
			this.photo_directory = dir;
		}

		public uint[] import (string[] paths)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; ++i)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		// Perform the actual import of items in the queue.
		private bool handle_import_request (Request req) throws GLib.Error
		{
			string path = req.get_string (0);
			debug ("handling import request for '%s'...".printf(path));
			bool success = true;

			try
			{
				string new_path = this.construct_new_path (path);

				if (GLib.FileUtils.test (new_path, GLib.FileTest.EXISTS))
				{
					// FIXME: Pop up a window comparing this photo with the one in its
					//        destination and ask the user whether they're the same or
					//        different.
					string old_digest = this.digest_from_photo (path);
					string new_digest = this.digest_from_photo (new_path);

					if (old_digest == new_digest)
					{
						success = false;
					}
				}

				if (success)
				{
					success = this.copy_photo (path, new_path);
				}

				if (success)
				{
					this.request_succeeded (req.request_id, new_path);

					return true;
				}
				else
				{
					this.request_failed (req.request_id, "Unknown error");
				}
			}

			catch (Snap.ImportError e)
			{
				this.request_failed (req.request_id, e.message);
			}

			return false;
		}

		private string construct_new_path (string path) throws Snap.ImportError
		{
			string suffix = this.suffix_from_photo (path);
			debug ("suffix: '%s'", suffix);
			string[] datetime = this.datetime_from_photo (path);
			debug ("datetime: %s%s%s_%s%s%s%s",
				datetime[0],
				datetime[1],
				datetime[2],
				datetime[3],
				datetime[4],
				datetime[5],
				datetime[6]);

			string year = datetime[0];
			string month = datetime[1];
			string day = datetime[2];
			string hour = datetime[3];
			string minute = datetime[4];
			string second = datetime[5];
			string subsecond = datetime[6];

			// We determine the proper directory root within the photo directory by
			// examining the quality of the image (which, in this case, is apparently
			// a function of the file name suffix).
			string quality;

			if (suffix == "nef" || suffix == "NEF")
			{
				quality = "raw";
			}
			else
			{
				quality = "high";
			}

			debug ("quality: %s", quality);

			// Construct the path and file names from this information. The naming
			// convention is strict and looks like this:
			//
			//   [raw,high,thumb]/YYYY/MM/DD/YYYYMMDD_hhmmssxx.[nef,jpg]
			if (photo_directory == null)
			{
				this.photo_directory = this.get_preference ("photo-directory");
			}
			debug ("photo_directory: %s", this.photo_directory);

			string dir = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				this.photo_directory,
				quality,
				year,
				month,
				day);
			debug ("dir: %s", dir);
			string file_name = "%s%s%s_%s%s%s%s.%s".printf (year,
				month,
				day,
				hour,
				minute,
				second,
				subsecond,
				suffix);
			debug ("file: %s", file_name);

			return GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, dir, file_name);
		}

		private bool copy_photo (string old_path, string new_path) throws Snap.ImportError
		{
			bool success = false;

			try
			{
				var src = GLib.File.new_for_path (old_path);
				var dest = GLib.File.new_for_path (new_path);

				// If the directory tree doesn't exist, make it.
				if (!dest.get_parent ().query_exists ())
				{
					dest.get_parent ().make_directory_with_parents (null);
				}

				success = src.copy (dest, GLib.FileCopyFlags.BACKUP, null, null);
			}

			catch (GLib.Error e)
			{
				throw new Snap.ImportError.COPY (e.message);
			}

			return success;
		}

		private string suffix_from_photo (string path) throws Snap.ImportError
		{
			// First, we verify that this is a file with the proper extension (and we
			// figure out what that extension is for later, when we copy it).
			string suffix;
			GLib.Regex suffix_ex;
			GLib.MatchInfo suffix_match;

			try
			{
				suffix_ex = new GLib.Regex (".*\\.(?<suffix>nef|NEF|jpg|JPG|jpeg|JPEG)");
			}

			catch (GLib.RegexError e)
			{
				throw new Snap.ImportError.REGEX ("Error creating the regular expression to parse the file name for '%s'".printf (path));
			}

			suffix_ex.match (path, 0, out suffix_match);

			if (suffix_match.matches ())
			{
				suffix = suffix_match.fetch_named ("suffix");
			}

			else
			{
				throw new Snap.ImportError.SUFFIX ("Error examining '%s': Invalid file type".printf (path));
			}

			return suffix;
		}

		// FIXME: Look into using libexif or some other library to do this without
		//        needing to spawn processes and dump tons of unnecessary strings.
		private string[] datetime_from_photo (string path) throws Snap.ImportError
		{
			// Dump the EXIF data from eviv2 in the format "Exif.Key     Value".
			Invocation dump_exif = new Invocation ("exiv2 -Pkv %s".printf (path));

			if (!dump_exif.clean)
			{
				throw new Snap.ImportError.SPAWN ("Error spawning '%s': %s".printf (dump_exif.command, dump_exif.error));
			}

			if (dump_exif.return_value < 0)
			{
				throw new Snap.ImportError.EXIV2 ("Error extracting EXIF data from '%s' (return code: %d)".printf (path, dump_exif.return_value));
			}

			// Extract the DateTime and SubSecTime values from the EXIF dump.
			GLib.MatchInfo datetime_match = dump_exif.scan ("Exif.Image.DateTime\\s+(?<year>\\d{4}):(?<month>\\d{2}):(?<day>\\d{2}) (?<hour>\\d{2}):(?<minute>\\d{2}):(?<second>\\d{2})");
			GLib.MatchInfo subsecond_match = dump_exif.scan ("Exif.Photo.SubSecTime\\s+(?<subsecond>\\d{2})");

			string[] datetime = new string[8];

			// Some cameras don't support sub-second resolution.
			if (subsecond_match.matches ())
			{
				datetime[6] = subsecond_match.fetch_named ("subsecond");
			}

			else
			{
				datetime[6] = "00";
			}

			// If the datetime data didn't match, we've got problems.
			// FIXME: If this fails, we should then try to construct a datetime using
			//        the file's mtime or something...
			if (datetime_match.matches ())
			{
				datetime[0] = datetime_match.fetch_named ("year");
				datetime[1] = datetime_match.fetch_named ("month");
				datetime[2] = datetime_match.fetch_named ("day");
				datetime[3] = datetime_match.fetch_named ("hour");
				datetime[4] = datetime_match.fetch_named ("minute");
				datetime[5] = datetime_match.fetch_named ("second");
			}

			else
			{
				throw new Snap.ImportError.REGEX ("Error parsing the EXIF data for '%s': No datetime information was found".printf (path));
			}
			debug("got %s-%s-%s %s:%s:%s.%s".printf(datetime[0], datetime[1], datetime[2], datetime[3], datetime[4], datetime[5], datetime[6]));

			return datetime;
		}

		// FIXME: Look into using libexif or some other library to do this without
		//        needing to spawn processes and dump tons of unnecessary strings.
		private string digest_from_photo (string path) throws Snap.ImportError
		{
			string digest = "";

			// Dump the EXIF data from eviv2 in the format "Exif.Key     Value".
			Invocation dump_exif = new Invocation ("exiv2 -Pkv %s".printf (path));

			if (!dump_exif.clean)
			{
				throw new Snap.ImportError.SPAWN ("Error spawning '%s': %s".printf (dump_exif.command, dump_exif.error));
			}

			if (dump_exif.return_value < 0)
			{
				throw new Snap.ImportError.EXIV2 ("Error extracting EXIF data from '%s' (return code: %d)".printf (path, dump_exif.return_value));
			}

			// Extract the digest, if it exists.
			GLib.MatchInfo digest_match = dump_exif.scan ("Xmp.exif.Digest\\s+(?<digest>\\w*)");

			if (digest_match.matches ())
			{
				digest = digest_match.fetch_named ("digest");
			}
			else
			{
				throw new Snap.ImportError.REGEX ("Error parsing the EXIF data for '%s': No digest information was found".printf (path));
			}

			debug ("got digest of '%s'".printf(digest));
			return digest;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new ImportDaemon (args);

			return 0;
		}
	}
}
