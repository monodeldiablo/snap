AC_INIT([Snap: The simple photo workflow manager], [0.1.0], [brian.william.davis@gmail.com], [snap], [http://github.com/monodeldiablo/snap])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AH_TEMPLATE([GETTEXT_PACKAGE], [Snap: The simple photo workflow manager])
GETTEXT_PACKAGE=snap
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

# Set up prefix-relative directories
if test "x${prefix}" = "xNONE"; then
  PREFIX="${ac_default_prefix}"
else
  PREFIX="${prefix}"
fi
AC_DEFINE_UNQUOTED(PACKAGE_DATADIR, "${PREFIX}/${DATADIRNAME}/${PACKAGE}",[Package data directory])
AC_DEFINE_UNQUOTED(PACKAGE_BINDIR, "${PREFIX}/bin",[Package executable directory])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GEE_REQUIRED=0.5.0
GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.16.0
DBUS_GLIB_REQUIRED=0.80
GCONF_REQUIRED=2.28.0
GIO_REQUIRED=0.23.0
XMPL_REQUIRED=0.1.0

PKG_CHECK_MODULES(SNAP, gee-1.0 >= $GEE_REQUIRED glib-2.0 >= $GLIB_REQUIRED gthread-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED dbus-glib-1 >= $DBUS_GLIB_REQUIRED gconf-2.0 >= $GCONF_REQUIRED gtk+-2.0 >= $GLIB_REQUIRED gio-2.0 >= $GIO_REQUIRED xmpl >= $XMPL_REQUIRED)
AC_SUBST(SNAP_CFLAGS)
AC_SUBST(SNAP_LIBS)

AC_CONFIG_FILES([Makefile
	include/Makefile
	src/Makefile
	data/Makefile
	po/Makefile.in])

AC_OUTPUT
