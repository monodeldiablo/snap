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

	public class RotateRequest : GLib.Object
	{
		public string path;
		public int degrees;

		public RotateRequest (string path, int degrees)
		{
			this.path = path;
			this.degrees = degrees;
		}
	}

	[DBus (name = "org.washedup.Snap.RotateDaemon")]
	public class RotateDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.RotateDaemon";
		private string dbus_object_path = "/org/washedup/Snap/RotateDaemon";

		private new GLib.AsyncQueue<RotateRequest> request_queue;

		/**********
		* SIGNALS *
		**********/

		// Indicates that the photo at *path* has been successfully appended to the
		// rotate queue.
		// FIXME: Is *queue_length* really necessary?
		public signal void rotate_request_enqueued (string path, uint queue_length);

		// Indicates that the photo at *path* was successfully rotated.
		public signal void photo_rotated (string path, int degrees);

		/************
		* OPERATION *
		************/

		public RotateDaemon (string[] args)
		{
			hook_up_signals ();
			this.register_dbus_service (dbus_object_name, dbus_object_path);
		}

		private void hook_up_signals ()
		{
			rotate_request_enqueued += rotate_photos_in_queue;
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the rotate queue, firing the
		// *rotate_request_enqueued* signal when done.
		public void rotate_photo (string path, int degrees)
		{
			if (this.request_queue == null)
			{
				this.request_queue = new GLib.AsyncQueue<RotateRequest> ();
			}
				
			this.request_queue.push (new RotateRequest (path, degrees));

			debug ("Got request to rotate '%s' %d degrees", path, degrees);

			// Signal that the rotate request has been handled.
			rotate_request_enqueued (path, this.request_queue.length ());
		}

		// Perform the actual deletion of items in the queue.
		private void rotate_photos_in_queue ()
		{
			// Notify future invocations that we're on the case.
			this.in_progress.lock ();

			if (this.request_queue.length () > 0)
			{
				do
				{
					RotateRequest req = this.request_queue.pop ();
					bool success = perform_rotation (req.path, req.degrees);

					if (success)
					{
						// Signal that the photo has been successfully rotated.
						photo_rotated (req.path, req.degrees);
					}
				} while (this.request_queue.length () > 0);
			}

			this.in_progress.unlock ();

			quit ();
		}

		private bool perform_rotation (string path, int degrees)
		{
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
				//throw new RotateError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				critical ("Error spawning '%s': %s", command, e.message);
				return false;
			}

			if (success < 0)
			{
				//throw new RotateError.MOGRIFY ("Error rotating photo at '%s' (return code: %d)".printf (path, success));
				critical ("Error rotating photo at '%s' (return code: %d)", path, success);
				return false;
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
