@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "CLAUDE_HOME=%USERPROFILE%\.claude"
set "CODEX_HOME=%USERPROFILE%\.codex"

:: Timestamp for backups
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "DT=%%I"
set "TIMESTAMP=%DT:~0,8%_%DT:~8,6%"
set "BACKUP_DIR=%USERPROFILE%\just-works-backups\%TIMESTAMP%"

:: Flags
set "PERSONAL=0"
set "DRY_RUN=0"
set "CLAUDE_ONLY=0"
set "CODEX_ONLY=0"
set "SKIP_CONFIG=0"
set "SKIP_STATUSLINE=0"
set "SKIP_SKILLS_CLAUDE=0"
set "SKIP_SKILLS_CODEX=0"
set "DO_BACKUP=1"

:: Parse arguments
:parse_args
if "%~1"=="" goto :validate
if /i "%~1"=="--personal"    ( set "PERSONAL=1"    & shift & goto :parse_args )
if /i "%~1"=="--dry-run"     ( set "DRY_RUN=1"     & shift & goto :parse_args )
if /i "%~1"=="--claude-only" ( set "CLAUDE_ONLY=1"  & shift & goto :parse_args )
if /i "%~1"=="--codex-only"  ( set "CODEX_ONLY=1"   & shift & goto :parse_args )
if /i "%~1"=="--skip-config"     ( set "SKIP_CONFIG=1"     & shift & goto :parse_args )
if /i "%~1"=="--skip-statusline" ( set "SKIP_STATUSLINE=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-skills-claude" ( set "SKIP_SKILLS_CLAUDE=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-skills-codex"  ( set "SKIP_SKILLS_CODEX=1"  & shift & goto :parse_args )
if /i "%~1"=="-h"            goto :usage
if /i "%~1"=="--help"        goto :usage
echo [x] Unknown option: %~1
goto :usage

:validate
if "%CLAUDE_ONLY%"=="1" if "%CODEX_ONLY%"=="1" (
    echo [x] --claude-only and --codex-only are mutually exclusive
    exit /b 1
)

echo just-works installer
echo.

:: --- Interactive: backup prompt ---
if not "%DRY_RUN%"=="1" (
    set /p "ANSWER=Do you want to create backups? (Y/n) "
    if /i "!ANSWER!"=="n" ( set "DO_BACKUP=0" )
    if /i "!ANSWER!"=="no" ( set "DO_BACKUP=0" )
    echo.
)

:: --- Claude Code ---
if "%CODEX_ONLY%"=="1" goto :codex

echo Claude Code
call :install_dir "%SCRIPT_DIR%.claude\agents"   "%CLAUDE_HOME%\agents"   "agents"
if "%SKIP_SKILLS_CLAUDE%"=="1" (
    echo [+] Skipping Claude skills (--skip-skills-claude)
) else (
    call :install_dir "%SCRIPT_DIR%.claude\skills"    "%CLAUDE_HOME%\skills"   "skills"
)
call :install_dir "%SCRIPT_DIR%.claude\commands"  "%CLAUDE_HOME%\commands" "commands"
if "%PERSONAL%"=="1" call :install_dir "%SCRIPT_DIR%.claude\hooks"     "%CLAUDE_HOME%\hooks"    "hooks"

if "%SKIP_CONFIG%"=="1" (
    echo [+] Skipping settings.json (--skip-config)
) else if "%PERSONAL%"=="1" (
    call :install_file "%SCRIPT_DIR%.claude\settings.json"         "%CLAUDE_HOME%\settings.json" "settings.json (personal)"
) else (
    call :install_file "%SCRIPT_DIR%.claude\settings.json.default" "%CLAUDE_HOME%\settings.json" "settings.json (default)"
)

call :install_file "%SCRIPT_DIR%CLAUDE.md" "%CLAUDE_HOME%\CLAUDE.md" "CLAUDE.md"
if "%SKIP_STATUSLINE%"=="1" (
    echo [+] Skipping statusline-command.sh (--skip-statusline)
) else (
    call :install_file "%SCRIPT_DIR%.claude\statusline-command.sh" "%CLAUDE_HOME%\statusline-command.sh" "statusline-command.sh"
)
echo.

:: --- Codex ---
:codex
if "%CLAUDE_ONLY%"=="1" goto :summary

echo Codex
call :install_dir  "%SCRIPT_DIR%.codex\prompts" "%CODEX_HOME%\prompts" "prompts"
if "%SKIP_SKILLS_CODEX%"=="1" (
    echo [+] Skipping Codex skills (--skip-skills-codex)
) else (
    call :install_dir  "%SCRIPT_DIR%.codex\skills"  "%CODEX_HOME%\skills"  "skills"
)
call :install_file "%SCRIPT_DIR%AGENTS.md"       "%CODEX_HOME%\AGENTS.md" "AGENTS.md"
echo.

:: --- Summary ---
:summary
if "%DRY_RUN%"=="1" (
    echo [!] Dry run complete -- no files were modified.
) else (
    echo Done.
    if "%DO_BACKUP%"=="1" echo   Backups:     %BACKUP_DIR%\
    if not "%CODEX_ONLY%"=="1" echo   Claude Code: %CLAUDE_HOME%\
    if not "%CLAUDE_ONLY%"=="1" echo   Codex:       %CODEX_HOME%\
)
exit /b 0

:: ============================================================
:: Functions
:: ============================================================

:prepare_target
:: %~1 = target path (file or dir)
if not exist "%~1" exit /b 0
if "%DO_BACKUP%"=="1" (
    call :backup_target "%~1"
) else (
    call :clean_target "%~1"
)
exit /b 0

:backup_target
:: %~1 = target path (file or dir)
if not exist "%~1" exit /b 0
:: Build relative path by stripping USERPROFILE prefix
set "TARGET=%~1"
set "REL_PATH=!TARGET:%USERPROFILE%\=!"
set "BACKUP_PATH=%BACKUP_DIR%\!REL_PATH!"
if "%DRY_RUN%"=="1" (
    echo [!] Would back up: %~1 -^> !BACKUP_PATH!
    exit /b 0
)
:: Ensure backup parent directory exists
for %%F in ("!BACKUP_PATH!") do if not exist "%%~dpF" mkdir "%%~dpF"
if exist "%~1\" (
    xcopy "%~1" "!BACKUP_PATH!" /e /i /y /q >nul
) else (
    copy "%~1" "!BACKUP_PATH!" >nul
)
echo [!] Backed up: %~1 -^> !BACKUP_PATH!
exit /b 0

:clean_target
:: %~1 = target path (file or dir)
if not exist "%~1" exit /b 0
if "%DRY_RUN%"=="1" (
    echo [!] Would remove: %~1
    exit /b 0
)
if exist "%~1\" (
    rmdir /s /q "%~1"
) else (
    del /q "%~1"
)
echo [!] Removed: %~1
exit /b 0

:install_dir
:: %~1 = source dir, %~2 = dest dir, %~3 = label
if not exist "%~1\" (
    echo [!] Source not found, skipping: %~1
    exit /b 0
)
call :prepare_target "%~2"
if "%DRY_RUN%"=="1" (
    echo [+] Would copy: %~1\ -^> %~2\
    exit /b 0
)
if not exist "%~2\" mkdir "%~2"
xcopy "%~1" "%~2" /e /i /y /q >nul
echo [+] Installed: %~3 -^> %~2\
exit /b 0

:install_file
:: %~1 = source file, %~2 = dest file, %~3 = label
if not exist "%~1" (
    echo [!] Source not found, skipping: %~1
    exit /b 0
)
call :prepare_target "%~2"
if "%DRY_RUN%"=="1" (
    echo [+] Would copy: %~1 -^> %~2
    exit /b 0
)
:: Ensure parent directory exists
for %%F in ("%~2") do if not exist "%%~dpF" mkdir "%%~dpF"
copy "%~1" "%~2" >nul
echo [+] Installed: %~3 -^> %~2
exit /b 0

:usage
echo Usage: install.bat [OPTIONS]
echo.
echo Install just-works agents, skills, and commands globally.
echo.
echo Options:
echo   --personal      Use opinionated settings.json (permissions, hooks, sounds)
echo                   Default: minimal settings.json.default
echo   --skip-config      Skip installing settings.json
echo   --skip-statusline  Skip installing statusline-command.sh
echo   --skip-skills-claude  Skip installing Claude Code skills
echo   --skip-skills-codex   Skip installing Codex skills
echo   --claude-only   Install only Claude Code files
echo   --codex-only    Install only Codex files
echo   --dry-run       Show what would be installed without making changes
echo   -h, --help      Show this help message
echo.
echo What gets installed:
echo   %%USERPROFILE%%\.claude\
echo     agents\       Agent definitions (python-code-writer, prompt-writer)
echo     skills\       Coding and prompting standards
echo     commands\     Workflows (project-docs)
echo     settings.json             Permission and hook configuration
echo     CLAUDE.md                 Global behavioral instructions
echo     statusline-command.sh     Status line script
echo.
echo   %%USERPROFILE%%\.codex\
echo     prompts\      Agent definitions (plan-reviewer, project-docs)
echo     skills\       Coding and prompting standards
echo     AGENTS.md     Global behavioral instructions
exit /b 0
