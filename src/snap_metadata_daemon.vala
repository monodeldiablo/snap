/*
 * snap_metadata_daemon.vala
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
	[DBus (name = "org.washedup.Snap.Metadata")]
	public class MetadataDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.Metadata";
		private string dbus_object_path = "/org/washedup/Snap/Metadata";

		/**********
		* SIGNALS *
		**********/

		public signal void request_succeeded (uint request_id);
		public signal void request_failed (uint request_id, string reason);

		/************
		* OPERATION *
		************/

		public MetadataDaemon (string[] args)
		{
			this.processing_method = this.handle_metadata_request;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
			this.run ();
		}

		/**********
		* METHODS *
		**********/

		public uint[] set_metadata (string[] paths, string key, string value)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("set");
				req.append_string (key);
				req.append_string (value);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public uint[] unset_metadata (string[] paths, string key)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("unset");
				req.append_string (key);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public uint[] append_metadata (string[] paths, string key, string value)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("append");
				req.append_string (key);
				req.append_string (value);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public uint[] remove_metadata (string[] paths, string key, string value)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("remove");
				req.append_string (key);
				req.append_string (value);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public string get_metadata (string path, string key)
		{
			// Restart the timer to go for another N seconds.
			//this.restart_timer ();

			string value = Xmpl.get_property (path, Xmpl.DC, key);

			if (value == null)
				value = "";

			return value;
		}

		private bool handle_metadata_request (Request req) throws GLib.Error
		{
			string path = req.get_string (0);
			string verb = req.get_string (1);
			string key = req.get_string (2);
			bool success = false;

			switch (verb)
			{
				case "set":
					string value = req.get_string (3);
					success = Xmpl.set_property (path, Xmpl.DC, key, value);
					break;
				case "unset":
					success = Xmpl.delete_property (path, Xmpl.DC, key);
					break;
				case "append":
					string value = req.get_string (3);
					string[] current_values = this.get_metadata (path, key).split (",");

					foreach (string keyword in current_values)
					{
						// If the value is already present, do nothing.
						if (value.down () == keyword.down ())
						{
							success = true;
							break;
						}
					}

					current_values += value.down ();
					success = Xmpl.set_property (path, Xmpl.DC, key, string.joinv (",", current_values));
					break;
				case "remove":
					string value = req.get_string (3);
					string[] current_values = this.get_metadata (path, key).split (",");
					string[] new_values = new string[0];

					for (int i = 0; i < current_values.length; ++i)
					{
						if (current_values[i].down () != value.down ())
						{
							new_values += current_values[i].down ();
						}
					}

					success = Xmpl.delete_property (path, Xmpl.DC, key) && Xmpl.set_property (path, Xmpl.DC, key, string.joinv (",", new_values));
					break;
				default:
					this.request_failed (req.request_id, "Error processing verb: '%s' invalid".printf (verb));
					break;
			}

			if (success)
				this.request_succeeded (req.request_id);
			else
				this.request_failed (req.request_id, "Unknown error");

			return success;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new MetadataDaemon (args);

			return 0;
		}
	}
}
