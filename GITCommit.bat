@echo off
setlocal EnableExtensions
title Shutdown (Auto-Commit - Verbose)

cd /d "%~dp0" || exit /b 1

echo ==========================================================
echo [0] Repo + tool sanity
echo ==========================================================
where git
if errorlevel 1 (
  echo ERROR: git not found in PATH.
  pause
  exit /b 1
)
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo ERROR: This folder is not a git repo.
  pause
  exit /b 1
)
echo OK: git repo detected
echo.

echo ==========================================================
echo [1] Current changes (before staging)
echo ==========================================================
git status
echo.
git status --porcelain
echo.

REM --- Timestamp via Python (escape %%) ---
for /f "usebackq delims=" %%T in (`python -c "from datetime import datetime; print(datetime.now().strftime('%%Y-%%m-%%d_%%H-%%M-%%S'))"`) do set "TS=%%T"
set "MSG=Auto-commit %TS%"

REM --- Commit message file inside .git (never tracked) ---
set "MSGFILE=%CD%\.git\COMMIT_MSG_TMP.txt"
> "%MSGFILE%" echo %MSG%

echo ==========================================================
echo [2] Commit message
echo ==========================================================
echo MSG    = "%MSG%"
echo MSGFILE= "%MSGFILE%"
type "%MSGFILE%"
echo.

echo ==========================================================
echo [3] Stage changes (git add .)
echo ==========================================================
git add .
set "AERR=%ERRORLEVEL%"
echo git add exit code: %AERR%
if not "%AERR%"=="0" (
  echo ERROR: git add failed.
  del "%MSGFILE%" >nul 2>&1
  pause
  exit /b %AERR%
)
echo.

echo --- Staged files ---
git diff --name-only --cached
echo.

REM If nothing staged, there is nothing to commit
git diff --cached --quiet
if %ERRORLEVEL%==0 (
  echo ==========================================================
  echo [4] Nothing staged - no commit needed
  echo ==========================================================
  del "%MSGFILE%" >nul 2>&1
  echo Done.
  pause
  exit /b 0
)

echo ==========================================================
echo [4] Commit
echo ==========================================================
git commit -F "%MSGFILE%"
set "CERR=%ERRORLEVEL%"
echo git commit exit code: %CERR%
if not "%CERR%"=="0" (
  echo ERROR: git commit failed. Common fixes:
  echo   git config --global user.name "Your Name"
  echo   git config --global user.email "you@example.com"
  echo.
  del "%MSGFILE%" >nul 2>&1
  pause
  exit /b %CERR%
)

echo.
echo ==========================================================
echo [5] Push
echo ==========================================================
git push
set "PERR=%ERRORLEVEL%"
echo git push exit code: %PERR%
del "%MSGFILE%" >nul 2>&1

if not "%PERR%"=="0" (
  echo ERROR: git push failed.
  pause
  exit /b %PERR%
)
echo.
echo Done.
pause
exit /b 0