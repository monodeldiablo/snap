/*
 * snap_request.vala
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

namespace Snap
{
	// This is the request class, which holds the various arguments submitted in a
	// given daemon request. Request objects are harvested from the request queue
	// by the processing method, whose implementation varies by daemon.
	public class Request : GLib.Object
	{
		public GLib.List<GLib.Value?> arguments;
		public uint request_id;

		public Request ()
		{
			this.arguments = new GLib.List<GLib.Value?> ();
		}

		// Convenience methods to wrap awkward GLib.Value crap.
		public void append_int (int arg)
		{
			GLib.Value arg_val = GLib.Value (typeof (int));

			arg_val.set_int (arg);
			this.arguments.append (arg_val);
		}

		public void append_string (string arg)
		{
			GLib.Value arg_val = GLib.Value (typeof (string));

			arg_val.set_string (arg);
			this.arguments.append (arg_val);
		}

		public int get_int (int pos)
		{
			GLib.Value arg_val = this.arguments.nth_data (pos);

			return arg_val.get_int ();
		}

		public string get_string (int pos)
		{
			GLib.Value arg_val = this.arguments.nth_data (pos);

			return arg_val.get_string ();
		}
	}
}
