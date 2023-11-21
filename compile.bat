@REM encoding = gb2312
@REM Set version number from arg
set version=%1
@REM Create version directory in release
rm release\%version% -rf
mkdir release\%version%
cp data release\%version%\data -rf
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "app.ahk" /icon "data\icon.ico" /out "release\%version%\������ȥ.exe" /bin "C:\Program Files\AutoHotkey\ahk_h v2.1-alpha.7\AutoHotkey64.exe"
@REM bandizip compress to zip
"C:\Program Files\Bandizip\Bandizip.exe" c -y -r "release\%version%.zip" "release\%version%"