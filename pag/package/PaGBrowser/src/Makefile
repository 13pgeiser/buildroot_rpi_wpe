# Variables
PREFIX = /usr
BINDIR = $(PREFIX)/bin
TARGET = PaGBrowser

# Default target: compile the program
all: $(TARGET)

$(TARGET): main.c icon_buildbot.c icon_electricity.c icon_gallery.c icon_grafana.c icon_meteo.c icon_status.c
	$(CC) -o $(TARGET) main.c icon_buildbot.c icon_electricity.c icon_gallery.c icon_grafana.c icon_meteo.c icon_status.c `pkg-config gtk4 webkitgtk-6.0 --cflags --libs`

# Install target: copies the binary to /usr/bin
install: all
	install -D $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

# Uninstall target: removes the binary
uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)

# Clean target: removes local build files
clean:
	rm -f $(TARGET)

.PHONY: all install uninstall clean
