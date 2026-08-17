@echo off
chcp 65001 >nul
title
call :main >nul 2>&1
exit /b

:main
set "url=http://10.160.7.136/myStudyOnline"

:: ========== 用户输入标识或任务数量 ==========
:get_input
echo 请输入任务标识（如 hrg / gzd）或直接输入任务数量（数字）：
set "user_input="
set /p user_input="输入："
if "%user_input%"=="" set user_input=1

:: 判断是否为纯数字（仅判断整数）
echo %user_input%| findstr /r "^[0-9][0-9]*$" >nul
if %errorlevel% equ 0 (
    set "task_count=%user_input%"
    set "serial="
    goto :confirm_count
)

:: 非数字，按预配置匹配
set "serial="
if /i "%user_input%"=="hrg" set "serial=998524535"
if /i "%user_input%"=="gzd" set "serial=1474745"

if not defined serial (
    echo [错误] 无法识别的输入：%user_input%
    echo 请输入数字或预配置标识（hrg / gzd）。
    echo.
    goto :get_input
)

echo.
echo ----------------------------------------------------
echo 输入标识：%user_input%
echo 对应序列号：%serial%
echo ----------------------------------------------------
echo.

:ask_count
echo 请输入 task_count（任务数量，默认 1）：
set "task_count="
set /p task_count="数量："
if "%task_count%"=="" set task_count=1

:: 校验 task_count 是否为有效数字
echo %task_count%| findstr /r "^[0-9][0-9]*$" >nul
if %errorlevel% neq 0 (
    echo [错误] task_count 必须是正整数，请重新输入。
    goto :ask_count
)

:confirm_count
echo.
echo ====================================================
echo 准备启动 %task_count% 个任务
if defined serial echo 标识 %user_input% 对应序列号 %serial%
echo ====================================================
echo.


:: ========== 生成 JS 代码并复制到剪贴板 ==========
:: ===自动复活版代码，可以替换下面的刷新失效版========
:: ===set "js=(function(){function run(){setInterval(()=>{const b=document.querySelectorAll('button');b.forEach(x=>{if(x.textContent.toLowerCase().includes('继续学习')){x.click();console.log('✅ CKT');}})},3000);}run();window.addEventListener('pageshow',run);})();"
::======================================================================

set "js=setInterval(()=>{const b=document.querySelectorAll('button');b.forEach(x=>{if(x.textContent.toLowerCase().includes('继续学习')){x.click();console.log('✅ CKT');}})},3000);"
echo|set /p="%js%">tmp.tmp
type tmp.tmp | clip
del tmp.tmp /q

echo JS 代码已复制到剪贴板
echo.

:: ========== 循环：每次启动一个窗口并注入完成后再启动下一个 ==========
for /l %%i in (1,1,%task_count%) do (
    echo.
    echo ===== 正在处理第 %%i 个任务 =====

    :: 启动带自定义标题的 Chrome 窗口（独立窗口 + 自动打开开发者工具）
    echo 启动任务 %%i 窗口...
    start chrome.exe --new-tab --auto-open-devtools-for-tabs --window-name="沉浸式学习提醒%%i" "%url%"

    :: 等待页面加载（可根据实际网速调整等待秒数）
    echo 等待页面加载（3秒）...
    timeout /t 3 /nobreak >nul

    :: 使用 PowerShell 激活该窗口并粘贴运行 JS
    echo 正在向窗口 [学习任务%%i] 注入代码...
powershell -Command "$wshell=New-Object -ComObject WScript.Shell;$wshell.AppActivate('Chrome') | Out-Null;$wshell.SendKeys('{F12}');Start-Sleep -Milliseconds 800;$wshell.SendKeys('^v');Start-Sleep -Milliseconds 300;$wshell.SendKeys('{ENTER}');Start-Sleep -Milliseconds 800;$wshell.SendKeys('{F12}')"

    echo 第 %%i 个任务注入完成！
    timeout /t 2 /nobreak >nul
)

echo.
echo ====================================================
echo 全部 %task_count% 个任务已独立启动并注入完成！
echo 每个窗口每3秒自动点击 [继续学习]
echo 关闭对应窗口即可停止该任务
echo ====================================================
echo.

exit /b
