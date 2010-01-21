/*
 * snap_invocation.vala
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
	// This is the invocation class, which executes a given command and holds the
	// invocation state for examination in calling code. This is mostly to reduce
	// the amount of redundant and verbose code elsewhere, where trapping out to
	// the command line happens frequesntly.
	//
	// FIXME: As Snap matures, it would be nice to reduce the amount of external
	//        calls it makes, as this introduces stupid dependencies on the UI of
	//        other applications. Libraries are cleaner, faster, and less hassle.
	public class Invocation: GLib.Object
	{
		public string command;
		public string stdout;
		public string stderr;
		public int return_value;
		public bool clean;
		public string error;

		public Invocation (string command)
		{
			this.command = command;

			try
			{
				GLib.Process.spawn_command_line_sync (this.command,
				                                      out this.stdout,
								      out this.stderr,
								      out this.return_value);
				this.clean = true;
			}

			catch (GLib.SpawnError e)
			{
				this.error = e.message;
				this.clean = false;
			}
		}

		// This is more convenience code for doing regular expressions against the
		// result of an invocation (usually the command's STDOUT).
		public GLib.MatchInfo scan (string regex_string, string source = "")
		{
			GLib.Regex regex;
			GLib.MatchInfo result;

			if (source == "")
			{
				source = this.stdout;
			}

			try
			{
				regex = new GLib.Regex (regex_string);
				regex.match (source, 0, out result);
			}

			catch (GLib.RegexError e)
			{
				this.clean = false;
				this.error = e.message;
				result = null;
			}

			return result;
		}
	}
}
