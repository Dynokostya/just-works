@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
:: Same variables Claude Code and Codex read, so a second profile can be targeted
if defined CLAUDE_CONFIG_DIR ( set "CLAUDE_HOME=%CLAUDE_CONFIG_DIR%" ) else ( set "CLAUDE_HOME=%USERPROFILE%\.claude" )
if not defined CODEX_HOME set "CODEX_HOME=%USERPROFILE%\.codex"
set "AGENTS_HOME=%USERPROFILE%\.agents"

:: Timestamp for backups
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TIMESTAMP=%%I"
set "BACKUP_DIR=%USERPROFILE%\just-works-backups\%TIMESTAMP%"

:: Flags
set "PERSONAL=0"
set "AZURE=0"
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
if /i "%~1"=="--azure"       ( set "AZURE=1"       & shift & goto :parse_args )
if /i "%~1"=="--dry-run"     ( set "DRY_RUN=1"     & shift & goto :parse_args )
if /i "%~1"=="--claude-only" ( set "CLAUDE_ONLY=1"  & shift & goto :parse_args )
if /i "%~1"=="--codex-only"  ( set "CODEX_ONLY=1"   & shift & goto :parse_args )
if /i "%~1"=="--skip-config"     ( set "SKIP_CONFIG=1"     & shift & goto :parse_args )
if /i "%~1"=="--skip-statusline" ( set "SKIP_STATUSLINE=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-skills-claude" ( set "SKIP_SKILLS_CLAUDE=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-skills-codex"  ( set "SKIP_SKILLS_CODEX=1"  & shift & goto :parse_args )
if /i "%~1"=="--no-backup"   ( set "DO_BACKUP=0"   & shift & goto :parse_args )
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

:: Files and folders that are never copied (xcopy /exclude list)
set "EXCL_FILE=%TEMP%\jw-exclude-%RANDOM%.txt"
>"%EXCL_FILE%" echo \__pycache__\
>>"%EXCL_FILE%" echo .DS_Store
:: xcopy /exclude does not accept quoted paths, so use the short (space-free) form of the path
for %%I in ("%EXCL_FILE%") do set "EXCL_FILE=%%~sI"

:: --- Interactive: backup prompt ---
if not "%DRY_RUN%"=="1" if "%DO_BACKUP%"=="1" (
    set /p "ANSWER=Do you want to create backups? (Y/n) "
    if /i "!ANSWER!"=="n" ( set "DO_BACKUP=0" )
    if /i "!ANSWER!"=="no" ( set "DO_BACKUP=0" )
    echo.
)

:: --- Claude Code ---
if "%CODEX_ONLY%"=="1" goto :codex

echo Claude Code
call :manifest_begin "%CLAUDE_HOME%" claude
call :sync_scope agents "%SCRIPT_DIR%.claude\agents" "agent"
if "%SKIP_SKILLS_CLAUDE%"=="1" (
    echo [+] Skipping Claude skills ^(--skip-skills-claude^)
) else (
    call :sync_scope skills "%SCRIPT_DIR%.claude\skills" "skill"
)
call :retire_scope commands
call :sync_scope output-styles "%SCRIPT_DIR%.claude\output-styles" "output style"

if "%SKIP_CONFIG%"=="1" (
    echo [+] Skipping settings.json ^(--skip-config^)
    call :migrate_rtk_hook "%CLAUDE_HOME%\settings.json"
) else if "%PERSONAL%"=="1" (
    call :install_file "%SCRIPT_DIR%.claude\settings.json"         "%CLAUDE_HOME%\settings.json" "settings.json (personal)"
) else (
    call :install_file "%SCRIPT_DIR%.claude\settings.json.default" "%CLAUDE_HOME%\settings.json" "settings.json (default)"
)

call :install_file "%SCRIPT_DIR%CLAUDE.md" "%CLAUDE_HOME%\CLAUDE.md" "CLAUDE.md"
call :sync_owned_file "%SCRIPT_DIR%web-chat-prompt.md" web-chat-prompt.md
if "%SKIP_STATUSLINE%"=="1" (
    echo [+] Skipping statusline-command.sh ^(--skip-statusline^)
) else (
    call :install_file "%SCRIPT_DIR%.claude\statusline-command.sh" "%CLAUDE_HOME%\statusline-command.sh" "statusline-command.sh"
)
call :manifest_end
echo.

:: --- Codex ---
:codex
if "%CLAUDE_ONLY%"=="1" goto :summary

echo Codex
call :manifest_begin "%CODEX_HOME%" codex
call :sync_scope agents  "%SCRIPT_DIR%.codex\agents"  "agent"
call :retire_scope prompts
call :manifest_end
if "%SKIP_SKILLS_CODEX%"=="1" (
    echo [+] Skipping Codex skills ^(--skip-skills-codex^)
) else (
    call :stage_codex_skills
    call :manifest_begin "%AGENTS_HOME%" agents
    call :sync_scope skills "!STAGE_DIR!" "skill"
    call :manifest_end
    rmdir /s /q "!STAGE_DIR!"
)

if "%SKIP_CONFIG%"=="1" (
    echo [+] Skipping config.toml and hooks.json ^(--skip-config^)
) else if "%AZURE%"=="1" (
    if "%PERSONAL%"=="1" (
        call :install_file "%SCRIPT_DIR%.codex\config\azure\config.toml"         "%CODEX_HOME%\config.toml" "config.toml (azure, personal)"
    ) else (
        call :install_file "%SCRIPT_DIR%.codex\config\azure\config.toml.default" "%CODEX_HOME%\config.toml" "config.toml (azure, default)"
    )
) else (
    if "%PERSONAL%"=="1" (
        call :install_file "%SCRIPT_DIR%.codex\config.toml"         "%CODEX_HOME%\config.toml" "config.toml (personal)"
    ) else (
        call :install_file "%SCRIPT_DIR%.codex\config.toml.default" "%CODEX_HOME%\config.toml" "config.toml (default)"
    )
)
if not "%SKIP_CONFIG%"=="1" (
    if "%PERSONAL%"=="1" (
        call :install_file "%SCRIPT_DIR%.codex\hooks.json"         "%CODEX_HOME%\hooks.json" "hooks.json (personal)"
    ) else (
        call :install_file "%SCRIPT_DIR%.codex\hooks.json.default" "%CODEX_HOME%\hooks.json" "hooks.json (default)"
    )
)

call :install_file "%SCRIPT_DIR%AGENTS.md"       "%CODEX_HOME%\AGENTS.md" "AGENTS.md"
echo.

:: --- Summary ---
:summary
if "%DRY_RUN%"=="1" (
    echo [^^!] Dry run complete -- no files were modified.
) else (
    echo Done.
    if "%DO_BACKUP%"=="1" echo   Backups:     %BACKUP_DIR%\
    if not "%CODEX_ONLY%"=="1" echo   Claude Code: %CLAUDE_HOME%\
    if not "%CLAUDE_ONLY%"=="1" echo   Codex:       %CODEX_HOME%\
    if not "%CLAUDE_ONLY%"=="1" echo   Skills:      %AGENTS_HOME%\skills\
)
del "%EXCL_FILE%" 2>nul
exit /b 0

:: ============================================================
:: Functions
:: ============================================================

:backup_target
:: %~1 = target path (file, directory or link)
if not exist "%~1" exit /b 0
:: Build relative path by stripping USERPROFILE prefix
set "TARGET=%~1"
set "REL_PATH=!TARGET:%USERPROFILE%\=!"
set "BACKUP_PATH=%BACKUP_DIR%\!REL_PATH!"
if "%DRY_RUN%"=="1" (
    echo [^^!] Would back up: %~1 -^> !BACKUP_PATH!
    exit /b 0
)
:: Ensure backup parent directory exists
for %%F in ("!BACKUP_PATH!") do if not exist "%%~dpF" mkdir "%%~dpF"
if exist "%~1\" (
    xcopy "%~1" "!BACKUP_PATH!" /e /i /y /q >nul
) else (
    copy "%~1" "!BACKUP_PATH!" >nul
)
echo [^^!] Backed up: %~1 -^> !BACKUP_PATH!
exit /b 0

:remove_entry
:: %~1 = file, directory or link. A link is removed without touching what it points to.
if not exist "%~1" exit /b 0
if not exist "%~1\" goto :re_file
set "RE_ATTR=%~a1"
if "!RE_ATTR:~8,1!"=="l" (
    rmdir "%~1"
) else (
    rmdir /s /q "%~1"
)
exit /b 0
:re_file
del /f /q "%~1"
exit /b 0

:install_entry
:: %~1 = source (file or directory), %~2 = destination.
:: Only the entry itself is replaced; a directory is replaced as a whole so files
:: removed upstream do not linger, and nothing next to it is touched.
if exist "%~2" if "%DO_BACKUP%"=="1" call :backup_target "%~2"
if "%DRY_RUN%"=="1" goto :ie_dry
call :remove_entry "%~2"
for %%F in ("%~2") do if not exist "%%~dpF" mkdir "%%~dpF"
if exist "%~1\" goto :ie_dir
copy /y "%~1" "%~2" >nul
exit /b 0
:ie_dir
xcopy "%~1" "%~2" /e /i /y /q /exclude:%EXCL_FILE% >nul
exit /b 0
:ie_dry
if exist "%~2" echo [^^!] Would replace: %~2
exit /b 0

:install_file
:: %~1 = source file, %~2 = dest file, %~3 = label
if not exist "%~1" (
    echo [^^!] Source not found, skipping: %~1
    exit /b 0
)
if exist "%~2" if "%DO_BACKUP%"=="1" call :backup_target "%~2"
if "%DRY_RUN%"=="1" (
    echo [+] Would copy: %~1 -^> %~2
    exit /b 0
)
call :remove_entry "%~2"
:: Ensure parent directory exists
for %%F in ("%~2") do if not exist "%%~dpF" mkdir "%%~dpF"
copy "%~1" "%~2" >nul
echo [+] Installed: %~3 -^> %~2
exit /b 0

:: ------------------------------------------------------------
:: Manifest: which entries just-works installed into a home directory.
:: Used to remove entries that a later version renamed or deleted, without
:: touching other files. One entry per line, relative to the home directory,
:: with forward slashes (for example skills/python-coding).
:: ------------------------------------------------------------

:legacy_entries
:: %~1 = claude, codex or agents. Entries shipped by earlier versions, used when no manifest exists yet.
if "%~1"=="claude" (
    echo skills/opus-5-prompting
    echo skills/fable-5-prompting
    echo skills/gpt-5-6-prompting
    echo CLAUDE-CHAT.md
    echo agents/diagrammer.md
    echo agents/ticket-creator.md
    echo commands/git-sync.md
    echo commands/project-docs.md
)
if "%~1"=="codex" (
    echo agents/diagrammer.toml
    echo agents/ticket-creator.toml
    echo prompts/git-sync.md
    echo prompts/project-docs.md
)
if "%~1"=="agents" (
    echo skills/opus-5-prompting
    echo skills/fable-5-prompting
    echo skills/gpt-5-6-prompting
)
exit /b 0

:manifest_begin
:: %~1 = home directory, %~2 = legacy key
set "CUR_HOME=%~1"
set "CUR_MANIFEST=%~1\.just-works-manifest"
set "DONE_SCOPES=;"
set "NEW_FILE=%TEMP%\jw-new-%RANDOM%.txt"
set "OLD_FILE=%TEMP%\jw-old-%RANDOM%.txt"
type nul > "%NEW_FILE%"
if exist "%CUR_MANIFEST%" goto :mb_read
call :legacy_entries "%~2" > "%OLD_FILE%.raw"
goto :mb_filter
:mb_read
findstr /v /b /c:"#" "%CUR_MANIFEST%" > "%OLD_FILE%.raw"
:mb_filter
:: Keep only plain relative entries: letters, digits, _ . / - and no ".." (blank and unsafe lines are dropped)
findstr /r "^[A-Za-z0-9_][A-Za-z0-9_./-]*$" "%OLD_FILE%.raw" | findstr /v /c:".." > "%OLD_FILE%"
del "%OLD_FILE%.raw" 2>nul
exit /b 0

:prune_stale
:: %~1 = scope (. for files directly in the home directory), %~2 = file listing the shipped names
for /f "usebackq delims=" %%E in ("%OLD_FILE%") do call :prune_one "%%E" "%~1" "%~2"
exit /b 0

:prune_one
:: %~1 = manifest entry, %~2 = scope, %~3 = file listing the shipped names
set "P_SCOPE=."
set "P_NAME=%~1"
echo %~1 | findstr /c:"/" >nul && for /f "tokens=1* delims=/" %%A in ("%~1") do set "P_SCOPE=%%A" & set "P_NAME=%%B"
if not "!P_SCOPE!"=="%~2" exit /b 0
findstr /x /l /c:"!P_NAME!" "%~3" >nul && exit /b 0
set "P_ENTRY=%~1"
set "P_TARGET=%CUR_HOME%\!P_ENTRY:/=\!"
if not exist "!P_TARGET!" exit /b 0
if "%DO_BACKUP%"=="1" call :backup_target "!P_TARGET!"
if "%DRY_RUN%"=="1" goto :po_dry
call :remove_entry "!P_TARGET!"
echo [^^!] Pruned ^(no longer shipped^): !P_TARGET!
exit /b 0
:po_dry
echo [^^!] Would prune ^(no longer shipped^): !P_TARGET!
exit /b 0

:sync_scope
:: %~1 = scope (folder name inside the home directory), %~2 = source dir, %~3 = label
:: Installs every entry of the source dir and prunes entries no longer shipped.
if exist "%~2\" goto :ss_go
echo [^^!] Source not found, skipping: %~2
exit /b 0
:ss_go
set "SHIPPED_FILE=%TEMP%\jw-ship-%RANDOM%.txt"
dir /b "%~2" | findstr /v /x /l /c:".DS_Store" /c:"__pycache__" /c:".gitkeep" > "%SHIPPED_FILE%"
call :prune_stale "%~1" "%SHIPPED_FILE%"
set "DONE_SCOPES=!DONE_SCOPES!%~1;"
set "SC_COUNT=0"
for /f "usebackq delims=" %%N in ("%SHIPPED_FILE%") do (
    call :install_entry "%~2\%%N" "%CUR_HOME%\%~1\%%N"
    >>"%NEW_FILE%" echo %~1/%%N
    set /a SC_COUNT+=1
)
del "%SHIPPED_FILE%" 2>nul
if "%DRY_RUN%"=="1" goto :ss_dry
echo [+] Installed: !SC_COUNT! %~3 entries -^> %CUR_HOME%\%~1\
exit /b 0
:ss_dry
echo [+] Would install: !SC_COUNT! %~3 entries -^> %CUR_HOME%\%~1\
exit /b 0

:retire_scope
:: %~1 = scope that just-works no longer ships at all; removes every entry it owned there
set "SHIPPED_FILE=%TEMP%\jw-ship-%RANDOM%.txt"
type nul > "%SHIPPED_FILE%"
call :prune_stale "%~1" "%SHIPPED_FILE%"
del "%SHIPPED_FILE%" 2>nul
set "DONE_SCOPES=!DONE_SCOPES!%~1;"
exit /b 0

:sync_owned_file
:: %~1 = source file, %~2 = file name directly inside the home directory
set "SHIPPED_FILE=%TEMP%\jw-ship-%RANDOM%.txt"
>"%SHIPPED_FILE%" echo %~2
call :prune_stale "." "%SHIPPED_FILE%"
del "%SHIPPED_FILE%" 2>nul
set "DONE_SCOPES=!DONE_SCOPES!.;"
if not exist "%~1" (
    echo [^^!] Source not found, skipping: %~1
    exit /b 0
)
call :install_file "%~1" "%CUR_HOME%\%~2" "%~2"
>>"%NEW_FILE%" echo %~2
exit /b 0

:manifest_end
:: Writes entries installed now, plus old entries of scopes this run skipped.
if "%DRY_RUN%"=="1" goto :me_dry
copy /y "%NEW_FILE%" "%NEW_FILE%.all" >nul
for /f "usebackq delims=" %%E in ("%OLD_FILE%") do call :keep_if_skipped "%%E"
if not exist "%CUR_HOME%\" mkdir "%CUR_HOME%"
>"%CUR_MANIFEST%" echo # Entries installed by just-works, relative to this directory. Do not add your own files.
sort "%NEW_FILE%.all" >> "%CUR_MANIFEST%"
del "%NEW_FILE%.all" 2>nul
goto :me_clean
:me_dry
echo [+] Would write manifest: %CUR_MANIFEST%
:me_clean
del "%NEW_FILE%" "%OLD_FILE%" 2>nul
exit /b 0

:keep_if_skipped
:: %~1 = old manifest entry
set "K_SCOPE=."
echo %~1 | findstr /c:"/" >nul && for /f "tokens=1* delims=/" %%A in ("%~1") do set "K_SCOPE=%%A"
if not "!DONE_SCOPES:;%K_SCOPE%;=!"=="!DONE_SCOPES!" exit /b 0
>>"%NEW_FILE%.all" echo %~1
exit /b 0

:stage_codex_skills
:: Codex skills = the Claude skills plus Codex-only extras from .codex\skills. Sets STAGE_DIR.
set "STAGE_DIR=%TEMP%\jw-skills-%RANDOM%"
if exist "%SCRIPT_DIR%.claude\skills\" xcopy "%SCRIPT_DIR%.claude\skills" "!STAGE_DIR!" /e /i /y /q /exclude:%EXCL_FILE% >nul
if exist "%SCRIPT_DIR%.codex\skills\" xcopy "%SCRIPT_DIR%.codex\skills" "!STAGE_DIR!" /e /i /y /q /exclude:%EXCL_FILE% >nul
exit /b 0

:migrate_rtk_hook
:: %~1 = settings.json path
:: Rewrites legacy rtk-rewrite.sh hook commands to "rtk hook claude" (rtk 0.37+ removed the script).
:: JW_PS exits 10 if a rewrite is needed (JW_MODE=apply also writes it), 0 if not, 1 on error.
:: JW_RE and JW_PS must not contain double quotes, exclamation marks or percent signs.
if not exist "%~1" exit /b 0
set "JW_SETTINGS=%~1"
set "JW_RE=(\x22command\x22\s*:\s*)\x22(?:[^\x22\\]|\\.)*rtk-rewrite\.sh(?:[^\x22\\]|\\.)*\x22"
set "JW_PS=try { $p = $env:JW_SETTINGS; $old = [IO.File]::ReadAllText($p); $new = [regex]::Replace($old, $env:JW_RE, '$1' + [char]34 + 'rtk hook claude' + [char]34); $rc = 0; if ($new -cne $old) { if ($env:JW_MODE -eq 'apply') { [IO.File]::WriteAllText($p, $new) }; $rc = 10 } } catch { $rc = 1 }; exit $rc"
set "JW_MODE=check"
powershell -NoProfile -ExecutionPolicy Bypass -Command "!JW_PS!"
set "JW_RC=!ERRORLEVEL!"
if "!JW_RC!"=="0" exit /b 0
if not "!JW_RC!"=="10" (
    echo [^^!] Could not migrate legacy rtk hook in !JW_SETTINGS! -- set its command to "rtk hook claude" manually
    exit /b 0
)
if "%DO_BACKUP%"=="1" call :backup_target "%~1"
if "%DRY_RUN%"=="1" (
    echo [+] Would migrate: legacy rtk hook -^> rtk hook claude in !JW_SETTINGS!
    exit /b 0
)
set "JW_MODE=apply"
powershell -NoProfile -ExecutionPolicy Bypass -Command "!JW_PS!"
if "!ERRORLEVEL!"=="10" (
    echo [+] Migrated: legacy rtk hook -^> rtk hook claude in !JW_SETTINGS!
) else (
    echo [^^!] Could not migrate legacy rtk hook in !JW_SETTINGS! -- set its command to "rtk hook claude" manually
)
exit /b 0

:usage
echo Usage: install.bat [OPTIONS]
echo.
echo Install just-works agents, skills, and settings globally.
echo.
echo Options:
echo   --personal      Use opinionated settings.json (permissions, hooks, sounds)
echo                   Default: minimal settings.json.default
echo   --azure         Use Azure OpenAI config instead of direct OpenAI API
echo   --skip-config      Skip installing settings/config files (still migrates a legacy rtk hook)
echo   --skip-statusline  Skip installing statusline-command.sh
echo   --skip-skills-claude  Skip installing Claude Code skills
echo   --skip-skills-codex   Skip installing Codex skills
echo   --claude-only   Install only Claude Code files
echo   --codex-only    Install only Codex files
echo   --dry-run       Show what would be installed without making changes
echo   --no-backup     Skip backup prompt, disable backups (for CI/non-interactive)
echo   -h, --help      Show this help message
echo.
echo Environment:
echo   CLAUDE_CONFIG_DIR  Claude Code config dir to install into ^(default %%USERPROFILE%%\.claude^)
echo   CODEX_HOME         Codex home to install into ^(default %%USERPROFILE%%\.codex^)
echo.
echo What gets installed:
echo   %%USERPROFILE%%\.claude\
echo     agents\       Agent definitions (python-code-writer, prompt-writer, ...)
echo     skills\       Coding and prompting standards
echo     output-styles\  Selectable output styles (compressed, ...)
echo     settings.json             Permission and hook configuration
echo     CLAUDE.md                 Global behavioral instructions
echo     web-chat-prompt.md        Instructions for claude.ai chat
echo     statusline-command.sh     Status line script ^(needs jq^)
echo.
echo   %%USERPROFILE%%\.codex\
echo     agents\       Custom agent definitions (python-code-writer, prompt-writer, ...)
echo     config.toml   Codex CLI configuration (--azure for Azure OpenAI)
echo     hooks.json    Lifecycle hooks (notification)
echo     AGENTS.md     Global behavioral instructions
echo.
echo   %%USERPROFILE%%\.agents\
echo     skills\       Coding and prompting standards (Codex discovery path)
echo.
echo Agents, skills and output styles are installed one entry at
echo a time. Other files in those directories are never touched. Each home keeps a
echo .just-works-manifest listing the entries it installed; entries that a later
echo version no longer ships are removed ^(after a backup, unless --no-backup^).
exit /b 0
