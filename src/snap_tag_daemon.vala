/*
 * snap_tag_daemon.vala
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
	public errordomain TagError
	{
		SPAWN,
		EXIV2
	}

	public class TagRequest : GLib.Object
	{
		public string path;
		public string verb;
		public string tag;

		public TagRequest (string path, string verb, string tag)
		{
			this.path = path;
			this.verb = verb;
			this.tag = tag;
		}
	}

	[DBus (name = "org.washedup.Snap.TagDaemon")]
	public class TagDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.TagDaemon";
		private string dbus_object_path = "/org/washedup/Snap/TagDaemon";

		private new GLib.AsyncQueue<TagRequest> request_queue;

		/**********
		* SIGNALS *
		**********/

		// Indicates that the photo at *path* has been successfully appended to the
		// tag queue.
		// FIXME: Is *queue_length* really necessary?
		public signal void tag_request_enqueued (string path, uint queue_length);

		// Indicates that the photo at *path* was successfully tagged.
		public signal void photo_tagged (string path, string tag);

		/************
		* OPERATION *
		************/

		public TagDaemon (string[] args)
		{
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Append the photo at *path* to the tag queue, firing the
		// *tag_request_enqueued* signal when done.
		public void tag_photo (string path, string tag)
		{
			if (this.request_queue == null)
			{
				this.request_queue = new GLib.AsyncQueue<TagRequest> ();
			}

			this.request_queue.push (new TagRequest (path, "add", tag));

			// Signal that the tag request has been handled.
			tag_request_enqueued (path, this.request_queue.length ());

			debug ("Enqueued request to tag '%s' with '%s'!", path, tag);

			if (this.worker_thread == null)
			{
				try
				{
					this.worker_thread = GLib.Thread.create (this.tag_photos_in_queue, true);
				}

				catch (GLib.ThreadError e)
				{
					critical ("Error creating a new thread: %s", e.message);
				}
			}
		}

		// Append the photo at *path* to the tag queue, firing the
		// *tag_request_enqueued* signal when done.
		public void untag_photo (string path, string tag)
		{
			if (this.request_queue == null)
			{
				this.request_queue = new GLib.AsyncQueue<TagRequest> ();
			}

			this.request_queue.push (new TagRequest (path, "del", tag));

			// Signal that the tag request has been handled.
			tag_request_enqueued (path, this.request_queue.length ());

			debug ("Enqueued request to remove tag '%s' from '%s'!", tag, path);

			if (this.worker_thread == null)
			{
				try
				{
					this.worker_thread = GLib.Thread.create (this.tag_photos_in_queue, true);
				}

				catch (GLib.ThreadError e)
				{
					critical ("Error creating a new thread: %s", e.message);
				}
			}
		}

		// Perform the actual handling of items in the queue.
		private void* tag_photos_in_queue ()
		{
			if (this.request_queue.length () > 0)
			{
				do
				{
					TagRequest req = this.request_queue.pop ();
					bool success = false;

					switch (req.verb)
					{
						case "add":
							success = this.add_tag (req.path, req.tag);
							break;
						case "del":
							success = this.remove_tag (req.path, req.tag);
							break;
						default:
							critical ("Error processing verb: '%s' invalid", req.verb);
							break;
					}

					if (success)
					{
						// Signal that the photo has been successfully tagged.
						this.photo_tagged (req.path, req.tag);
						debug ("Successfully tagged '%s' with '%s'!", req.path, req.tag);
					}
				} while (this.request_queue.length () > 0);
			}

			this.worker_thread = null;
			return ((void*) 0);
		}

		private bool add_tag (string path, string tag)
		{
			string command = "exiv2 -kM \"add Iptc.Application2.Keywords '%s'\" %s".printf (tag, path);
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
				//throw new TagError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				critical ("Error spawning '%s': %s", command, e.message);
				return false;
			}

			if (success < 0)
			{
				//throw new TagError.EXIV2 ("Error tagging photo at '%s' (return code: %d)".printf (path, success));
				critical ("Error tagging photo at '%s' (return code: %d)", path, success);
				return false;
			}

			return true;
		}

		// FIXME: Make this work! As it is, this is terribly broken, nuking any and
		//        all tags the photo has ever received. DANGER!
		private bool remove_tag (string path, string tag)
		{
			string command = "exiv2 -kM \"del Iptc.Application2.Keywords '%s'\" %s".printf (tag, path);
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
				//throw new TagError.SPAWN ("Error spawning '%s': %s".printf (command, e.message));
				critical ("Error spawning '%s': %s", command, e.message);
				return false;
			}

			if (success < 0)
			{
				//throw new TagError.EXIV2 ("Error tagging photo at '%s' (return code: %d)".printf (path, success));
				critical ("Error tagging photo at '%s' (return code: %d)", path, success);
				return false;
			}

			return true;
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new TagDaemon (args);

			return 0;
		}
	}
}
