/*
 * snap_preferences_daemon.vala
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
using Gtk;

namespace Snap
{
	public errordomain PreferencesError
	{
		UNSET,
		EMPTY,
		UNSUPPORTED_TYPE
	}

	[DBus (name = "org.washedup.Snap.Preferences")]
	public class PreferencesDaemon : GLib.Object
	{
		private string dbus_object_name = "org.washedup.Snap.Preferences";
		private string dbus_object_path = "/org/washedup/Snap/Preferences";

		private GConf.Client gconf_client = GConf.Client.get_default ();
		private string key_format = "/apps/snap/%s";

		public bool awaiting_user_feedback = false;
		private GLib.Mutex feedback_lock = new GLib.Mutex ();

		private Gtk.Dialog preferences_dialog;
		private Gtk.Action close_action;
		private Gtk.Entry photo_directory_entry;
		private Gtk.Entry window_width_entry;
		private Gtk.Entry window_height_entry;
		private Gtk.Entry daemon_lifetime_entry;
		private Gtk.Entry default_artist_entry;
		private Gtk.Entry default_copyright_entry;

		/************
		* OPERATION *
		************/

		public PreferencesDaemon (string[] args)
		{
			// Initialize Gtk.
			Gtk.init (ref args);

			// Launch the service.
			this.start_dbus_service (this.dbus_object_name, this.dbus_object_path);
		}

		/**********
		* METHODS *
		**********/

		// Register the daemon as a DBus service.
		private void start_dbus_service (string object_name, string object_path)
		{
			try
			{
				var conn = DBus.Bus.get (DBus.BusType.SESSION);

				dynamic DBus.Object dbus = conn.get_object ("org.freedesktop.DBus",
					"/org/freedesktop/DBus",
					"org.freedesktop.DBus");

				uint request_name_result = dbus.request_name (object_name, (uint) 0);

				if (request_name_result == DBus.RequestNameReply.PRIMARY_OWNER)
				{
					conn.register_object (object_path, this);

					debug ("Successfully registered DBus service!");
					Gtk.main ();
				}

				else
				{
					critical ("Another instance already owns this bus address!");
					this.quit ();
				}
			}

			catch (DBus.Error e)
			{
				stderr.printf ("Shit! %s\n", e.message);
			}
		}

		public void quit ()
		{
			debug ("Goodbye!");
			Gtk.main_quit ();
		}

		public string get_preference (string key)
		{
			string preference;

			try
			{
				preference = this.gconf_client.get_string (key_format.printf (key));

				if (preference == null)
					throw new PreferencesError.UNSET ("there is no value for this key");
				else if (preference == "")
					throw new PreferencesError.EMPTY ("empty strings are not allowed");
			}

			catch (GLib.Error e)
			{
				// OK. We have no idea what this setting is or should be. We'll launch a
				// separate process to investigate and prompt the user for input (showing
				// a helpful little message explaining the inconvenience, of course).
				preference = "";
				this.prompt_user (key, e.message);
			}

			// Send the client 'val'. If an error was thrown, 'val' will be initialized
			// to the uchar value of 0, which means that we're terribly sorry, but we're
			// desperately trying to contact the user to clear things up,
			// thankyouverymuch. Check back in the tiniest of moments, if it's not an
			// overly bothersome amount of trouble.
			return preference;
		}

		public bool set_preference (string key, string val)
		{
			GConf.Value setting;

			try
			{
				setting = to_gconf_value (val);
				this.gconf_client.set (key_format.printf (key), setting);
			}

			catch (GLib.Error e)
			{
				this.prompt_user (key, e.message);

				return false;
			}

			return true;
		}

		public void invalidate_preference (string key, string reason)
		{
			try
			{
				this.gconf_client.unset (key_format.printf (key));
			}

			catch (GLib.Error e)
			{
				critical ("error unsetting '%s': '%s'", key, e.message);
			}

			this.prompt_user (key, reason);
		}

		// Convert from a GLib.Value type to a GConf.Value type. If we can't convert,
		// this function throws an exception and gives up.
		private GConf.Value to_gconf_value (string val) throws PreferencesError
		{
			GConf.Value setting = new GConf.Value (GConf.ValueType.STRING);

			if (val != "")
				setting.set_string (val);
			else
				throw new PreferencesError.EMPTY ("empty strings are not allowed");

			return setting;
		}

		private void prompt_user (string key, string error)
		{
			// Check to see if we're already asking the user to mess with a setting...
			if (!awaiting_user_feedback)
			{
				// Notify other threads that we're launching the preferences window now.
				this.feedback_lock.@lock ();
				this.awaiting_user_feedback = true;
				this.feedback_lock.unlock ();

				this.construct_preferences_dialog ();
				this.populate_preferences_dialog ();
				this.set_error_state (this.key_to_widget (key), error);

				this.preferences_dialog.show_all ();
			}
		}

		private void construct_preferences_dialog ()
		{
			// Construct the window and its child widgets from the UI definition.
			Gtk.Builder builder = new Gtk.Builder ();
			string path = GLib.Path.build_filename (Config.PACKAGE_DATADIR, "preferences.ui");

			try
			{
				builder.add_from_file (path);
			}
			
			catch (GLib.Error e)
			{
				stderr.printf ("Error loading the interface definition file: %s\n", e.message);
				this.quit ();
			}

			this.preferences_dialog = (Gtk.Dialog) builder.get_object ("preferences_dialog");
			this.photo_directory_entry = (Gtk.Entry) builder.get_object ("photo_directory_entry");
			this.window_width_entry = (Gtk.Entry) builder.get_object ("window_width_entry");
			this.window_height_entry = (Gtk.Entry) builder.get_object ("window_height_entry");
			this.daemon_lifetime_entry = (Gtk.Entry) builder.get_object ("daemon_lifetime_entry");
			this.default_artist_entry = (Gtk.Entry) builder.get_object ("default_artist_entry");
			this.default_copyright_entry = (Gtk.Entry) builder.get_object ("default_copyright_entry");
			this.close_action = (Gtk.Action) builder.get_object ("close_action");

			close_action.activate += this.sync_preferences;
			this.preferences_dialog.close += this.sync_preferences;
			this.preferences_dialog.destroy += this.sync_preferences;
		}

		private void populate_preferences_dialog ()
		{
			// Initialize the preference entries with the current GConf settings.
			try
			{
				if (this.gconf_client.get (key_format.printf ("photo-directory")) != null)
					this.photo_directory_entry.set_text (this.gconf_client.get_string (key_format.printf ("photo-directory")));

				if (this.gconf_client.get (key_format.printf ("window-width")) != null)
					this.window_width_entry.set_text (this.gconf_client.get_string (key_format.printf ("window-width")));

				if (this.gconf_client.get (key_format.printf ("window-height")) != null)
					this.window_height_entry.set_text (this.gconf_client.get_string (key_format.printf ("window-height")));

				if (this.gconf_client.get (key_format.printf ("default-artist")) != null)
					this.default_artist_entry.set_text (this.gconf_client.get_string (key_format.printf ("default-artist")));

				if (this.gconf_client.get (key_format.printf ("default-copyright")) != null)
					this.default_copyright_entry.set_text (this.gconf_client.get_string (key_format.printf ("default-copyright")));

				if (this.gconf_client.get (key_format.printf ("daemon-lifetime")) != null)
					this.daemon_lifetime_entry.set_text (this.gconf_client.get_string (key_format.printf ("daemon-lifetime")));
			}

			catch (GLib.Error e)
			{
				critical ("Error synching the settings in GConf to the preferences window: %s", e.message);
			}
		}

		private void sync_preferences ()
		{
			this.feedback_lock.@lock ();
			this.awaiting_user_feedback = false;
			this.feedback_lock.unlock ();

			this.preferences_dialog.hide ();

			var photo_directory_setting = this.photo_directory_entry.get_text ();
			var window_width_setting = this.window_width_entry.get_text ();
			var window_height_setting = this.window_height_entry.get_text ();
			var default_artist_setting = this.default_artist_entry.get_text ();
			var default_copyright_setting = this.default_copyright_entry.get_text ();
			var daemon_lifetime_setting = this.daemon_lifetime_entry.get_text ();

			this.set_preference ("photo-directory", photo_directory_setting);
			this.set_preference ("window-width", window_width_setting);
			this.set_preference ("window-height", window_height_setting);
			this.set_preference ("default-artist", default_artist_setting);
			this.set_preference ("default-copyright", default_copyright_setting);
			this.set_preference ("daemon-lifetime", daemon_lifetime_setting);
		}

		private void set_error_state (Gtk.Entry entry_widget, string text)
		{
			entry_widget.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY,
				"dialog-error");
			entry_widget.set_icon_sensitive (Gtk.EntryIconPosition.SECONDARY, true);
			entry_widget.set_icon_tooltip_text (Gtk.EntryIconPosition.SECONDARY, text);
		}

		private Gtk.Entry? key_to_widget (string key)
		{
			switch (key)
			{
				case "photo-directory": return this.photo_directory_entry;
				case "window-width": return this.window_width_entry;
				case "window-height": return this.window_height_entry;
				case "default-artist": return this.default_artist_entry;
				case "default-copyright": return this.default_copyright_entry;
				case "daemon-lifetime": return this.daemon_lifetime_entry;
				default: return null;
			}
		}

		/************
		* EXECUTION *
		************/

		static int main (string[] args)
		{
			new PreferencesDaemon (args);

			return 0;
		}
	}
}
