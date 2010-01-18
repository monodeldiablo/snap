/*
 * snap_delete_daemon.vala
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
	[DBus (name = "org.washedup.Snap.DeleteDaemon")]
	public class DeleteDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.DeleteDaemon";
		private string dbus_object_path = "/org/washedup/Snap/DeleteDaemon";

		/************
		* OPERATION *
		************/

		public DeleteDaemon (string[] args)
		{
			this.processing_method = this.perform_deletion;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the delete queue, returning the request's
		// unique ID to the client to track.
		public uint delete_photo (string path)
		{
			Request req = new Request ();
			GLib.Value path_val = GLib.Value (typeof (string));

			path_val.set_string (path);
			req.arguments.append (path_val);

			uint request_id = this.add_request_to_queue (req);

			debug ("Enqueued request to delete '%s'!", path);
			return request_id;
		}

		private bool perform_deletion (Request req)
		{
			string path = req.arguments.nth_data (0).get_string ();
			int success = GLib.FileUtils.remove (path);

			// FIXME: Consider making this an exception that the caller catches (that
			//        way the cause of the error also reaches the client).
			if (success < 0)
			{
				critical ("Error deleting photo at '%s' (return code: %d)", path, success);
				return false;
			}

			return true;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new DeleteDaemon (args);

			return 0;
		}
	}
}
