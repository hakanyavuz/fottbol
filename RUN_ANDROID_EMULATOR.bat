@echo off
title FOTTBOL - Android Emulator Baslatiliyor
echo ========================================================
echo   FOTTBOL - Android Emulator ve Canli Test
echo ========================================================
echo.
echo Android Emulator (Testing_Device) baslatiliyor...
echo.

start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd Testing_Device

echo Emulator acilmasi bekleniyor (15 saniye)...
timeout /t 15 /nobreak > nul

echo.
echo Uygulama Android cihaza yukleniyor...
flutter run

pause
