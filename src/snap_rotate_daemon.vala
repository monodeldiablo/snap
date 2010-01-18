/*
 * snap_rotate_daemon.vala
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
	public errordomain RotateError
	{
		SPAWN,
		MOGRIFY
	}

	[DBus (name = "org.washedup.Snap.RotateDaemon")]
	public class RotateDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.RotateDaemon";
		private string dbus_object_path = "/org/washedup/Snap/RotateDaemon";

		/************
		* OPERATION *
		************/

		public RotateDaemon (string[] args)
		{
			this.processing_method = this.perform_rotation;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the rotate queue, returning the request's
		// unique ID to the client to track.
		public uint rotate_photo (string path, int degrees)
		{
			Request req = new Request ();

			req.append_string (path);
			req.append_int (degrees);

			uint request_id = this.add_request_to_queue (req);

			debug ("Enqueued request to rotate '%s' %d degrees (%u)!", path, degrees, request_id);
			return request_id;
		}

		private bool perform_rotation (Request req) throws RotateError
		{
			string path = req.get_string (0);
			int degrees = req.get_int (1);
			string command = "mogrify -rotate %d %s".printf (degrees, path);
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
				throw new RotateError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				//critical ("Error spawning '%s': %s", command, e.message);
				//return false;
			}

			if (success < 0)
			{
				throw new RotateError.MOGRIFY ("Error rotating photo at '%s' (return code: %d)".printf (path, success));
				//critical ("Error rotating photo at '%s' (return code: %d)", path, success);
				//return false;
			}

			return true;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new RotateDaemon (args);

			return 0;
		}
	}
}
