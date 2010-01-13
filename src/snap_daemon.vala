/*
 * snap_daemon.vala
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
	public abstract class Daemon : GLib.Object
	{
		// The application main loop.
		private GLib.MainLoop mainloop;
		
		/******************
		* DATA STRUCTURES *
		******************/

		public GLib.AsyncQueue<string> request_queue;
		public weak GLib.Thread worker_thread;
		public uint timeout_id;

		/************
		* OPERATION *
		************/

		// The constructor...
		public Daemon ()
		{
			this.mainloop = new GLib.MainLoop (null, false);
		}

		// ... and its darker counterpart, the destructor.
		~Daemon ()
		{
		}

		// Register the daemon as a DBus service.
		public void start_dbus_service (string object_name, string object_path)
		{
			try
			{
				var conn = DBus.Bus.get (DBus.BusType.SESSION);

				dynamic DBus.Object dbus = conn.get_object ("org.freedesktop.DBus",
					"/org/freedesktop/DBus",
					"org.freedesktop.DBus");

				uint request_name_result = dbus.request_name (object_name, (uint) 0);

				if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER)
				{
					conn.register_object (object_path, this);

					debug ("Successfully registered DBus service!");

					// Add a timeout to check if this is active every n seconds.
					this.timeout_id = GLib.Timeout.add (10000, this.exit_if_inactive);

					this.mainloop.run ();
				}

				else
				{
					critical ("Another instance already owns this bus address!");
					this.quit ();
				}
			}

			catch (DBus.Error e)
			{
				stderr.printf ("Shit! %s\n", e.message);
			}
		}

		// Check every n seconds if the application is inactive and, if so, quit.
		public bool exit_if_inactive ()
		{
			debug ("exit_if_inactive called");
			if (this.worker_thread == null)
			{
				this.quit ();
			}

			return true;
		}

		// Tear down the application.
		public void quit ()
		{
			debug ("Quitting...");

			if (this.worker_thread != null)
			{
				this.worker_thread.join ();
			}

			// Let clients and listeners know that we're going bye bye.
			//exiting ();
			
			// Actually, finally, really go away.
			debug ("Goodbye!");
			this.mainloop.quit ();
		}
	}
}
