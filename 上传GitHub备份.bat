@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title 排版印相 - GitHub 备份上传
echo.
echo   ═══════════════════════════════════════════
echo     📦 排版印相 · PrintAlbum - GitHub 备份
echo   ═══════════════════════════════════════════
echo.
echo   仓库: https://github.com/yx9920002016-creator/print-album-ios
echo.

cd /d "%~dp0"

REM 检查 git 状态
git status --porcelain >nul 2>&1
if errorlevel 1 (
    echo   ❌ 错误: 未找到 Git 仓库，请确认在项目目录下运行
    pause
    exit /b 1
)

REM 检查是否有变更
git diff --quiet 2>nul
if errorlevel 1 (
    set HAS_CHANGES=1
) else (
    git diff --cached --quiet 2>nul
    if errorlevel 1 (
        set HAS_CHANGES=1
    ) else (
        set HAS_CHANGES=0
    )
)

if !HAS_CHANGES!==0 (
    echo   没有检测到文件变更，无需上传。
    echo.
    pause
    exit /b 0
)

echo   检测到以下文件变更:
echo   ─────────────────────────────────────────
git status --short
echo   ─────────────────────────────────────────
echo.

REM 让用户输入提交说明
set /p COMMIT_MSG="  ✏️  输入本次修改说明（直接回车使用默认）: "

if "!COMMIT_MSG!"=="" (
    REM 生成带时间戳的默认说明
    for /f "tokens=1-3 delims=/- " %%a in ('date /t') do set DATE=%%a-%%b-%%c
    for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIME=%%a:%%b
    set COMMIT_MSG=代码备份 !DATE! !TIME!
)

echo.
echo   ⏳ 正在打包文件并上传到 GitHub...
echo.

REM add, commit, push 三步
git add -A
if errorlevel 1 (
    echo   ❌ 文件添加失败
    pause
    exit /b 1
)

git commit -m "!COMMIT_MSG!"
if errorlevel 1 (
    echo   ❌ 提交失败
    pause
    exit /b 1
)

git push
if errorlevel 1 (
    echo.
    echo   ⚠️  推送失败！可能需要登录 GitHub。
    echo   请确认已配置 GitHub 凭据。
    echo.
    echo   解决方式:
    echo   1. 打开 https://github.com/settings/tokens
    echo   2. 生成 Personal Access Token
    echo   3. 在命令行运行: git config --global credential.helper manager
    echo.
    pause
    exit /b 1
)

echo.
echo   ═══════════════════════════════════════════
echo     ✅ 备份上传成功！
echo   ═══════════════════════════════════════════
echo.
echo   📂 查看仓库: https://github.com/yx9920002016-creator/print-album-ios
echo.

pause
