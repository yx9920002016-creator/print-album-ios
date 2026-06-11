@echo off
cd /d d:\photo-album-maker-ios
echo 正在添加 web 支持...
flutter create . --platforms=web
echo.
echo web 支持已添加！按任意键退出。
pause >nul
