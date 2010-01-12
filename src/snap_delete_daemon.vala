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
		string dbus_object_name = "org.washedup.Snap.DeleteDaemon";
		string dbus_object_path = "/org/washedup/Snap/DeleteDaemon";

		/**********
		* SIGNALS *
		**********/

		// Indicates that the photo at *path* has been successfully appended to the
		// delete queue.
		// FIXME: Is *queue_length* really necessary?
		public signal void delete_request_enqueued (string path, uint queue_length);

		// Indicates that the photo at *path* was successfully deleted.
		public signal void photo_deleted (string path);

		/************
		* OPERATION *
		************/

		public DeleteDaemon (string[] args)
		{
			hook_up_signals ();
			this.register_dbus_service (dbus_object_name, dbus_object_path);
		}

		private void hook_up_signals ()
		{
			delete_request_enqueued += delete_photos_in_queue;
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the delete queue, firing the
		// *delete_request_enqueued* signal when done.
		public void delete_photo (string path)
		{
			if (this.request_queue == null)
			{
				this.request_queue = new GLib.AsyncQueue<string> ();
			}
				
			this.request_queue.push (path);

			debug ("Got request to delete '%s'", path);

			// Signal that the delete request has been handled.
			delete_request_enqueued (path, this.request_queue.length ());
		}

		// Perform the actual deletion of items in the queue.
		private void delete_photos_in_queue ()
		{
			// Notify future invocations that we're on the case.
			this.in_progress.lock ();

			if (this.request_queue.length () > 0)
			{
				do
				{
					string path = this.request_queue.pop ();
					int success = FileUtils.remove (path);

					if (success >= 0)
					{
						// Signal that the photo has been successfully deleted.
						photo_deleted (path);
					}

					else
					{
						critical ("Could not delete file at '%s'!", path);
					}
				} while (this.request_queue.length () > 0);
			}

			this.in_progress.unlock ();

			quit ();
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
