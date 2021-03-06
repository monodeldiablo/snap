/*
 * photo_viewer.vala
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
using Gtk;

namespace Snap
{
	public class PhotoViewer : GLib.Object
	{
		private Gtk.Builder ui;
		public Gtk.VBox container;
		private Gtk.Toolbar toolbar;
		private Gtk.ScrolledWindow scrolled_window;
		private Gtk.Viewport viewport;
		private Gtk.Image image;
		private Gtk.Action zoom_in_action;
		private Gtk.Action zoom_out_action;
		private Gtk.Action zoom_normal_action;
		private Gtk.Action zoom_fit_action;
		private Gtk.Action rotate_left_action;
		private Gtk.Action rotate_right_action;
		private Gtk.Action leave_action;

		private string photo_path;
		private Gdk.Pixbuf pixbuf;
		private double scale_factor = 1.0;

		public signal void loaded ();
		public signal void error (string reason);
		public signal void finished ();

		public PhotoViewer (string path)
		{
			this.photo_path = path;

			try
			{
				string ui_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
					Config.PACKAGE_DATADIR,
					"photo_viewer.ui");
				this.ui = new Builder ();
				this.ui.add_from_file (ui_path);

				this.container = (Gtk.VBox) this.ui.get_object ("container");
				this.toolbar = (Gtk.Toolbar) this.ui.get_object ("toolbar");
				this.scrolled_window = (Gtk.ScrolledWindow) this.ui.get_object ("scrolled_window");
				this.viewport = (Gtk.Viewport) this.ui.get_object ("viewport");
				this.image = (Gtk.Image) this.ui.get_object ("image");
				this.zoom_in_action = (Gtk.Action) this.ui.get_object ("zoom_in_action");
				this.zoom_out_action = (Gtk.Action) this.ui.get_object ("zoom_out_action");
				this.zoom_normal_action = (Gtk.Action) this.ui.get_object ("zoom_normal_action");
				this.zoom_fit_action = (Gtk.Action) this.ui.get_object ("zoom_fit_action");
				this.rotate_left_action = (Gtk.Action) this.ui.get_object ("rotate_left_action");
				this.rotate_right_action = (Gtk.Action) this.ui.get_object ("rotate_right_action");
				this.leave_action = (Gtk.Action) this.ui.get_object ("leave_action");

				this.connect_signals ();
				this.load_image ();
			}

			catch (GLib.Error e)
			{
				error (e.message);
			}
		}

		private void connect_signals ()
		{
			this.zoom_in_action.activate.connect (this.zoom_in);
			this.zoom_out_action.activate.connect (this.zoom_out);
			this.zoom_normal_action.activate.connect (this.zoom_normal);
			this.zoom_fit_action.activate.connect (this.zoom_best_fit);
			this.rotate_left_action.activate.connect (this.rotate_left);
			this.rotate_right_action.activate.connect (this.rotate_right);

			this.leave_action.activate.connect (this.handle_finished);
		}

		private void handle_finished ()
		{
			this.finished ();
		}

		private void load_image ()
		{
			try
			{
				this.pixbuf = new Gdk.Pixbuf.from_file (this.photo_path);
				this.zoom ();
				this.loaded ();
			}

			catch (GLib.Error e)
			{
				this.error ("Error loading image file: %s".printf (e.message));
			}
		}

		private void zoom ()
		{
			int width = (int) (this.pixbuf.width * this.scale_factor);
			int height = (int) (this.pixbuf.height * this.scale_factor);

			this.image.set_from_pixbuf (this.pixbuf.scale_simple (width, height, Gdk.InterpType.NEAREST));
		}

		public void zoom_in ()
		{
			this.scale_factor = this.scale_factor * 1.25;
			this.zoom ();
		}

		public void zoom_out ()
		{
			this.scale_factor = this.scale_factor * 0.8;
			this.zoom ();
		}

		public void zoom_normal ()
		{
			this.scale_factor = 1.0;
			this.zoom ();
		}

		public void zoom_best_fit ()
		{
			// FIXME: I use 4 here because it seems to be the magic number (on my
			//        computer, with my GTK theme, etc.) that fits the image inside the
			//        viewport without activating scroll bars. FILTHY HACK!
			int height = this.scrolled_window.allocation.height - 4;
			int width = this.scrolled_window.allocation.width - 4;
			double y_ratio = (float) height / (float) this.pixbuf.height;
			double x_ratio = (float) width / (float) this.pixbuf.width;

			if (y_ratio < x_ratio)
				this.scale_factor = y_ratio;
			else
				this.scale_factor = x_ratio;

			this.zoom ();
		}

		// FIXME: This should actually rotate the image (i.e. send a request to the
		//        RotateDaemon) and update the the thumb browser (which will probably
		//        be listening for rotate signals from the RotateDaemon).
		public void rotate_left ()
		{
			this.pixbuf = this.pixbuf.rotate_simple (Gdk.PixbufRotation.COUNTERCLOCKWISE);
			this.zoom ();
		}

		public void rotate_right ()
		{
			this.pixbuf = this.pixbuf.rotate_simple (Gdk.PixbufRotation.CLOCKWISE);
			this.zoom ();
		}

		public string get_selected ()
		{
			return this.photo_path;
		}
	}
}
