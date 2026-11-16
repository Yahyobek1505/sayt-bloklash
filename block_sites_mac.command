#!/bin/bash
# Saytlarni bloklash - macOS versiyasi
# 1) /etc/hosts fayliga saytlarni yozadi (Safari va barcha dasturlar uchun)
# 2) Chrome, Edge, Yandex va Firefox uchun konfiguratsiya profilini yaratadi
#    va uni o'rnatish oynasini ochadi.

PROFILE_ID="uz.maktab.sayt-bloklash"
MARK="# SCHOOL-BLOCK"
HOSTS="/etc/hosts"

# Fayl yuklab olish cheklovi - Chrome, Edge, Yandex
#   1 = xavfli fayllarni bloklash: .dmg .pkg .app va h.k. PDF, Word ruxsat
#   3 = HAMMA yuklab olishni bloklash
#   0 = cheklov yo'q
DL_LEVEL=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$SCRIPT_DIR/sites.txt"
PROFILE="$SCRIPT_DIR/maktab-sayt-bloklash.mobileconfig"

# sites.txt dan saytlarni o'qish: izoh va bo'sh qatorlar tashlab ketiladi
read_sites() {
    tr -d '\r' < "$LIST" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v -e '^#' -e '^$'
}

# Brauzer profili uchun XML qismlari
xml_array() {
    # $1 = old qo'shimcha (masalan "*://*."), $2 = oxirgi qo'shimcha (masalan "/*")
    while IFS= read -r site; do
        printf '\t\t\t\t<string>%s%s%s</string>\n' "$1" "$site" "$2"
    done
}

chromium_payload() {
    # $1 = brauzer domeni, $2 = nomi
    cat <<EOF
		<dict>
			<key>PayloadType</key>
			<string>$1</string>
			<key>PayloadIdentifier</key>
			<string>$PROFILE_ID.$1</string>
			<key>PayloadUUID</key>
			<string>$(uuidgen)</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>PayloadEnabled</key>
			<true/>
			<key>PayloadDisplayName</key>
			<string>$2</string>
			<key>URLBlocklist</key>
			<array>
$(read_sites | xml_array "" "")
			</array>
			<key>URLAllowlist</key>
			<array>
				<string>accounts.youtube.com</string>
			</array>
			<key>IncognitoModeAvailability</key>
			<integer>1</integer>
			<key>BrowserGuestModeEnabled</key>
			<false/>
			<key>BrowserAddPersonEnabled</key>
			<false/>
			<key>DnsOverHttpsMode</key>
			<string>off</string>
			<key>DownloadRestrictions</key>
			<integer>$DL_LEVEL</integer>
			<key>GeminiSettings</key>
			<integer>1</integer>
			<key>HubsSidebarEnabled</key>
			<false/>
		</dict>
EOF
}

firefox_payload() {
    cat <<EOF
		<dict>
			<key>PayloadType</key>
			<string>org.mozilla.firefox</string>
			<key>PayloadIdentifier</key>
			<string>$PROFILE_ID.org.mozilla.firefox</string>
			<key>PayloadUUID</key>
			<string>$(uuidgen)</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>PayloadEnabled</key>
			<true/>
			<key>PayloadDisplayName</key>
			<string>Firefox</string>
			<key>EnterprisePoliciesEnabled</key>
			<true/>
			<key>DisablePrivateBrowsing</key>
			<true/>
			<key>WebsiteFilter</key>
			<dict>
				<key>Block</key>
				<array>
$(read_sites | xml_array "*://*." "/*")
$(read_sites | xml_array "*://" "/*")
				</array>
				<key>Exceptions</key>
				<array>
					<string>*://accounts.youtube.com/*</string>
				</array>
			</dict>
		</dict>
EOF
}

generate_profile() {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadIdentifier</key>
	<string>$PROFILE_ID</string>
	<key>PayloadUUID</key>
	<string>$(uuidgen)</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadDisplayName</key>
	<string>Maktab: saytlarni bloklash</string>
	<key>PayloadDescription</key>
	<string>Chrome, Edge, Yandex va Firefox brauzerlarida keraksiz saytlarni bloklaydi.</string>
	<key>PayloadContent</key>
	<array>
$(chromium_payload "com.google.Chrome" "Google Chrome")
$(chromium_payload "com.microsoft.Edge" "Microsoft Edge")
$(chromium_payload "ru.yandex.desktop.yandex-browser" "Yandex Browser")
$(firefox_payload)
	</array>
</dict>
</plist>
EOF
}

update_hosts() {
    # Eski blok qatorlarini o'chirish
    sed -i '' "/$MARK/d" "$HOSTS"
    {
        echo ""
        read_sites | while IFS= read -r site; do
            # "/" bo'lgan manzillarni hosts ga yozib bo'lmaydi
            case "$site" in */*) continue ;; esac
            echo "0.0.0.0 $site $MARK"
            echo "0.0.0.0 www.$site $MARK"
            echo "0.0.0.0 m.$site $MARK"
        done
    } >> "$HOSTS"
    dscacheutil -flushcache
    killall -HUP mDNSResponder 2>/dev/null
}

main() {
    # Administrator huquqi: parol so'raladi
    if [ "$(id -u)" -ne 0 ]; then
        echo "Administrator paroli so'raladi (yozayotganda ko'rinmaydi)."
        exec sudo bash "$0" "$@"
    fi

    if [ ! -f "$LIST" ]; then
        echo "[XATO] sites.txt topilmadi: $LIST"
        exit 1
    fi

    echo "Saytlar soni: $(read_sites | wc -l | tr -d ' ')"

    echo ""
    echo "=== hosts fayli yangilanmoqda ==="
    update_hosts
    echo "tayyor"

    echo ""
    echo "=== Brauzerlar uchun profil yaratilmoqda ==="
    generate_profile > "$PROFILE"
    if ! plutil -lint "$PROFILE" >/dev/null; then
        echo "[XATO] Profil fayli buzilgan: $PROFILE"
        exit 1
    fi
    # Profil fayli oddiy foydalanuvchiga tegishli bo'lsin
    [ -n "$SUDO_USER" ] && chown "$SUDO_USER" "$PROFILE"
    echo "tayyor: $PROFILE"

    # O'rnatish oynasini foydalanuvchi nomidan ochish
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" open "$PROFILE"
    else
        open "$PROFILE"
    fi

    echo ""
    echo "================================================================"
    echo " OXIRGI QADAM - profilni o'rnating:"
    echo "  1. System Settings (Sozlamalar) ni oching"
    echo "  2. Privacy & Security -> Profiles"
    echo "     (yoki General -> Device Management)"
    echo "  3. 'Maktab: saytlarni bloklash' ni tanlab, Install ni bosing"
    echo "  4. Brauzerlarni to'liq yopib (Cmd+Q), qayta oching"
    echo " Tekshirish: Chrome manzil qatoriga chrome://policy yozing."
    echo "================================================================"
}

# Fayl to'g'ridan-to'g'ri ishga tushirilganda main ishlaydi
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
