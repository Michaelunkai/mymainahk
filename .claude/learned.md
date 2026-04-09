
## 2026-04-09: AHK startup configuration

### Setup:
- **Method**: Registry `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` key `MyMainAHK`
- **Value**: `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "F:\study\Platforms\windows\autohotkey\mymainahk\current.ahk"`
- **No delay**: Registry Run fires immediately at logon
- **No duplicates**: `#SingleInstance Force` in script + only one startup entry
- **Tray icon**: Custom tray menu with Reload/Exit, tooltip "MyMainAHK"
- **Old disabled Task Scheduler entry `AHK_current`**: removed

### Lesson:
- Registry Run is simpler and more reliable than Task Scheduler for user-level startup
- Task Scheduler `Register-ScheduledTask` with `-RunLevel Limited` can fail with "parameter incorrect" on some Windows configs
- `#SingleInstance Force` + single startup entry = zero duplicate risk

## 2026-04-09: ppppp Paragon automation broken - venv Python PATH issue

### Root Cause:
- `ppppp` hotstring runs `paragon_complete.py` which needs `pyautogui` and `win32gui`
- The AHK script called bare `python` which resolved to `F:\backup\LocalAI\ollama\venv\Scripts\python.exe` (first in PATH)
- That venv has NO `pyautogui` or `win32gui` installed — only system Python (3.12) has them

### Fix:
1. Changed AHK to use explicit `C:\Users\micha\AppData\Local\Programs\Python\Python312\python.exe` instead of bare `python`
2. Added `ParagonPythonExe` global variable for the full path
3. Removed `"Hide"` flag from RunWait (pyautogui needs visible window context)

### LocalAI reorganization:
- Created `F:\study\AI_ML\LocalAI\` with README, launcher scripts, data pointers
- Updated `llocalai` AHK shortcut from `F:\backup\LocalAI` to `F:\study\AI_ML\LocalAI`
- Actual data (13GB models) stays at `F:\backup\LocalAI\ollama\`

### Lesson:
- Never use bare `python` in automation scripts — venvs in PATH can hijack the call
- Always use full path to the Python interpreter that has the required packages

## 2026-04-08: oll1-90 Full Rehaul

### Changes Made:
1. **All 90 oll functions now use `qwen3.5:latest`** - replaced qwen3:8b (oll21-30), qwen3:30b-a3b (oll69-82), qwen3-coder:latest (oll83-90)
2. **Added `--dangerously-skip-permissions`** to all 90 functions for full tool/PS/agentic access
3. **Added ollama serve dedup** - checks `Get-Process ollama` before starting, avoids duplicate serve processes
4. **Created `oll-scan` function** - run it to see a table of all 90 levels (context, GPU layers, overhead, parallel, KV cache, model)
5. **Fixed settings.json trailing comma** in UserPromptSubmit hooks array (invalid JSON causing hook errors)

### Root Causes Fixed:
- `deepseek-r1:32b does not support tools` → all models now qwen3.5:latest (tool-supporting)
- UserPromptSubmit hook error → trailing comma in JSON array removed
- Multiple ollama serve processes → dedup check added
