@echo off
title FOTTBOL - Windows Masaustu Uygulamasi & Otomatik Guncelleyici
echo ========================================================
echo   FOTTBOL - Windows Masaustu Uygulamasi
echo ========================================================
echo.

set "APP_DIR=%~dp0dist\fottbol-windows"
set "APP_EXE=%APP_DIR%\fottbol_prediction.exe"

if exist "%APP_EXE%" (
    echo [BILGI] Uygulama baslatiliyor...
    start "" "%APP_EXE%"
    exit /b 0
)

echo [BILGI] Uygulama henuz bilgisayarinizda kurulu degil.
echo GitHub Releases uzerinden en guncel Windows surumu indiriliyor...
echo.

if not exist "%APP_DIR%" mkdir "%APP_DIR%"

echo 1. En son Windows paketi (FOTTBOL_Windows_x64.zip) indiriliyor...
curl.exe -L -o "%TEMP%\FOTTBOL_Windows_x64.zip" "https://github.com/hakanyavuz/fottbol/releases/download/latest/FOTTBOL_Windows_x64.zip"

if %errorlevel% neq 0 (
    echo [HATA] Indirme basarisiz oldu. Lutfen internet baglantinizi kontrol edin.
    pause
    exit /b %errorlevel%
)

echo.
echo 2. Dosyalar aciliyor...
tar -xf "%TEMP%\FOTTBOL_Windows_x64.zip" -C "%APP_DIR%"
del /f /q "%TEMP%\FOTTBOL_Windows_x64.zip"

echo.
echo 3. FOTTBOL Windows Masaustu Uygulamasi Aciliyor!
start "" "%APP_EXE%"

echo.
echo Basarili! Bu pencereyi kapatabilirsiniz.
timeout /t 3 > nul
exit /b 0
