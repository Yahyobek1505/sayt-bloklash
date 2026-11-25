@echo off
setlocal
title Bloklarni olib tashlash

net session >nul 2>&1
if errorlevel 1 (
    echo [XATO] "Run as administrator" orqali ishga tushiring.
    pause
    exit /b 1
)

set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
set "MARK=# SCHOOL-BLOCK"

for %%B in ("Google\Chrome" "Microsoft\Edge" "YandexBrowser") do (
    reg delete "HKLM\SOFTWARE\Policies\%%~B\URLBlocklist" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B\URLAllowlist" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B\ExtensionInstallBlocklist" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B" /v IncognitoModeAvailability /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B" /v BrowserGuestModeEnabled /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B" /v BrowserAddPersonEnabled /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B" /v DnsOverHttpsMode /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\%%~B" /v DownloadRestrictions /f >nul 2>&1
)
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v GeminiSettings /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HubsSidebarEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Mozilla\Firefox\WebsiteFilter" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v DisablePrivateBrowsing /f >nul 2>&1

attrib -r "%HOSTS%" >nul 2>&1
findstr /v /c:"%MARK%" "%HOSTS%" > "%TEMP%\hosts.tmp"
copy /y "%TEMP%\hosts.tmp" "%HOSTS%" >nul
del "%TEMP%\hosts.tmp" >nul 2>&1
ipconfig /flushdns >nul

echo Barcha bloklar olib tashlandi. Brauzerlarni qayta oching.
pause
