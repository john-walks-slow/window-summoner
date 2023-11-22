@REM encoding = gb2312
@REM Read version from version.txt
for /f "delims=" %%a in (data\version.txt) do set version=%%a

@REM Create version directory in release
rm release\%version% -rf
mkdir release\%version%
cp data release\%version%\data -rf
rm release\%version%\data\config.json
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "app.ahk" /icon "data\icon.ico" /out "release\%version%\∫Ù¿¥ªΩ»•.exe" /bin "C:\Program Files\AutoHotkey\ahk_h v2.1-alpha.7\AutoHotkey64.exe"
@REM bandizip compress to zip
"C:\Program Files\Bandizip\Bandizip.exe" c -y -r "release\%version%.zip" "release\%version%"