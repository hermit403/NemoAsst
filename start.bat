@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion


set PROJECT_ROOT=%~dp0
cd /d "%PROJECT_ROOT%"
set TAVILY_API_KEY=your-dev-key

if not exist "NeMo-Agent-Toolkit" (
    echo [错误] 未找到 NeMo-Agent-Toolkit 目录
    pause
    exit /b 1
)

echo [1/6] 检查API密钥...
if not defined TAVILY_API_KEY (
    echo.
    echo [配置] 未找到Tavily API Key环境变量
    echo.
    echo 请按照以下步骤获取Tavily API Key：
    echo 1. 访问 https://tavily.com/
    echo 2. 注册免费账户
    echo 3. 在控制面板中获取API Key
    echo.
    set /p TAVILY_KEY_INPUT="请输入您的Tavily API Key（或按Enter跳过）: "
    
    if not "!TAVILY_KEY_INPUT!"=="" (
        set TAVILY_API_KEY=!TAVILY_KEY_INPUT!
        echo [信息] Tavily API Key已设置（当前会话有效）
        echo [提示] 要永久设置，请运行: setx TAVILY_API_KEY "!TAVILY_KEY_INPUT!"
    ) else (
        echo [警告] 跳过Tavily API Key设置，网络搜索功能将不可用
    )
    echo.
) else (
    echo [信息] Tavily API Key已配置
)

echo [2/6] 构建 Filesystem MCP Server...
cd mcps\filesystem-mcp-server
call npm run build
if errorlevel 1 (
    echo [错误] Filesystem MCP 服务器构建失败
    pause
    exit /b 1
)
cd ..\..

echo [3/6] 启动代码执行沙盒服务器...
start "Code Execution Sandbox" cmd /k "cd /d %PROJECT_ROOT%NeMo-Agent-Toolkit && .venv\Scripts\activate.bat && echo 代码执行沙盒正在启动（端口6000）... && python src\nat\tool\code_execution\local_sandbox\local_sandbox_server.py"

echo [4/6] 启动NAT服务器...
netstat -ano | findstr ":8001" >nul
if not errorlevel 1 (
    echo [警告] 端口8001已被占用，尝试使用端口8002...
    start "NAT Server" cmd /k "cd /d %PROJECT_ROOT%NeMo-Agent-Toolkit && .venv\Scripts\activate.bat && echo NAT服务器正在启动（端口8002）... && nat serve --config_file ..\configs\hackathon_config.yml --host 0.0.0.0 --port 8002"
    set NAT_PORT=8002
) else (
    start "NAT Server" cmd /k "cd /d %PROJECT_ROOT%NeMo-Agent-Toolkit && .venv\Scripts\activate.bat && echo NAT服务器正在启动（端口8001）... && nat serve --config_file ..\configs\hackathon_config.yml --host 0.0.0.0 --port 8001"
    set NAT_PORT=8001
)

echo 等待NAT服务器启动 (3秒)...
timeout /t 3 /nobreak >nul

echo [5/6] 启动前端开发服务器...
start "Frontend Server" cmd /k "cd /d %PROJECT_ROOT%external/aiqtoolkit-opensource-ui/ && npm run dev"

echo.
echo ====================================
echo  所有服务已启动！
echo ====================================
echo.
echo 服务访问地址：
echo - NAT API服务器: http://localhost:!NAT_PORT!
echo - 前端开发服务器: http://localhost:3000
echo.
echo 服务窗口：
echo - NAT Server: 在单独窗口中运行（端口 !NAT_PORT!）
echo - Code Execution Sandbox: 在单独窗口中运行（端口 6000）
echo - Frontend Dev Server: 在单独窗口中运行（端口 3000）
echo.
echo 要停止所有服务，请运行 stop.bat
echo.

echo 正在打开浏览器...
timeout /t 2 /nobreak >nul
start http://localhost:3000

echo [6/6] 开发环境启动完成！按任意键退出此窗口...
pause >nul
