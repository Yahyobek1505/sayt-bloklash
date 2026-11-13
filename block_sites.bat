@echo off
setlocal EnableDelayedExpansion
title Saytlarni bloklash

rem --- Administrator huquqini tekshirish ---
net session >nul 2>&1
if errorlevel 1 (
    echo [XATO] Bu faylni sichqonchaning o'ng tugmasi bilan bosib
    echo        "Run as administrator" orqali ishga tushiring.
    pause
    exit /b 1
)

set "LIST=%~dp0sites.txt"
if not exist "%LIST%" (
    echo [XATO] sites.txt topilmadi: %LIST%
    pause
    exit /b 1
)

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "MARK=# SCHOOL-BLOCK"

rem --- Fayl yuklab olish cheklovi - Chrome, Edge, Yandex ---
rem   1 = xavfli fayl turlarini bloklash: .exe .msi .bat va h.k. PDF, Word ruxsat
rem   3 = HAMMA yuklab olishni bloklash
rem   0 = cheklov yo'q
set "DL_LEVEL=1"

rem --- Brauzerlar siyosati: Chrome, Edge, Yandex Browser ---
for %%B in ("Google\Chrome" "Microsoft\Edge" "YandexBrowser") do (
    set "KEY=HKLM\SOFTWARE\Policies\%%~B"
    echo.
    echo === %%~B ===
    rem Eski ro'yxatni tozalash, keyin qaytadan yozish
    reg delete "!KEY!\URLBlocklist" /f >nul 2>&1
    set /a N=0
    for /f "usebackq eol=# tokens=*" %%S in ("%LIST%") do (
        set /a N+=1
        reg add "!KEY!\URLBlocklist" /v !N! /t REG_SZ /d "%%S" /f >nul
        echo   bloklandi: %%S
    )
    rem Ruxsat ro'yxati - Google akkauntga kirish uchun kerak
    reg delete "!KEY!\URLAllowlist" /f >nul 2>&1
    reg add "!KEY!\URLAllowlist" /v 1 /t REG_SZ /d "accounts.youtube.com" /f >nul
    echo   ruxsat berildi: accounts.youtube.com
    rem Inkognito rejimini o'chirish - 1 = o'chirilgan
    reg add "!KEY!" /v IncognitoModeAvailability /t REG_DWORD /d 1 /f >nul
    rem Mehmon rejimi va yangi profil qo'shishni o'chirish
    reg add "!KEY!" /v BrowserGuestModeEnabled /t REG_DWORD /d 0 /f >nul
    reg add "!KEY!" /v BrowserAddPersonEnabled /t REG_DWORD /d 0 /f >nul
    rem DNS-over-HTTPS ni o'chirish - aks holda hosts fayli chetlab o'tiladi
    reg add "!KEY!" /v DnsOverHttpsMode /t REG_SZ /d off /f >nul
    rem Fayl yuklab olishni cheklash
    reg add "!KEY!" /v DownloadRestrictions /t REG_DWORD /d %DL_LEVEL% /f >nul
    echo   yuklab olish cheklovi: %DL_LEVEL%
)

rem --- Brauzer va Windows ichidagi AI yordamchilar ---
rem Chrome: Gemini - 1 = o'chirilgan
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v GeminiSettings /t REG_DWORD /d 1 /f >nul
rem Edge: yon panel va undagi Copilot
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /t REG_DWORD /d 0 /f >nul
rem Windows: Copilot
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul
echo.
echo === AI yordamchilar o'chirildi: Gemini, Edge Copilot, Windows Copilot ===

rem --- Firefox siyosati ---
reg delete "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter\Block" /f >nul 2>&1
set /a N=0
for /f "usebackq eol=# tokens=*" %%S in ("%LIST%") do (
    set /a N+=1
    reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter\Block" /v !N! /t REG_SZ /d "*://*.%%S/*" /f >nul
    set /a N+=1
    reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter\Block" /v !N! /t REG_SZ /d "*://%%S/*" /f >nul
)
reg delete "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter\Exceptions" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter\Exceptions" /v 1 /t REG_SZ /d "*://accounts.youtube.com/*" /f >nul
reg add "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisablePrivateBrowsing /t REG_DWORD /d 1 /f >nul
echo.
echo === Firefox === siyosat yozildi

rem --- hosts fayli: barcha dasturlar uchun ishlaydi ---
attrib -r "%HOSTS%" >nul 2>&1
findstr /v /c:"%MARK%" "%HOSTS%" > "%TEMP%\hosts.tmp"
copy /y "%TEMP%\hosts.tmp" "%HOSTS%" >nul
for /f "usebackq eol=# tokens=*" %%S in ("%LIST%") do (
    set "SITE=%%S"
    rem "/" bo'lgan manzillarni hosts ga yozib bo'lmaydi
    if "!SITE:/=!"=="!SITE!" (
        >>"%HOSTS%" echo 0.0.0.0 %%S %MARK%
        >>"%HOSTS%" echo 0.0.0.0 www.%%S %MARK%
        >>"%HOSTS%" echo 0.0.0.0 m.%%S %MARK%
    )
)
del "%TEMP%\hosts.tmp" >nul 2>&1
ipconfig /flushdns >nul
echo.
echo === hosts fayli yangilandi ===

echo.
echo TAYYOR. Brauzerlarni to'liq yopib, qayta oching.
echo Tekshirish: Chrome manzil qatoriga chrome://policy yozing.
pause
