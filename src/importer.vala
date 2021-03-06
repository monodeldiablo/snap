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
		private dynamic DBus.Object thumbnail_daemon;
		private Gee.HashMap<uint, string> requests;
		private Gee.HashMap<uint, string> successes;
		private Gee.HashMap<uint, string> failures;
		private Gee.HashMap<uint, string> thumb_requests;
		private Gee.HashMap<uint, string> thumb_successes;
		private Gee.HashMap<uint, string> thumb_failures;

		private Gtk.FileChooserButton chooser;
		private Gtk.Label current_file;
		private Gtk.ProgressBar import_progress;
		private Gtk.ProgressBar thumb_progress;
		private Gtk.Label summary;
		private Gtk.TextView errors;

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
			this.current_file = new Gtk.Label ("Importing...");
			this.current_file.use_markup = true;
			this.import_progress = new Gtk.ProgressBar ();
			this.thumb_progress = new Gtk.ProgressBar ();
			Gtk.VBox box = new Gtk.VBox (false, 0);

			this.import_progress.adjustment = new Adjustment (0.0, 0.0, 1.0, 0.01, 0.01, 0.1);
			this.thumb_progress.adjustment = new Adjustment (0.0, 0.0, 1.0, 0.01, 0.01, 0.1);

			box.pack_start (current_file);
			box.pack_start (this.import_progress);
			box.pack_start (this.thumb_progress);

			return box;
		}

		private Gtk.Widget create_summary_page()
		{
			Gtk.VBox box = new Gtk.VBox (false, 0);
			Gtk.ScrolledWindow win = new Gtk.ScrolledWindow (null, null);

			this.summary = new Gtk.Label ("");
			this.errors = new Gtk.TextView ();

			this.summary.use_markup = true;
			this.summary.wrap = true;
			this.errors.editable = false;

			win.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			win.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			win.add_with_viewport (this.errors);

			box.pack_start (this.summary);
			box.pack_start (win);

			return box;
		}

		private void set_import_directory ()
		{
			this.import_directory = this.chooser.get_file ();
			debug ("Set import directory to '%s'", this.import_directory.get_path ());
		}

		private void import ()
		{
			try
			{
				string [] paths = this.get_all_files_in_dir (this.import_directory);
				debug ("Preparing to import %d files...", paths.length);

				// Initialize the progress bar.
				this.import_progress.fraction = 0.0;
				this.thumb_progress.fraction = 0.0;

				// Connect to the import daemon.
				this.set_up_connections ();

				// Set up the success and failure hashes for summary.
				this.successes = new Gee.HashMap<int, string> ();
				this.failures = new Gee.HashMap<int, string> ();
				this.thumb_requests = new Gee.HashMap<int, string> ();
				this.thumb_successes = new Gee.HashMap<int, string> ();
				this.thumb_failures = new Gee.HashMap<int, string> ();

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
				this.summary.set_text ("Uh oh! A fatal error occurred during import!");

				var buf = new Gtk.TextBuffer (null);
				buf.set_text (e.message);
				this.errors.buffer = buf;

				this.set_page_complete (this.pages[PageIndex.PROGRESS].widget, true);
			}
		}

		// Generate some statistics about import.
		private void summarize ()
		{
			string text = "";
			string errors_summary;

			if (this.failures.size > 0)
			{
				text = "Uh oh! There were %d failures (out of %d total photos):\n".printf (this.failures.size,
					this.requests.size);
				errors_summary = "";

				Gee.MapIterator<uint, string> iter = this.failures.map_iterator ();

				iter.first ();

				do
				{
					string reason = iter.get_value ();

					errors_summary += " • %s\n".printf (reason);
				} while (iter.next ());

				var buf = new Gtk.TextBuffer (null);
				buf.set_text (errors_summary);
				this.errors.buffer = buf;
			}

			else
			{
				text = "Yay! Successfully imported %d photos.".printf (this.requests.size);
				this.errors.hide ();
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
				this.thumbnail_daemon = conn.get_object ("org.washedup.Snap.Thumbnail",
					"/org/washedup/Snap/Thumbnail",
					"org.washedup.Snap.Thumbnail");

				// Register callbacks for the import daemon's updates.
				this.import_daemon.RequestSucceeded.connect (this.handle_import_request_succeeded);
				this.import_daemon.RequestFailed.connect (this.handle_import_request_failed);
				this.thumbnail_daemon.RequestSucceeded.connect (this.handle_thumbnail_request_succeeded);
				this.thumbnail_daemon.RequestFailed.connect (this.handle_thumbnail_request_failed);
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

			string [] paths = {new_path};
			uint [] id = this.thumbnail_daemon.thumbnail (paths);
			this.thumb_requests.set (id[0], new_path);

			this.current_file.set_markup ("'%s' → '%s'".printf (original_path, new_path));
			this.increment_progress_bar ();
		}

		private void handle_import_request_failed (dynamic DBus.Object daemon, uint request_id, string reason)
		{
			string original_path = this.requests.get (request_id);
			debug ("import failed for #%u (%s): %s", request_id, original_path, reason);

			this.failures.set (request_id, reason);

			this.import_progress.set_text ("'%s' FAILED!".printf (original_path));
			this.increment_progress_bar ();
		}

		private void handle_thumbnail_request_succeeded (dynamic DBus.Object daemon, uint request_id, string new_path)
		{
			string original_path = this.thumb_requests.get (request_id);
			debug ("thumbnail succeeded for #%u ('%s' → '%s')", request_id, original_path, new_path);

			this.thumb_successes.set (request_id, new_path);

			this.thumb_progress.set_text ("'%s' → '%s'".printf (original_path, new_path));
			this.increment_progress_bar ();
		}

		private void handle_thumbnail_request_failed (dynamic DBus.Object daemon, uint request_id, string reason)
		{
			string original_path = this.thumb_requests.get (request_id);
			debug ("thumbnail failed for #%u (%s): %s", request_id, original_path, reason);

			this.thumb_failures.set (request_id, reason);

			this.thumb_progress.set_text ("'%s' FAILED".printf (original_path));
			this.increment_progress_bar ();
		}

		private void increment_progress_bar ()
		{
			int num_finished = this.successes.size + this.failures.size;
			int num_thumbs_finished = this.thumb_successes.size + this.thumb_failures.size;

			this.import_progress.fraction = (double) num_finished / (double) this.requests.size;
			this.thumb_progress.fraction = (double) num_thumbs_finished / (double) this.thumb_requests.size;

			if (this.requests.size == num_finished && this.thumb_requests.size == num_thumbs_finished)
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

		// Recursively build a list of files to import, given a directory.
		private string [] get_all_files_in_dir (GLib.File dir) throws GLib.Error
		{
			string [] paths = {};
			debug ("-> getting files in %s", dir.get_path ());

			GLib.FileEnumerator iter = dir.enumerate_children ("*",
				GLib.FileQueryInfoFlags.NONE);

			// Loop over the files, appending each path to "paths".
			GLib.FileInfo info = iter.next_file ();

			while (info != null)
			{
				string name = info.get_name ();

				// If this is a directory, recursively call this method on that path.
				if (info.get_file_type () == GLib.FileType.DIRECTORY)
				{
					string [] subdir_paths = this.get_all_files_in_dir (dir.get_child (name));

					foreach (string subdir_path in subdir_paths)
					{
						paths += subdir_path;
					}
				}

				else
				{
					string content_type = info.get_content_type ();

					// FIXME: This is still too loose, allowing PNGs, GIFs, SVGs, and other
					//        unsavory formats in to clog up the pipes.
					if (content_type.has_prefix ("image/"))
					{
						paths += GLib.Path.build_path (GLib.Path.DIR_SEPARATOR.to_string (),
							dir.get_path (), name);
					}
				}

				info = iter.next_file ();
			}

			iter.close ();

			return paths;
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
