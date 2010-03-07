NULL = 

#Build in these directories:

SUBDIRS = \
	src \
	data \
	po \
	$(NULL)

snapservicedir = ${datadir}/dbus-1/services
snapservice_DATA = \
	org.washedup.Snap.Import.service \
	org.washedup.Snap.Thumbnail.service \
	org.washedup.Snap.Rotate.service \
	org.washedup.Snap.Delete.service \
	org.washedup.Snap.Metadata.service \
	org.washedup.Snap.Preferences.service \
	$(NULL)

org.washedup.Snap.Import.service:
	cp org.washedup.Snap.Import.service.in org.washedup.Snap.Import.service && \
	echo "Exec=${bindir}/snap-import-daemon" >> org.washedup.Snap.Import.service

org.washedup.Snap.Thumbnail.service:
	cp org.washedup.Snap.Thumbnail.service.in org.washedup.Snap.Thumbnail.service && \
	echo "Exec=${bindir}/snap-thumbnail-daemon" >> org.washedup.Snap.Thumbnail.service

org.washedup.Snap.Rotate.service:
	cp org.washedup.Snap.Rotate.service.in org.washedup.Snap.Rotate.service && \
	echo "Exec=${bindir}/snap-rotate-daemon" >> org.washedup.Snap.Rotate.service

org.washedup.Snap.Delete.service:
	cp org.washedup.Snap.Delete.service.in org.washedup.Snap.Delete.service && \
	echo "Exec=${bindir}/snap-delete-daemon" >> org.washedup.Snap.Delete.service

org.washedup.Snap.Metadata.service:
	cp org.washedup.Snap.Metadata.service.in org.washedup.Snap.Metadata.service && \
	echo "Exec=${bindir}/snap-metadata-daemon" >> org.washedup.Snap.Metadata.service

org.washedup.Snap.Preferences.service:
	cp org.washedup.Snap.Preferences.service.in org.washedup.Snap.Preferences.service && \
	echo "Exec=${bindir}/snap-preferences-daemon" >> org.washedup.Snap.Preferences.service

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
	$(snapdoc_DATA) \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	$(NULL)

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update \
	po/.intltool-merge-cache \
	$(NULL)
