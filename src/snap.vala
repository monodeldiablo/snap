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

// FIXME: Remove all of the ".container" stuff. I shouldn't be able to
//        access members directly unless strictly necessary.
namespace Snap
{
	public class UI : Gtk.Window
	{
		public Gtk.HPaned container;
		public ThumbBrowser thumb_browser;
		public TagViewer tag_viewer;
		public PhotoViewer photo_viewer;

		public UI (string [] args)
		{
			this.thumb_browser = new ThumbBrowser ();
			this.tag_viewer = new TagViewer ();
			this.container = new Gtk.HPaned ();

			this.container.pack1 (this.tag_viewer.container, false, true);
			this.container.pack2 (this.thumb_browser.container, true, true);
			this.container.position = 3;
			this.add (this.container);

			this.set_default_icon_name ("camera-photo");
			this.title = "Photo Manager";
			this.maximize ();

			for (int i = 1; i < args.length; ++i)
			{
				thumb_browser.add_photo (args [i]);
			}

			this.thumb_browser.selected.connect (this.handle_selected);
			this.thumb_browser.activated.connect (this.handle_activated);
			this.destroy.connect (this.quit);

			this.show_all ();
			this.thumb_browser.container.show_all ();
		}

		private void activate_photo_view (string path)
		{
			this.photo_viewer = new PhotoViewer (path);
			this.thumb_browser.container.hide ();

			this.container.remove (this.thumb_browser.container);
			this.container.pack2 (this.photo_viewer.container, true, true);

			this.photo_viewer.finished.connect (this.activate_thumb_view);
			this.photo_viewer.container.show_all ();
		}

		private void activate_thumb_view ()
		{
			this.photo_viewer.container.hide ();
			this.container.remove (this.photo_viewer.container);
			this.photo_viewer = null;

			this.container.pack2 (this.thumb_browser.container, true, true);

			this.thumb_browser.container.show_all ();
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
