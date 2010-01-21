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
		private GLib.MainLoop mainloop;
		
		/******************
		* DATA STRUCTURES *
		******************/

		public GLib.AsyncQueue<Request> request_queue;
		public weak GLib.Thread worker_thread;
		public ProcessingMethod processing_method;

		// This is the last request_id that was assigned. This is the cheapest way of
		// assigning an almost-unique ID to long-running processes.
		public uint request_counter;

		// Ensure that the request_counter variable is thread-safe, since it will be
		// incremented by every request that comes in.
		public GLib.Mutex request_counter_lock;

		// Set the daemon's timeout for 60 seconds, so that it exits after a minute
		// of inactivity.
		public uint timeout_usec = 60000;
		public uint timeout_id;

		/**********
		* SIGNALS *
		**********/

		public signal void request_succeeded (uint request_id);
		public signal void request_failed (uint request_id);

		/************
		* OPERATION *
		************/

		// The constructor...
		public Daemon ()
		{
			this.request_counter = 0;
			this.request_counter_lock = new Mutex ();
			this.mainloop = new GLib.MainLoop (null, false);
		}

		// ... and its darker counterpart, the destructor.
		~Daemon ()
		{
			quit ();
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
					this.timeout_id = GLib.Timeout.add (this.timeout_usec, this.exit_if_inactive);

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
				this.request_queue = new GLib.AsyncQueue<Request> ();
			}

			// Assign the request a unique(ish) ID.
			this.request_counter_lock.@lock ();
			this.request_counter += 1;
			req.request_id = this.request_counter;
			this.request_counter_lock.unlock ();

			// Add the request to the queue.
			this.request_queue.push (req);

			// Spawn a worker thread that processes the items in the queue, if one such
			// thread does not already exist.
			if (this.worker_thread == null)
			{
				try
				{
					this.worker_thread = GLib.Thread.create (this.process_queue, true);
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

		// Process the items in the request queue.
		private void* process_queue ()
		{
			if (this.request_queue.length () > 0)
			{
				do
				{
					Request req = this.request_queue.pop ();

					try
					{
						bool success = this.processing_method (req);

						if (success)
						{
							// Signal that the request has been successfully completed.
							this.request_succeeded (req.request_id);
						}

						else
						{
							this.request_failed (req.request_id);
						}
					}

					catch (GLib.Error e)
					{
						error ("Error processing request %u: %s", req.request_id, e.message);
					}
				} while (this.request_queue.length () > 0);
			}

			this.worker_thread = null;

			return ((void*) 0);
		}

		// Restart the timer.
		public void restart_timer ()
		{
			GLib.Source.remove (timeout_id);
			this.timeout_id = GLib.Timeout.add (this.timeout_usec, this.exit_if_inactive);
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
