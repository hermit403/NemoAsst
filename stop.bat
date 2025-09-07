@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo [1/5] 停止NAT服务器进程...
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr "nat serve"') do (
    echo 停止NAT服务器进程: %%i
    taskkill /pid %%i /f >nul 2>&1
)

for /f "tokens=5" %%i in ('netstat -ano ^| findstr ":8001"') do (
    echo 停止端口8001的进程: %%i
    taskkill /pid %%i /f >nul 2>&1
)

echo [2/5] 停止CLI MCP服务器进程...
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr "cli-mcp-server"') do (
    echo 停止CLI MCP服务器进程: %%i
    taskkill /pid %%i /f >nul 2>&1
)

echo [3/5] 停止前端开发服务器（Next.js）...
for /f "tokens=5" %%i in ('netstat -ano ^| findstr ":3000"') do (
    echo 停止前端服务器进程（端口3000）: %%i
    taskkill /pid %%i /f >nul 2>&1
)

echo [4/5] 停止Node.js相关进程...
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq node.exe" /fo csv') do (
    echo 停止Node.js进程: %%i
    taskkill /pid %%i /f >nul 2>&1
)

echo [5/5] 停止开发相关窗口...
taskkill /fi "WindowTitle eq CLI MCP Server*" /f >nul 2>&1
taskkill /fi "WindowTitle eq NAT Server*" /f >nul 2>&1
taskkill /fi "WindowTitle eq Frontend Dev Server*" /f >nul 2>&1

echo 验证端口状态：
netstat -ano | findstr ":8001" >nul
if errorlevel 1 (
    echo ✅ 端口 8001 已释放
) else (
    echo ❌ 端口 8001 仍被占用
)

netstat -ano | findstr ":3000" >nul
if errorlevel 1 (
    echo ✅ 端口 3000 已释放
) else (
    echo ❌ 端口 3000 仍被占用
)

echo.
echo 要重新启动开发环境，请运行 start.bat
echo.
echo 按任意键退出...
pause >nul
