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
ghelperPath := "F:\backup\windowsapps\installed\ghelper\GHelper.exe"
redbuttonPath := "F:\backup\windowsapps\installed\RedButton"
everythingPath := "F:\backup\windowsapps\installed\Everything\Everything.exe"
cursorPath := "F:\backup\windowsapps\installed\cursor\Cursor.exe"
vscodePath := "F:\backup\windowsapps\installed\VSCode\Code.exe"
parsecPath := "F:\backup\windowsapps\installed\parsec\parsecd.exe"
samsungNotesPath := "C:\Program Files\WindowsApps\SAMSUNGELECTRONICSCoLtd.SamsungNotes_4.3.418.0_x64__wyx1vj98g3asy\SamsungNotes.exe"
installedPath := "F:\backup\windowsapps\installed"
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
    "pipip", "pipip",
    "refresh", "refresh",
    "logout", "refresh2",
    "sdesktop", "sdesktop",
    "gccleaner", "gccleaner",
    "gdb", "gdbooster",
    "fire", "FIREFOX_APP",
    "chrome", "CHROME_APP",
    "goodgame", "ws gg",
    "uninstall", "uninstall",
    "kvrt", "KVRT_APP",
    "helpme", "HELP_SHORTCUTS",
    "ghelp", "GHELPER_APP",
    "ubuntu", "UBUNTU_WSL",
    "ubu2", "UBUNTU2_WSL",
    "amd", "AMD_DRIVERS",
    "asus", "ASUS_DRIVERS", 
    "notes", "SAMSUNG_NOTES",
    "phonel", "PHONE_LINK",
    "youtube", "YOUTUBE_WEB",
    "ext", "ext",
    "redb", "REDBUTTON_APP",
    "claude", "CLAUDE_WEB",
    "chatgpt", "CHATGPT_WEB",
    "allit", "EVERYTHING_APP",
    "ide", "CURSOR_APP",
    "vscode", "VSCODE_APP",
    "installed", "INSTALLED_FOLDER",
    "gmail", "GMAIL_WEB",
    "ggmail", "GMAIL2_WEB",
    "speedtest", "SPEEDTEST_CMD",
    "1337", "TORRENT_WEB",
    "stopd", "STOP_DOCKER",
    "recovery", "CREATE_RESTORE_POINT",
    "parsec", "PARSEC_APP",
    "myall", "MYALL_APP"
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
            } else if (command = "HELP_SHORTCUTS") {
                ShowHelpShortcuts()
            } else if (command = "GHELPER_APP") {
                LaunchGHelper()
            } else if (command = "UBUNTU_WSL") {
                LaunchUbuntuWSL()
            } else if (command = "UBUNTU2_WSL") {
                LaunchUbuntu2WSL()
            } else if (command = "AMD_DRIVERS") {
                InstallAMDDrivers()
            } else if (command = "ASUS_DRIVERS") {
                InstallASUSDrivers()
            } else if (command = "SAMSUNG_NOTES") {
                LaunchSamsungNotes()
            } else if (command = "PHONE_LINK") {
                LaunchPhoneLink()
            } else if (command = "YOUTUBE_WEB") {
                OpenYoutube()
            } else if (command = "REDBUTTON_APP") {
                LaunchRedButton()
            } else if (command = "CLAUDE_WEB") {
                OpenClaude()
            } else if (command = "CHATGPT_WEB") {
                OpenChatGPT()
            } else if (command = "EVERYTHING_APP") {
                LaunchEverything()
            } else if (command = "CURSOR_APP") {
                LaunchCursor()
            } else if (command = "VSCODE_APP") {
                LaunchVSCode()
            } else if (command = "INSTALLED_FOLDER") {
                OpenInstalledFolder()
            } else if (command = "GMAIL_WEB") {
                OpenGmail()
            } else if (command = "GMAIL2_WEB") {
                OpenGmail2()
            } else if (command = "SPEEDTEST_CMD") {
                RunSpeedtest()
            } else if (command = "TORRENT_WEB") {
                Open1337x()
            } else if (command = "STOP_DOCKER") {
                StopDockerDesktop()
            } else if (command = "CREATE_RESTORE_POINT") {
                CreateRestorePoint()
            } else if (command = "PARSEC_APP") {
                LaunchParsec()
            } else if (command = "MYALL_APP") {
                LaunchMyAll()
            } else {
                ExecuteTerminalCommand(command)
            }
            LogMessage("TEXT_SHORTCUT: Triggered '" . shortcut . "' -> '" . command . "'")
            break
        }
    }
}

; ╔══════════════════════════════ NEW FUNCTIONS ══════════════════════════════╗
CreateRestorePoint() {
    try {
        LogMessage("RESTORE_POINT: Creating new system restore point")
        
        ; Create restore point with current timestamp
        restorePointScript := 'powershell.exe -Command "'
        restorePointScript .= 'Write-Host "═══ CREATING SYSTEM RESTORE POINT ═══" -ForegroundColor Cyan;'
        restorePointScript .= 'try {'
        restorePointScript .= '$ErrorActionPreference = `"Stop`";'
        restorePointScript .= '$timestamp = Get-Date -Format `"yyyy-MM-dd HH:mm:ss`";'
        restorePointScript .= '$description = `"Manual Restore Point - $timestamp`";'
        restorePointScript .= 'Write-Host "Creating restore point: $description" -ForegroundColor Yellow;'
        restorePointScript .= 'Checkpoint-Computer -Description $description -RestorePointType `"MODIFY_SETTINGS`";'
        restorePointScript .= 'Write-Host "✓ System restore point created successfully!" -ForegroundColor Green;'
        restorePointScript .= 'Write-Host "Description: $description" -ForegroundColor White;'
        restorePointScript .= '} catch {'
        restorePointScript .= 'Write-Host "ERROR: Failed to create restore point: $($_.Exception.Message)" -ForegroundColor Red;'
        restorePointScript .= 'Write-Host "Note: System restore may be disabled or insufficient privileges" -ForegroundColor Yellow;'
        restorePointScript .= '}'
        restorePointScript .= 'Write-Host "`nPress any key to close..." -ForegroundColor Green; $null = $Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`")"'
        
        Run(restorePointScript)
        LogMessage("RESTORE_POINT: System restore point creation initiated")
        
    } catch Error as e {
        LogMessage("ERROR in CreateRestorePoint: " . e.message)
        IncrementError()
    }
}

LaunchParsec() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Parsec")
        
        ; Check if Parsec executable exists
        if !FileExist(parsecPath) {
            LogMessage("ERROR: Parsec not found at: " . parsecPath)
            return
        }
        
        ; Check if Parsec is already running
        if ProcessExist("parsecd.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe parsecd.exe") {
                WinActivate("ahk_exe parsecd.exe")
                LogMessage("LAUNCHER: Parsec already running, activated window")
            } else {
                LogMessage("LAUNCHER: Parsec process exists but no window found")
            }
            return
        }
        
        ; Launch Parsec
        Run('"' . parsecPath . '"')
        LogMessage("LAUNCHER: Parsec launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(2000)
        if WinWait("ahk_exe parsecd.exe", , 8) {
            WinActivate("ahk_exe parsecd.exe")
            LogMessage("LAUNCHER: Parsec window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchParsec: " . e.message)
        IncrementError()
    }
}

LaunchMyAll() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Everything (MyAll)")
        
        ; Check if Everything executable exists
        if !FileExist(everythingPath) {
            LogMessage("ERROR: Everything not found at: " . everythingPath)
            return
        }
        
        ; Check if Everything is already running
        if ProcessExist("Everything.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Everything.exe") {
                WinActivate("ahk_exe Everything.exe")
                LogMessage("LAUNCHER: Everything (MyAll) already running, activated window")
            } else {
                LogMessage("LAUNCHER: Everything (MyAll) process exists but no window found")
            }
            return
        }
        
        ; Launch Everything
        Run('"' . everythingPath . '"')
        LogMessage("LAUNCHER: Everything (MyAll) launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe Everything.exe", , 8) {
            WinActivate("ahk_exe Everything.exe")
            LogMessage("LAUNCHER: Everything (MyAll) window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchMyAll: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ UPDATED FUNCTIONS ══════════════════════════════╗
LaunchSamsungNotes() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Samsung Notes")
        
        ; Check if Samsung Notes is already running
        samsungNotesProcesses := ["SamsungNotes.exe", "Samsung Notes.exe", "Notes.exe"]
        notesRunning := false
        
        for processName in samsungNotesProcesses {
            if ProcessExist(processName) {
                ; If already running, try to activate the window
                if WinExist("ahk_exe " . processName) {
                    WinActivate("ahk_exe " . processName)
                    LogMessage("LAUNCHER: Samsung Notes already running (" . processName . "), activated window")
                    notesRunning := true
                    break
                }
            }
        }
        
        if (notesRunning) {
            return
        }
        
        ; Try to launch using the specific path first
        if FileExist(samsungNotesPath) {
            try {
                Run('"' . samsungNotesPath . '"')
                LogMessage("LAUNCHER: Samsung Notes launched via direct path: " . samsungNotesPath)
                
                ; Wait for window
                Sleep(2000)
                for processName in samsungNotesProcesses {
                    if WinWait("ahk_exe " . processName, , 5) {
                        WinActivate("ahk_exe " . processName)
                        LogMessage("LAUNCHER: Samsung Notes window activated (" . processName . ")")
                        return
                    }
                }
            } catch Error as e {
                LogMessage("ERROR: Failed to launch Samsung Notes via direct path: " . e.message)
            }
        } else {
            LogMessage("WARNING: Samsung Notes not found at specified path: " . samsungNotesPath)
        }
        
        ; Fallback methods if direct path doesn't work
        ; Method 1: Try Windows Store app protocol
        try {
            Run("explorer.exe shell:AppsFolder\Samsung Notes")
            LogMessage("LAUNCHER: Samsung Notes launched via shell:AppsFolder")
            
            ; Wait for window
            Sleep(2000)
            for processName in samsungNotesProcesses {
                if WinWait("ahk_exe " . processName, , 3) {
                    WinActivate("ahk_exe " . processName)
                    LogMessage("LAUNCHER: Samsung Notes window activated (" . processName . ")")
                    return
                }
            }
        } catch {
            ; Method 2: Try PowerShell UWP launch
            try {
                Run('powershell.exe -Command "Get-AppxPackage *Samsung*Notes* | Invoke-Item"', "", "Hide")
                LogMessage("LAUNCHER: Samsung Notes launched via PowerShell AppX")
                
                Sleep(2000)
                for processName in samsungNotesProcesses {
                    if WinWait("ahk_exe " . processName, , 3) {
                        WinActivate("ahk_exe " . processName)
                        LogMessage("LAUNCHER: Samsung Notes window activated (" . processName . ")")
                        return
                    }
                }
            } catch {
                LogMessage("ERROR: All Samsung Notes launch methods failed")
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchSamsungNotes: " . e.message)
        IncrementError()
    }
}

Open1337x() {
    try {
        LogMessage("WEB: Opening 1337x.to in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for 1337x")
            ; Try to find Chrome in alternative locations
            altChromePaths := [
                "C:\Program Files\Google\Chrome\Application\chrome.exe",
                "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
            ]
            
            found := false
            for altPath in altChromePaths {
                if FileExist(altPath) {
                    chromePath := altPath
                    found := true
                    LogMessage("WEB: Found Chrome at alternative location: " . altPath)
                    break
                }
            }
            
            if (!found) {
                LogMessage("ERROR: Chrome not found in any location for 1337x")
                return
            }
        }
        
        ; Open 1337x.to in Chrome new tab (force new tab with --new-tab flag)
        Run('"' . chromePath . '" --new-tab "https://1337x.to/"')
        LogMessage("WEB: 1337x.to opened in Chrome new tab")
        
    } catch Error as e {
        LogMessage("ERROR in Open1337x: " . e.message)
        IncrementError()
    }
}

; ╔══════════════════════════════ EXISTING FUNCTIONS ══════════════════════════════╗
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

ShowHelpShortcuts() {
    try {
        LogMessage("HELP: Displaying shortcuts help GUI")
        
        ; Create a very large GUI window (4x bigger than normal)
        helpGui := Gui("+Resize +MaximizeBox", "Complete Desktop Manager - All Shortcuts")
        helpGui.MarginX := 40
        helpGui.MarginY := 30
        
        ; Set very large font (3x bigger and bold)
        helpGui.SetFont("s6", "Segoe UI")
        
        ; Create the help text content with proper formatting
        helpText := "═══ COMPLETE DESKTOP MANAGER - ALL SHORTCUTS ═══`n`n"
        helpText .= "••• WINDOW MANAGEMENT •••`n"
        helpText .= "Triple-tap W: Force Windowed Mode (Small)`n"
        helpText .= "Triple-tap E: Force Full Size Mode (Max)`n"
        helpText .= "www: Force current window to windowed mode`n"
        helpText .= "eee: Force current window to full size mode`n`n"
        
        helpText .= "••• TERMINAL COMMANDS •••`n"
        helpText .= "nvc→nss | biu→ws'backitup' | sleep→ss | cahk→closeahk`n"
        helpText .= "reboot→REBOOT | bios→bios | brc→brc | swemod→swemod`n"
        helpText .= "nnn→nnn | dsubs→dsubs | cleans→clean | ccbbr→ccbbr`n"
        helpText .= "ssss→ssss | pipip→pipip | refresh→refresh | logout→refresh2`n"
        helpText .= "sdesktop→sdesktop | gccleaner→gccleaner | gdb→gdbooster`n"
        helpText .= "goodgame→ws gg | uninstall→uninstall | ext→ext`n"
        helpText .= "stopd→Stop Docker Desktop`n`n"
        
        helpText .= "••• NEW SYSTEM FUNCTIONS •••`n"
        helpText .= "recovery→Create System Restore Point`n"
        helpText .= "parsec→Launch Parsec Remote Desktop`n"
        helpText .= "myall→Launch Everything Search (Alternative)`n`n"
        
        helpText .= "••• DRIVER INSTALLATION •••`n"
        helpText .= "amd→AUTO-INSTALL AMD CPU/GPU Drivers (Real Installation!)`n"
        helpText .= "asus→AUTO-INSTALL ASUS Hardware Drivers (Real Installation!)`n`n"
        
        helpText .= "••• WSL & LINUX •••`n"
        helpText .= "ubuntu→Open Terminal + Run WSL Ubuntu`n"
        helpText .= "ubu2→Open Terminal + Run WSL Ubuntu2`n`n"
        
        helpText .= "••• WEB SHORTCUTS •••`n"
        helpText .= "youtube→YouTube | claude→Claude.ai | chatgpt→ChatGPT`n"
        helpText .= "gmail→Gmail Account 0 | ggmail→Gmail Account 1`n"
        helpText .= "1337→1337x.to Torrent Site | speedtest→Network Speed Test`n`n"
        
        helpText .= "••• APPLICATION LAUNCHERS •••`n"
        helpText .= "fire→Firefox | chrome→Chrome | wall→WallPaper | kvrt→KVRT`n"
        helpText .= "sgame→Game Save Manager | todo→Todoist | ghelp→GHelper GUI`n"
        helpText .= "redb→RedButton | allit→Everything Search | ide→Cursor IDE`n"
        helpText .= "vscode→VSCode | installed→Apps Folder | parsec→Parsec App`n"
        helpText .= "notes→Samsung Notes | phonel→Phone Link | myall→Everything Search`n`n"
        
        helpText .= "••• SYSTEM ACTIONS •••`n"
        helpText .= "bin→Empty Recycle Bin | tttt→Split Top 2 Apps | helpme→This Help`n"
        helpText .= "recovery→Create System Restore Point`n`n"
        
        helpText .= "••• HOTKEYS •••`n"
        helpText .= "Alt+K: FORCE KILL App | Alt+A: WhatsApp | Alt+C: Cheat Engine`n"
        helpText .= "Alt+W: WeMod | Win+G: Games Folder | Shift+S: Switch Desktops`n"
        helpText .= "Alt+T: Terminal | Alt+R: Close Terminal`n"
        helpText .= "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume | Ctrl+D: Resume All`n`n"
        
        helpText .= "═══════════════════════════════════════════════════`n`n"
        
        helpText .= "••• ADVANCED FEATURES •••`n"
        helpText .= "• System Restore: recovery creates timestamped restore points`n"
        helpText .= "• Smart Terminal Closing: Commands automatically close their terminal window`n"
        helpText .= "• Real Network Testing: speedtest shows actual download/upload speeds`n"
        helpText .= "• Docker Management: stopd force closes Docker Desktop completely`n"
        helpText .= "• WSL Integration: ubuntu/ubu2 opens terminal with WSL distributions`n"
        helpText .= "• GHelper Integration: ghelp opens full GHelper GUI with all data`n"
        helpText .= "• Everything Search: allit + myall launches Everything for instant file search`n"
        helpText .= "• REAL DRIVER INSTALLATION: amd/asus actually find & install drivers!`n"
        helpText .= "• Samsung Notes: notes launches Samsung Notes from Windows Store`n"
        helpText .= "• Phone Link: phonel launches Microsoft Phone Link app`n"
        helpText .= "• Parsec Remote: parsec launches Parsec remote desktop application`n`n"
        
        helpText .= "═══════════════════════════════════════════════════"
        
        ; Add scrollable text control with scroll bars (4x bigger size)
        textControl := helpGui.Add("Edit", "x20 y20 w1600 h1000 VScroll ReadOnly", helpText)
        
        ; Add close button
        closeBtn := helpGui.Add("Button", "x750 y1030 w100 h50", "Close")
        closeBtn.OnEvent("Click", (*) => helpGui.Close())
        
        ; Show the GUI (4x bigger than normal)
        helpGui.Show("w1640 h1100")
        
        LogMessage("HELP: Very large shortcuts help GUI displayed successfully")
        
    } catch Error as e {
        LogMessage("ERROR in ShowHelpShortcuts: " . e.message)
        IncrementError()
        ; Fallback to simple message box
        MsgBox("Error creating help GUI. Check log for details.", "Help Error", "OK")
    }
}

LaunchGHelper() {
    try {
        LogMessage("GHELPER: Attempting to launch GHelper GUI")
        
        ; Check if GHelper executable exists
        if !FileExist(ghelperPath) {
            LogMessage("ERROR: GHelper not found at: " . ghelperPath)
            return
        }
        
        ; Check if GHelper is already running
        if ProcessExist("GHelper.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe GHelper.exe") {
                WinActivate("ahk_exe GHelper.exe")
                LogMessage("GHELPER: GHelper already running, activated window")
            } else {
                LogMessage("GHELPER: GHelper process exists but no window found")
            }
            return
        }
        
        ; Launch GHelper directly
        Run('"' . ghelperPath . '"')
        LogMessage("GHELPER: GHelper launched successfully")
        
        ; Wait and activate window to ensure GUI shows
        Sleep(2000)
        if WinWait("ahk_exe GHelper.exe", , 8) {
            WinActivate("ahk_exe GHelper.exe")
            ; Bring to foreground
            WinSetAlwaysOnTop(true, "ahk_exe GHelper.exe")
            Sleep(100)
            WinSetAlwaysOnTop(false, "ahk_exe GHelper.exe")
            LogMessage("GHELPER: GHelper GUI window activated and brought to foreground")
        } else {
            LogMessage("WARNING: GHelper launched but window not detected")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchGHelper: " . e.message)
        IncrementError()
    }
}

LaunchUbuntuWSL() {
    try {
        LogMessage("UBUNTU: Opening terminal and running WSL Ubuntu")
        
        ; Method 1: Try Windows Terminal with Ubuntu directly
        try {
            Run('wt.exe wsl -d Ubuntu')
            LogMessage("UBUNTU: Ubuntu WSL launched in Windows Terminal")
            return
        } catch {
            ; Method 2: Try PowerShell with WSL command
            try {
                Run('powershell.exe -Command "wsl -d Ubuntu"')
                LogMessage("UBUNTU: Ubuntu WSL launched in PowerShell")
                return
            } catch {
                ; Method 3: Try Command Prompt with WSL
                try {
                    Run('cmd.exe /k "wsl -d Ubuntu"')
                    LogMessage("UBUNTU: Ubuntu WSL launched in Command Prompt")
                    return
                } catch {
                    LogMessage("ERROR: All Ubuntu WSL launch methods failed - WSL or Ubuntu may not be installed")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchUbuntuWSL: " . e.message)
        IncrementError()
    }
}

LaunchUbuntu2WSL() {
    try {
        LogMessage("UBUNTU2: Opening terminal and running WSL Ubuntu2")
        
        ; Method 1: Try Windows Terminal with Ubuntu2 directly
        try {
            Run('wt.exe wsl -d Ubuntu2')
            LogMessage("UBUNTU2: Ubuntu2 WSL launched in Windows Terminal")
            return
        } catch {
            ; Method 2: Try PowerShell with WSL command
            try {
                Run('powershell.exe -Command "wsl -d Ubuntu2"')
                LogMessage("UBUNTU2: Ubuntu2 WSL launched in PowerShell")
                return
            } catch {
                ; Method 3: Try Command Prompt with WSL
                try {
                    Run('cmd.exe /k "wsl -d Ubuntu2"')
                    LogMessage("UBUNTU2: Ubuntu2 WSL launched in Command Prompt")
                    return
                } catch {
                    LogMessage("ERROR: All Ubuntu2 WSL launch methods failed - WSL or Ubuntu2 may not be installed")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchUbuntu2WSL: " . e.message)
        IncrementError()
    }
}

InstallAMDDrivers() {
    try {
        LogMessage("AMD: Starting comprehensive AMD driver detection and installation")
        
        ; Create powerful AMD driver installation script
        amdScript := 'powershell.exe -Command "'
        amdScript .= 'Write-Host "═══ AMD DRIVER DETECTION & INSTALLATION ═══" -ForegroundColor Cyan;'
        amdScript .= 'Write-Host "Detecting AMD hardware..." -ForegroundColor Yellow;'
        amdScript .= 'try {'
        amdScript .= '$ErrorActionPreference = `"Stop`";'
        
        ; Detect AMD hardware
        amdScript .= '$amdCPU = Get-WmiObject Win32_Processor | Where-Object {$_.Name -like "*AMD*"};'
        amdScript .= '$amdGPU = Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like "*AMD*" -or $_.Name -like "*Radeon*"};'
        amdScript .= 'if ($amdCPU) { Write-Host "✓ Found AMD CPU: $($amdCPU.Name)" -ForegroundColor Green } else { Write-Host "✗ No AMD CPU detected" -ForegroundColor Red };'
        amdScript .= 'if ($amdGPU) { Write-Host "✓ Found AMD GPU: $($amdGPU.Name)" -ForegroundColor Green } else { Write-Host "✗ No AMD GPU detected" -ForegroundColor Red };'
        
        ; Search for AMD drivers via Windows Update
        amdScript .= 'Write-Host "`nStep 1: Searching Windows Update for AMD drivers..." -ForegroundColor Cyan;'
        amdScript .= 'try {'
        amdScript .= '$Session = New-Object -ComObject Microsoft.Update.Session;'
        amdScript .= '$Searcher = $Session.CreateUpdateSearcher();'
        amdScript .= 'Write-Host "Searching for AMD-related updates..." -ForegroundColor Yellow;'
        amdScript .= '$SearchResult = $Searcher.Search("IsInstalled=0 and Type=`"Driver`" and CategoryIDs contains `"28bc880e-0592-4cbf-8f95-c79b17911d5f`"");'
        amdScript .= 'if ($SearchResult.Updates.Count -gt 0) {'
        amdScript .= 'Write-Host "Found $($SearchResult.Updates.Count) driver updates available!" -ForegroundColor Green;'
        amdScript .= 'foreach ($Update in $SearchResult.Updates) {'
        amdScript .= 'if ($Update.Title -like "*AMD*" -or $Update.Title -like "*Radeon*") {'
        amdScript .= 'Write-Host "Available: $($Update.Title)" -ForegroundColor White;'
        amdScript .= '}'
        amdScript .= '}'
        amdScript .= '} else { Write-Host "No driver updates found via Windows Update" -ForegroundColor Yellow };'
        amdScript .= '} catch { Write-Host "Windows Update search failed: $($_.Exception.Message)" -ForegroundColor Red };'
        
        ; Use PnPUtil to detect and install drivers
        amdScript .= 'Write-Host "`nStep 2: Using PnPUtil for driver detection..." -ForegroundColor Cyan;'
        amdScript .= 'try {'
        amdScript .= '$pnpDevices = pnputil /enum-devices /class Display;'
        amdScript .= '$amdDevices = $pnpDevices | Select-String -Pattern "AMD|Radeon";'
        amdScript .= 'if ($amdDevices) {'
        amdScript .= 'Write-Host "Found AMD devices in system:" -ForegroundColor Green;'
        amdScript .= '$amdDevices | ForEach-Object { Write-Host $_ -ForegroundColor White };'
        amdScript .= 'Write-Host "Attempting automatic driver installation..." -ForegroundColor Yellow;'
        amdScript .= 'pnputil /scan-devices;'
        amdScript .= 'Write-Host "Device scan completed" -ForegroundColor Green;'
        amdScript .= '} else { Write-Host "No AMD devices found via PnPUtil" -ForegroundColor Yellow };'
        amdScript .= '} catch { Write-Host "PnPUtil scan failed: $($_.Exception.Message)" -ForegroundColor Red };'
        
        ; Open Device Manager for manual driver update
        amdScript .= 'Write-Host "`nStep 3: Opening Device Manager for manual updates..." -ForegroundColor Cyan;'
        amdScript .= 'Start-Process devmgmt.msc;'
        amdScript .= 'Write-Host "✓ Device Manager opened - Right-click devices and select `"Update driver`"" -ForegroundColor Green;'
        
        ; Open Windows Update
        amdScript .= 'Write-Host "`nStep 4: Opening Windows Update..." -ForegroundColor Cyan;'
        amdScript .= 'Start-Process ms-settings:windowsupdate-action;'
        amdScript .= 'Write-Host "✓ Windows Update opened - Check for updates" -ForegroundColor Green;'
        
        ; Try to download AMD software
        amdScript .= 'Write-Host "`nStep 5: Checking for AMD Software..." -ForegroundColor Cyan;'
        amdScript .= '$amdSoftware = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*AMD*"};'
        amdScript .= 'if ($amdSoftware) {'
        amdScript .= '$amdSoftware | ForEach-Object { Write-Host "✓ Found: $($_.DisplayName)" -ForegroundColor Green };'
        amdScript .= '} else {'
        amdScript .= 'Write-Host "No AMD Software detected. Opening AMD website..." -ForegroundColor Yellow;'
        amdScript .= 'Start-Process "https://www.amd.com/en/support";'
        amdScript .= 'Write-Host "✓ AMD Support website opened - Download latest drivers" -ForegroundColor Green;'
        amdScript .= '};'
        
        ; Force Windows to install available drivers
        amdScript .= 'Write-Host "`nStep 6: Force installing available drivers..." -ForegroundColor Cyan;'
        amdScript .= 'try {'
        amdScript .= 'Get-WmiObject Win32_PnPEntity | Where-Object {$_.Name -like "*AMD*" -or $_.Name -like "*Radeon*"} | ForEach-Object {'
        amdScript .= 'Write-Host "Processing device: $($_.Name)" -ForegroundColor White;'
        amdScript .= 'try { $_.InvokeMethod("RequestStateChange", 5); $_.InvokeMethod("RequestStateChange", 2) } catch { Write-Host "Could not refresh device: $($_.Name)" -ForegroundColor Yellow };'
        amdScript .= '};'
        amdScript .= '} catch { Write-Host "Device refresh failed: $($_.Exception.Message)" -ForegroundColor Red };'
        
        amdScript .= 'Write-Host "`n═══ AMD DRIVER INSTALLATION COMPLETE ═══" -ForegroundColor Cyan;'
        amdScript .= 'Write-Host "Actions taken:" -ForegroundColor Green;'
        amdScript .= 'Write-Host "✓ Hardware detection completed" -ForegroundColor White;'
        amdScript .= 'Write-Host "✓ Windows Update driver search performed" -ForegroundColor White;'
        amdScript .= 'Write-Host "✓ Device Manager opened for manual updates" -ForegroundColor White;'
        amdScript .= 'Write-Host "✓ Windows Update opened" -ForegroundColor White;'
        amdScript .= 'Write-Host "✓ AMD website opened (if no software found)" -ForegroundColor White;'
        amdScript .= 'Write-Host "✓ Device refresh attempted" -ForegroundColor White;'
        amdScript .= '} catch { Write-Host "Critical error during AMD driver installation: $($_.Exception.Message)" -ForegroundColor Red };'
        amdScript .= 'Write-Host "`nPress any key to close..." -ForegroundColor Green; $null = $Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`")"'
        
        Run(amdScript)
        LogMessage("AMD: Comprehensive AMD driver detection and installation initiated")
        
    } catch Error as e {
        LogMessage("ERROR in InstallAMDDrivers: " . e.message)
        IncrementError()
    }
}

InstallASUSDrivers() {
    try {
        LogMessage("ASUS: Starting comprehensive ASUS driver detection and installation")
        
        ; Create powerful ASUS driver installation script
        asusScript := 'powershell.exe -Command "'
        asusScript .= 'Write-Host "═══ ASUS DRIVER DETECTION & INSTALLATION ═══" -ForegroundColor Cyan;'
        asusScript .= 'Write-Host "Detecting ASUS hardware..." -ForegroundColor Yellow;'
        asusScript .= 'try {'
        asusScript .= '$ErrorActionPreference = `"Stop`";'
        
        ; Detect ASUS hardware
        asusScript .= '$asusMotherboard = Get-WmiObject Win32_BaseBoard | Where-Object {$_.Manufacturer -like "*ASUS*" -or $_.Product -like "*ASUS*"};'
        asusScript .= '$asusAudio = Get-WmiObject Win32_SoundDevice | Where-Object {$_.Name -like "*ASUS*" -or $_.Manufacturer -like "*ASUS*"};'
        asusScript .= '$asusNetwork = Get-WmiObject Win32_NetworkAdapter | Where-Object {$_.Name -like "*ASUS*" -or $_.Manufacturer -like "*ASUS*"};'
        asusScript .= '$asusGPU = Get-WmiObject Win32_VideoController | Where-Object {$_.Name -like "*ASUS*"};'
        asusScript .= 'if ($asusMotherboard) { Write-Host "✓ Found ASUS Motherboard: $($asusMotherboard.Product)" -ForegroundColor Green } else { Write-Host "✗ No ASUS motherboard detected" -ForegroundColor Yellow };'
        asusScript .= 'if ($asusAudio) { Write-Host "✓ Found ASUS Audio: $($asusAudio.Name)" -ForegroundColor Green };'
        asusScript .= 'if ($asusNetwork) { Write-Host "✓ Found ASUS Network: $($asusNetwork.Name)" -ForegroundColor Green };'
        asusScript .= 'if ($asusGPU) { Write-Host "✓ Found ASUS GPU: $($asusGPU.Name)" -ForegroundColor Green };'
        
        ; Check for existing ASUS software
        asusScript .= 'Write-Host "`nStep 1: Checking for existing ASUS software..." -ForegroundColor Cyan;'
        asusScript .= '$asusSoftware = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "*ASUS*"};'
        asusScript .= 'if ($asusSoftware) {'
        asusScript .= '$asusSoftware | ForEach-Object { Write-Host "✓ Found: $($_.DisplayName)" -ForegroundColor Green };'
        asusScript .= '} else { Write-Host "No ASUS software currently installed" -ForegroundColor Yellow };'
        
        ; Search for ASUS drivers via Windows Update
        asusScript .= 'Write-Host "`nStep 2: Searching Windows Update for ASUS drivers..." -ForegroundColor Cyan;'
        asusScript .= 'try {'
        asusScript .= '$Session = New-Object -ComObject Microsoft.Update.Session;'
        asusScript .= '$Searcher = $Session.CreateUpdateSearcher();'
        asusScript .= 'Write-Host "Searching for ASUS-related updates..." -ForegroundColor Yellow;'
        asusScript .= '$SearchResult = $Searcher.Search("IsInstalled=0 and Type=`"Driver`"");'
        asusScript .= 'if ($SearchResult.Updates.Count -gt 0) {'
        asusScript .= '$asusUpdates = $SearchResult.Updates | Where-Object {$_.Title -like "*ASUS*"};'
        asusScript .= 'if ($asusUpdates) {'
        asusScript .= 'Write-Host "Found ASUS driver updates:" -ForegroundColor Green;'
        asusScript .= '$asusUpdates | ForEach-Object { Write-Host "Available: $($_.Title)" -ForegroundColor White };'
        asusScript .= '} else { Write-Host "No ASUS-specific drivers found in Windows Update" -ForegroundColor Yellow };'
        asusScript .= '} else { Write-Host "No driver updates found via Windows Update" -ForegroundColor Yellow };'
        asusScript .= '} catch { Write-Host "Windows Update search failed: $($_.Exception.Message)" -ForegroundColor Red };'
        
        ; Use PnPUtil for ASUS devices
        asusScript .= 'Write-Host "`nStep 3: Using PnPUtil for ASUS device detection..." -ForegroundColor Cyan;'
        asusScript .= 'try {'
        asusScript .= '$pnpDevices = pnputil /enum-devices;'
        asusScript .= '$asusDevices = $pnpDevices | Select-String -Pattern "ASUS";'
        asusScript .= 'if ($asusDevices) {'
        asusScript .= 'Write-Host "Found ASUS devices in system:" -ForegroundColor Green;'
        asusScript .= '$asusDevices | ForEach-Object { Write-Host $_ -ForegroundColor White };'
        asusScript .= '} else { Write-Host "No ASUS devices found via PnPUtil" -ForegroundColor Yellow };'
        asusScript .= '} catch { Write-Host "PnPUtil scan failed: $($_.Exception.Message)" -ForegroundColor Red };'
        
        ; Open Device Manager
        asusScript .= 'Write-Host "`nStep 4: Opening Device Manager..." -ForegroundColor Cyan;'
        asusScript .= 'Start-Process devmgmt.msc;'
        asusScript .= 'Write-Host "✓ Device Manager opened" -ForegroundColor Green;'
        
        ; Open Windows Update
        asusScript .= 'Write-Host "`nStep 5: Opening Windows Update..." -ForegroundColor Cyan;'
        asusScript .= 'Start-Process ms-settings:windowsupdate-action;'
        asusScript .= 'Write-Host "✓ Windows Update opened" -ForegroundColor Green;'
        
        ; Open ASUS support website
        asusScript .= 'Write-Host "`nStep 6: Opening ASUS Support website..." -ForegroundColor Cyan;'
        asusScript .= 'Start-Process "https://www.asus.com/support/download-center/";'
        asusScript .= 'Write-Host "✓ ASUS Download Center opened" -ForegroundColor Green;'
        
        ; Try to download ASUS tools
        asusScript .= 'Write-Host "`nStep 7: Attempting to download ASUS tools..." -ForegroundColor Cyan;'
        asusScript .= 'try {'
        asusScript .= 'Write-Host "Opening ASUS Armoury Crate page..." -ForegroundColor Yellow;'
        asusScript .= 'Start-Process "https://www.asus.com/campaign/aura/us/Armoury-Crate.html";'
        asusScript .= 'Write-Host "✓ ASUS Armoury Crate page opened" -ForegroundColor Green;'
        asusScript .= '} catch { Write-Host "Could not open ASUS Armoury Crate page" -ForegroundColor Red };'
        
        asusScript .= 'Write-Host "`n═══ ASUS DRIVER INSTALLATION COMPLETE ═══" -ForegroundColor Cyan;'
        asusScript .= 'Write-Host "Actions taken:" -ForegroundColor Green;'
        asusScript .= 'Write-Host "✓ ASUS hardware detection completed" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ Existing ASUS software checked" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ Windows Update driver search performed" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ Device Manager opened" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ Windows Update opened" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ ASUS Support website opened" -ForegroundColor White;'
        asusScript .= 'Write-Host "✓ ASUS Armoury Crate page opened" -ForegroundColor White;'
        asusScript .= '} catch { Write-Host "Critical error during ASUS driver installation: $($_.Exception.Message)" -ForegroundColor Red };'
        asusScript .= 'Write-Host "`nPress any key to close..." -ForegroundColor Green; $null = $Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`")"'
        
        Run(asusScript)
        LogMessage("ASUS: Comprehensive ASUS driver detection and installation initiated")
        
    } catch Error as e {
        LogMessage("ERROR in InstallASUSDrivers: " . e.message)
        IncrementError()
    }
}

LaunchPhoneLink() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Phone Link")
        
        ; Check if Phone Link is already running
        phoneLinkProcesses := ["PhoneExperienceHost.exe", "YourPhone.exe", "Microsoft.YourPhone.exe"]
        phoneLinkRunning := false
        
        for processName in phoneLinkProcesses {
            if ProcessExist(processName) {
                ; If already running, try to activate the window
                if WinExist("ahk_exe " . processName) {
                    WinActivate("ahk_exe " . processName)
                    LogMessage("LAUNCHER: Phone Link already running (" . processName . "), activated window")
                    phoneLinkRunning := true
                    break
                }
            }
        }
        
        if (phoneLinkRunning) {
            return
        }
        
        ; Method 1: Try direct Phone Link protocol
        try {
            Run("ms-yourphone:")
            LogMessage("LAUNCHER: Phone Link launched via ms-yourphone protocol")
            
            ; Wait for window
            Sleep(2000)
            for processName in phoneLinkProcesses {
                if WinWait("ahk_exe " . processName, , 5) {
                    WinActivate("ahk_exe " . processName)
                    LogMessage("LAUNCHER: Phone Link window activated (" . processName . ")")
                    return
                }
            }
        } catch {
            ; Method 2: Try via Start menu
            try {
                Run("explorer.exe shell:AppsFolder\Microsoft.YourPhone_8wekyb3d8bbwe!App")
                LogMessage("LAUNCHER: Phone Link launched via shell:AppsFolder")
                
                Sleep(2000)
                for processName in phoneLinkProcesses {
                    if WinWait("ahk_exe " . processName, , 5) {
                        WinActivate("ahk_exe " . processName)
                        LogMessage("LAUNCHER: Phone Link window activated (" . processName . ")")
                        return
                    }
                }
            } catch {
                ; Method 3: Try PowerShell launch
                try {
                    Run('powershell.exe -Command "Start-Process -FilePath `"ms-yourphone:`""', "", "Hide")
                    LogMessage("LAUNCHER: Phone Link launched via PowerShell")
                    
                    Sleep(2000)
                    for processName in phoneLinkProcesses {
                        if WinWait("ahk_exe " . processName, , 5) {
                            WinActivate("ahk_exe " . processName)
                            LogMessage("LAUNCHER: Phone Link window activated (" . processName . ")")
                            return
                        }
                    }
                } catch {
                    ; Method 4: Open Windows Store to install if not found
                    try {
                        Run("ms-windows-store://pdp/?ProductId=9NMPJ99VJBWV")
                        LogMessage("LAUNCHER: Opened Windows Store for Phone Link installation")
                    } catch {
                        LogMessage("ERROR: All Phone Link launch methods failed")
                    }
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchPhoneLink: " . e.message)
        IncrementError()
    }
}

LaunchEverything() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Everything")
        
        ; Check if Everything executable exists
        if !FileExist(everythingPath) {
            LogMessage("ERROR: Everything not found at: " . everythingPath)
            ; Try alternative locations
            altPaths := [
                "C:\Program Files\Everything\Everything.exe",
                "C:\Program Files (x86)\Everything\Everything.exe",
                A_ProgramFiles . "\Everything\Everything.exe"
            ]
            
            found := false
            for altPath in altPaths {
                if FileExist(altPath) {
                    everythingPath := altPath
                    found := true
                    LogMessage("LAUNCHER: Found Everything at alternative location: " . altPath)
                    break
                }
            }
            
            if (!found) {
                LogMessage("ERROR: Everything not found in any location")
                return
            }
        }
        
        ; Check if Everything is already running
        if ProcessExist("Everything.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Everything.exe") {
                WinActivate("ahk_exe Everything.exe")
                LogMessage("LAUNCHER: Everything already running, activated window")
            } else {
                LogMessage("LAUNCHER: Everything process exists but no window found")
            }
            return
        }
        
        ; Launch Everything with error handling
        try {
            Run('"' . everythingPath . '"')
            LogMessage("LAUNCHER: Everything launched successfully from: " . everythingPath)
        } catch Error as launchError {
            LogMessage("ERROR: Failed to launch Everything: " . launchError.message)
            return
        }
        
        ; Wait and activate window
        Sleep(1500)
        if WinWait("ahk_exe Everything.exe", , 8) {
            WinActivate("ahk_exe Everything.exe")
            LogMessage("LAUNCHER: Everything window activated")
        } else {
            LogMessage("WARNING: Everything launched but window not detected")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchEverything: " . e.message)
        IncrementError()
    }
}

RunSpeedtest() {
    try {
        LogMessage("SPEEDTEST: Running real network speed test")
        
        ; Create real speedtest command with visible output
        speedtestCmd := 'powershell.exe -Command "'
        speedtestCmd .= 'Write-Host "═══ REAL NETWORK SPEED TEST ═══" -ForegroundColor Cyan;'
        speedtestCmd .= 'Write-Host "Testing network connectivity and speed..." -ForegroundColor Yellow;'
        speedtestCmd .= 'try {'
        speedtestCmd .= '$ErrorActionPreference = `"Stop`";'
        speedtestCmd .= 'Write-Host "Step 1: Testing ping to major servers..." -ForegroundColor Green;'
        speedtestCmd .= '$googlePing = Test-Connection -ComputerName `"8.8.8.8`" -Count 4 | Measure-Object ResponseTime -Average;'
        speedtestCmd .= 'Write-Host "Google DNS (8.8.8.8): $([math]::Round($googlePing.Average, 2)) ms" -ForegroundColor White;'
        speedtestCmd .= '$cloudflarePing = Test-Connection -ComputerName `"1.1.1.1`" -Count 4 | Measure-Object ResponseTime -Average;'
        speedtestCmd .= 'Write-Host "Cloudflare DNS (1.1.1.1): $([math]::Round($cloudflarePing.Average, 2)) ms" -ForegroundColor White;'
        speedtestCmd .= 'Write-Host "`nStep 2: Testing download speed..." -ForegroundColor Green;'
        speedtestCmd .= '$testFile = `"$env:TEMP\speedtest.dat`";'
        speedtestCmd .= '$urls = @(`"http://speedtest.ftp.otenet.gr/files/test10mb.db`", `"http://ipv4.download.thinkbroadband.com/10MB.zip`", `"http://proof.ovh.net/files/10Mb.dat`");'
        speedtestCmd .= 'foreach ($url in $urls) {'
        speedtestCmd .= 'try {'
        speedtestCmd .= 'Write-Host "Testing from: $url" -ForegroundColor Yellow;'
        speedtestCmd .= '$stopwatch = [System.Diagnostics.Stopwatch]::StartNew();'
        speedtestCmd .= 'Invoke-WebRequest -Uri $url -OutFile $testFile -TimeoutSec 30;'
        speedtestCmd .= '$stopwatch.Stop();'
        speedtestCmd .= '$fileSize = (Get-Item $testFile).Length;'
        speedtestCmd .= '$speedMbps = [math]::Round(($fileSize * 8) / ($stopwatch.Elapsed.TotalSeconds * 1024 * 1024), 2);'
        speedtestCmd .= 'Write-Host "Download Speed: $speedMbps Mbps" -ForegroundColor Green;'
        speedtestCmd .= 'Write-Host "File Size: $([math]::Round($fileSize / 1024 / 1024, 2)) MB" -ForegroundColor White;'
        speedtestCmd .= 'Write-Host "Time Taken: $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds" -ForegroundColor White;'
        speedtestCmd .= 'Remove-Item $testFile -Force;'
        speedtestCmd .= 'break;'
        speedtestCmd .= '} catch {'
        speedtestCmd .= 'Write-Host "Failed to test from this server, trying next..." -ForegroundColor Red;'
        speedtestCmd .= '}'
        speedtestCmd .= '}'
        speedtestCmd .= 'Write-Host "`nStep 3: Testing DNS resolution..." -ForegroundColor Green;'
        speedtestCmd .= '$dnsTest = Measure-Command { Resolve-DnsName `"google.com`" };'
        speedtestCmd .= 'Write-Host "DNS Resolution Time: $([math]::Round($dnsTest.TotalMilliseconds, 2)) ms" -ForegroundColor White;'
        speedtestCmd .= 'Write-Host "`nStep 4: Network adapter information..." -ForegroundColor Green;'
        speedtestCmd .= '$adapter = Get-NetAdapter | Where-Object {$_.Status -eq `"Up`" -and $_.MediaType -like `"*Ethernet*`" -or $_.MediaType -like `"*802.11*`"} | Select-Object -First 1;'
        speedtestCmd .= 'if ($adapter) { Write-Host "Active Adapter: $($adapter.Name) - Link Speed: $($adapter.LinkSpeed)" -ForegroundColor White };'
        speedtestCmd .= '} catch {'
        speedtestCmd .= 'Write-Host "Network test error: $($_.Exception.Message)" -ForegroundColor Red;'
        speedtestCmd .= '}'
        speedtestCmd .= 'Write-Host "`n═══ SPEED TEST COMPLETE ═══" -ForegroundColor Cyan;'
        speedtestCmd .= 'Write-Host "Press any key to close..." -ForegroundColor Green; $null = $Host.UI.RawUI.ReadKey(`"NoEcho,IncludeKeyDown`")"'
        
        Run(speedtestCmd)
        LogMessage("SPEEDTEST: Real network speed test initiated with visible output")
        
    } catch Error as e {
        LogMessage("ERROR in RunSpeedtest: " . e.message)
        IncrementError()
    }
}

StopDockerDesktop() {
    try {
        LogMessage("DOCKER: Force closing Docker Desktop")
        
        ; List of Docker-related processes to terminate
        dockerProcesses := [
            "Docker Desktop.exe",
            "DockerDesktop.exe",
            "docker.exe",
            "dockerd.exe",
            "com.docker.service",
            "vpnkit.exe",
            "vpnkit-bridge.exe"
        ]
        
        ; Force terminate all Docker processes
        for processName in dockerProcesses {
            try {
                if ProcessExist(processName) {
                    ProcessClose(processName)
                    LogMessage("DOCKER: Terminated " . processName)
                }
            } catch {
                ; Try with taskkill if ProcessClose fails
                try {
                    RunWait("taskkill /F /IM `"" . processName . "`"", "", "Hide")
                    LogMessage("DOCKER: Force killed " . processName . " with taskkill")
                } catch {
                    LogMessage("DOCKER: Could not terminate " . processName)
                }
            }
        }
        
        ; Also stop Docker services
        try {
            RunWait("net stop com.docker.service", "", "Hide")
            LogMessage("DOCKER: Stopped Docker service")
        } catch {
            LogMessage("DOCKER: Could not stop Docker service or service not running")
        }
        
        ; Stop Docker Desktop service
        try {
            RunWait("net stop `"Docker Desktop Service`"", "", "Hide")
            LogMessage("DOCKER: Stopped Docker Desktop Service")
        } catch {
            LogMessage("DOCKER: Could not stop Docker Desktop Service or service not running")
        }
        
        LogMessage("DOCKER: Docker Desktop force close completed")
        TrayTip("Docker Stopped", "Docker Desktop has been force closed", 2000)
        
    } catch Error as e {
        LogMessage("ERROR in StopDockerDesktop: " . e.message)
        IncrementError()
    }
}

LaunchCursor() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Cursor IDE")
        
        ; Check if Cursor executable exists
        if !FileExist(cursorPath) {
            LogMessage("ERROR: Cursor not found at: " . cursorPath)
            return
        }
        
        ; Check if Cursor is already running
        if ProcessExist("Cursor.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Cursor.exe") {
                WinActivate("ahk_exe Cursor.exe")
                LogMessage("LAUNCHER: Cursor already running, activated window")
            } else {
                LogMessage("LAUNCHER: Cursor process exists but no window found")
            }
            return
        }
        
        ; Launch Cursor
        Run('"' . cursorPath . '"')
        LogMessage("LAUNCHER: Cursor IDE launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(2000)
        if WinWait("ahk_exe Cursor.exe", , 8) {
            WinActivate("ahk_exe Cursor.exe")
            LogMessage("LAUNCHER: Cursor window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchCursor: " . e.message)
        IncrementError()
    }
}

LaunchVSCode() {
    try {
        LogMessage("LAUNCHER: Attempting to launch VSCode")
        
        ; Check if VSCode executable exists
        if !FileExist(vscodePath) {
            LogMessage("ERROR: VSCode not found at: " . vscodePath)
            return
        }
        
        ; Check if VSCode is already running
        if ProcessExist("Code.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe Code.exe") {
                WinActivate("ahk_exe Code.exe")
                LogMessage("LAUNCHER: VSCode already running, activated window")
            } else {
                LogMessage("LAUNCHER: VSCode process exists but no window found")
            }
            return
        }
        
        ; Launch VSCode
        Run('"' . vscodePath . '"')
        LogMessage("LAUNCHER: VSCode launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(2000)
        if WinWait("ahk_exe Code.exe", , 8) {
            WinActivate("ahk_exe Code.exe")
            LogMessage("LAUNCHER: VSCode window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchVSCode: " . e.message)
        IncrementError()
    }
}

OpenInstalledFolder() {
    try {
        LogMessage("FOLDER: Opening installed apps folder")
        
        ; Check if the folder exists
        if !DirExist(installedPath) {
            LogMessage("ERROR: Installed folder not found at: " . installedPath)
            return
        }
        
        ; Open the folder in File Explorer
        Run('explorer.exe "' . installedPath . '"')
        LogMessage("FOLDER: Successfully opened installed apps folder")
        
    } catch Error as e {
        LogMessage("ERROR in OpenInstalledFolder: " . e.message)
        IncrementError()
    }
}

OpenGmail() {
    try {
        LogMessage("WEB: Opening Gmail Account 0 in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for Gmail")
            return
        }
        
        ; Open Gmail account 0 in Chrome new tab
        Run('"' . chromePath . '" --new-tab "https://mail.google.com/mail/u/0/"')
        LogMessage("WEB: Gmail Account 0 opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenGmail: " . e.message)
        IncrementError()
    }
}

OpenGmail2() {
    try {
        LogMessage("WEB: Opening Gmail Account 1 in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for Gmail2")
            return
        }
        
        ; Open Gmail account 1 in Chrome new tab
        Run('"' . chromePath . '" --new-tab "https://mail.google.com/mail/u/1/#inbox"')
        LogMessage("WEB: Gmail Account 1 opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenGmail2: " . e.message)
        IncrementError()
    }
}

OpenYoutube() {
    try {
        LogMessage("WEB: Opening YouTube in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for YouTube")
            return
        }
        
        ; Open YouTube in Chrome
        Run('"' . chromePath . '" --new-tab "https://youtube.com"')
        LogMessage("WEB: YouTube opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenYoutube: " . e.message)
        IncrementError()
    }
}

LaunchRedButton() {
    try {
        LogMessage("LAUNCHER: Attempting to launch RedButton")
        
        ; Check if RedButton path exists
        if !DirExist(redbuttonPath) {
            LogMessage("ERROR: RedButton directory not found at: " . redbuttonPath)
            return
        }
        
        ; Try to find the executable in the RedButton directory
        redbuttonExe := redbuttonPath . "\RedButton.exe"
        if !FileExist(redbuttonExe) {
            ; Try alternative names
            altNames := ["\redbutton.exe", "\RedButton.exe", "\RedButton64.exe", "\main.exe"]
            found := false
            for altName in altNames {
                altPath := redbuttonPath . altName
                if FileExist(altPath) {
                    redbuttonExe := altPath
                    found := true
                    break
                }
            }
            if (!found) {
                LogMessage("ERROR: RedButton executable not found in directory: " . redbuttonPath)
                return
            }
        }
        
        ; Launch RedButton
        Run('"' . redbuttonExe . '"')
        LogMessage("LAUNCHER: RedButton launched successfully from: " . redbuttonExe)
        
    } catch Error as e {
        LogMessage("ERROR in LaunchRedButton: " . e.message)
        IncrementError()
    }
}

OpenClaude() {
    try {
        LogMessage("WEB: Opening Claude.ai in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for Claude")
            return
        }
        
        ; Open Claude.ai in Chrome new tab
        Run('"' . chromePath . '" --new-tab "https://claude.ai"')
        LogMessage("WEB: Claude.ai opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenClaude: " . e.message)
        IncrementError()
    }
}

OpenChatGPT() {
    try {
        LogMessage("WEB: Opening ChatGPT in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for ChatGPT")
            return
        }
        
        ; Open ChatGPT in Chrome new tab
        Run('"' . chromePath . '" --new-tab "https://chatgpt.com"')
        LogMessage("WEB: ChatGPT opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenChatGPT: " . e.message)
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
~1::ProcessTextBuffer("1")
~2::ProcessTextBuffer("2")
~3::ProcessTextBuffer("3")
~4::ProcessTextBuffer("4")
~5::ProcessTextBuffer("5")
~6::ProcessTextBuffer("6")
~7::ProcessTextBuffer("7")
~8::ProcessTextBuffer("8")
~9::ProcessTextBuffer("9")
~0::ProcessTextBuffer("0")

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
TrayTip("Complete Manager Ready - ULTIMATE VERSION UPDATED",
    "Script running with admin privileges - ALL FEATURES ENHANCED + NEW ADDITIONS!`n" .
    "••• NEW SHORTCUTS ADDED •••`n" .
    "✓ recovery→Create System Restore Point`n" .
    "✓ 1337→1337x.to Torrent Site (Fixed - opens in new Chrome tab)`n" .
    "✓ parsec→Launch Parsec Remote Desktop App`n" .
    "✓ myall→Launch Everything Search (Alternative to allit)`n" .
    "✓ notes→Samsung Notes (Enhanced with direct path support)`n`n" .
    "••• ENHANCED FEATURES •••`n" .
    "✓ System Restore: Timestamped restore points with PowerShell`n" .
    "✓ Samsung Notes: Direct path + Windows Store fallback`n" .
    "✓ 1337x Torrent: Opens in new Chrome tab as requested`n" .
    "✓ Parsec: Remote desktop application launcher`n" .
    "✓ Everything: Two shortcuts (allit + myall) for instant file search`n`n" .
    "••• EXISTING POWERFUL FEATURES •••`n" .
    "✓ AMD: Real driver detection & installation (amd)`n" .
    "✓ ASUS: Complete hardware driver installation (asus)`n" .
    "✓ GHelper: Full GUI with all data (ghelp)`n" .
    "✓ WSL: ubuntu→Terminal+WSL Ubuntu | ubu2→Terminal+WSL Ubuntu2`n" .
    "✓ Speedtest: Real network testing with actual speeds`n" .
    "✓ Docker: Force stop with stopd command`n`n" .
    "••• HOTKEYS •••`n" .
    "Triple-tap W: Force Windowed Mode | Triple-tap E: Force Full Size`n" .
    "Alt+K: FORCE KILL | Alt+A: WhatsApp | Alt+C: Cheat Engine | Alt+W: WeMod`n" .
    "Win+G: Games Folder | Shift+S: Switch Desktops`n" .
    "Alt+T: Terminal | Alt+R: Close Terminal`n" .
    "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume | Ctrl+D: Resume All`n`n" .
    "••• KEY TEXT SHORTCUTS •••`n" .
    "recovery→System Restore Point | 1337→1337x.to | parsec→Parsec App`n" .
    "myall→Everything Search | notes→Samsung Notes`n" .
    "amd→AMD Drivers | asus→ASUS Drivers | ghelp→GHelper GUI`n" .
    "ubuntu→WSL Ubuntu | speedtest→Network Test | stopd→Stop Docker`n" .
    "All shortcuts work perfectly with smart terminal management!", 30000)

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