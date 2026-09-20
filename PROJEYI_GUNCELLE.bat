@echo off
title FOTTBOL - GitHub'dan Guncelleme Aliniyor
echo ========================================================
echo   FOTTBOL - Proje Guncelleme Araci (Sync)
echo ========================================================
echo.
echo 1. GitHub'dan en son degisiklikler cekiliyor...
git pull origin main

if %errorlevel% neq 0 (
    echo.
    echo [HATA] GitHub baglantisinda bir sorun olustu. Lutfen internet baglantinizi kontrol edin.
    pause
    exit /b %errorlevel%
)

echo.
echo 2. Paketler ve kutuphaneler senkronize ediliyor...
call flutter pub get

echo.
echo ========================================================
echo   TEBRIKLER! Projeniz en son surume basariyla guncellendi.
echo   Simdi uygulamayi calistirabilirsiniz.
echo ========================================================
echo.
pause
