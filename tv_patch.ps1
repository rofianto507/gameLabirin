# Menambahkan pengaturan Android TV (leanback) ke AndroidManifest.xml.
# Aman dijalankan berulang kali.
$p = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $p)) {
    Write-Host "AndroidManifest.xml tidak ditemukan: $p"
    exit 1
}
$x = Get-Content $p -Raw
if ($x -match 'android.software.leanback') {
    Write-Host 'Manifest sudah berisi pengaturan TV.'
    exit 0
}

$features = "`r`n    <uses-feature android:name=`"android.software.leanback`" android:required=`"false`" />" +
            "`r`n    <uses-feature android:name=`"android.hardware.touchscreen`" android:required=`"false`" />"

# Sisipkan uses-feature tepat setelah tag <manifest ...>
$x = [regex]::Replace($x, '(<manifest[^>]*>)', ('$1' + $features), 1)

# Tambahkan kategori launcher TV di samping LAUNCHER biasa
$x = [regex]::Replace(
    $x,
    '(<category android:name="android.intent.category.LAUNCHER"\s*/>)',
    ('$1' + "`r`n                <category android:name=`"android.intent.category.LEANBACK_LAUNCHER`" />"),
    1)

Set-Content -Path $p -Value $x -Encoding UTF8
Write-Host 'Manifest diperbarui untuk Android TV.'
