/* importer.vala
 *
 * Copyright (C) 2008-2010  Brian Davis
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Brian Davis <brian.william.davis@gmail.com>
 */

using GLib;
using DBus;
using Gtk;

namespace Snap
{
	public class Importer : Gtk.Window
	{
		private Gtk.Builder ui;

		public Importer (string [] args)
		{
			try
			{
				string ui_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
					Config.PACKAGE_DATADIR,
					"importer.ui");
				this.ui = new Builder ();
				this.ui.add_from_file (ui_path);

				this.destroy += this.quit;

				this.show_all ();
			}

			catch (GLib.Error e)
			{
				error (e.message);
				this.quit ();
			}
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		public static void main (string [] args)
		{
			Gtk.init (ref args);

			new Importer (args);

			Gtk.main ();
		}
	}
}
