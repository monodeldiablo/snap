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
using Xmpl;

namespace Snap
{
	public errordomain ImportError
	{
		SUFFIX,
		REGEX,
		DIGEST,
		FILE_SYSTEM,
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
			this.set_preference ("photo-directory", dir);
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
			string error = "Unknown error";

			try
			{
				string new_path = this.construct_new_path (path);

				debug ("Testing if we already have this file...");

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
						error = "Collision detected with %s!".printf (new_path);
					}
				}

				if (success)
				{
					debug ("Copying file...");

					success = this.copy_photo (path, new_path);
				}

				if (success)
				{
					debug ("Done!");

					this.request_succeeded (req.request_id, new_path);

					return true;
				}
				else
				{
					this.request_failed (req.request_id, error);
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
			int [] datetime = this.datetime_from_photo (path);
			debug ("suffix: '%s'", suffix);
			debug ("datetime: %04d%02d%02d_%02d%02d%02d%02d",
				datetime[0],
				datetime[1],
				datetime[2],
				datetime[3],
				datetime[4],
				datetime[5],
				datetime[6]);

			int year = datetime[0];
			int month = datetime[1];
			int day = datetime[2];
			int hour = datetime[3];
			int minute = datetime[4];
			int second = datetime[5];
			int subsecond = datetime[6];

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
			//   [raw,high,low,thumb]/YYYY/MM/DD/YYYYMMDD_hhmmssxx.[nef,jpg]
			string photo_directory = this.get_preference ("photo-directory");
			debug ("photo_directory: %s", photo_directory);

			string dir = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				photo_directory,
				quality,
				"%04d".printf (year),
				"%02d".printf (month),
				"%02d".printf (day));
			debug ("dir: %s", dir);
			string file_name = "%04d%02d%02d_%02d%02d%02d%02d.%s".printf (year,
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
				throw new Snap.ImportError.FILE_SYSTEM (e.message);
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

		// Returns an array of the order:
		//
		//   [year, month, day, hour, minutes, second, subsecond]
		//
		// The datetime returned is always in UTC, to prevent collisions due to time
		// zone.
		//
		// FIXME: Consider just returning a TimeVal instead of an array.
		private int [] datetime_from_photo (string path) throws Snap.ImportError
		{
			GLib.TimeVal time;
			string datetime_string = Xmpl.get_property (path, Xmpl.EXIF, "DateTimeOriginal");

			if (datetime_string == null)
			{
				try
				{
					var info = GLib.File.new_for_path (path).query_info ("*", GLib.FileQueryInfoFlags.NONE);

					info.get_modification_time (out time);
					datetime_string = time.to_iso8601 ();
				}

				catch (GLib.Error e)
				{
					throw new Snap.ImportError.FILE_SYSTEM ("No datetime information was found for '%s': %s".printf (path, e.message));
				}
			}

			/* Uncomment this if we plan on passing around the TimeVal.
			else
			{
				time = TimeVal ();

				if (!time.from_iso8601 (datetime_string))
				{
					throw new Snap.ImportError.REGEX ("No datetime information was found for '%s'".printf (path));
				}
			}
			*/

			// Extract the DateTime and SubSecTime values from the EXIF dump.
			// NOTE: The "subsecond" substring from xmpl is 4 characters long, but Snap
			//       will only track subsecond resolution to the hundredth of a second.
			//       The truncation is regrettable, but should only impact a very tiny
			//       number of cases.
			GLib.MatchInfo datetime_match;
			GLib.Regex datetime_regex = new GLib.Regex (
				"(?<year>\\d{4})-" +
				"(?<month>\\d{2})-" +
				"(?<day>\\d{2})T" +
				"(?<hour>\\d{2}):" +
				"(?<minute>\\d{2}):" +
				"(?<second>\\d{2})\\." +
				"(?<subsecond>\\d{2}).*");

			datetime_regex.match (datetime_string, 0, out datetime_match);

			int [] datetime = new int [7];

			// If the datetime data didn't match, we've got problems.
			// FIXME: If this fails, we should then try to construct a datetime using
			//        the file's mtime or something...
			if (datetime_match.matches ())
			{
				datetime[0] = datetime_match.fetch_named ("year").to_int ();
				datetime[1] = datetime_match.fetch_named ("month").to_int ();
				datetime[2] = datetime_match.fetch_named ("day").to_int ();
				datetime[3] = datetime_match.fetch_named ("hour").to_int ();
				datetime[4] = datetime_match.fetch_named ("minute").to_int ();
				datetime[5] = datetime_match.fetch_named ("second").to_int ();
				datetime[6] = datetime_match.fetch_named ("subsecond").to_int ();
			}

			else
			{
				throw new Snap.ImportError.REGEX ("Error parsing datetime information ('%s') for '%s'".printf (datetime_string, path));
			}
			debug("got %04d-%02d-%02d %02d:%02d:%02d.%02d".printf(datetime[0], datetime[1], datetime[2], datetime[3], datetime[4], datetime[5], datetime[6]));

			return datetime;
		}

		// Grab a fingerprint for the file.
		private string digest_from_photo (string path) throws Snap.ImportError
		{
			string digest = Xmpl.get_property (path, Xmpl.EXIF, "NativeDigest");

			if (digest == null)
			{
				throw new Snap.ImportError.DIGEST ("Error obtaining the digest for '%s'".printf (path));
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
