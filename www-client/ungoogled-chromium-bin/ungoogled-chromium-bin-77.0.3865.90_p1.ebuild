# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CHROMIUM_LANGS="am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk vi zh-CN zh-TW"

inherit chromium-2 desktop readme.gentoo-r1 xdg-utils

UGC_PV="${PV/_p/-}"

DESCRIPTION="Modifications to Chromium for removing Google integration and enhancing privacy"
HOMEPAGE="https://www.chromium.org/Home https://github.com/Eloston/ungoogled-chromium"
SRC_URI="
	core2? (
		https://github.com/PF4Public/${PN}/releases/download/${UGC_PV}/core2.tar.bz2
		-> ${P}-core2.tar.bz2
	)
	generic? (
		https://github.com/PF4Public/${PN}/releases/download/${UGC_PV}/x86-64.tar.bz2
		-> ${P}-generic.tar.bz2
	)
	haswell? (
		https://github.com/PF4Public/${PN}/releases/download/${UGC_PV}/haswell.tar.bz2
		-> ${P}-haswell.tar.bz2
	)
"

RESTRICT="mirror"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="convert-dict core2 +generic haswell suid widevine"

REQUIRED_USE="|| ( core2 generic haswell )"

CDEPEND="
	>=app-accessibility/at-spi2-atk-2.26:2
	app-arch/snappy:=
	>=dev-libs/atk-2.26
	dev-libs/expat:=
	dev-libs/glib:2
	>=dev-libs/libxml2-2.9.4-r3:=[icu]
	dev-libs/libxslt:=
	dev-libs/nspr:=
	>=dev-libs/nss-3.26:=
	>=dev-libs/re2-0.2018.10.01:=
	>=media-libs/alsa-lib-1.0.19:=
	media-libs/flac:=
	media-libs/fontconfig:=
	media-libs/libjpeg-turbo:=
	media-libs/libpng:=
	>=media-libs/libwebp-0.4.0:=
	sys-apps/dbus:=
	sys-apps/pciutils:=
	sys-libs/zlib:=[minizip]
	virtual/udev
	x11-libs/cairo:=
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3[X]
	x11-libs/libX11:=
	x11-libs/libXcomposite:=
	x11-libs/libXcursor:=
	x11-libs/libXdamage:=
	x11-libs/libXext:=
	x11-libs/libXfixes:=
	>=x11-libs/libXi-1.6.0:=
	x11-libs/libXrandr:=
	x11-libs/libXrender:=
	x11-libs/libXScrnSaver:=
	x11-libs/libXtst:=
	x11-libs/pango:=
	>=net-print/cups-1.3.11:=
	media-libs/lcms:=
	media-sound/pulseaudio:=
	>=media-video/ffmpeg-3.4.5:=
	|| (
		media-video/ffmpeg[-samba]
		>=net-fs/samba-4.5.16[-debug(-)]
	)
	media-libs/opus:=
	media-libs/freetype:=
	>=media-libs/harfbuzz-2.0.0:0=[icu(-)]
	>=dev-libs/icu-58.2:=
	dev-libs/jsoncpp
	dev-libs/libevent
	>=media-libs/libvpx-1.7.0:=[postproc,svc]
	>=media-libs/openh264-1.6.0:=
	media-libs/openjpeg:2=
	x11-libs/libva:=
"
RDEPEND="${CDEPEND}
	virtual/opengl
	virtual/ttf-fonts
	x11-misc/xdg-utils
	widevine? ( !x86? ( www-plugins/chrome-binary-plugins[widevine(-)] ) )
	!www-client/chromium
	!www-client/chromium-bin
	!www-client/ungoogled-chromium
"

DISABLE_AUTOFORMATTING="yes"
DOC_CONTENTS="
Some web pages may require additional fonts to display properly.
Try installing some of the following packages if some characters
are not displayed properly:
- media-fonts/arphicfonts
- media-fonts/droid
- media-fonts/ipamonafont
- media-fonts/noto
- media-fonts/noto-emoji
- media-fonts/ja-ipafonts
- media-fonts/takao-fonts
- media-fonts/wqy-microhei
- media-fonts/wqy-zenhei

To fix broken icons on the Downloads page, you should install an icon
theme that covers the appropriate MIME types, and configure this as your
GTK+ icon theme.

For native file dialogs in KDE, install kde-apps/kdialog.
"

pkg_setup() {
	chromium_suid_sandbox_check_kernel_config
}

QA_PREBUILT="*"
S="${WORKDIR}"

src_install() {
	local CHROMIUM_HOME="/opt/chromium-browser"
	exeinto "${CHROMIUM_HOME}"
	doexe ./usr/lib64/chromium-browser/chrome

	if use convert-dict; then
		newexe "./usr/lib64/chromium-browser/ungoogled-chromium-update-dicts.sh" ungoogled-chromium-update-dicts.sh
		doexe ./usr/lib64/chromium-browser/convert_dict
	fi

	if use suid; then
		newexe chrome_sandbox ./usr/lib64/chromium-browser/chrome-sandbox
		fperms 4755 "${CHROMIUM_HOME}/chrome-sandbox"
	fi

	if use widevine; then
		dosym "../../usr/$(get_libdir)/chromium/libwidevinecdm.so" \
			"${CHROMIUM_HOME}/libwidevinecdm.so"
	fi

	doexe ./usr/lib64/chromium-browser/chromedriver

	doexe ./usr/lib64/chromium-browser/chromium-launcher.sh

	# It is important that we name the target "chromium-browser",
	# xdg-utils expect it; bug #355517.
	dosym "${CHROMIUM_HOME}/chromium-launcher.sh" /usr/bin/chromium-browser
	# keep the old symlink around for consistency
	dosym "${CHROMIUM_HOME}/chromium-launcher.sh" /usr/bin/chromium

	dosym "${CHROMIUM_HOME}/chromedriver" /usr/bin/chromedriver

	# Allow users to override command-line options, bug #357629.
	insinto /etc/chromium
	doins ./etc/chromium/default

	pushd ./usr/lib64/chromium-browser/locales > /dev/null || die
	chromium_remove_language_paks
	popd

	insinto "${CHROMIUM_HOME}"
	doins ./usr/lib64/chromium-browser/*.bin
	doins ./usr/lib64/chromium-browser/*.pak
	doins ./usr/lib64/chromium-browser/*.so

	doins -r ./usr/lib64/chromium-browser/locales
	doins -r ./usr/lib64/chromium-browser/resources

	# Install icons and desktop entry
	newicon -s 48 ./usr/share/icons/hicolor/256x256/apps/chromium-browser.png chromium-browser.png

	local mime_types="text/html;text/xml;application/xhtml+xml;"
	mime_types+="x-scheme-handler/http;x-scheme-handler/https;" # bug #360797
	mime_types+="x-scheme-handler/ftp;" # bug #412185
	mime_types+="x-scheme-handler/mailto;x-scheme-handler/webcal;" # bug #416393
	make_desktop_entry \
		chromium-browser \
		"Chromium" \
		chromium-browser \
		"Network;WebBrowser" \
		"MimeType=${mime_types}\nStartupWMClass=chromium-browser"
	sed -e "/^Exec/s/$/ %U/" -i "${ED}"/usr/share/applications/*.desktop || die

	# Install GNOME default application entry (bug #303100).
	insinto /usr/share/gnome-control-center/default-apps
	doins ./usr/share/gnome-control-center/default-apps/chromium-browser.xml

	readme.gentoo_create_doc
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
	readme.gentoo_print_elog
}
