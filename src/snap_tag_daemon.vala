/*
 * snap_tag_daemon.vala
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
	public errordomain TagError
	{
		SPAWN,
		EXIV2
	}

	[DBus (name = "org.washedup.Snap.TagDaemon")]
	public class TagDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.TagDaemon";
		private string dbus_object_path = "/org/washedup/Snap/TagDaemon";


		/************
		* OPERATION *
		************/

		public TagDaemon (string[] args)
		{
			this.processing_method = this.perform_tagging;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the tag queue, returning the request's
		// unique ID to the client to track;
		public uint tag_photo (string path, string tag)
		{
			Request req = new Request ();

			req.append_string (path);
			req.append_string ("add");
			req.append_string (tag);

			uint request_id = this.add_request_to_queue (req);

			debug ("Enqueued request to tag '%s' with '%s'!", path, tag);
			return request_id;
		}

		// Append the photo at *path* to the tag queue, returning the request's
		// unique ID to the client to track;
		public uint untag_photo (string path, string tag)
		{
			Request req = new Request ();

			req.append_string (path);
			req.append_string ("del");
			req.append_string (tag);

			uint request_id = this.add_request_to_queue (req);

			debug ("Enqueued request to remove the tag '%s' from '%s'!", tag, path);
			return request_id;
		}

		private bool perform_tagging (Request req) throws GLib.Error
		{
			string path = req.get_string (0);
			string verb = req.get_string (1);
			string tag = req.get_string (2);
			bool success = false;

			switch (verb)
			{
				case "add":
					success = this.add_tag (path, tag);
					break;
				case "del":
					success = this.remove_tag (path, tag);
					break;
				default:
					critical ("Error processing verb: '%s' invalid", verb);
					break;
			}

			return success;
		}

		private bool add_tag (string path, string tag)
		{
			string command = "exiv2 -kM \"add Iptc.Application2.Keywords '%s'\" %s".printf (tag, path);
			string stdout;
			string stderr;
			int success;

			try
			{
				GLib.Process.spawn_command_line_sync (command,
				                                      out stdout,
								      out stderr,
								      out success);
			}

			catch (SpawnError e)
			{
				//throw new TagError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				critical ("Error spawning '%s': %s", command, e.message);
				return false;
			}

			if (success < 0)
			{
				//throw new TagError.EXIV2 ("Error tagging photo at '%s' (return code: %d)".printf (path, success));
				critical ("Error tagging photo at '%s' (return code: %d)", path, success);
				return false;
			}

			return true;
		}

		// FIXME: Make this work! As it is, this is terribly broken, nuking any and
		//        all tags the photo has ever received. DANGER!
		private bool remove_tag (string path, string tag)
		{
			string command = "exiv2 -kM \"del Iptc.Application2.Keywords '%s'\" %s".printf (tag, path);
			string stdout;
			string stderr;
			int success;

			try
			{
				GLib.Process.spawn_command_line_sync (command,
				                                      out stdout,
								      out stderr,
								      out success);
			}

			catch (SpawnError e)
			{
				//throw new TagError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				critical ("Error spawning '%s': %s", command, e.message);
				return false;
			}

			if (success < 0)
			{
				//throw new TagError.EXIV2 ("Error tagging photo at '%s' (return code: %d)".printf (path, success));
				critical ("Error tagging photo at '%s' (return code: %d)", path, success);
				return false;
			}

			return true;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new TagDaemon (args);

			return 0;
		}
	}
}
