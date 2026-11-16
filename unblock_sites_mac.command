#!/bin/bash
# Bloklarni olib tashlash - macOS versiyasi

PROFILE_ID="uz.maktab.sayt-bloklash"
MARK="# SCHOOL-BLOCK"
HOSTS="/etc/hosts"

if [ "$(id -u)" -ne 0 ]; then
    echo "Administrator paroli so'raladi (yozayotganda ko'rinmaydi)."
    exec sudo bash "$0" "$@"
fi

echo "=== hosts faylidan blok qatorlari o'chirilmoqda ==="
sed -i '' "/$MARK/d" "$HOSTS"
dscacheutil -flushcache
killall -HUP mDNSResponder 2>/dev/null
echo "tayyor"

echo ""
echo "=== Brauzer profili o'chirilmoqda ==="
if profiles remove -identifier "$PROFILE_ID" 2>/dev/null; then
    echo "tayyor"
else
    echo "Profilni avtomatik o'chirib bo'lmadi. Qo'lda o'chiring:"
    echo "  System Settings -> Privacy & Security -> Profiles"
    echo "  'Maktab: saytlarni bloklash' ni tanlab, minus (-) tugmasini bosing."
fi

echo ""
echo "Barcha bloklar olib tashlandi. Brauzerlarni to'liq yopib (Cmd+Q), qayta oching."
