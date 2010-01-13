NULL = 

#Build in these directories:

SUBDIRS = \
	src \
	data \
	po \
	$(NULL)

snapservicedir = ${datadir}/dbus-1/services
snapservice_DATA = \
	org.washedup.Snap.ImportDaemon.service \
	org.washedup.Snap.RotateDaemon.service \
	org.washedup.Snap.TagDaemon.service \
	org.washedup.Snap.DeleteDaemon.service \
	$(NULL)

org.washedup.Snap.ImportDaemon.service:
	cp org.washedup.Snap.ImportDaemon.service.in org.washedup.Snap.ImportDaemon.service && \
	echo "Exec=${bindir}/snap-import-daemon" >> org.washedup.Snap.ImportDaemon.service

org.washedup.Snap.RotateDaemon.service:
	cp org.washedup.Snap.RotateDaemon.service.in org.washedup.Snap.RotateDaemon.service && \
	echo "Exec=${bindir}/snap-rotate-daemon" >> org.washedup.Snap.RotateDaemon.service

org.washedup.Snap.TagDaemon.service:
	cp org.washedup.Snap.TagDaemon.service.in org.washedup.Snap.TagDaemon.service && \
	echo "Exec=${bindir}/snap-tag-daemon" >> org.washedup.Snap.TagDaemon.service

org.washedup.Snap.DeleteDaemon.service:
	cp org.washedup.Snap.DeleteDaemon.service.in org.washedup.Snap.DeleteDaemon.service && \
	echo "Exec=${bindir}/snap-delete-daemon" >> org.washedup.Snap.DeleteDaemon.service

snapdocdir = ${docdir}
snapdoc_DATA = \
	ChangeLog \
	README \
	COPYING \
	AUTHORS \
	INSTALL \
	NEWS \
	$(NULL)

EXTRA_DIST = \
	org.washedup.Snap.service.in \
	$(snapdoc_DATA) \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	$(NULL)

DISTCLEANFILES = \
	org.washedup.Snap.service \
	intltool-extract \
	intltool-merge \
	intltool-update \
	po/.intltool-merge-cache \
	$(NULL)
