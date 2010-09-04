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
	public struct ImporterPage
	{
		int index;
		string title;
		bool complete;
		Gtk.Widget widget;
		Gtk.AssistantPageType type;
	}

	public class Importer : Gtk.Assistant
	{
		public ImporterPage [] pages;

		public Importer (string [] args)
		{
			this.title = "Import photos";
			this.set_default_icon_name ("camera-photo");
			this.set_size_request (450, 300);

			this.pages = {
				ImporterPage () { index = -1, title = "Import from...", complete = true, widget = null, type = Gtk.AssistantPageType.INTRO },
				ImporterPage () { index = -1, title = "Importing...", complete = false, widget = null, type = Gtk.AssistantPageType.PROGRESS },
				ImporterPage () { index = -1, title = "Import finished", complete = true, widget = null, type = Gtk.AssistantPageType.SUMMARY }};

			this.pages[0].widget = this.create_intro_page ();
			this.pages[1].widget = this.create_progress_page ();
			this.pages[2].widget = this.create_summary_page ();

			foreach (ImporterPage page in this.pages)
			{
				page.index = this.append_page (page.widget);
				this.set_page_title (page.widget, page.title);
				this.set_page_type (page.widget, page.type);
				this.set_page_complete (page.widget, page.complete);
			}

			this.close.connect (this.quit);
			this.cancel.connect (this.quit);

			this.show_all ();
		}

		public Gtk.Widget create_intro_page ()
		{
			Gtk.FileChooserButton button = new Gtk.FileChooserButton (
				"Import from...",
				FileChooserAction.SELECT_FOLDER);
			Gtk.Label label = new Gtk.Label ("Select the folder containing the photos you wish to import:");
			Gtk.HBox box = new Gtk.HBox (false, 0);
			box.pack_start (label);
			box.pack_start (button);

			return box;
		}

		public Gtk.Widget create_progress_page ()
		{
			// FIXME: Update this label for each file
			//        (e.g. "DSC8193.JPG -> 2010012343343.jpg")
			Gtk.Label label = new Gtk.Label ("Importing...");
			Gtk.ProgressBar progress = new ProgressBar ();
			Gtk.VBox box = new Gtk.VBox (false, 0);

			progress.adjustment = new Adjustment (0.0, 0.0, 1.0, 0.01, 0.01, 0.1);
			progress.pulse ();

			box.pack_start (label);
			box.pack_start (progress);

			return box;
		}

		public Gtk.Widget create_summary_page()
		{
			Gtk.Label label = new Gtk.Label ("Successfully imported <b>0</b> new photos!");

			return label;
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
