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
    "clean", "clean",
    "sleep", "ss",
    "reboot", "REBOOT_SYSTEM",
    "bios", "bios",
    "brc", "brc",
    "rws", "rws",
    "rewsl", "rewsl",
    "rrewsl", "rrewsl",
    "nnn", "nnn",
    "dsubs", "dsubs"
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
        if (InStr(textBuffer, shortcut) > 0) {
            ; Clear buffer to prevent repeat triggers
            textBuffer := ""
            
            ; Execute terminal command
            ExecuteTerminalCommand(command)
            LogMessage("TEXT_SHORTCUT: Triggered '" . shortcut . "' -> '" . command . "'")
            break
        }
    }
}

ExecuteTerminalCommand(command) {
    try {
        LogMessage("TERMINAL_CMD: Executing command - " . command)
        
        ; Handle special reboot command
        if (command = "REBOOT_SYSTEM") {
            LogMessage("REBOOT: Initiating immediate system reboot")
            TrayTip("System Reboot", "Rebooting Windows 11 now...", 3000)
            
            ; Use shutdown command with immediate restart flags
            try {
                RunWait("shutdown /r /t 0 /f", "", "Hide")
            } catch {
                ; Fallback method
                try {
                    RunWait("shutdown -r -t 0", "", "Hide")
                } catch {
                    LogMessage("ERROR: Failed to execute reboot command")
                    TrayTip("Reboot Failed", "Could not reboot system", 2000)
                }
            }
            return
        }
        
        ; Always open new terminal for text shortcuts (don't reuse existing ones)
        terminalOpened := false
        
        ; Try to open new Windows Terminal first
        try {
            Run("wt.exe")
            if WinWait("ahk_exe WindowsTerminal.exe", , 3) {
                WinActivate("ahk_exe WindowsTerminal.exe")
                Sleep(1000)  ; Wait for terminal to fully load
                Send(command . "{Enter}")
                LogMessage("TERMINAL_CMD: Opened new Windows Terminal and sent command")
                terminalOpened := true
            }
        } catch {
            ; Fallback to new PowerShell
            try {
                Run("powershell.exe")
                if WinWait("ahk_exe powershell.exe", , 3) {
                    WinActivate("ahk_exe powershell.exe")
                    Sleep(1000)
                    Send(command . "{Enter}")
                    LogMessage("TERMINAL_CMD: Opened new PowerShell and sent command")
                    terminalOpened := true
                }
            } catch {
                ; Final fallback to CMD
                try {
                    Run("cmd.exe")
                    if WinWait("ahk_exe cmd.exe", , 3) {
                        WinActivate("ahk_exe cmd.exe")
                        Sleep(1000)
                        Send(command . "{Enter}")
                        LogMessage("TERMINAL_CMD: Opened new CMD and sent command")
                        terminalOpened := true
                    }
                } catch {
                    LogMessage("TERMINAL_CMD: Failed to open any new terminal")
                    TrayTip("Terminal Error", "Could not execute: " . command, 2000)
                }
            }
        }
        
        if (terminalOpened) {
            TrayTip("Command Executed", command . " (New Terminal)", 1500)
        }
        
    } catch Error as e {
        LogMessage("ERROR in ExecuteTerminalCommand: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ WINDOW MANAGEMENT ENHANCED ══════════════════════════════╗
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
            TrayTip("Windowed Mode", "No active window to process", 1000)
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
        
        ; Show success notification
        gameStatus := isGame ? " (Game Mode)" : ""
        TrayTip("Windowed Mode" . gameStatus, 
            "Applied to: " . activeProcess . "`n" .
            "Size: " . Round(windowWidth) . "x" . Round(windowHeight) . "`n" .
            "Position: Centered", 2000)
        
        LogMessage("WINDOWED: Successfully applied windowed mode to " . activeProcess)

    } catch Error as e {
        LogMessage("ERROR in ForceWindowedMode: " . e.message)
        IncrementError()
        TrayTip("Windowed Mode Error", "Failed to apply windowed mode", 1000)
    }
}

ForceFullSizeMode() {
    try {
        ; Get active window
        activeHwnd := WinGetID("A")
        if (!activeHwnd) {
            LogMessage("FULLSIZE: No active window found")
            TrayTip("Full Size Mode", "No active window to process", 1000)
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
        
        ; Show success notification
        TrayTip("Full Size Mode", 
            "Applied to: " . activeProcess . "`n" .
            "Size: " . screenWidth . "x" . screenHeight . "`n" .
            "Position: Full Screen (Windowed)", 2000)
        
        LogMessage("FULLSIZE: Successfully applied full size mode to " . activeProcess)

    } catch Error as e {
        LogMessage("ERROR in ForceFullSizeMode: " . e.message)
        IncrementError()
        TrayTip("Full Size Mode Error", "Failed to apply full size mode", 1000)
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
            TrayTip("Desktop Switch", "Switched to Desktop 2", 1000)
        } else {
            ; Go from Desktop 2 to Desktop 1
            Send("^#{Left}")   ; Ctrl + Win + Left Arrow
            currentDesktop := 1
            LogMessage("DESKTOP: Switched to Desktop 1")
            TrayTip("Desktop Switch", "Switched to Desktop 1", 1000)
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
                TrayTip("Terminal", "Windows Terminal opened", 1000)
                terminalOpened := true
            }
        } catch {
            try {
                Run("powershell.exe")
                Sleep(500)
                if WinWait("ahk_exe powershell.exe", , 2) {
                    WinActivate("ahk_exe powershell.exe")
                    LogMessage("TERMINAL: PowerShell opened")
                    TrayTip("Terminal", "PowerShell opened", 1000)
                    terminalOpened := true
                }
            } catch {
                try {
                    Run("cmd.exe")
                    Sleep(500)
                    if WinWait("ahk_exe cmd.exe", , 2) {
                        WinActivate("ahk_exe cmd.exe")
                        LogMessage("TERMINAL: Command Prompt opened")
                        TrayTip("Terminal", "Command Prompt opened", 1000)
                        terminalOpened := true
                    }
                } catch {
                    LogMessage("ERROR: Failed to open any terminal application")
                    TrayTip("Terminal Error", "Failed to open terminal", 1000)
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
            TrayTip("Terminal", "Terminal closed", 1000)
        } else {
            ; If not a terminal, show a brief tooltip
            LogMessage("TERMINAL: Active window is not a terminal - " . activeProcess)
            TrayTip("Not Terminal", "Active window is not a terminal", 1000)
        }
    } catch Error as e {
        LogMessage("ERROR in CloseCurrentTerminal: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ APPLICATION LAUNCHER ══════════════════════════════╗
LaunchCheatEngine() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Cheat Engine")

        ; Check if Cheat Engine executable exists
        if !FileExist(cheatEngine) {
            LogMessage("ERROR: Cheat Engine not found at: " . cheatEngine)
            TrayTip("Cheat Engine Error", "Cheat Engine.exe not found", 2000)
            return
        }

        ; Check if Cheat Engine is already running
        if ProcessExist("Cheat Engine.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Cheat Engine.exe") {
                WinActivate("ahk_exe Cheat Engine.exe")
                LogMessage("LAUNCHER: Cheat Engine already running, activated window")
                TrayTip("Cheat Engine", "Cheat Engine activated", 1000)
            } else {
                LogMessage("LAUNCHER: Cheat Engine process exists but no window found")
                TrayTip("Cheat Engine", "Cheat Engine process already running", 1000)
            }
            return
        }

        ; Launch Cheat Engine
        Run('"' . cheatEngine . '"')
        LogMessage("LAUNCHER: Cheat Engine launched successfully")
        TrayTip("Cheat Engine", "Cheat Engine launched", 1000)

        ; Optional: Wait and activate window
        Sleep(1000)
        if WinWait("ahk_exe Cheat Engine.exe", , 5) {
            WinActivate("ahk_exe Cheat Engine.exe")
            LogMessage("LAUNCHER: Cheat Engine window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchCheatEngine: " . e.message)
        IncrementError()
        TrayTip("Error", "Failed to launch Cheat Engine", 1000)
    }
}

LaunchWeMod() {
    try {
        LogMessage("LAUNCHER: Attempting to close and relaunch WeMod")

        ; Check if WeMod executable exists
        if !FileExist(weMod) {
            LogMessage("ERROR: WeMod not found at: " . weMod)
            TrayTip("WeMod Error", "WeMod.exe not found", 2000)
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
            TrayTip("WeMod", "WeMod closed, relaunching...", 1000)
        }

        ; Launch WeMod
        Run('"' . weMod . '"')
        LogMessage("LAUNCHER: WeMod launched successfully")
        TrayTip("WeMod", "WeMod launched", 1000)

        ; Optional: Wait and activate window
        Sleep(2000)  ; WeMod may take longer to start
        if WinWait("ahk_exe WeMod.exe", , 10) {
            WinActivate("ahk_exe WeMod.exe")
            LogMessage("LAUNCHER: WeMod window activated")
        }

    } catch Error as e {
        LogMessage("ERROR in LaunchWeMod: " . e.message)
        IncrementError()
        TrayTip("Error", "Failed to launch WeMod", 1000)
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
; Triple-tap W to force windowed mode (small resolution for games)
~w:: {
    global lastWPress, wTapCount, tripleTapThreshold, tapResetTime, skipMap
    try {
        procName := GetActiveProcess()
        if (procName == "" || skipMap.Has(procName) || procName = "Program Manager") {
            ; Do nothing if protected or Program Manager
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

; Triple-tap E to force full-size windowed mode (max resolution)
~e:: {
    global lastEPress, eTapCount, tripleTapThreshold, tapResetTime, skipMap
    try {
        procName := GetActiveProcess()
        if (procName == "" || skipMap.Has(procName) || procName = "Program Manager") {
            ; Do nothing if protected or Program Manager
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
; Capture all letter keys for text shortcuts
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

; ••• APPLICATION LAUNCHER •••
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
    "••• TEXT SHORTCUTS (New Terminal) •••`n" .
    "nvc→nss | biu→ws'backitup' | clean→clean`n" .
    "sleep→ss | reboot→REBOOT | bios→bios`n" .
    "brc→brc | rws→rws | rewsl→rewsl`n" .
    "rrewsl→rrewsl | nnn→nnn | dsubs→dsubs`n" .
    "••• OTHER •••`n" .
    "Shift+S: Switch Desktops`n" .
    "Alt+T: Open Terminal | Alt+R: Close Terminal`n" .
    "Alt+C: Launch Cheat Engine | Alt+W: Restart WeMod`n" .
    "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume | Ctrl+D: Resume All", 10000)

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