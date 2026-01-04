WEBKIT="webkitgtk-2.46.6"
ROOT="/devel/pag/webkit"
(
mkdir -p "$ROOT"
cd "$ROOT"
if [ ! -e "$WEBKIT.tar.xz" ]; then
	wget "https://webkitgtk.org/releases/${WEBKIT}.tar.xz"
fi
if [ ! -d "$WEBKIT" ]; then
	tar xvJf "${WEBKIT}.tar.xz"
fi
if [ ! -d "$ROOT/webkit" ]; then
	cd "$ROOT/$WEBKIT"
	./Tools/gtk/install-dependencies
	mkdir -p "$ROOT/build_webkit"
	cd "$ROOT/build_webkit"
	cmake -DPORT=GTK -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_GTK4=ON -DUSE_SOUP2=OFF -DCMAKE_INSTALL_PREFIX="$ROOT/webkit" -G Ninja "../${WEBKIT}"
	ninja
	ninja install
fi
)
make  -C src PKG_CONFIG_PATH="$ROOT/build_webkit/Source/WebKit:/$ROOT/build_webkit/Source/JavaScriptCore" $1 