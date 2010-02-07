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
	[DBus (name = "org.washedup.Snap.Delete")]
	public class DeleteDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.Delete";
		private string dbus_object_path = "/org/washedup/Snap/Delete";

		/************
		* OPERATION *
		************/

		public DeleteDaemon (string[] args)
		{
			this.processing_method = this.perform_deletion;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
			this.run ();
		}

		/**********
		* METHODS *
		**********/

		public uint[] delete (string[] paths)
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

		private bool perform_deletion (Request req)
		{
			string path = req.get_string (0);
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
