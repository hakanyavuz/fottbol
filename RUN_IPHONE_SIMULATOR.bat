@echo off
title FOTTBOL - iPhone Simulatorde Baslatiliyor
echo ========================================================
echo   FOTTBOL - iPhone 15/16 Pro Simulatorde Calistiriliyor
echo   (Cozunurluk: 430x932, Dokunmatik & iOS Safe Area)
echo ========================================================
echo.
echo Tarayici acildiginda otomatik olarak iPhone ekran olculerinde
echo baslayacaktir. Dilerseniz F12 tusuna basip "Ctrl + Shift + M"
echo ile istediginiz farkli bir iPhone modelini de secebilirsiniz.
echo.

flutter run -d chrome --web-browser-flag="--window-size=440,960" --web-browser-flag="--window-position=50,50" --web-browser-flag="--user-agent=Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"

pause
