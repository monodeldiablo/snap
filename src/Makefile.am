NULL = 

AM_CPPFLAGS = \
	$(SNAP_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-I$(top_srcdir)/include \
	$(NULL)

AM_VALAFLAGS = \
	--thread \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg dbus-glib-1 \
	--pkg gconf-2.0 \
	--pkg gtk+-2.0 \
	--pkg gio-2.0 \
	--pkg xmpl \
	$(NULL)

lib_LTLIBRARIES = \
	libxmpl.la \
	$(NULL)

bin_PROGRAMS = \
	snap-import-daemon \
	snap-thumbnail-daemon \
	snap-rotate-daemon \
	snap-tag-daemon \
	snap-delete-daemon \
	snap-preferences-daemon \
	$(NULL)

libxmpl_la_SOURCES = \
	xmpl.h \
	xmpl.c \
	$(NULL)

libxmpl_la_CFLAGS = \
	`pkg-config --cflags --libs exempi-2.0` \
	$(NULL)

libxmpl_la_LDFLAGS = \
	-shared \
	-Wl,-rpath \
	-Wl,LIBDIR \
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

snap_tag_daemon_SOURCES = \
	snap_tag_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	snap_invocation.vala \
	$(NULL)

snap_tag_daemon_LDADD = \
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

snap_preferences_daemon_SOURCES = \
	snap_preferences_daemon.vala \
	snap_daemon.vala \
	snap_request.vala \
	$(NULL)

snap_preferences_daemon_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)

