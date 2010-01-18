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
using Posix;

// FIXME: Implement thumbnailing (exiv2 will pull the preview images from all
//        photos, 160x120 first).
namespace Snap
{
	public errordomain ImportError
	{
		SUFFIX,
		SPAWN,
		EXIV2,
		REGEX
	}

	[DBus (name = "org.washedup.Snap.ImportDaemon")]
	public class ImportDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.ImportDaemon";
		private string dbus_object_path = "/org/washedup/Snap/ImportDaemon";

		private string photo_directory;

		/************
		* OPERATION *
		************/

		public ImportDaemon (string[] args)
		{
			// FIXME: Install the snap.schemas file first, before you can use this.
			//GConf.Client gconf_client = GConf.Client.get_default ();
			//this.photo_directory = gconf_client.get_string ("/schemas/apps/snap/photo-directory");
			//this.photo_directory = GLib.Environment.get_user_special_dir (GLib.UserDirectory.PICTURES);
			this.photo_directory = "/home/brian/photos";

			this.processing_method = this.perform_import;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the import queue, returning the request's
		// unique ID to the client to track.
		public uint import_photo (string path)
		{
			Request req = new Request ();

			req.append_string (path);

			uint request_id = this.add_request_to_queue (req);

			debug ("Enqueued request to import '%s' (%u)!", path, request_id);
			return request_id;
		}

		// Perform the actual import of items in the queue.
		private bool perform_import (Request req)
		{
			string path = req.get_string (0);

			try
			{
				string new_path = this.make_new_path (path);
				bool success = this.move_photo (path, new_path);

				if (success)
				{
					debug ("Successfully imported file at '%s' -> '%s'!", path, new_path);
					return true;
				}
			}

			catch (Snap.ImportError e)
			{
				critical ("Error making a new path from '%s': %s", path, e.message);
			}

			return false;
		}

		// FIXME: Look into using libexif or some other library to do this without
		//        needing to spawn processes and dump tons of unnecessary strings.
		private string make_new_path (string path) throws Snap.ImportError
		{
			// First, we verify that this is a file with the proper extension (and we
			// figure out what that extension is for later, when we move it).
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

			// Next, we need to dump the EXIF data for the image.
			string command = "exiv2 -Pkv %s".printf (path);
			string stdout;
			string stderr;
			int success;

			// Dump the EXIF data from eviv2 in the format "Exif.Key     Value".
			try
			{
				GLib.Process.spawn_command_line_sync (command,
			        	                              out stdout,
								      out stderr,
								      out success);
			}

			catch (SpawnError e)
			{
				throw new Snap.ImportError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
			}

			if (success < 0)
			{
				throw new Snap.ImportError.EXIV2 ("Error extracting EXIF data from '%s' (return code: %d)".printf (path, success));
			}

			// Extract the DateTime and SubSecTime values from the EXIF dump.
			try
			{
				GLib.Regex datetime_ex = new GLib.Regex ("Exif.Image.DateTime\\s+(?<year>\\d{4}):(?<month>\\d{2}):(?<day>\\d{2}) (?<hour>\\d{2}):(?<minute>\\d{2}):(?<second>\\d{2})");
				GLib.Regex subsecond_ex = new GLib.Regex ("Exif.Photo.SubSecTime\\s+(?<subsecond>\\d{2})");
				GLib.MatchInfo datetime_match;
				GLib.MatchInfo subsecond_match;

				string year;
				string month;
				string day;
				string hour;
				string minute;
				string second;
				string subsecond;

				// Run the EXIF data through the regexes.
				datetime_ex.match (stdout, 0, out datetime_match);
				subsecond_ex.match (stdout, 0, out subsecond_match);

				// Some cameras don't support sub-second resolution.
				if (subsecond_match.matches ())
				{
					subsecond = subsecond_match.fetch_named ("subsecond");
				}

				else
				{
					subsecond = "00";
				}

				// If the datetime data didn't match, we've got problems.
				// FIXME: If this fails, we should then try to construct a datetime using
				//        the file's mtime or something...
				if (datetime_match.matches ())
				{
					year = datetime_match.fetch_named ("year");
					month = datetime_match.fetch_named ("month");
					day = datetime_match.fetch_named ("day");
					hour = datetime_match.fetch_named ("hour");
					minute = datetime_match.fetch_named ("minute");
					second = datetime_match.fetch_named ("second");
				}

				else
				{
					throw new Snap.ImportError.REGEX ("Error parsing the EXIF data for '%s': No datetime information was found".printf (path));
				}

				// We determine the proper directory root within the photo directory by
				// examining the quality of the image.
				string quality;

				if (suffix == "nef" || suffix == "NEF")
				{
					quality = "raw";
				}
				else
				{
					quality = "high";
				}

				// Construct the path and file names from this information. The naming
				// convention is strict and looks like this:
				//
				//   [raw,high,thumb]/YYYY/MM/DD/YYYYMMDD_hhmmssxx.[nef,jpg]
				string dir = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
				                                   this.photo_directory,
				                                   quality,
								   year,
								   month,
								   day);
				string file_name = "%s%s%s_%s%s%s%s.%s".printf (year,
				                                                month,
										day,
										hour,
										minute,
										second,
										subsecond,
										suffix);

				return GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, dir, file_name);
			}

			catch (GLib.RegexError e)
			{
				throw new Snap.ImportError.REGEX ("Error creating the regular expression to parse the EXIF data for '%s'".printf (path));
			}
		}

		private bool move_photo (string old_path, string new_path)
		{
			string dir = GLib.Path.get_dirname (new_path);
			int status;

			// Create the directory, if necessary.
			// FIXME: Check the return code of this call to make sure it actually completed.
			status = GLib.DirUtils.create_with_parents (dir, (int) (Posix.S_IRWXU | Posix.S_IRWXU));

			if (status < 0)
			{
				critical ("Error creating the directory at '%s'", dir);
				return false;
			}

			// Move the file to the proper location in the photo directory.
			// FIXME: Check the return code of this call to make sure it actually completed.
			GLib.FileUtils.rename (old_path, new_path);

			if (status < 0)
			{
				critical ("Error moving file from '%s' to '%s'", old_path, new_path);
				return false;
			}

			return true;
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
