@echo off
REM Siapkan proyek Flutter (folder android) tanpa menimpa kode yang sudah ada.
REM Jalankan sekali saja dengan klik dua kali atau dari terminal: setup.bat
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter tidak ditemukan di PATH. Pasang Flutter dulu atau buka terminal Flutter.
  pause
  exit /b 1
)

if exist android (
  echo Folder android sudah ada, melewati flutter create.
  goto patch
)

echo Mencadangkan kode...
if exist _backup rmdir /s /q _backup
mkdir _backup
xcopy /E /I /Y lib _backup\lib >nul
copy /Y pubspec.yaml _backup\pubspec.yaml >nul

echo Menjalankan flutter create...
call flutter create . --project-name kuna_labirin --org id.keluarga --platforms=android

echo Mengembalikan kode...
xcopy /E /I /Y _backup\lib lib >nul
copy /Y _backup\pubspec.yaml pubspec.yaml >nul
if exist test\widget_test.dart del /q test\widget_test.dart
rmdir /s /q _backup

:patch
echo Menyesuaikan AndroidManifest untuk Android TV...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tv_patch.ps1"

call flutter pub get
echo.
echo Selesai. Langkah berikutnya:
echo   flutter run            (ke emulator Android TV / TV lewat adb)
echo   flutter build apk --release
pause
