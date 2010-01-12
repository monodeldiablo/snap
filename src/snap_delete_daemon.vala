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

// FIXME: Use the built-in logging facilities!
// FIXME: Investigate using a timeout or something to keep this daemon alive
//        for some fixed period past the last operation, to save on startup
//        costs.

namespace Snap
{
	[DBus (name = "org.washedup.Snap.DeleteDaemon")]
	public class DeleteDaemon : GLib.Object
	{
		// The application main loop.
		private GLib.MainLoop mainloop;

		/***********
		* SETTINGS *
		***********/
		
		// FIXME: These settings should probably be persisted using GConf or
		//        something.
		private string photo_directory;

		/******************
		* DATA STRUCTURES *
		******************/

		private GLib.AsyncQueue<string> delete_queue;
		private GLib.Mutex in_progress;

		/**********
		* SIGNALS *
		**********/

		// Indicates that the photo at *path* was successfully deleted.
		public signal void photo_deleted (string path);
		
		// Indicates that the photo at *path* has been successfully appended to the
		// delete queue.
		// FIXME: Is *queue_length* really necessary?
		public signal void delete_enqueued (string path, uint queue_length);

		/************
		* OPERATION *
		************/

		// The constructor...
		DeleteDaemon (string[] args)
		{
			this.mainloop = new GLib.MainLoop (null, false);
			this.in_progress = new Mutex ();

			// Hook up signals.
			delete_enqueued += delete_photos_in_queue;
			
			// FIXME: Fetch photo directory from GConf or something.
			
			debug ("DeleteDaemon instantiated.");
			register_dbus_service ();
		}

		// ... and its darker counterpart, the destructor.
		~DeleteDaemon ()
		{
		}

		// Run the application.
		private void run ()
		{
			this.mainloop.run ();
		}

		// Tear down the application.
		public void quit ()
		{
			debug ("Quitting...");

			// Let clients and listeners know that we're going bye bye.
			//exiting ();
			
			// Actually, finally, really go away.
			debug ("Goodbye!");
			this.mainloop.quit ();
		}

		// Register DeleteDaemon as a DBus service.
		private void register_dbus_service ()
		{
			try
			{
				var conn = DBus.Bus.get (DBus.BusType.SESSION);

				dynamic DBus.Object dbus = conn.get_object ("org.freedesktop.DBus",
					"/org/freedesktop/DBus",
					"org.freedesktop.DBus");

				uint request_name_result = dbus.request_name ("org.washedup.Snap.DeleteDaemon", (uint) 0);

				if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER)
				{
					conn.register_object ("/org/washedup/Snap/DeleteDaemon", this);
					
					debug ("Successfully registered DBus service!");
					
					run ();
				}

				else
				{
					quit ();
				}
			}

			catch (DBus.Error e)
			{
				stderr.printf ("Shit! %s\n", e.message);
			}
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the delete queue, firing the
		// *delete_enqueued* signal when done.
		public void delete_photo (string path)
		{
			if (this.delete_queue == null)
			{
				this.delete_queue = new GLib.AsyncQueue<string> ();
			}
				
			this.delete_queue.push (path);

			debug ("Got request to delete '%s'", path);

			// Signal that the delete request has been handled.
			delete_enqueued (path, this.delete_queue.length ());
		}

		// Perform the actual deletion of items in the queue.
		private void delete_photos_in_queue ()
		{
			// Notify future invocations that we're on the case.
			this.in_progress.lock ();

			if (this.delete_queue.length () > 0)
			{
				do
				{
					string path = this.delete_queue.pop ();
					int success = GLib.FileUtils.remove (path);

					if (success >= 0)
					{
						debug ("Deleted '%s'", path);

						// Signal that the photo has been successfully deleted.
						photo_deleted (path);
					}

					else
					{
						critical ("%s not deleted. delete returned %d", path, success);
					}
				} while (this.delete_queue.length () > 0);
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
