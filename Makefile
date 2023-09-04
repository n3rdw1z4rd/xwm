.POSIX:
.SUFFIXES:

VERSION = 0.1
PKG_CONFIG = pkg-config
PREFIX = /usr/local
MANDIR = $(PREFIX)/share/man

MAKEFLAGS = -j$(nproc)
XWLCPPFLAGS = -I. -DWLR_USE_UNSTABLE -D_POSIX_C_SOURCE=200809L -DVERSION=\"$(VERSION)\" -DXWAYLAND
XWLDEVCFLAGS = -pedantic -Wall -Wextra -Wdeclaration-after-statement -Wno-unused-parameter -Wno-sign-compare -Wshadow -Wunused-macros\
	-Werror=strict-prototypes -Werror=implicit -Werror=return-type -Werror=incompatible-pointer-types

PKGS      = wlroots wayland-server xkbcommon libinput xcb xcb-icccm
DWLCFLAGS = `$(PKG_CONFIG) --cflags $(PKGS)` $(XWLCPPFLAGS) $(XWLDEVCFLAGS) $(CFLAGS)
LDLIBS    = `$(PKG_CONFIG) --libs $(PKGS)` $(LIBS)

all: xwl
xwl: xwl.o utils.o
	$(CC) xwl.o utils.o $(LDLIBS) $(LDFLAGS) $(DWLCFLAGS) -o $@
xwl.o: xwl.c config.h client.h xdg-shell-protocol.h wlr-layer-shell-unstable-v1-protocol.h
utils.o: utils.c utils.h

WAYLAND_SCANNER   = `$(PKG_CONFIG) --variable=wayland_scanner wayland-scanner`
WAYLAND_PROTOCOLS = `$(PKG_CONFIG) --variable=pkgdatadir wayland-protocols`

xdg-shell-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		$(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml $@
wlr-layer-shell-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		protocols/wlr-layer-shell-unstable-v1.xml $@

config.h:
	cp config.def.h $@
clean:
	rm -f xwl *.o *-protocol.h

dist: clean
	mkdir -p xwl-$(VERSION)
	cp -R LICENSE* Makefile README.md client.h config.def.h\
		protocols xwl.1 xwl.c utils.c utils.h\
		xwl-$(VERSION)
	tar -caf xwl-$(VERSION).tar.gz xwl-$(VERSION)
	rm -rf xwl-$(VERSION)

install: xwl
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f xwl $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/xwl
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	cp -f xwl.1 $(DESTDIR)$(MANDIR)/man1
	chmod 644 $(DESTDIR)$(MANDIR)/man1/xwl.1
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/xwl $(DESTDIR)$(MANDIR)/man1/xwl.1

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CPPFLAGS) $(DWLCFLAGS) -c $<
