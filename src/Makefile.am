NULL = 

AM_CPPFLAGS = \
	$(SNAP_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg dbus-glib-1 \
	--pkg gconf-2.0 \
	--pkg posix \
	--pkg gtk+-2.0 \
	--thread \
	$(NULL)

bin_PROGRAMS = \
	snap \
	snap-import-daemon \
	snap-rotate-daemon \
	snap-tag-daemon \
	snap-delete-daemon \
	$(NULL)

snap_SOURCES = \
	snap.vala \
	$(NULL)

snap_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_import_daemon_SOURCES = \
	snap_import_daemon.vala \
	snap_daemon.vala \
	$(NULL)

snap_import_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_rotate_daemon_SOURCES = \
	snap_rotate_daemon.vala \
	snap_daemon.vala \
	$(NULL)

snap_rotate_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_tag_daemon_SOURCES = \
	snap_tag_daemon.vala \
	snap_daemon.vala \
	$(NULL)

snap_tag_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

snap_delete_daemon_SOURCES = \
	snap_delete_daemon.vala \
	snap_daemon.vala \
	$(NULL)

snap_delete_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)
