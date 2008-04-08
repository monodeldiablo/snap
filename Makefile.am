NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	po \
	data \
	$(NULL)

DIST_SUBDIRS = \
	data \
	$(NULL)

INCLUDES = \
	$(SNAP_CFLAGS) \
	-include $(CONFIG_HEADER) \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\"
	$(NULL)

BUILT_SOURCES = src/snap.vala.stamp

bin_PROGRAMS = snap

snap_VALASOURCES = \
	src/snap.vala \
	$(NULL)

snap_SOURCES = \
	$(snap_VALASOURCES:.vala=.c) \
	$(snap_VALASOURCES:.vala=.h) \
	$(NULL)

src/snap.vala.stamp: $(snap_VALASOURCES)
	$(VALAC) --vapidir $(top_srcdir) --pkg config --pkg dbus-glib-1 --pkg gdk-2.0 --pkg gtk+-2.0 --pkg libgnome-2.0 --pkg libgnomeui-2.0 --thread --basedir $(top_srcdir) -g $^
	touch $@

snap_LDADD = \
	$(SNAP_LIBS) \
	$(NULL)

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	$(snap_VALASOURCES) \
	src/snap.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache \
	$(NULL)

