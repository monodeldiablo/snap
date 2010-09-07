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
using Posix;

// FIXME: Use the built-in logging facilities!

namespace Snap
{
	// This is the signature for methods that process items in the request queue.
	public delegate bool ProcessingMethod (Request req) throws GLib.Error;

	// This is the Daemon base class, from which actual daemons will derive. To be
	// a valid daemon, the child classes must implement at least a request handler
	// method, which generates a Request object and calls add_request_to_queue()
	// to generate a unique ID, and a processing method (which they must assign to
	// the variable 'processing_method'), which is called once for every Request
	// object in the process queue (see ProcessingMethod() for the appropriate
	// signature).
	public abstract class Daemon : GLib.Object
	{
		// The application main loop.
		private GLib.MainLoop mainloop = new GLib.MainLoop (null, false);

		// The daemon that manages settings.
		public dynamic DBus.Object preferences_daemon;

		/******************
		* DATA STRUCTURES *
		******************/

		public GLib.AsyncQueue<Request> request_queue;
		public weak GLib.Thread worker_thread;
		public ProcessingMethod processing_method;

		// This is the last request_id that was assigned. This is the cheapest way of
		// assigning an almost-unique ID to long-running processes.
		public uint request_counter;

		// Any time we modify a thread-global setting, we need to lock...
		public GLib.Mutex global_lock;

		// Keep track of the timeout ID for extending the timeout later.
		public uint timeout_id = 0;

		/**********
		* SIGNALS *
		**********/

		//public signal void request_succeeded (uint request_id);
		//public signal void request_failed (uint request_id);

		/************
		* OPERATION *
		************/

		// The constructor...
		public Daemon ()
		{
			this.request_counter = 0;
			this.global_lock = new Mutex ();
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

					// Add a timeout to check if this application is active every n seconds.
					this.restart_timer ();
				}

				else
				{
					critical ("Another instance already owns this bus address!");
					this.quit ();
				}
			}

			catch (DBus.Error e)
			{
				GLib.stderr.printf ("Could not register DBus service: %s\n", e.message);
			}
		}

		// FIXME: Currently, any GLib.Value is initialized to null, which later
		//        results in an error being thrown when we assign a value to the
		//        GLib.Value variable, complaining that the variable is already set
		//        to null. Later, it all blows up.
		//
		//        My solution, for now, is to just make everything strings and deal
		//        with the problem later (hopefully by just updating Vala).
		//public GLib.Value get_preference (string key)
		public string get_preference (string key)
		{
			string preference = "";

			if (this.preferences_daemon == null)
			{
				this.launch_preferences_daemon ();
			}

			preference = preferences_daemon.get_preference (key);

			while (preference == "")
			{
				GLib.Thread.usleep (1000);
				preference = preferences_daemon.get_preference (key);
			}

			return preference;
		}

		// Make a persistent change to the settings for the suite.
		public bool set_preference (string key, string value)
		{
			bool success;

			if (this.preferences_daemon == null)
			{
				this.launch_preferences_daemon ();
			}

			debug ("setting...");
			success = this.preferences_daemon.set_preference (key, value);
			debug ("set '%s' to '%s'!", key, value);

			return success;
		}

		// Check every timeout_usec if the application is inactive and, if so, quit.
		public bool exit_if_inactive ()
		{
			if (this.worker_thread == null)
			{
				this.quit ();
			}

			return true;
		}

		// Add an item to the processing queue, returning the item's request ID.
		public uint add_request_to_queue (Request req)
		{
			if (this.request_queue == null)
			{
				this.global_lock.@lock ();
				this.request_queue = new GLib.AsyncQueue<Request> ();
				this.global_lock.unlock ();
			}

			// Assign the request a unique(ish) ID.
			this.global_lock.@lock ();
			this.request_counter += 1;
			req.request_id = this.request_counter;
			this.global_lock.unlock ();

			// Add the request to the queue.
			this.request_queue.push (req);

			// Spawn a worker thread that processes the items in the queue, if one such
			// thread does not already exist.
			// FIXME: Investigate a thread pool.
			if (this.worker_thread == null)
			{
				try
				{
					this.global_lock.@lock ();
					this.worker_thread = GLib.Thread.create (this.process_queue, true);
					this.global_lock.unlock ();
				}

				catch (GLib.ThreadError e)
				{
					critical ("Error creating a new thread: %s", e.message);
				}
			}

			// Restart the timer.
			this.restart_timer ();

			// Return the request's ID to the caller.
			return req.request_id;
		}

		// Initialize the preferences daemon in order to get or set preferences.
		private void launch_preferences_daemon ()
		{
			try
			{
				debug ("launching the preferences daemon");
				DBus.Connection conn;

				conn = DBus.Bus.get (DBus.BusType.SESSION);

				this.global_lock.@lock ();
				this.preferences_daemon = conn.get_object ("org.washedup.Snap.Preferences",
					"/org/washedup/Snap/Preferences",
					"org.washedup.Snap.Preferences");
				debug ("launched!");
				this.global_lock.unlock ();
			}

			catch (DBus.Error e)
			{
				critical ("Error connecting to the preferences daemon: %s", e.message);
			}
		}

		// Process the items in the request queue.
		private void* process_queue ()
		{
			while (this.request_queue.length () > 0)
			{
				Request req = this.request_queue.pop ();

				try
				{
					//bool success = this.processing_method (req);
					this.processing_method (req);

					// FIXME: As of right now, these signals cannot be inherited and are thus
					//        meaningless. Child classes must implement their own signals
					//        that do the same thing as this, but less cleanly.
					/*
					if (success)
					{
						// Signal that the request has been successfully completed.
						this.request_succeeded (req.request_id);
					}

					else
					{
						this.request_failed (req.request_id);
					}
					*/
				}

				catch (GLib.Error e)
				{
					error ("Error processing request %u: %s", req.request_id, e.message);
				}
			}

			this.worker_thread = null;

			return ((void*) 0);
		}

		// Restart the timer.
		public void restart_timer ()
		{
			// Set the daemon's timeout for timeout_usec, so that it exits after a
			// period of inactivity.
			uint timeout_usec = (uint) (get_preference ("daemon-lifetime").to_double () * 1000);

			if (this.timeout_id > 0)
			{
				GLib.Source.remove (this.timeout_id);
			}

			this.timeout_id = GLib.Timeout.add (timeout_usec, this.exit_if_inactive);
		}

		// Run the program's event loop.
		public void run ()
		{
			this.mainloop.run ();
		}

		// Tear down the application.
		public void quit ()
		{
			debug ("Quitting...");

			if (this.worker_thread != null)
			{
				this.worker_thread.join ();
			}

			// Actually, finally, really go away.
			if (this.mainloop != null && this.mainloop.is_running ())
			{
				debug ("Goodbye!");
				this.mainloop.quit ();
			}

			else
			{
				Posix.exit (-1);
			}
		}
	}
}
