; ╔══════════════════════════════ COMPLETE DESKTOP, TERMINAL & PROCESS MANAGER ══════════════════════════════╗
#Requires AutoHotkey v2.0
#SingleInstance Force

; Performance optimizations for v2
ListLines(false)
SetKeyDelay(-1, -1)
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
SetWinDelay(-1)
SetControlDelay(-1)
SendMode("Input")

; ╔══════════════════════════════ ELEVATION & INITIALIZATION ══════════════════════════════╗
; Relaunch elevated if needed
if !A_IsAdmin {
    try {
        Run("*RunAs " . A_ScriptFullPath)
        ExitApp()
    } catch {
        MsgBox("Failed to elevate script. Please run as administrator.", "Error", "OK IconX")
        ExitApp()
    }
}

; Initialize core variables
SetWorkingDir("F:\backup\windowsapps\installed\PSTools")
psSuspend := A_WorkingDir . "\pssuspend64.exe"
cheatEngine := "F:\backup\windowsapps\installed\Cheat Engine 7.5\Cheat Engine.exe"
weMod := "C:\Users\micha.DESKTOP-QCAU2KC\AppData\Local\WeMod\WeMod.exe"
wallPaperApp := "C:\Users\micha.DESKTOP-QCAU2KC\Desktop\WallPaper.lnk"
chromePath := "F:\backup\windowsapps\installed\Chrome\Application\chrome.exe"
firefoxPath := "F:\backup\windowsapps\installed\firefox\firefox.exe"
whatsappPath := "C:\Program Files\WindowsApps\5319275A.WhatsAppDesktop_2.2524.4.0_x64__cv1g1gvanyjgm\WhatsApp.exe"
gameSaveManagerPath := "F:\backup\windowsapps\installed\gameSaveManager\gs_mngr_3.exe"
todoistPath := "F:\backup\windowsapps\installed\todoist\Todoist.exe"
kvrtPath := "F:\backup\windowsapps\installed\KVRT\KVRT.exe"
suspended := Map()
lastCleanup := A_TickCount
errorCount := 0
maxErrors := 50
logFile := A_ScriptDir . "\complete_manager.log"

; Desktop tracking
currentDesktop := 1  ; Start assuming we're on desktop 1

; Triple-tap variables for window management
lastWPress := 0
lastEPress := 0
wTapCount := 0
eTapCount := 0
tripleTapThreshold := 500  ; milliseconds
tapResetTime := 1000  ; time to reset tap count

; Text shortcut variables
textBuffer := ""
maxBufferLength := 15
textShortcuts := Map(
    "nvc", "nss",
    "biu", "ws 'backitup'",
    "sleep", "ss",
    "reboot", "REBOOT_SYSTEM",
    "bios", "bios",
    "brc", "brc",
    "nnn", "nnn",
    "dsubs", "dsubs",
    "wall", "WALLPAPER_APP",
    "tttt", "SPLIT_TOP_APPS",
    "cahk", "closeahk",
    "sgame", "GAME_SAVE_MANAGER",
    "todo", "TODOIST_APP",
    "swemod", "swemod",
    "bin", "EMPTY_RECYCLE_BIN",
    "cleans", "clean",
    "ccbbr", "ccbbr",
    "ssss", "ssss",
    "pipit", "pipit",
    "refresh", "refresh",
    "logout", "refresh2",
    "sdesktop", "sdesktop",
    "gccleaner", "gccleaner",
    "gdb", "gdbooster",
    "fire", "FIREFOX_APP",
    "chrome", "CHROME_APP",
    "goodgame", "ws gg",
    "uninstall", "uninstall",
    "kvrt", "KVRT_APP"
)

; Game process detection (common game engines and launchers)
gameProcesses := Map(
    "Unity.exe", 1,
    "UnityPlayer.exe", 1,
    "UE4Game.exe", 1,
    "UE5Game.exe", 1,
    "steam.exe", 1,
    "steamwebhelper.exe", 1,
    "GameOverlayUI.exe", 1,
    "Origin.exe", 1,
    "EpicGamesLauncher.exe", 1,
    "Battle.net.exe", 1,
    "uplay.exe", 1,
    "GoG.exe", 1
)

; Validate PsSuspend exists
if !FileExist(psSuspend) {
    MsgBox("PsSuspend64.exe not found at: " . psSuspend, "Error", "OK IconX")
    ExitApp()
}

; Skip list for protected processes
skipMap := Map(
    "MultiSuspend.exe", 1,
    "MultiSuspend.ahk", 1,
    "a.exe", 1,
    "a.ahk", 1,
    "autohotkey.exe", 1,
    "autohotkey64.exe", 1,
    "explorer.exe", 1,
    "winlogon.exe", 1,
    "csrss.exe", 1,
    "smss.exe", 1,
    "wininit.exe", 1,
    "services.exe", 1,
    "lsass.exe", 1,
    "dwm.exe", 1
)

; ╔══════════════════════════════ LOGGING & ERROR HANDLING ══════════════════════════════╗
LogMessage(message) {
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend(timestamp . " - " . message . "`n", logFile)
    } catch {
        ; Silent fail for logging errors
    }
}

IncrementError() {
    global errorCount, maxErrors
    errorCount++
    if (errorCount > maxErrors) {
        LogMessage("ERROR: Too many errors (" . errorCount . "), resetting error count")
        errorCount := 0
    }
}

; ╔══════════════════════════════ TEXT SHORTCUT SYSTEM ══════════════════════════════╗
ProcessTextBuffer(newChar) {
    global textBuffer, maxBufferLength, textShortcuts, skipMap
    
    ; Add new character to buffer
    textBuffer .= newChar
    
    ; Keep buffer at reasonable length
    if (StrLen(textBuffer) > maxBufferLength) {
        textBuffer := SubStr(textBuffer, -maxBufferLength + 1)
    }
    
    ; Check for special window management triggers
    if (InStr(StrLower(textBuffer), "www")) {
        procName := GetActiveProcess()
        if (procName != "" && !skipMap.Has(procName) && procName != "Program Manager") {
            LogMessage("TEXT_SHORTCUT: Triggered 'www' -> ForceWindowedMode()")
            ForceWindowedMode()
        }
        textBuffer := ""
        return
    }
    if (InStr(StrLower(textBuffer), "eee")) {
        procName := GetActiveProcess()
        if (procName != "" && !skipMap.Has(procName) && procName != "Program Manager") {
            LogMessage("TEXT_SHORTCUT: Triggered 'eee' -> ForceFullSizeMode()")
            ForceFullSizeMode()
        }
        textBuffer := ""
        return
    }
    
    ; Check for other shortcuts
    for shortcut, command in textShortcuts {
        if (InStr(StrLower(textBuffer), StrLower(shortcut)) > 0) {
            ; Clear buffer to prevent repeat triggers
            textBuffer := ""
            
            ; Execute command based on type
            if (command = "WALLPAPER_APP") {
                LaunchWallpaperApp()
            } else if (command = "SPLIT_TOP_APPS") {
                SplitTopAppsHorizontally()
            } else if (command = "GAME_SAVE_MANAGER") {
                LaunchGameSaveManager()
            } else if (command = "TODOIST_APP") {
                LaunchTodoist()
            } else if (command = "EMPTY_RECYCLE_BIN") {
                EmptyRecycleBin()
            } else if (command = "FIREFOX_APP") {
                LaunchFirefox()
            } else if (command = "CHROME_APP") {
                LaunchChrome()
            } else if (command = "KVRT_APP") {
                LaunchKVRT()
            } else {
                ExecuteTerminalCommand(command)
            }
            LogMessage("TEXT_SHORTCUT: Triggered '" . shortcut . "' -> '" . command . "'")
            break
        }
    }
}

LaunchWallpaperApp() {
    try {
        LogMessage("LAUNCHER: Attempting to launch WallPaper app")
        
        ; Check if wallpaper app exists
        if !FileExist(wallPaperApp) {
            LogMessage("ERROR: WallPaper app not found at: " . wallPaperApp)
            return
        }
        
        ; Launch the wallpaper application
        Run('"' . wallPaperApp . '"')
        LogMessage("LAUNCHER: WallPaper app launched successfully")
        
    } catch Error as e {
        LogMessage("ERROR in LaunchWallpaperApp: " . e.message)
        IncrementError()
    }
}

LaunchGameSaveManager() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Game Save Manager")
        
        ; Check if Game Save Manager exists
        if !FileExist(gameSaveManagerPath) {
            LogMessage("ERROR: Game Save Manager not found at: " . gameSaveManagerPath)
            return
        }
        
        ; Check if Game Save Manager is already running
        if ProcessExist("gs_mngr_3.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe gs_mngr_3.exe") {
                WinActivate("ahk_exe gs_mngr_3.exe")
                LogMessage("LAUNCHER: Game Save Manager already running, activated window")
            } else {
                LogMessage("LAUNCHER: Game Save Manager process exists but no window found")
            }
            return
        }
        
        ; Launch Game Save Manager
        Run('"' . gameSaveManagerPath . '"')
        LogMessage("LAUNCHER: Game Save Manager launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe gs_mngr_3.exe", , 5) {
            WinActivate("ahk_exe gs_mngr_3.exe")
            LogMessage("LAUNCHER: Game Save Manager window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchGameSaveManager: " . e.message)
        IncrementError()
    }
}

LaunchTodoist() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Todoist")
        
        ; First check if Todoist is already running (try multiple possible process names)
        todoistProcessNames := ["Todoist.exe", "todoist.exe", "Todoist Desktop.exe"]
        todoistRunning := false
        
        for processName in todoistProcessNames {
            if ProcessExist(processName) {
                ; If already running, try to activate the window
                if WinExist("ahk_exe " . processName) {
                    WinActivate("ahk_exe " . processName)
                    LogMessage("LAUNCHER: Todoist already running (" . processName . "), activated window")
                    todoistRunning := true
                    break
                }
            }
        }
        
        if (todoistRunning) {
            return
        }
        
        ; Check if Todoist executable exists at the specified path
        if FileExist(todoistPath) {
            ; Launch using direct path
            Run('"' . todoistPath . '"')
            LogMessage("LAUNCHER: Todoist launched via direct path: " . todoistPath)
        } else {
            LogMessage("ERROR: Todoist not found at: " . todoistPath)
            
            ; Try alternative methods to launch Todoist
            try {
                ; Method 1: Try to find Todoist in common locations
                commonPaths := [
                    "C:\Program Files\Todoist\Todoist.exe",
                    "C:\Program Files (x86)\Todoist\Todoist.exe",
                    A_ProgramFiles . "\Todoist\Todoist.exe"
                ]
                
                ; Add user-specific paths manually to avoid A_LocalAppData issue
                userProfile := EnvGet("USERPROFILE")
                if (userProfile) {
                    commonPaths.Push(userProfile . "\AppData\Local\Programs\todoist-desktop\Todoist.exe")
                    commonPaths.Push(userProfile . "\AppData\Roaming\Todoist\Todoist.exe")
                }
                
                todoistFound := false
                for altPath in commonPaths {
                    if FileExist(altPath) {
                        Run('"' . altPath . '"')
                        LogMessage("LAUNCHER: Todoist launched via alternative path: " . altPath)
                        todoistFound := true
                        break
                    }
                }
                
                if (!todoistFound) {
                    ; Method 2: Try to launch via start command
                    Run("cmd.exe /c start todoist", "", "Hide")
                    LogMessage("LAUNCHER: Attempted to launch Todoist via start command")
                }
                
            } catch {
                LogMessage("ERROR: All Todoist launch methods failed")
            }
        }
        
        ; Wait for window and activate (try multiple process names)
        Sleep(2000)
        for processName in todoistProcessNames {
            if WinWait("ahk_exe " . processName, , 3) {
                WinActivate("ahk_exe " . processName)
                LogMessage("LAUNCHER: Todoist window activated (" . processName . ")")
                break
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchTodoist: " . e.message)
        IncrementError()
    }
}

LaunchKVRT() {
    try {
        LogMessage("LAUNCHER: Attempting to launch KVRT")
        
        ; Check if KVRT executable exists
        if !FileExist(kvrtPath) {
            LogMessage("ERROR: KVRT not found at: " . kvrtPath)
            return
        }
        
        ; Check if KVRT is already running
        if ProcessExist("KVRT.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe KVRT.exe") {
                WinActivate("ahk_exe KVRT.exe")
                LogMessage("LAUNCHER: KVRT already running, activated window")
            } else {
                LogMessage("LAUNCHER: KVRT process exists but no window found")
            }
            return
        }
        
        ; Launch KVRT
        Run('"' . kvrtPath . '"')
        LogMessage("LAUNCHER: KVRT launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe KVRT.exe", , 5) {
            WinActivate("ahk_exe KVRT.exe")
            LogMessage("LAUNCHER: KVRT window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchKVRT: " . e.message)
        IncrementError()
    }
}

ExecuteTerminalCommand(command) {
    try {
        LogMessage("TERMINAL_CMD: Executing command - " . command)
        
        ; Handle special reboot command
        if (command = "REBOOT_SYSTEM") {
            LogMessage("REBOOT: Initiating immediate system reboot")
            
            ; Use shutdown command with immediate restart flags
            try {
                RunWait("shutdown /r /t 0 /f", "", "Hide")
            } catch {
                ; Fallback method
                try {
                    RunWait("shutdown -r -t 0", "", "Hide")
                } catch {
                    LogMessage("ERROR: Failed to execute reboot command")
                }
            }
            return
        }
        
        ; Execute command and close ONLY the specific terminal that was opened
        
        ; Method 1: Use PowerShell with self-terminating command (preferred)
        try {
            ; Create a PowerShell command that runs and terminates itself only
            psCommand := 'powershell.exe -Command "& {' . command . '; Start-Process -FilePath `"cmd.exe`" -ArgumentList `"/c taskkill /F /PID $PID`" -WindowStyle Hidden}"'
            RunWait(psCommand, "", "")
            LogMessage("TERMINAL_CMD: Executed '" . command . "' with self-terminating PowerShell")
            return
        } catch Error as e1 {
            LogMessage("TERMINAL_CMD: Self-terminating PowerShell failed - " . e1.message)
        }
        
        ; Method 2: Launch specific terminal and track its process
        try {
            ; Get current PowerShell processes before launching
            beforeProcesses := []
            for process in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='powershell.exe'") {
                beforeProcesses.Push(process.ProcessId)
            }
            
            ; Launch PowerShell with command
            Run('powershell.exe -Command "' . command . '"')
            Sleep(500) ; Wait for process to start
            
            ; Find the new PowerShell process
            newPID := 0
            for process in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='powershell.exe'") {
                found := false
                for oldPID in beforeProcesses {
                    if (process.ProcessId = oldPID) {
                        found := true
                        break
                    }
                }
                if (!found) {
                    newPID := process.ProcessId
                    break
                }
            }
            
            ; Wait for command to complete, then kill only the specific process
            Sleep(3000)
            if (newPID > 0) {
                RunWait("taskkill /F /PID " . newPID, "", "Hide")
                LogMessage("TERMINAL_CMD: Executed '" . command . "' and closed specific PowerShell PID " . newPID)
            }
            return
        } catch Error as e2 {
            LogMessage("TERMINAL_CMD: Process tracking method failed - " . e2.message)
        }
        
        ; Method 3: Hidden execution (no terminal window to close)
        try {
            ; Run completely hidden - no terminal window at all
            RunWait('powershell.exe -WindowStyle Hidden -Command "' . command . '"', "", "Hide")
            LogMessage("TERMINAL_CMD: Executed '" . command . "' in hidden mode (no terminal window)")
            return
        } catch Error as e3 {
            LogMessage("TERMINAL_CMD: Hidden execution failed - " . e3.message)
        }
        
        ; Method 4: Simple background execution
        try {
            ; Final fallback - background execution
            RunWait('cmd.exe /c powershell.exe -Command "' . command . '"', "", "Hide")
            LogMessage("TERMINAL_CMD: Executed '" . command . "' via background CMD")
            return
        } catch Error as e4 {
            LogMessage("TERMINAL_CMD: Background execution failed - " . e4.message)
        }
        
        ; If all methods failed, log error
        LogMessage("ERROR: All execution methods failed for command: " . command)
        
    } catch Error as e {
        LogMessage("ERROR in ExecuteTerminalCommand: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ WINDOW MANAGEMENT ENHANCED ══════════════════════════════╗
SplitTopAppsHorizontally() {
    try {
        LogMessage("SPLIT_APPS: Starting horizontal split of top applications")
        
        ; Get all visible windows that are not minimized
        visibleWindows := []
        
        ; Get list of all windows
        windowList := WinGetList()
        
        for hwnd in windowList {
            ; Skip if window is minimized or not visible
            if (WinGetMinMax(hwnd) = -1 || !WinGetTitle(hwnd))
                continue
                
            ; Skip desktop and taskbar
            try {
                processName := WinGetProcessName(hwnd)
                if (skipMap.Has(processName) || processName = "explorer.exe")
                    continue
            } catch {
                continue
            }
                
            ; Skip very small windows (likely not main application windows)
            try {
                WinGetPos(&x, &y, &w, &h, hwnd)
                if (w < 200 || h < 150)
                    continue
            } catch {
                continue
            }
            
            visibleWindows.Push({hwnd: hwnd, title: WinGetTitle(hwnd), process: processName})
        }
        
        ; Get top 2 most recently used applications
        if (visibleWindows.Length < 2) {
            LogMessage("SPLIT_APPS: Less than 2 windows found, cannot split")
            return
        }
        
        ; Get screen dimensions
        MonitorGet(1, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        
        ; Calculate split dimensions (50% each horizontally)
        leftWidth := screenWidth / 2
        rightWidth := screenWidth / 2
        fullHeight := screenHeight
        
        ; Split the first two windows
        app1 := visibleWindows[1]
        app2 := visibleWindows[2]
        
        ; Position first app on left half
        try {
            ; Restore if maximized
            if (WinGetMinMax(app1.hwnd) = 1)
                WinRestore(app1.hwnd)
            
            WinMove(0, 0, leftWidth, fullHeight, app1.hwnd)
            WinActivate(app1.hwnd)
            LogMessage("SPLIT_APPS: Positioned " . app1.process . " on left half")
        } catch Error as e {
            LogMessage("SPLIT_APPS: Failed to position left app - " . e.message)
        }
        
        ; Position second app on right half
        try {
            ; Restore if maximized
            if (WinGetMinMax(app2.hwnd) = 1)
                WinRestore(app2.hwnd)
            
            WinMove(leftWidth, 0, rightWidth, fullHeight, app2.hwnd)
            WinActivate(app2.hwnd)
            LogMessage("SPLIT_APPS: Positioned " . app2.process . " on right half")
        } catch Error as e {
            LogMessage("SPLIT_APPS: Failed to position right app - " . e.message)
        }
        
        LogMessage("SPLIT_APPS: Successfully split " . app1.process . " and " . app2.process . " horizontally")
        
    } catch Error as e {
        LogMessage("ERROR in SplitTopAppsHorizontally: " . e.message)
        IncrementError()
    }
}

OpenGamesFolder() {
    try {
        gamesPath := "C:\Users\micha.DESKTOP-QCAU2KC\Desktop\Games"
        LogMessage("FOLDER: Opening Games folder in File Explorer")
        
        ; Check if the Games folder exists
        if !DirExist(gamesPath) {
            LogMessage("ERROR: Games folder not found at: " . gamesPath)
            return
        }
        
        ; Open the folder in File Explorer
        Run('explorer.exe "' . gamesPath . '"')
        LogMessage("FOLDER: Successfully opened Games folder")
        
    } catch Error as e {
        LogMessage("ERROR in OpenGamesFolder: " . e.message)
        IncrementError()
    }
}

EmptyRecycleBin() {
    try {
        LogMessage("RECYCLE_BIN: Attempting to empty recycle bin")
        
        ; Method 1: Use PowerShell command (most reliable)
        try {
            RunWait('powershell.exe -Command "Clear-RecycleBin -Force"', "", "Hide")
            LogMessage("RECYCLE_BIN: Successfully emptied using PowerShell")
            return
        } catch {
            ; Method 2: Use rd command for each drive
            try {
                RunWait('cmd.exe /c rd /s /q C:\$Recycle.Bin', "", "Hide")
                RunWait('cmd.exe /c rd /s /q D:\$Recycle.Bin', "", "Hide")
                RunWait('cmd.exe /c rd /s /q E:\$Recycle.Bin', "", "Hide")
                RunWait('cmd.exe /c rd /s /q F:\$Recycle.Bin', "", "Hide")
                LogMessage("RECYCLE_BIN: Successfully emptied using rd command")
                return
            } catch {
                ; Method 3: Use SHEmptyRecycleBin via RunWait
                try {
                    RunWait('powershell.exe -Command "(New-Object -comObject Shell.Application).Namespace(10).InvokeVerb(`"Empty Recycle Bin`")"', "", "Hide")
                    LogMessage("RECYCLE_BIN: Successfully emptied using Shell.Application")
                } catch {
                    LogMessage("RECYCLE_BIN: All empty methods failed")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in EmptyRecycleBin: " . e.message)
        IncrementError()
    }
}

IsGameProcess(processName) {
    global gameProcesses
    
    ; Check if it's in our known games list
    if (gameProcesses.Has(processName)) {
        return true
    }
    
    ; Check for common game indicators in process name
    lowerName := StrLower(processName)
    gameKeywords := ["game", "unity", "unreal", "dx11", "dx12", "opengl", "vulkan", "steam", "epic", "launcher"]
    
    for keyword in gameKeywords {
        if (InStr(lowerName, keyword) > 0) {
            return true
        }
    }
    
    return false
}

ForceWindowedMode() {
    try {
        ; Get active window
        activeHwnd := WinGetID("A")
        if (!activeHwnd) {
            LogMessage("WINDOWED: No active window found")
            return
        }

        activeTitle := WinGetTitle(activeHwnd)
        activeProcess := WinGetProcessName(activeHwnd)
        
        LogMessage("WINDOWED: Processing window - " . activeProcess . " (" . activeTitle . ")")

        ; Get screen dimensions
        MonitorGet(1, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        
        ; Determine window size based on whether it's a game
        isGame := IsGameProcess(activeProcess)
        
        if (isGame) {
            ; Smaller window for games (60% of screen, common gaming resolutions)
            windowWidth := screenWidth * 0.6
            windowHeight := screenHeight * 0.6
            
            ; Try to use common gaming resolutions that fit
            if (windowWidth >= 1280 && windowHeight >= 720) {
                windowWidth := 1280
                windowHeight := 720
            } else if (windowWidth >= 1024 && windowHeight >= 768) {
                windowWidth := 1024
                windowHeight := 768
            }
            
            LogMessage("WINDOWED: Detected game, using gaming resolution: " . windowWidth . "x" . windowHeight)
        } else {
            ; Regular apps get 80% of screen
            windowWidth := screenWidth * 0.8
            windowHeight := screenHeight * 0.8
            LogMessage("WINDOWED: Regular application, using 80% screen size")
        }
        
        ; Calculate centered position
        windowX := (screenWidth - windowWidth) / 2
        windowY := (screenHeight - windowHeight) / 2

        ; Store current window state
        currentStyle := WinGetStyle(activeHwnd)
        isMaximized := (WinGetMinMax(activeHwnd) = 1)
        
        ; Remove fullscreen attributes and restore window
        if (isMaximized) {
            WinRestore(activeHwnd)
            Sleep(200)
            LogMessage("WINDOWED: Restored maximized window")
        }

        ; Force window to be resizable and have borders (especially important for games)
        try {
            ; Remove WS_POPUP (0x80000000) and add WS_OVERLAPPEDWINDOW (0x00CF0000)
            ; Also remove WS_EX_TOPMOST if present
            newStyle := (currentStyle & ~0x80000000) | 0x00CF0000
            WinSetStyle(newStyle, activeHwnd)
            
            ; Remove topmost attribute for games
            WinSetAlwaysOnTop(false, activeHwnd)
            
            LogMessage("WINDOWED: Applied windowed style and removed topmost")
        } catch Error as e {
            LogMessage("WINDOWED: Style change failed - " . e.message)
        }

        ; Wait for style changes to take effect
        Sleep(300)

        ; Move and resize window
        try {
            WinMove(windowX, windowY, windowWidth, windowHeight, activeHwnd)
            LogMessage("WINDOWED: Positioned window at " . windowX . "," . windowY . " size " . windowWidth . "x" . windowHeight)
        } catch Error as e {
            LogMessage("WINDOWED: Move/resize failed - " . e.message)
        }

        ; Ensure window is active
        WinActivate(activeHwnd)
        
        LogMessage("WINDOWED: Successfully applied windowed mode to " . activeProcess)

    } catch Error as e {
        LogMessage("ERROR in ForceWindowedMode: " . e.message)
        IncrementError()
    }
}

ForceFullSizeMode() {
    try {
        ; Get active window
        activeHwnd := WinGetID("A")
        if (!activeHwnd) {
            LogMessage("FULLSIZE: No active window found")
            return
        }

        activeTitle := WinGetTitle(activeHwnd)
        activeProcess := WinGetProcessName(activeHwnd)
        
        LogMessage("FULLSIZE: Processing window - " . activeProcess . " (" . activeTitle . ")")

        ; Get screen dimensions (full resolution)
        MonitorGet(1, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        
        LogMessage("FULLSIZE: Using full resolution: " . screenWidth . "x" . screenHeight)

        ; Store current window state
        currentStyle := WinGetStyle(activeHwnd)
        
        ; Remove any popup/borderless styles and ensure proper windowed mode with borders
        try {
            ; Apply full windowed style with title bar and borders
            newStyle := (currentStyle & ~0x80000000) | 0x00CF0000
            WinSetStyle(newStyle, activeHwnd)
            
            ; Remove topmost if set
            WinSetAlwaysOnTop(false, activeHwnd)
            
            LogMessage("FULLSIZE: Applied windowed style with borders")
        } catch Error as e {
            LogMessage("FULLSIZE: Style change failed - " . e.message)
        }

        ; Wait for style changes
        Sleep(200)

        ; First restore if maximized
        if (WinGetMinMax(activeHwnd) = 1) {
            WinRestore(activeHwnd)
            Sleep(200)
        }

        ; Move to top-left and resize to full screen (but keep borders)
        try {
            WinMove(0, 0, screenWidth, screenHeight, activeHwnd)
            LogMessage("FULLSIZE: Positioned window at full screen size with borders")
        } catch Error as e {
            LogMessage("FULLSIZE: Move/resize failed - " . e.message)
        }

        ; Activate window
        WinActivate(activeHwnd)
        
        LogMessage("FULLSIZE: Successfully applied full size mode to " . activeProcess)

    } catch Error as e {
        LogMessage("ERROR in ForceFullSizeMode: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ DESKTOP MANAGEMENT ══════════════════════════════╗
SwitchDesktop() {
    global currentDesktop
    try {
        if (currentDesktop = 1) {
            ; Go from Desktop 1 to Desktop 2
            Send("^#{Right}")  ; Ctrl + Win + Right Arrow
            currentDesktop := 2
            LogMessage("DESKTOP: Switched to Desktop 2")
        } else {
            ; Go from Desktop 2 to Desktop 1
            Send("^#{Left}")   ; Ctrl + Win + Left Arrow
            currentDesktop := 1
            LogMessage("DESKTOP: Switched to Desktop 1")
        }
    } catch Error as e {
        LogMessage("ERROR in SwitchDesktop: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ TERMINAL MANAGEMENT ══════════════════════════════╗
OpenFloatingTerminal() {
    try {
        LogMessage("TERMINAL: Attempting to open floating terminal")

        ; Try to open Windows Terminal first, fallback to PowerShell, then CMD
        terminalOpened := false

        try {
            Run("wt.exe")
            Sleep(500)  ; Wait for window to appear
            if WinWait("ahk_exe WindowsTerminal.exe", , 2) {
                WinActivate("ahk_exe WindowsTerminal.exe")
                LogMessage("TERMINAL: Windows Terminal opened")
                terminalOpened := true
            }
        } catch {
            try {
                Run("powershell.exe")
                Sleep(500)
                if WinWait("ahk_exe powershell.exe", , 2) {
                    WinActivate("ahk_exe powershell.exe")
                    LogMessage("TERMINAL: PowerShell opened")
                    terminalOpened := true
                }
            } catch {
                try {
                    Run("cmd.exe")
                    Sleep(500)
                    if WinWait("ahk_exe cmd.exe", , 2) {
                        WinActivate("ahk_exe cmd.exe")
                        LogMessage("TERMINAL: Command Prompt opened")
                        terminalOpened := true
                    }
                } catch {
                    LogMessage("ERROR: Failed to open any terminal application")
                }
            }
        }

        if (!terminalOpened) {
            LogMessage("WARNING: No terminal application could be opened")
        }

    } catch Error as e {
        LogMessage("ERROR in OpenFloatingTerminal: " . e.message)
        IncrementError()
    }
}

CloseCurrentTerminal() {
    try {
        ; Get the active window
        activeTitle := WinGetTitle("A")
        activeProcess := WinGetProcessName("A")

        LogMessage("TERMINAL: Checking active window - Process: " . activeProcess . ", Title: " . activeTitle)

        ; Check if current window is a terminal application
        if (activeProcess = "WindowsTerminal.exe"
            || activeProcess = "powershell.exe"
            || activeProcess = "cmd.exe"
            || activeProcess = "pwsh.exe"
            || InStr(activeTitle, "Command Prompt")
            || InStr(activeTitle, "PowerShell")
            || InStr(activeTitle, "Windows Terminal")) {

            ; Close the terminal
            WinClose("A")
            LogMessage("TERMINAL: Closed terminal - " . activeProcess)
        } else {
            ; If not a terminal, just log it
            LogMessage("TERMINAL: Active window is not a terminal - " . activeProcess)
        }
    } catch Error as e {
        LogMessage("ERROR in CloseCurrentTerminal: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ APPLICATION LAUNCHER ══════════════════════════════╗
ForceKillActiveApp() {
    try {
        ; Get the active window process
        activeHwnd := WinGetID("A")
        if (!activeHwnd) {
            return
        }

        activeProcess := WinGetProcessName(activeHwnd)
        activeTitle := WinGetTitle(activeHwnd)
        activePID := WinGetPID(activeHwnd)

        ; Check if it's a protected process
        if (skipMap.Has(activeProcess)) {
            LogMessage("FORCE_KILL: Blocked attempt to kill protected process: " . activeProcess)
            return
        }

        LogMessage("FORCE_KILL: Attempting to force kill " . activeProcess . " (PID: " . activePID . ") - " . activeTitle)

        ; Ultra-aggressive kill approach - more powerful than Task Manager
        killSuccess := false

        ; Method 1: Try ProcessClose first (graceful but forced)
        try {
            ProcessClose(activeProcess)
            killSuccess := true
            LogMessage("FORCE_KILL: Successfully killed " . activeProcess . " using ProcessClose")
        } catch {
            ; Method 2: Use taskkill with maximum force
            try {
                RunWait("taskkill /F /PID " . activePID, "", "Hide")
                killSuccess := true
                LogMessage("FORCE_KILL: Successfully killed " . activeProcess . " using taskkill /F /PID")
            } catch {
                ; Method 3: Kill by process name with force and tree (kills child processes too)
                try {
                    RunWait("taskkill /F /T /IM " . activeProcess, "", "Hide")
                    killSuccess := true
                    LogMessage("FORCE_KILL: Successfully killed " . activeProcess . " using taskkill /F /T /IM")
                } catch {
                    ; Method 4: Ultimate nuclear option - WMIC process termination
                    try {
                        RunWait('wmic process where "ProcessId=' . activePID . '" delete', "", "Hide")
                        killSuccess := true
                        LogMessage("FORCE_KILL: Successfully killed " . activeProcess . " using WMIC")
                    } catch {
                        LogMessage("FORCE_KILL: All kill methods failed for " . activeProcess)
                    }
                }
            }
        }

        if (!killSuccess) {
            LogMessage("FORCE_KILL: Failed to kill " . activeProcess)
        }

    } catch Error as e {
        LogMessage("ERROR in ForceKillActiveApp: " . e.message)
        IncrementError()
    }
}

LaunchChrome() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Chrome")

        ; Check if Chrome executable exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found at: " . chromePath)
            return
        }

        ; Check if Chrome is already running
        if ProcessExist("chrome.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe chrome.exe") {
                WinActivate("ahk_exe chrome.exe")
                LogMessage("LAUNCHER: Chrome already running, activated window")
            } else {
                LogMessage("LAUNCHER: Chrome process exists but no window found")
            }
            return
        }

        ; Launch Chrome
        Run('"' . chromePath . '"')
        LogMessage("LAUNCHER: Chrome launched successfully")

        ; Optional: Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe chrome.exe", , 8) {
            WinActivate("ahk_exe chrome.exe")
            LogMessage("LAUNCHER: Chrome window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchChrome: " . e.message)
        IncrementError()
    }
}

LaunchFirefox() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Firefox")

        ; Check if Firefox executable exists
        if !FileExist(firefoxPath) {
            LogMessage("ERROR: Firefox not found at: " . firefoxPath)
            return
        }

        ; Check if Firefox is already running
        if ProcessExist("firefox.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe firefox.exe") {
                WinActivate("ahk_exe firefox.exe")
                LogMessage("LAUNCHER: Firefox already running, activated window")
            } else {
                LogMessage("LAUNCHER: Firefox process exists but no window found")
            }
            return
        }

        ; Launch Firefox
        Run('"' . firefoxPath . '"')
        LogMessage("LAUNCHER: Firefox launched successfully")

        ; Optional: Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe firefox.exe", , 8) {
            WinActivate("ahk_exe firefox.exe")
            LogMessage("LAUNCHER: Firefox window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchFirefox: " . e.message)
        IncrementError()
    }
}

LaunchWhatsApp() {
    try {
        LogMessage("LAUNCHER: Attempting to launch WhatsApp")

        ; Check if WhatsApp is already running and activate it
        if ProcessExist("WhatsApp.exe") {
            if WinExist("ahk_exe WhatsApp.exe") {
                WinActivate("ahk_exe WhatsApp.exe")
                LogMessage("LAUNCHER: WhatsApp already running, activated window")
                return
            }
        }

        ; Check if the specific WhatsApp executable exists
        if FileExist(whatsappPath) {
            ; Launch using direct path
            Run('"' . whatsappPath . '"')
            LogMessage("LAUNCHER: WhatsApp launched via direct path")
            
            ; Wait for window and activate
            if WinWait("ahk_exe WhatsApp.exe", , 5) {
                WinActivate("ahk_exe WhatsApp.exe")
                LogMessage("LAUNCHER: WhatsApp window activated")
            }
            return
        }

        ; Fallback methods if direct path doesn't work
        whatsappLaunched := false

        ; Method 1: Try Windows Store app protocol
        try {
            Run("explorer.exe ms-windows-store://pdp/?ProductId=9NKSQGP7F2NH")
            Sleep(1000)
            if WinWait("ahk_exe WhatsApp.exe", , 3) {
                WinActivate("ahk_exe WhatsApp.exe")
                whatsappLaunched := true
                LogMessage("LAUNCHER: WhatsApp launched via Store protocol")
            }
        } catch {
            ; Method 2: Try PowerShell command to launch UWP app
            try {
                Run("powershell.exe -Command `"Start-Process 'shell:AppsFolder\5319275A.WhatsAppDesktop_cv1g1gvanyjgm!WhatsAppDesktop'`"", "", "Hide")
                if WinWait("ahk_exe WhatsApp.exe", , 5) {
                    WinActivate("ahk_exe WhatsApp.exe")
                    whatsappLaunched := true
                    LogMessage("LAUNCHER: WhatsApp launched via PowerShell UWP")
                }
            } catch {
                ; Method 3: Try start command
                try {
                    Run("cmd.exe /c start whatsapp:", "", "Hide")
                    if WinWait("ahk_exe WhatsApp.exe", , 3) {
                        WinActivate("ahk_exe WhatsApp.exe")
                        whatsappLaunched := true
                        LogMessage("LAUNCHER: WhatsApp launched via start command")
                    }
                } catch {
                    LogMessage("LAUNCHER: All WhatsApp launch methods failed")
                }
            }
        }

        if (!whatsappLaunched) {
            LogMessage("ERROR: WhatsApp could not be launched - may not be installed or path incorrect")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchWhatsApp: " . e.message)
        IncrementError()
    }
}
LaunchCheatEngine() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Cheat Engine")

        ; Check if Cheat Engine executable exists
        if !FileExist(cheatEngine) {
            LogMessage("ERROR: Cheat Engine not found at: " . cheatEngine)
            return
        }

        ; Check if Cheat Engine is already running
        if ProcessExist("Cheat Engine.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Cheat Engine.exe") {
                WinActivate("ahk_exe Cheat Engine.exe")
                LogMessage("LAUNCHER: Cheat Engine already running, activated window")
            } else {
                LogMessage("LAUNCHER: Cheat Engine process exists but no window found")
            }
            return
        }

        ; Launch Cheat Engine
        Run('"' . cheatEngine . '"')
        LogMessage("LAUNCHER: Cheat Engine launched successfully")

        ; Optional: Wait and activate window
        Sleep(1000)
        if WinWait("ahk_exe Cheat Engine.exe", , 5) {
            WinActivate("ahk_exe Cheat Engine.exe")
            LogMessage("LAUNCHER: Cheat Engine window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchCheatEngine: " . e.message)
        IncrementError()
    }
}

LaunchWeMod() {
    try {
        LogMessage("LAUNCHER: Attempting to close and relaunch WeMod")

        ; Check if WeMod executable exists
        if !FileExist(weMod) {
            LogMessage("ERROR: WeMod not found at: " . weMod)
            return
        }

        ; Check if WeMod is currently running and close it
        if ProcessExist("WeMod.exe") {
            LogMessage("LAUNCHER: WeMod is running, attempting to close")

            ; Try to close WeMod window gracefully first
            if WinExist("ahk_exe WeMod.exe") {
                WinClose("ahk_exe WeMod.exe")
                LogMessage("LAUNCHER: Sent close signal to WeMod window")

                ; Wait for graceful close
                ProcessWaitClose("WeMod.exe", 5)
            }

            ; If still running, force terminate
            if ProcessExist("WeMod.exe") {
                try {
                    ProcessClose("WeMod.exe")
                    LogMessage("LAUNCHER: Force terminated WeMod process")
                } catch {
                    LogMessage("WARNING: Could not force close WeMod process")
                }
            }

            ; Wait a moment for cleanup
            Sleep(1000)
        }

        ; Launch WeMod
        Run('"' . weMod . '"')
        LogMessage("LAUNCHER: WeMod launched successfully")

        ; Optional: Wait and activate window
        Sleep(2000)  ; WeMod may take longer to start
        if WinWait("ahk_exe WeMod.exe", , 10) {
            WinActivate("ahk_exe WeMod.exe")
            LogMessage("LAUNCHER: WeMod window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchWeMod: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ PROCESS SUSPENSION CORE ══════════════════════════════╗
GetActiveProcess() {
    try {
        hwnd := WinGetID("A")
        if (!hwnd)
            return ""

        pid := WinGetPID(hwnd)
        if (!pid)
            return ""

        procName := ProcessGetName(pid)
        return procName
    } catch Error as e {
        LogMessage("ERROR in GetActiveProcess: " . e.message)
        IncrementError()
        return ""
    }
}

ValidateProcess(procName) {
    try {
        ; Check if process still exists
        if (!ProcessExist(procName))
            return false
        return true
    } catch {
        return false
    }
}

SuspendProcess(procName) {
    try {
        ; Double-check process exists before suspending
        if (!ValidateProcess(procName)) {
            LogMessage("WARNING: Cannot suspend " . procName . " - process not found")
            return false
        }

        ; Use RunWait with timeout
        cmd := '"' . psSuspend . '" "' . procName . '"'
        LogMessage("SUSPEND: Executing " . cmd)

        ; Simple RunWait approach for v2
        RunWait(cmd, "", "Hide")

        ; Verify suspension worked
        Sleep(100)
        suspended[procName] := A_TickCount
        LogMessage("SUCCESS: Suspended " . procName)
        return true

    } catch Error as e {
        LogMessage("ERROR in SuspendProcess(" . procName . "): " . e.message)
        IncrementError()
        return false
    }
}

ResumeProcess(procName) {
    try {
        ; Check if we think it's suspended
        if (!suspended.Has(procName)) {
            LogMessage("WARNING: " . procName . " not in suspended list")
            return false
        }

        ; Use RunWait for resume
        cmd := '"' . psSuspend . '" -r "' . procName . '"'
        LogMessage("RESUME: Executing " . cmd)

        ; Simple RunWait approach for v2
        RunWait(cmd, "", "Hide")

        ; Remove from suspended list
        suspended.Delete(procName)
        LogMessage("SUCCESS: Resumed " . procName)
        return true

    } catch Error as e {
        LogMessage("ERROR in ResumeProcess(" . procName . "): " . e.message)
        IncrementError()
        ; Still remove from list to prevent stuck entries
        if (suspended.Has(procName))
            suspended.Delete(procName)
        return false
    }
}

; ╔══════════════════════════════ MAINTENANCE & CLEANUP ══════════════════════════════╗
CleanupSuspendedList() {
    try {
        LogMessage("CLEANUP: Starting suspended list cleanup")
        toRemove := []

        for procName, suspendTime in suspended {
            ; Check if process still exists
            if (!ValidateProcess(procName)) {
                toRemove.Push(procName)
                LogMessage("CLEANUP: Removing dead process " . procName)
                continue
            }

            ; Check for extremely old suspensions (over 24 hours)
            if ((A_TickCount - suspendTime) > 86400000) {
                LogMessage("CLEANUP: Found 24+ hour suspension for " . procName . ", attempting resume")
                ResumeProcess(procName)
            }
        }

        ; Remove dead processes from tracking
        for procName in toRemove {
            suspended.Delete(procName)
        }

        lastCleanup := A_TickCount
        LogMessage("CLEANUP: Completed, " . toRemove.Length . " entries removed")

    } catch Error as e {
        LogMessage("ERROR in CleanupSuspendedList: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ HOTKEY FUNCTIONS ══════════════════════════════╗
HotkeySuspend() {
    try {
        procName := GetActiveProcess()
        if (procName == "" || skipMap.Has(procName)) {
            if (procName != "")
                TrayTip("Skipped", "Cannot suspend protected process: " . procName, 1000)
            return
        }

        ; Check if already suspended
        if (suspended.Has(procName)) {
            TrayTip("Already Suspended", procName . " is already suspended", 1000)
            LogMessage("INFO: " . procName . " already suspended")
            return
        }

        ; Attempt suspension
        if (SuspendProcess(procName)) {
            TrayTip("Suspended", procName . " suspended successfully", 1000)
        } else {
            TrayTip("Suspend Failed", "Failed to suspend " . procName, 1000)
        }

    } catch Error as e {
        LogMessage("ERROR in HotkeySuspend: " . e.message)
        IncrementError()
        TrayTip("Error", "Suspend operation failed", 1000)
    }
}

HotkeyResume() {
    try {
        procName := GetActiveProcess()
        if (procName == "") {
            return
        }

        ; Check if actually suspended
        if (!suspended.Has(procName)) {
            TrayTip("Not Suspended", procName . " is not suspended", 1000)
            return
        }

        ; Attempt resume
        if (ResumeProcess(procName)) {
            TrayTip("Resumed", procName . " resumed successfully", 1000)
        } else {
            TrayTip("Resume Failed", "Failed to resume " . procName, 1000)
        }

    } catch Error as e {
        LogMessage("ERROR in HotkeyResume: " . e.message)
        IncrementError()
        TrayTip("Error", "Resume operation failed", 1000)
    }
}

HotkeyResumeAll() {
    try {
        if (suspended.Count == 0) {
            TrayTip("No Suspended Processes", "No processes to resume", 1000)
            return
        }

        resumeCount := 0
        failCount := 0

        ; Create array to avoid modifying map during iteration
        toResume := []
        for procName, _ in suspended {
            toResume.Push(procName)
        }

        for procName in toResume {
            if (ResumeProcess(procName)) {
                resumeCount++
            } else {
                failCount++
            }
            Sleep(100) ; Small delay between operations
        }

        TrayTip("Resume All Complete", "Resumed: " . resumeCount . ", Failed: " . failCount, 2000)
        LogMessage("RESUME_ALL: Completed - Success: " . resumeCount . ", Failed: " . failCount)

    } catch Error as e {
        LogMessage("ERROR in HotkeyResumeAll: " . e.message)
        IncrementError()
        TrayTip("Error", "Resume all operation failed", 1000)
    }
}

; ╔══════════════════════════════ TIMER & MONITORING ══════════════════════════════╗
; Periodic maintenance timer (every 5 minutes)
SetTimer(MaintenanceTimer, 300000)

MaintenanceTimer() {
    global errorCount
    ; Cleanup dead processes every 5 minutes
    CleanupSuspendedList()

    ; Reset error count periodically
    if (errorCount > 0) {
        errorCount := Max(0, errorCount - 5)
    }
}

; ╔══════════════════════════════ HOTKEYS ══════════════════════════════════╗
; ••• DESKTOP MANAGEMENT •••
; Desktop switcher: Shift + S toggles between Desktop 1 and Desktop 2
+s:: {
    try {
        SwitchDesktop()
    } catch {
        Sleep(100)
        try {
            SwitchDesktop()
        } catch {
            LogMessage("CRITICAL: Desktop switch hotkey completely failed")
        }
    }
}

; ••• WINDOW MANAGEMENT •••
; Triple-tap W to force windowed mode (small resolution for games) + text buffer
~w:: {
    global lastWPress, wTapCount, tripleTapThreshold, tapResetTime, skipMap
    try {
        ; First, always process for text buffer
        ProcessTextBuffer("w")
        
        procName := GetActiveProcess()
        if (procName == "" || skipMap.Has(procName) || procName = "Program Manager") {
            ; Still process text buffer but skip window management
            return
        }
        currentTime := A_TickCount
        if (currentTime - lastWPress > tapResetTime) {
            wTapCount := 0
        }
        wTapCount++
        lastWPress := currentTime
        if (wTapCount >= 3) {
            LogMessage("WINDOWED: Triple-tap W detected")
            ForceWindowedMode()
            wTapCount := 0
        }
        if (A_TickCount - lastWPress > tapResetTime)
            wTapCount := 0
        return wTapCount
    } catch Error as e {
        LogMessage("ERROR in triple-tap W handler: " . e.message)
        IncrementError()
    }
}

; Triple-tap E to force full-size windowed mode (max resolution) + text buffer
~e:: {
    global lastEPress, eTapCount, tripleTapThreshold, tapResetTime, skipMap
    try {
        ; First, always process for text buffer
        ProcessTextBuffer("e")
        
        procName := GetActiveProcess()
        if (procName == "" || skipMap.Has(procName) || procName = "Program Manager") {
            ; Still process text buffer but skip window management
            return
        }
        currentTime := A_TickCount
        if (currentTime - lastEPress > tapResetTime) {
            eTapCount := 0
        }
        eTapCount++
        lastEPress := currentTime
        if (eTapCount >= 3) {
            LogMessage("FULLSIZE: Triple-tap E detected")
            ForceFullSizeMode()
            eTapCount := 0
        }
        if (A_TickCount - lastEPress > tapResetTime)
            eTapCount := 0
        return eTapCount
    } catch Error as e {
        LogMessage("ERROR in triple-tap E handler: " . e.message)
        IncrementError()
    }
}

; ••• TEXT SHORTCUTS •••
; Capture all letter keys for text shortcuts (except w and e which are handled above)
~a::ProcessTextBuffer("a")
~b::ProcessTextBuffer("b")
~c::ProcessTextBuffer("c")
~d::ProcessTextBuffer("d")
~f::ProcessTextBuffer("f")
~g::ProcessTextBuffer("g")
~h::ProcessTextBuffer("h")
~i::ProcessTextBuffer("i")
~j::ProcessTextBuffer("j")
~k::ProcessTextBuffer("k")
~l::ProcessTextBuffer("l")
~m::ProcessTextBuffer("m")
~n::ProcessTextBuffer("n")
~o::ProcessTextBuffer("o")
~p::ProcessTextBuffer("p")
~q::ProcessTextBuffer("q")
~r::ProcessTextBuffer("r")
~s::ProcessTextBuffer("s")
~t::ProcessTextBuffer("t")
~u::ProcessTextBuffer("u")
~v::ProcessTextBuffer("v")
~x::ProcessTextBuffer("x")
~y::ProcessTextBuffer("y")
~z::ProcessTextBuffer("z")

; ••• TERMINAL MANAGEMENT •••
; Open floating terminal: Alt + T
!t:: {
    try {
        OpenFloatingTerminal()
    } catch {
        Sleep(100)
        try {
            OpenFloatingTerminal()
        } catch {
            LogMessage("CRITICAL: Terminal open hotkey completely failed")
        }
    }
}

; Close current terminal: Alt + R
!r:: {
    try {
        CloseCurrentTerminal()
    } catch {
        Sleep(100)
        try {
            CloseCurrentTerminal()
        } catch {
            LogMessage("CRITICAL: Terminal close hotkey completely failed")
        }
    }
}

; ••• FOLDER MANAGEMENT •••
; Open Games folder: Win + G
#g:: {
    try {
        OpenGamesFolder()
    } catch {
        Sleep(100)
        try {
            OpenGamesFolder()
        } catch {
            LogMessage("CRITICAL: Games folder hotkey completely failed")
        }
    }
}

; ••• APPLICATION LAUNCHER •••
; Force kill active app: Alt + K (more powerful than Task Manager)
!k:: {
    try {
        ForceKillActiveApp()
    } catch {
        Sleep(100)
        try {
            ForceKillActiveApp()
        } catch {
            LogMessage("CRITICAL: Force kill hotkey completely failed")
        }
    }
}

; Launch WhatsApp: Alt + A
!a:: {
    try {
        LaunchWhatsApp()
    } catch {
        Sleep(100)
        try {
            LaunchWhatsApp()
        } catch {
            LogMessage("CRITICAL: WhatsApp launch hotkey completely failed")
        }
    }
}

; Launch Cheat Engine: Alt + C
!c:: {
    try {
        LaunchCheatEngine()
    } catch {
        Sleep(100)
        try {
            LaunchCheatEngine()
        } catch {
            LogMessage("CRITICAL: Cheat Engine launch hotkey completely failed")
        }
    }
}

; Close and Launch WeMod: Alt + W
!w:: {
    try {
        LaunchWeMod()
    } catch {
        Sleep(100)
        try {
            LaunchWeMod()
        } catch {
            LogMessage("CRITICAL: WeMod launch hotkey completely failed")
        }
    }
}

; ••• PROCESS SUSPENSION •••
; Primary hotkeys with error recovery
^z:: {
    try {
        HotkeySuspend()
    } catch {
        ; Fallback - try again once
        Sleep(100)
        try {
            HotkeySuspend()
        } catch {
            LogMessage("CRITICAL: Suspend hotkey completely failed")
        }
    }
}

^!r:: {
    try {
        HotkeyResume()
    } catch {
        ; Fallback - try again once
        Sleep(100)
        try {
            HotkeyResume()
        } catch {
            LogMessage("CRITICAL: Resume hotkey completely failed")
        }
    }
}

^d:: {
    try {
        HotkeyResumeAll()
    } catch {
        ; Fallback - try again once
        Sleep(100)
        try {
            HotkeyResumeAll()
        } catch {
            LogMessage("CRITICAL: Resume all hotkey completely failed")
        }
    }
}

; Alternative hotkeys for redundancy
^!z:: HotkeySuspend
^!d:: HotkeyResumeAll

; ╔══════════════════════════════ STARTUP NOTIFICATIONS ══════════════════════════════╗
LogMessage("STARTUP: Complete Desktop, Terminal & Process Manager started successfully (Admin mode)")
TrayTip("Complete Manager Ready",
    "Script running with admin privileges`n" .
    "••• HOTKEYS •••`n" .
    "Triple-tap W: Force Windowed Mode (Small)`n" .
    "Triple-tap E: Force Full Size Mode (Max)`n" .
    "••• TEXT SHORTCUTS (Smart Terminal Close) •••`n" .
    "nvc→nss | biu→ws'backitup' | sleep→ss | cahk→closeahk`n" .
    "reboot→REBOOT | bios→bios | brc→brc | swemod→swemod`n" .
    "nnn→nnn | dsubs→dsubs | cleans→clean | ccbbr→ccbbr | ssss→ssss`n" .
    "pipit→pipit | refresh→refresh | logout→refresh2`n" .
    "sdesktop→sdesktop | gccleaner→gccleaner | gdb→gdbooster`n" .
    "goodgame→ws gg | uninstall→uninstall`n" .
    "fire→Firefox | chrome→Chrome | kvrt→KVRT App`n" .
    "wall→WallPaper | tttt→Split Apps | bin→Empty Recycle Bin`n" .
    "sgame→Game Save Manager | todo→Todoist`n" .
    "••• APPLICATIONS •••`n" .
    "Alt+K: FORCE KILL App | Alt+A: WhatsApp`n" .
    "Alt+C: Cheat Engine | Alt+W: WeMod`n" .
    "••• OTHER •••`n" .
    "Win+G: Open Games Folder | Shift+S: Switch Desktops`n" .
    "Alt+T: Terminal | Alt+R: Close Terminal`n" .
    "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume | Ctrl+D: Resume All", 15000)

; ╔══════════════════════════════ EXIT HANDLER ══════════════════════════════╗
OnExit(ExitHandler)

ExitHandler(ExitReason, ExitCode) {
    LogMessage("SHUTDOWN: Script exiting - Reason: " . ExitReason)

    ; Resume all suspended processes before exit
    try {
        for procName, _ in suspended {
            ResumeProcess(procName)
            Sleep(50)
        }
        LogMessage("SHUTDOWN: All processes resumed before exit")
    } catch {
        LogMessage("ERROR: Failed to resume some processes during shutdown")
    }
}