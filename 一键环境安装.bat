@echo off
chcp 65001 >nul
title 排版印相 - 环境安装

echo ========================================
echo   排版印相 - 环境安装脚本
echo ========================================
echo.

:: 检查 Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [1/3] Flutter SDK 未安装
    echo.
    echo 请手动安装 Flutter SDK:
    echo   git clone https://github.com/flutter/flutter.git -b stable D:\flutter --depth 1
    echo.
    echo 然后添加环境变量:
    echo   setx PATH "%%PATH%%;D:\flutter\bin"
    echo.
    pause
    exit /b 1
)
echo [1/3] Flutter SDK 已找到
flutter --version 2>nul | findstr "Flutter"

:: 安装依赖
echo.
echo [2/3] 安装项目依赖...
cd /d "%~dp0"
flutter pub get
if %errorlevel% neq 0 (
    echo 依赖安装失败，请检查网络连接
    pause
    exit /b 1
)
echo 依赖安装完成

:: 验证
echo.
echo [3/3] 验证项目...
flutter analyze 2>nul
if %errorlevel% neq 0 (
    echo 警告: 代码分析发现问题，但仍可继续
) else (
    echo 代码分析通过
)

echo.
echo ========================================
echo   安装完成!
echo ========================================
echo.
echo 后续步骤:
echo   1. 注册 Apple Developer: https://developer.apple.com
echo   2. 注册 Codemagic: https://codemagic.io
echo   3. 将项目推送到 GitHub
echo   4. 在 Codemagic 连接仓库并配置证书
echo   5. Codemagic 自动编译上传 IPA
echo   6. 用 AppUploader 上传到 App Store Connect
echo.
echo 本地调试 (Web/Windows):
echo   flutter run -d chrome
echo   flutter run -d windows
echo.
pause
