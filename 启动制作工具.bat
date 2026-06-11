@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d d:\photo-album-maker-ios

echo.
echo ═══════════════════════════════════════════
echo   Photo Album Maker - 启动中...
echo ═══════════════════════════════════════════
echo.

REM 获取本机局域网 IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set "LOCAL_IP=%%a"
    set "LOCAL_IP=!LOCAL_IP: =!"
    goto :found
)
:found

echo   电脑访问: http://localhost:8080
if defined LOCAL_IP (
    echo   手机访问: http://!LOCAL_IP!:8080
    echo.
    echo   确保手机和电脑连的是同一个 WiFi！
) else (
    echo.
    echo   未能获取局域网IP，请手动查看 ipconfig
)
echo ═══════════════════════════════════════════
echo.
echo   终端快捷键:
echo     r  - 热重载    Shift+R - 完全重启
echo     q  - 退出
echo.
echo ═══════════════════════════════════════════
echo.

REM 后台等 flutter 编译完成后自动打开浏览器（每2秒检测一次，最多等40秒）
start "" powershell -WindowStyle Minimized -Command ^
  "$done=$false; for($i=0;$i -lt 20;$i++){try{$r=Invoke-WebRequest 'http://localhost:8080' -TimeoutSec 2 -UseBasicParsing; if($r.StatusCode -eq 200){Start-Process 'http://localhost:8080'; $done=$true; break}}catch{}; Start-Sleep 2}; if(-not $done){Start-Process 'http://localhost:8080'}"

echo   正在编译，请稍候...浏览器将在编译完成后自动打开。
echo.

REM 使用 web-server 模式启动，只开服务不自动弹浏览器，避免打开 0.0.0.0 无效地址
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080

echo.
echo 已关闭。按任意键退出...
pause >nul
