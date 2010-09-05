NULL = 

AM_CPPFLAGS = \
	$(SNAP_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/include \
	$(NULL)

AM_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--pkg dbus-glib-1 \
	--pkg gconf-2.0 \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg config \
	--pkg posix \
	--pkg xmpl \
	$(NULL)

bin_PROGRAMS = \
	snap-import-daemon \
	snap-thumbnail-daemon \
	snap-rotate-daemon \
	snap-delete-daemon \
	snap-metadata-daemon \
	snap-preferences-daemon \
	snap \
	importer \
	$(NULL)

snap_import_daemon_SOURCES = \
	snap_import_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	snap_invocation.vala \
	$(NULL)

snap_import_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_thumbnail_daemon_SOURCES = \
	snap_thumbnail_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	snap_invocation.vala \
	$(NULL)

snap_thumbnail_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_rotate_daemon_SOURCES = \
	snap_rotate_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	snap_invocation.vala \
	$(NULL)

snap_rotate_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_delete_daemon_SOURCES = \
	snap_delete_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	$(NULL)

snap_delete_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_metadata_daemon_SOURCES = \
	snap_metadata_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	$(NULL)

snap_metadata_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_preferences_daemon_SOURCES = \
	snap_preferences_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	$(NULL)

snap_preferences_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_SOURCES = \
	photo_viewer.vala \
	tag_viewer.vala \
	thumb_browser.vala \
	snap.vala \
	$(NULL)

snap_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

importer_SOURCES = \
	importer.vala \
	$(NULL)

importer_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

