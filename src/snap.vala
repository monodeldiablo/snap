/* snap.vala
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

// FIXME: Remove all of the thumb_browser.view stuff. I shouldn't be able to
//        access members directly unless strictly necessary.
namespace Snap
{
	public class UI : Gtk.Window
	{
		public Gtk.HPaned container;
		public Gtk.HBox box;
		public ThumbBrowser thumb_browser;
		public TagViewer tag_viewer;
		public PhotoViewer photo_viewer;

		public UI (string [] args)
		{
			this.thumb_browser = new ThumbBrowser ();
			this.tag_viewer = new TagViewer ();
			this.container = new Gtk.HPaned ();
			this.box = new Gtk.HBox (false, 0);

			this.box.add (this.thumb_browser.view);
			this.container.pack1 (this.tag_viewer.view, false, true);
			this.container.pack2 (this.box, false, true);
			this.add (this.container);

			// Set up a few defaults (window maximized, tag viewer a reasonable width,
			// etc).
			this.maximize ();
			this.container.position = 15;

			for (int i = 1; i < args.length; ++i)
			{
				thumb_browser.add_photo (args [i]);
			}

			this.thumb_browser.selected += this.handle_selected;
			this.thumb_browser.activated += this.handle_activated;
			this.destroy += this.quit;

			this.show_all ();
			this.thumb_browser.view.show_all ();
		}

		private void activate_photo_view (string path)
		{
			this.photo_viewer = new PhotoViewer (path);
			this.thumb_browser.view.hide ();

			this.box.add (this.photo_viewer.container);
			this.photo_viewer.finished += this.activate_thumb_view;
			this.photo_viewer.container.show_all ();
		}

		private void activate_thumb_view ()
		{
			this.photo_viewer.container.hide ();
			this.box.remove (this.photo_viewer.container);
			this.photo_viewer = null;

			this.thumb_browser.view.show_all ();
		}

		private void handle_selected (string [] paths)
		{
			this.tag_viewer.clear_photos ();

			foreach (string path in paths)
			{
				this.tag_viewer.add_photo (path);
			}
		}

		private void handle_activated (string path)
		{
			this.handle_selected ({path});
			this.activate_photo_view (path);
		}

		public void quit ()
		{
			Gtk.main_quit ();
		}

		public static void main (string [] args)
		{
			Gtk.init (ref args);

			new UI (args);

			Gtk.main ();
		}
	}
}
