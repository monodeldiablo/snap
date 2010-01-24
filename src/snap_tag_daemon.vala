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

	[DBus (name = "org.washedup.Snap.TagDaemon")]
	public class TagDaemon : Daemon
	{
		private string dbus_object_name = "org.washedup.Snap.TagDaemon";
		private string dbus_object_path = "/org/washedup/Snap/TagDaemon";

		/************
		* OPERATION *
		************/

		public TagDaemon (string[] args)
		{
			this.processing_method = this.perform_tagging;
			this.start_dbus_service (dbus_object_name, dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		public uint[] tag (string[] paths, string tag)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("add");
				req.append_string (tag);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public uint[] untag (string[] paths, string tag)
		{
			uint[] request_ids = new uint[paths.length];

			for (int i = 0; i < paths.length; i++)
			{
				Request req = new Request ();

				req.append_string (paths[i]);
				req.append_string ("del");
				req.append_string (tag);

				request_ids[i] = this.add_request_to_queue (req);
			}

			return request_ids;
		}

		public string[] get_tags (string path)
		{
			Invocation read_tags = new Invocation("exiv2 -Pkv %s".printf (path));
			GLib.MatchInfo match = read_tags.scan ("Xmp.dc.subject\\s+(?<tags>.*)");
			string[] tags;

			if (read_tags.clean && match.matches ())
			{
				tags = match.fetch_named ("tags").split (", ");
			}

			else
			{
				tags = new string[0];
			}

			// Restart the timer to go for another N seconds.
			this.restart_timer ();

			return tags;
		}

		private bool perform_tagging (Request req) throws GLib.Error
		{
			string path = req.get_string (0);
			string verb = req.get_string (1);
			string tag = req.get_string (2);
			bool success = false;

			switch (verb)
			{
				case "add":
					success = this.add_tag (path, tag);
					break;
				case "del":
					success = this.remove_tag (path, tag);
					break;
				default:
					critical ("Error processing verb: '%s' invalid", verb);
					break;
			}

			return success;
		}

		private bool add_tag (string path, string tag)
		{
			string[] tags = this.get_tags (path);

			foreach (string keyword in tags)
			{
				if (tag.down () == keyword)
				{
					return false;
				}
			}

			tags += tag.down ();

			return write_tags (path, tags);
		}

		private bool remove_tag (string path, string tag)
		{
			string[] tags = this.get_tags (path);
			string[] new_tags = new string[0];

			for (int i = 0; i < tags.length; i++)
			{
				if (tag.down () != tags[i])
				{
					new_tags += tags[i];
				}
			}

			return write_tags (path, new_tags);
		}

		private bool write_tags (string path, string[] tags)
		{
			string keywords = string.joinv (", ", tags);
			Invocation write_tags = new Invocation("exiv2 -kM \"add Xmp.dc.subject '%s'\" %s".printf (keywords, path));

			if (!write_tags.clean)
			{
				//throw new TagError.SPAWN ("Error spawning '%s': %s".printf (write_tags.command, write_tags.error));
				critical ("Error spawning '%s': %s", write_tags.command, write_tags.error);
				return false;
			}

			if (write_tags.return_value < 0)
			{
				//throw new TagError.EXIV2 ("Error tagging photo at '%s' (return code: %d)".printf (path, write_tags.return_value));
				critical ("Error tagging photo at '%s' (return code: %d)", path, write_tags.return_value);
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
