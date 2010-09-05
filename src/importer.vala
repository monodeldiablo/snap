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
using Gee;

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

	public enum PageIndex
	{
		INTRO,
		PROGRESS,
		SUMMARY
	}

	public class Importer : Gtk.Assistant
	{
		private ImporterPage [] pages;
		private GLib.File import_directory;
		private dynamic DBus.Object import_daemon;
		private Gee.HashMap<uint, string> requests;
		private Gee.HashMap<uint, string> successes;
		private Gee.HashMap<uint, string> failures;

		private Gtk.FileChooserButton chooser;
		private Gtk.Label current_file;
		private Gtk.ProgressBar progress;
		private Gtk.Label summary;

		public Importer (string [] args)
		{
			this.title = "Import photos";
			this.set_default_icon_name ("camera-photo");
			this.set_size_request (450, 300);

			this.pages = {
				ImporterPage () { index = -1, title = "Import from...", complete = true, widget = null, type = Gtk.AssistantPageType.INTRO },
				ImporterPage () { index = -1, title = "Importing...", complete = false, widget = null, type = Gtk.AssistantPageType.PROGRESS },
				ImporterPage () { index = -1, title = "Import finished", complete = true, widget = null, type = Gtk.AssistantPageType.SUMMARY }};

			this.pages[PageIndex.INTRO].widget = this.create_intro_page ();
			this.pages[PageIndex.PROGRESS].widget = this.create_progress_page ();
			this.pages[PageIndex.SUMMARY].widget = this.create_summary_page ();

			foreach (ImporterPage page in this.pages)
			{
				page.index = this.append_page (page.widget);
				this.set_page_title (page.widget, page.title);
				this.set_page_type (page.widget, page.type);
				this.set_page_complete (page.widget, page.complete);
			}

			this.close.connect (this.quit);
			this.cancel.connect (this.quit);
			this.set_forward_page_func (this.progress_through_pages);

			this.show_all ();
		}

		private Gtk.Widget create_intro_page ()
		{
			this.chooser = new Gtk.FileChooserButton (
				"Import from...",
				FileChooserAction.SELECT_FOLDER);

			this.chooser.file_set.connect (set_import_directory);

			Gtk.Label label = new Gtk.Label ("Select the folder containing the photos you wish to import:");
			label.wrap = true;
			Gtk.VBox box = new Gtk.VBox (false, 0);
			box.pack_start (label, true, false);
			box.pack_start (this.chooser, true, false);

			return box;
		}

		private Gtk.Widget create_progress_page ()
		{
			// FIXME: Update this label for each file
			//        (e.g. "DSC8193.JPG -> 2010012343343.jpg")
			this.current_file = new Gtk.Label ("Importing...");
			this.current_file.use_markup = true;
			this.progress = new Gtk.ProgressBar ();
			Gtk.VBox box = new Gtk.VBox (false, 0);

			this.progress.adjustment = new Adjustment (0.0, 0.0, 1.0, 0.01, 0.01, 0.1);
			this.progress.pulse ();

			box.pack_start (current_file);
			box.pack_start (this.progress);

			return box;
		}

		private Gtk.Widget create_summary_page()
		{
			this.summary = new Gtk.Label ("");
			this.summary.use_markup = true;
			this.summary.wrap = true;

			return this.summary;
		}

		private void set_import_directory ()
		{
			this.import_directory = this.chooser.get_file ();
			debug ("Set import directory to '%s'", this.import_directory.get_path ());
		}

		private void import ()
		{
			string [] paths = {};
			string dir_path = this.import_directory.get_path ();

			try
			{
				GLib.FileEnumerator iter = this.import_directory.enumerate_children ("*",
					GLib.FileQueryInfoFlags.NONE);

				// Loop over the files, appending each path to "paths".
				GLib.FileInfo info = iter.next_file ();

				while (info != null)
				{
					string name = info.get_name ();
					paths += GLib.Path.build_path (GLib.Path.DIR_SEPARATOR.to_string (), dir_path, name);
					info = iter.next_file ();
				}
				debug ("Preparing to import %d files...", paths.length);

				// Initialize the progress bar.
				this.progress.fraction = 0.0;

				// Connect to the import daemon.
				this.set_up_connections ();

				// Set up the success and failure hashes for summary.
				this.successes = new Gee.HashMap<int, string> ();
				this.failures = new Gee.HashMap<int, string> ();

				// Submit request to import daemon.
				uint [] request_ids = this.import_daemon.import (paths);
				debug ("Got %d responses enqueued", request_ids.length);

				// Map request IDs received from above to paths via "requests".
				this.requests = new Gee.HashMap<int, string> ();

				for (int i = 0; i < request_ids.length; i++)
				{
					this.requests.set (request_ids[i], paths[i]);
				}
			}

			// FIXME: Display a message to the user and then exit.
			catch (GLib.Error e)
			{
				critical (e.message);

				this.current_file.set_text ("Unrecoverable error! Please see the next page for more information.");
				this.summary.set_text ("Uh oh! A fatal error occurred during import: %s".printf (e.message));
				this.set_page_complete (this.pages[PageIndex.PROGRESS].widget, true);
			}
		}

		// Generate some statistics about import.
		private void summarize ()
		{
			string text = "";

			if (this.failures.size > 0)
			{
				text = "Uh oh! There were %d failures (out of %d total photos):\n".printf (this.failures.size,
					this.requests.size);

				Gee.MapIterator<uint, string> iter = this.failures.map_iterator ();

				iter.first ();

				do
				{
					string reason = iter.get_value ();

					text += "\n • %s".printf (reason);
				} while (iter.next ());
			}

			else
			{
				text = "Yay! Successfully imported %d photos.".printf (this.requests.size);
			}

			this.summary.set_markup (text);
		}

		// Initialize the DBus connection to the import daemon.
		private void set_up_connections ()
		{
			try
                        {
                                DBus.Connection conn;

                                conn = DBus.Bus.get (DBus.BusType.SESSION);
                                this.import_daemon = conn.get_object ("org.washedup.Snap.Import",
                                        "/org/washedup/Snap/Import",
                                        "org.washedup.Snap.Import");

				// Register callbacks for the import daemon's updates.
				this.import_daemon.RequestSucceeded.connect (this.handle_import_request_succeeded);
				this.import_daemon.RequestFailed.connect (this.handle_import_request_failed);
                        }

			catch (DBus.Error e)
			{
				critical (e.message);
			}
		}

		private void handle_import_request_succeeded (dynamic DBus.Object daemon, uint request_id, string new_path)
		{
			string original_path = this.requests.get (request_id);
			debug ("import succeeded for #%u ('%s' → '%s')", request_id, original_path, new_path);

			this.successes.set (request_id, new_path);

			this.current_file.set_markup ("'%s' → '%s'".printf (original_path, new_path));
			this.increment_progress_bar ();
		}

		private void handle_import_request_failed (dynamic DBus.Object daemon, uint request_id, string reason)
		{
			string original_path = this.requests.get (request_id);
			debug ("import failed for #%u (%s): %s", request_id, original_path, reason);

			this.failures.set (request_id, reason);

			this.current_file.set_markup ("'%s' <span foreground='red' weight='bold'>FAILED!</span>".printf (original_path));
			this.increment_progress_bar ();
		}

		private void increment_progress_bar ()
		{
			double step = 1.0 / (double) this.requests.size;
			this.progress.fraction += step;

			double delta = GLib.Math.fabs(1.0 - this.progress.fraction);

			if (delta < step)
			{
				this.current_file.set_markup ("Importing... done!");
				this.set_page_complete (this.pages[PageIndex.PROGRESS].widget, true);
			}
		}

		private int progress_through_pages (int page_index)
		{
			switch (page_index)
			{
				case PageIndex.INTRO:
					import ();
					break;
				case PageIndex.PROGRESS:
					// If there was a fatal error, don't bother summarizing.
					if (this.summary.get_text () == "")
					{
						summarize ();
					}
					break;
				default:
					break;
			}

			return page_index + 1;
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
