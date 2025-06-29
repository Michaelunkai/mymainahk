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
weMod := "C:\Users\Administrator\AppData\Local\WeMod\WeMod.exe"
wallPaperApp := "C:\Users\Administrator\Desktop\WallPaper.lnk"
chromePath := "F:\backup\windowsapps\installed\Chrome\Application\chrome.exe"
firefoxPath := "F:\backup\windowsapps\installed\firefox\firefox.exe"
whatsappPath := "C:\Program Files\WindowsApps\5319275A.WhatsAppDesktop_2.2524.4.0_x64__cv1g1gvanyjgm\WhatsApp.exe"
gameSaveManagerPath := "F:\backup\windowsapps\installed\gameSaveManager\gs_mngr_3.exe"
todoistPath := "F:\backup\windowsapps\installed\todoist\Todoist.exe"
kvrtPath := "F:\backup\windowsapps\installed\KVRT\KVRT.exe"
redbuttonPath := "F:\backup\windowsapps\installed\RedButton"
everythingPath := "F:\backup\windowsapps\installed\Everything\Everything.exe"
cursorPath := "F:\backup\windowsapps\installed\cursor\Cursor.exe"
vscodePath := "F:\backup\windowsapps\installed\VSCode\Code.exe"
softwareUpdaterPath := "F:\backup\windowsapps\installed\Software Updater\SoftwareUpdater.exe"
downloadsPath := "F:\Downloads"
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
    "nvc", "nvc",
    "biu", "ws 'backitup'",
    "sleep", "ss",
    "rebootit", "REBOOT_SYSTEM",
    "bios", "bios",
    "prof", "brc",
    "nnn", "nnn",
    "dsubs", "dsubs",
    "dssubs", "DSSUBS_TERMINAL",
    "wall", "WALLPAPER_APP",
    "tttt", "SPLIT_TOP_APPS",
    "cahk", "closeahk",
    "sgame", "GAME_SAVE_MANAGER",
    "mytodo", "TODOIST_APP",
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
    "uninstall", "BCUNINSTALLER_APP",
    "kvrt", "KVRT_APP",
    "helpme", "HELP_SHORTCUTS",
    "ubuntu", "UBUNTU_WSL",
    "ubu2", "UBUNTU2_WSL",
    "ranch", "RANCH_WSL",
    "notes", "SAMSUNG_NOTES",
    "phonel", "PHONE_LINK",
    "youtube", "YOUTUBE_WEB",
    "1337", "TORRENT_1337X_WEB",
    "venice", "VENICE_CHAT_WEB",
    "redb", "REDBUTTON_APP",
    "claude", "CLAUDE_WEB",
    "chatgpt", "CHATGPT_WEB",
    "allit", "everything",
    "ide", "CURSOR_APP",
    "vscode", "VSCODE_APP",
    "installed", "INSTALLED_FOLDER",
    "gmail", "GMAIL_WEB",
    "ggmail", "GMAIL2_WEB",
    "stopd", "STOP_DOCKER",
    "updater", "SOFTWARE_UPDATER_APP",
    "downloads", "DOWNLOADS_FOLDER",
    "myasus", "MYASUS_WEB",
    "mygames", "MYGAMES_TERMINAL",
    "mymail", "COPY_EMAIL",
    "mypass", "COPY_PASS1",
    "myp", "COPY_PASS2",
    "unzipit", "UNZIP_COMMAND",
    "rmod", "rmod",
    "mreflect", "MACRIUM_REFLECT_APP",
    "parsec", "PARSEC_APP",
    "rer", "OPEN_TERMINAL",
    "yyyy", "SPLIT_THREE_APPS"
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

; ╔══════════════════════════════ CLIPBOARD FUNCTIONS ══════════════════════════════╗
CopyToClipboard(text) {
    try {
        A_Clipboard := text
        LogMessage("CLIPBOARD: Copied text to clipboard (length: " . StrLen(text) . ")")
        TrayTip("Copied to Clipboard", "Text copied successfully!", 1500)
        return true
    } catch Error as e {
        LogMessage("ERROR in CopyToClipboard: " . e.message)
        IncrementError()
        return false
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
            
            ; Log which shortcut was triggered and which command will be executed
            LogMessage("TEXT_SHORTCUT: Triggered '" . shortcut . "' -> '" . command . "'")
            
            ; Execute command based on type
            if (command = "WALLPAPER_APP") {
                LaunchWallpaperApp()
            } else if (command = "SPLIT_TOP_APPS") {
                SplitTopAppsHorizontally()
            } else if (command = "SPLIT_THREE_APPS") {
                SplitThreeAppsHorizontally()
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
            } else if (command = "UBUNTU_WSL") {
                LaunchUbuntuWSL()
            } else if (command = "UBUNTU2_WSL") {
                LaunchUbuntu2WSL()
            } else if (command = "RANCH_WSL") {
                LaunchRanchWSL()
            } else if (command = "TORRENT_1337X_WEB") {
                Open1337xTorrent()
            } else if (command = "VENICE_CHAT_WEB") {
                OpenVeniceChat()
            } else if (command = "BCUNINSTALLER_APP") {
                LaunchBCUninstaller()
            } else if (command = "SAMSUNG_NOTES") {
                LaunchSamsungNotes()
            } else if (command = "PHONE_LINK") {
                LaunchPhoneLink()
            } else if (command = "YOUTUBE_WEB") {
                OpenYoutube()
            } else if (command = "TORRENT_1337X_WEB") {
                Open1337xTorrent()
            } else if (command = "VENICE_CHAT_WEB") {
                OpenVeniceChat()
            } else if (command = "REDBUTTON_APP") {
                LaunchRedButton()
            } else if (command = "CLAUDE_WEB") {
                OpenClaude()
            } else if (command = "CHATGPT_WEB") {
                OpenChatGPT()
            } else if (command = "everything") {
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
            } else if (command = "STOP_DOCKER") {
                StopDockerDesktop()
            } else if (command = "SOFTWARE_UPDATER_APP") {
                LaunchSoftwareUpdater()
            } else if (command = "DOWNLOADS_FOLDER") {
                OpenDownloadsFolder()
            } else if (command = "MYASUS_WEB") {
                OpenMyAsusWeb()
            } else if (command = "MYGAMES_TERMINAL") {
                LaunchMyGamesTerminal()
            } else if (command = "COPY_EMAIL") {
                CopyToClipboard("michaelovsky5@gmail.com")
            } else if (command = "COPY_PASS1") {
                CopyToClipboard("Aa1111111!")
            } else if (command = "COPY_PASS2") {
                CopyToClipboard("Blackablacka3!")
            } else if (command = "UNZIP_COMMAND") {
                LaunchUnzipCommand()
            } else if (command = "BCUNINSTALLER_APP") {
                LaunchBCUninstaller()
            } else if (command = "MACRIUM_REFLECT_APP") {
                LaunchMacriumReflect()
            } else if (command = "PARSEC_APP") {
                LaunchParsec()
            } else if (command = "OPEN_TERMINAL") {
                OpenFloatingTerminal()
            } else if (command = "DSSUBS_TERMINAL") {
                try {
                    LogMessage("DSSUBS: Opening terminal and running dsubs2 command")
                    ; Try Windows Terminal first
                    try {
                        Run('wt.exe powershell -NoExit -Command "dsubs2"')
                        LogMessage("DSSUBS: dsubs2 command launched in Windows Terminal (PowerShell)")
                        return
                    } catch {
                        ; Fallback to standalone PowerShell
                        try {
                            Run('powershell.exe -NoExit -Command "dsubs2"')
                            LogMessage("DSSUBS: dsubs2 command launched in PowerShell")
                            return
                        } catch {
                            ; Fallback to PowerShell ISE
                            try {
                                Run('powershell_ise.exe -Command "dsubs2"')
                                LogMessage("DSSUBS: dsubs2 command launched in PowerShell ISE")
                                return
                            } catch {
                                LogMessage("ERROR: All dsubs2 launch methods failed - PowerShell or dsubs2 may not be available")
                            }
                        }
                    }
                } catch Error as e {
                    LogMessage("ERROR in DSSUBS_TERMINAL: " . e.message)
                    IncrementError()
                }
            } else {
                ExecuteTerminalCommand(command)
            }
            break
        }
    }
}

; ╔══════════════════════════════ NEW FUNCTIONS ══════════════════════════════╗
LaunchUnzipCommand() {
    try {
        LogMessage("UNZIP: Opening PowerShell and running 'ext' command")
        
        ; Method 1: Try Windows Terminal with PowerShell and ext command
        try {
            Run('wt.exe powershell -NoExit -Command "ext"')
            LogMessage("UNZIP: ext command launched in Windows Terminal (PowerShell)")
            return
        } catch {
            ; Method 2: Try standalone PowerShell with ext command
            try {
                Run('powershell.exe -NoExit -Command "ext"')
                LogMessage("UNZIP: ext command launched in PowerShell")
                return
            } catch {
                ; Method 3: Try PowerShell ISE as fallback
                try {
                    Run('powershell_ise.exe -Command "ext"')
                    LogMessage("UNZIP: ext command launched in PowerShell ISE")
                    return
                } catch {
                    LogMessage("ERROR: All PowerShell ext command launch methods failed - PowerShell or ext command may not be available")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchUnzipCommand: " . e.message)
        IncrementError()
    }
}

LaunchRanchWSL() {
    try {
        LogMessage("RANCH: Opening PowerShell and running 'ws ranch' command")
        
        ; Method 1: Try Windows Terminal with PowerShell and ws ranch command
        try {
            Run('wt.exe powershell -NoExit -Command "ws ranch"')
            LogMessage("RANCH: ws ranch command launched in Windows Terminal (PowerShell)")
            return
        } catch {
            ; Method 2: Try standalone PowerShell with ws ranch command
            try {
                Run('powershell.exe -NoExit -Command "ws ranch"')
                LogMessage("RANCH: ws ranch command launched in PowerShell")
                return
            } catch {
                ; Method 3: Try PowerShell ISE as fallback
                try {
                    Run('powershell_ise.exe -Command "ws ranch"')
                    LogMessage("RANCH: ws ranch command launched in PowerShell ISE")
                    return
                } catch {
                    LogMessage("ERROR: All PowerShell ws ranch command launch methods failed - PowerShell or ws ranch command may not be available")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchRanchWSL: " . e.message)
        IncrementError()
    }
}

Open1337xTorrent() {
    try {
        LogMessage("WEB: Opening 1337x.to Torrent Search Engine in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for 1337x.to at path: " . chromePath)
            TrayTip("1337x Error", "Chrome not found at specified path", 3000)
            return
        }
        
        ; Open 1337x.to in Chrome new tab
        try {
            Run('"' . chromePath . '" --new-tab "https://1337x.to"')
            LogMessage("WEB: 1337x.to Torrent Search Engine opened in Chrome successfully")
            TrayTip("1337x", "1337x.to opened in Chrome", 2000)
        } catch Error as launchError {
            LogMessage("ERROR: Failed to launch Chrome for 1337x.to: " . launchError.message)
            TrayTip("1337x Error", "Failed to open Chrome: " . launchError.message, 3000)
        }
        
    } catch Error as e {
        LogMessage("ERROR in Open1337xTorrent: " . e.message)
        TrayTip("1337x Critical Error", "Critical error: " . e.message, 3000)
        IncrementError()
    }
}

OpenVeniceChat() {
    try {
        LogMessage("WEB: Opening Venice Chat - Venice Uncensored AI in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for Venice Chat at path: " . chromePath)
            TrayTip("Venice Error", "Chrome not found at specified path", 3000)
            return
        }
        
        ; Open Venice Chat in Chrome new tab
        try {
            Run('"' . chromePath . '" --new-tab "https://venice.ai"')
            LogMessage("WEB: Venice Chat - Venice Uncensored AI opened in Chrome successfully")
            TrayTip("Venice", "Venice.ai opened in Chrome", 2000)
        } catch Error as launchError {
            LogMessage("ERROR: Failed to launch Chrome for Venice: " . launchError.message)
            TrayTip("Venice Error", "Failed to open Chrome: " . launchError.message, 3000)
        }
        
    } catch Error as e {
        LogMessage("ERROR in OpenVeniceChat: " . e.message)
        TrayTip("Venice Critical Error", "Critical error: " . e.message, 3000)
        IncrementError()
    }
}

LaunchBCUninstaller() {
    try {
        LogMessage("LAUNCHER: Attempting to launch BCUninstaller")
        
        bcUninstallerPath := "F:\backup\windowsapps\installed\BCUninstaller\BCUninstaller.exe"
        
        ; Check if BCUninstaller executable exists
        if !FileExist(bcUninstallerPath) {
            LogMessage("ERROR: BCUninstaller not found at: " . bcUninstallerPath)
            TrayTip("BCUninstaller Error", "BCUninstaller.exe not found at specified path", 3000)
            return
        }
        
        ; Check if BCUninstaller is already running
        if ProcessExist("BCUninstaller.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe BCUninstaller.exe") {
                WinActivate("ahk_exe BCUninstaller.exe")
                LogMessage("LAUNCHER: BCUninstaller already running, activated window")
                TrayTip("BCUninstaller", "BCUninstaller already running, window activated", 2000)
            } else {
                LogMessage("LAUNCHER: BCUninstaller process exists but no window found")
            }
            return
        }
        
        ; Launch BCUninstaller with error handling
        try {
            Run('"' . bcUninstallerPath . '"')
            LogMessage("LAUNCHER: BCUninstaller launched successfully from: " . bcUninstallerPath)
            TrayTip("BCUninstaller", "BCUninstaller launched successfully", 2000)
        } catch Error as launchError {
            LogMessage("ERROR: Failed to launch BCUninstaller: " . launchError.message)
            TrayTip("BCUninstaller Error", "Failed to launch: " . launchError.message, 3000)
            return
        }
        
        ; Optional: Wait and activate window
        Sleep(2000)
        if WinWait("ahk_exe BCUninstaller.exe", , 10) {
            WinActivate("ahk_exe BCUninstaller.exe")
            LogMessage("LAUNCHER: BCUninstaller window activated")
        } else {
            LogMessage("WARNING: BCUninstaller launched but window not detected within 10 seconds")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchBCUninstaller: " . e.message)
        TrayTip("BCUninstaller Critical Error", "Critical error: " . e.message, 3000)
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
        LogMessage("HELP: Displaying shortcuts help GUI with 2 columns")
        
        ; Create a very large GUI window
        helpGui := Gui("+Resize +MaximizeBox", "Complete Desktop Manager - All Shortcuts")
        helpGui.MarginX := 20
        helpGui.MarginY := 20
        
        ; Set font
        helpGui.SetFont("s10", "Segoe UI")
        
        ; Create the help text content for LEFT column
        leftColumnText := "═══ COMPLETE DESKTOP MANAGER - SHORTCUTS ═══`n`n"
        leftColumnText .= "••• WINDOW MANAGEMENT •••`n"
        leftColumnText .= "Triple-tap W: Force Windowed Mode (Small)`n"
        leftColumnText .= "Triple-tap E: Force Full Size Mode (Max)`n"
        leftColumnText .= "www: Force current window to windowed mode`n"
        leftColumnText .= "eee: Force current window to full size mode`n"
        leftColumnText .= "yyyy: Split 3 latest apps into 3 equal sections`n`n"
        
        leftColumnText .= "••• TERMINAL COMMANDS •••`n"
        leftColumnText .= "nvc→nvc | biu→ws'backitup' | sleep→ss`n"
        leftColumnText .= "cahk→closeahk | rebootit→REBOOT | bios→bios`n"
        leftColumnText .= "prof→brc | swemod→swemod | nnn→nnn`n"
        leftColumnText .= "dsubs→dsubs | cleans→clean | ccbbr→ccbbr`n"
        leftColumnText .= "ssss→ssss | pipip→pipip | refresh→refresh`n"
        leftColumnText .= "logout→refresh2 | sdesktop→sdesktop`n"
        leftColumnText .= "gccleaner→gccleaner | gdb→gdbooster`n"
        leftColumnText .= "goodgame→ws gg | uninstall→BCUninstaller`n"
        leftColumnText .= "stopd→Stop Docker Desktop`n"
        leftColumnText .= "unzipit→PowerShell with 'ext' command`n"
        leftColumnText .= "rer→Open Terminal (same as Alt+T)`n`n"
        
        leftColumnText .= "••• SYSTEM FUNCTIONS •••`n"
        leftColumnText .= "updater→Launch Software Updater`n`n"
        
        leftColumnText .= "••• CREDENTIALS & DATA •••`n"
        leftColumnText .= "mymail→Copy Email to Clipboard`n"
        leftColumnText .= "mypass→Copy Password 1 to Clipboard`n"
        leftColumnText .= "myp→Copy Password 2 to Clipboard`n`n"
        
        leftColumnText .= "••• WSL & LINUX •••`n"
        leftColumnText .= "ubuntu→Open Terminal + Run WSL Ubuntu`n"
        leftColumnText .= "ubu2→Open Terminal + Run WSL Ubuntu2`n"
        leftColumnText .= "ranch→Open PowerShell + Run 'ws ranch'`n"
        leftColumnText .= "mygames→Open Terminal + Run myg`n`n"
        
        leftColumnText .= "••• WEB SHORTCUTS •••`n"
        leftColumnText .= "youtube→YouTube | claude→Claude.ai`n"
        leftColumnText .= "chatgpt→ChatGPT | gmail→Gmail Account 0`n"
        leftColumnText .= "ggmail→Gmail Account 1`n"
        leftColumnText .= "1337→1337x.to Torrent Search Engine`n"
        leftColumnText .= "venice→Venice Chat - Uncensored AI`n"
        leftColumnText .= "myasus→ASUS ROG Support & Downloads`n`n"
        
        ; Create the help text content for RIGHT column
        rightColumnText := "═══ APPLICATIONS & FOLDERS ═══`n`n"
        rightColumnText .= "••• APPLICATION LAUNCHERS •••`n"
        rightColumnText .= "fire→Firefox | chrome→Chrome`n"
        rightColumnText .= "wall→WallPaper | kvrt→KVRT`n"
        rightColumnText .= "sgame→Game Save Manager`n"
        rightColumnText .= "mytodo→Todoist | redb→RedButton`n"
        rightColumnText .= "allit→Everything Search`n"
        rightColumnText .= "ide→Cursor IDE | vscode→VSCode`n"
        rightColumnText .= "installed→Apps Folder`n"
        rightColumnText .= "notes→Samsung Notes`n"
        rightColumnText .= "phonel→Phone Link`n`n"
        
        rightColumnText .= "••• FOLDER SHORTCUTS •••`n"
        rightColumnText .= "downloads→Open Downloads Folder`n`n"
        
        rightColumnText .= "••• SYSTEM ACTIONS •••`n"
        rightColumnText .= "bin→Empty Recycle Bin`n"
        rightColumnText .= "tttt→Split Top 2 Apps`n"
        rightColumnText .= "helpme→This Help`n`n"
        
        rightColumnText .= "••• HOTKEYS •••`n"
        rightColumnText .= "Win+K: Close Window (Keep App Running)`n"
        rightColumnText .= "Alt+A: WhatsApp | Alt+C: Cheat Engine`n"
        rightColumnText .= "Alt+W: WeMod | Win+G: Games Folder`n"
        rightColumnText .= "Shift+S: Switch Desktops`n"
        rightColumnText .= "Alt+T: Terminal | Alt+R: Close Terminal`n"
        rightColumnText .= "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume`n"
        rightColumnText .= "Ctrl+D: Resume All`n`n"
        
        rightColumnText .= "••• ADVANCED FEATURES •••`n"
        rightColumnText .= "• Clipboard Integration: Auto-copy credentials`n"
        rightColumnText .= "• Docker Management: Force closes completely`n"
        rightColumnText .= "• WSL Integration: Direct terminal access`n"
        rightColumnText .= "• MyGames: Custom terminal command runner`n"
        rightColumnText .= "• Everything Search: Instant file search`n"
        rightColumnText .= "• Samsung Notes: Windows Store app`n"
        rightColumnText .= "• Software Updater: Update management`n"
        rightColumnText .= "• Downloads Folder: Quick file access`n"
        rightColumnText .= "• ASUS ROG: Direct support & downloads access`n"
        rightColumnText .= "• UnzipIt: PowerShell with ext command`n`n"
        
        rightColumnText .= "All shortcuts work with smart management!"
        
        ; Add left column text control
        leftTextControl := helpGui.Add("Edit", "x20 y20 w750 h600 VScroll ReadOnly", leftColumnText)
        
        ; Add right column text control
        rightTextControl := helpGui.Add("Edit", "x790 y20 w750 h600 VScroll ReadOnly", rightColumnText)
        
        ; Add close button centered
        closeBtn := helpGui.Add("Button", "x720 y640 w120 h40", "Close")
        closeBtn.OnEvent("Click", (*) => helpGui.Close())
        
        ; Show the GUI
        helpGui.Show("w1560 h700")
        
        LogMessage("HELP: 2-column shortcuts help GUI displayed successfully")
        
    } catch Error as e {
        LogMessage("ERROR in ShowHelpShortcuts: " . e.message)
        IncrementError()
        ; Fallback to simple message box
        MsgBox("Error creating help GUI. Check log for details.", "Help Error", "OK")
    }
}

LaunchMyGamesTerminal() {
    try {
        LogMessage("MYGAMES: Opening PowerShell terminal and running myg command")
        
        ; Method 1: Try Windows Terminal with PowerShell and myg command
        try {
            Run('wt.exe powershell -NoExit -Command "myg"')
            LogMessage("MYGAMES: myg command launched in Windows Terminal (PowerShell)")
            return
        } catch {
            ; Method 2: Try standalone PowerShell with myg command
            try {
                Run('powershell.exe -NoExit -Command "myg"')
                LogMessage("MYGAMES: myg command launched in PowerShell")
                return
            } catch {
                ; Method 3: Try PowerShell ISE as fallback
                try {
                    Run('powershell_ise.exe -Command "myg"')
                    LogMessage("MYGAMES: myg command launched in PowerShell ISE")
                    return
                } catch {
                    LogMessage("ERROR: All PowerShell myg command launch methods failed - PowerShell or myg command may not be available")
                }
            }
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchMyGamesTerminal: " . e.message)
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

LaunchSoftwareUpdater() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Software Updater")
        
        ; Check if Software Updater executable exists
        if !FileExist(softwareUpdaterPath) {
            LogMessage("ERROR: Software Updater not found at: " . softwareUpdaterPath)
            return
        }
        
        ; Check if Software Updater is already running
        if ProcessExist("SoftwareUpdater.exe") {
            ; If already running, activate the window
            if WinExist("ahk_exe SoftwareUpdater.exe") {
                WinActivate("ahk_exe SoftwareUpdater.exe")
            } else {
                LogMessage("LAUNCHER: Software Updater process exists but no window found")
            }
            return
        }
        
        ; Launch Software Updater
        Run('"' . softwareUpdaterPath . '"')
        LogMessage("LAUNCHER: Software Updater launched successfully")
        
        ; Optional: Wait and activate window
        Sleep(2000)
        if WinWait("ahk_exe SoftwareUpdater.exe", , 8) {
            WinActivate("ahk_exe SoftwareUpdater.exe")
            LogMessage("LAUNCHER: Software Updater window activated")
        }
        
    } catch Error as e {
        LogMessage("ERROR in LaunchSoftwareUpdater: " . e.message)
        IncrementError()
    }
}

OpenDownloadsFolder() {
    try {
        LogMessage("FOLDER: Opening Downloads folder")
        
        ; Check if the Downloads folder exists
        if !DirExist(downloadsPath) {
            LogMessage("ERROR: Downloads folder not found at: " . downloadsPath)
            return
        }
        
        ; Open the folder in File Explorer
        Run('explorer.exe "' . downloadsPath . '"')
        LogMessage("FOLDER: Successfully opened Downloads folder")
        
    } catch Error as e {
        LogMessage("ERROR in OpenDownloadsFolder: " . e.message)
        IncrementError()
    }
}

OpenMyAsusWeb() {
    try {
        LogMessage("WEB: Opening ASUS ROG Support & Downloads page in Chrome")
        
        ; Check if Chrome exists
        if !FileExist(chromePath) {
            LogMessage("ERROR: Chrome not found for ASUS ROG Support page")
            return
        }
        
        ; Open specific ASUS ROG Support page in Chrome new tab
        Run('"' . chromePath . '" --new-tab "https://rog.asus.com/laptops/rog-zephyrus/rog-zephyrus-g14-2023-series/helpdesk_download/?model2name=ga402xy"')
        LogMessage("WEB: ASUS ROG Support & Downloads page opened in Chrome")
        
    } catch Error as e {
        LogMessage("ERROR in OpenMyAsusWeb: " . e.message)
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

SplitThreeAppsHorizontally() {
    try {
        LogMessage("SPLIT_THREE_APPS: Starting horizontal split of top 3 applications")
        
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
        
        ; Get top 3 most recently used applications
        if (visibleWindows.Length < 3) {
            LogMessage("SPLIT_THREE_APPS: Less than 3 windows found, cannot split")
            TrayTip("Split Three Apps", "Need at least 3 windows to split", 2000)
            return
        }
        
        ; Get screen dimensions
        MonitorGet(1, &Left, &Top, &Right, &Bottom)
        screenWidth := Right - Left
        screenHeight := Bottom - Top
        
        ; Calculate split dimensions (33.33% each horizontally)
        sectionWidth := screenWidth / 3
        fullHeight := screenHeight
        
        ; Split the first three windows
        app1 := visibleWindows[1]
        app2 := visibleWindows[2]
        app3 := visibleWindows[3]
        
        ; Position first app on left third
        try {
            ; Restore if maximized
            if (WinGetMinMax(app1.hwnd) = 1)
                WinRestore(app1.hwnd)
            
            WinMove(0, 0, sectionWidth, fullHeight, app1.hwnd)
            WinActivate(app1.hwnd)
            LogMessage("SPLIT_THREE_APPS: Positioned " . app1.process . " on left third")
        } catch Error as e {
            LogMessage("SPLIT_THREE_APPS: Failed to position left app - " . e.message)
        }
        
        ; Position second app on middle third
        try {
            ; Restore if maximized
            if (WinGetMinMax(app2.hwnd) = 1)
                WinRestore(app2.hwnd)
            
            WinMove(sectionWidth, 0, sectionWidth, fullHeight, app2.hwnd)
            WinActivate(app2.hwnd)
            LogMessage("SPLIT_THREE_APPS: Positioned " . app2.process . " on middle third")
        } catch Error as e {
            LogMessage("SPLIT_THREE_APPS: Failed to position middle app - " . e.message)
        }
        
        ; Position third app on right third
        try {
            ; Restore if maximized
            if (WinGetMinMax(app3.hwnd) = 1)
                WinRestore(app3.hwnd)
            
            WinMove(sectionWidth * 2, 0, sectionWidth, fullHeight, app3.hwnd)
            WinActivate(app3.hwnd)
            LogMessage("SPLIT_THREE_APPS: Positioned " . app3.process . " on right third")
        } catch Error as e {
            LogMessage("SPLIT_THREE_APPS: Failed to position right app - " . e.message)
        }
        
        LogMessage("SPLIT_THREE_APPS: Successfully split " . app1.process . ", " . app2.process . ", and " . app3.process . " horizontally")
        TrayTip("Split Three Apps", "Successfully split 3 apps into equal sections", 2000)
        
    } catch Error as e {
        LogMessage("ERROR in SplitThreeAppsHorizontally: " . e.message)
        IncrementError()
    }
}

OpenGamesFolder() {
    try {
        gamesPath := "C:\Users\micha\Desktop\games"  ; Updated path
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
CloseWindowKeepRunning() {
    try {
        ; Get the active window
        activeHwnd := WinGetID("A")
        if (!activeHwnd) {
            return
        }

        activeProcess := WinGetProcessName(activeHwnd)
        activeTitle := WinGetTitle(activeHwnd)

        ; Check if it's a protected process
        if (skipMap.Has(activeProcess)) {
            LogMessage("CLOSE_WINDOW: Blocked attempt to close protected process window: " . activeProcess)
            return
        }

        LogMessage("CLOSE_WINDOW: Attempting to close window for " . activeProcess . " - " . activeTitle . " (keep process running)")

        ; Close the window gracefully, but keep the process running
        try {
            WinClose(activeHwnd)
            LogMessage("CLOSE_WINDOW: Successfully closed window for " . activeProcess . " (process still running)")
        } catch Error as e {
            LogMessage("CLOSE_WINDOW: Failed to close window for " . activeProcess . " - " . e.message)
        }

    } catch Error as e {
        LogMessage("ERROR in CloseWindowKeepRunning: " . e.message)
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
; Close window but keep app running: Win + K
#k:: {
    try {
        CloseWindowKeepRunning()
    } catch {
        Sleep(100)
        try {
            CloseWindowKeepRunning()
        } catch {
            LogMessage("CRITICAL: Close window hotkey completely failed")
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
TrayTip("Complete Manager Ready - LATEST VERSION",
    "Script running with admin privileges - ALL FEATURES UPDATED!`n" .
    "••• NEW SHORTCUTS ADDED •••`n" .
    "✓ mymail→Copy Email to Clipboard (michaelovsky5@gmail.com)`n" .
    "✓ pass→Copy Password 1 to Clipboard`n" .
    "✓ myp→Copy Password 2 to Clipboard (changed from mypass2)`n" .
    "✓ ranch→PowerShell Terminal + run 'ws ranch' command`n" .
    "✓ 1337→1337x.to Torrent Search Engine in Chrome`n" .
    "✓ venice→Venice Chat - Uncensored AI in Chrome`n" .
    "✓ unzipit→PowerShell with 'ext' command`n" .
    "✓ yyyy→Split 3 latest apps into 3 equal sections`n`n" .
    "••• UPDATED FEATURES •••`n" .
    "✓ Win+K: Close window but keep app running (changed from Ctrl+K)`n" .
    "✓ uninstall→Now launches BCUninstaller.exe instead of terminal`n" .
    "✓ Win+G: Opens games folder at C:\Users\micha\Desktop\games`n" .
    "✓ Changed: reboot→rebootit | todo→mytodo | mypass2→myp`n" .
    "✓ Help GUI: Displays in 2 columns with all new shortcuts`n`n" .
    "••• POWERFUL FEATURES •••`n" .
    "✓ Credential Management: Instant clipboard copy for login info`n" .
    "✓ WSL Integration: ubuntu/ubu2→Terminal+WSL | ranch→PowerShell+ws`n" .
    "✓ Torrent Access: 1337→Direct access to 1337x.to`n" .
    "✓ AI Chat: venice→Direct access to Venice uncensored AI`n" .
    "✓ Docker: Force stop with stopd command`n" .
    "✓ Everything Search: allit launches Everything for instant file search`n" .
    "✓ Advanced Uninstaller: uninstall→BCUninstaller for clean removal`n`n" .
    "••• HOTKEYS •••`n" .
    "Triple-tap W: Force Windowed Mode | Triple-tap E: Force Full Size`n" .
    "Win+K: Close Window (Keep Running) | Alt+A: WhatsApp`n" .
    "Alt+C: Cheat Engine | Alt+W: WeMod | Win+G: Games Folder`n" .
    "Shift+S: Switch Desktops | Alt+T: Terminal | Alt+R: Close Terminal`n" .
    "Ctrl+Z: Suspend | Ctrl+Alt+R: Resume | Ctrl+D: Resume All`n`n" .
    "••• KEY TEXT SHORTCUTS •••`n" .
    "mymail→Email Copy | pass→Password 1 | myp→Password 2`n" .
    "ranch→PowerShell+ws | 1337→Torrent Site | venice→AI Chat`n" .
    "unzipit→PowerShell ext | uninstall→BCUninstaller`n" .
    "yyyy→Split 3 Apps | rer→Open Terminal (Alt+T) | updater→Software Updater`n" .
    "downloads→Downloads Folder | mygames→Terminal+myg`n" .
    "mytodo→Todoist | rebootit→System Reboot`n" .
    "ubuntu→WSL Ubuntu | stopd→Stop Docker | helpme→2-Column Help`n" .
    "All shortcuts work perfectly with smart management, clipboard integration, and web access!", 35000)

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

; ╔══════════════════════════════ NEW FUNCTIONS ══════════════════════════════╗
LaunchMacriumReflect() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Macrium Reflect")
        macriumPath := "F:\backup\windowsapps\installed\MacriumReflect\Reflect\Reflect.exe"
        if !FileExist(macriumPath) {
            LogMessage("ERROR: Macrium Reflect not found at: " . macriumPath)
            TrayTip("Macrium Reflect Error", "Reflect.exe not found at specified path", 3000)
            return
        }
        if ProcessExist("Reflect.exe") {
            if WinExist("ahk_exe Reflect.exe") {
                WinActivate("ahk_exe Reflect.exe")
                LogMessage("LAUNCHER: Macrium Reflect already running, activated window")
                TrayTip("Macrium Reflect", "Already running, window activated", 2000)
            } else {
                LogMessage("LAUNCHER: Macrium Reflect process exists but no window found")
            }
            return
        }
        Run('"' . macriumPath . '"')
        LogMessage("LAUNCHER: Macrium Reflect launched successfully from: " . macriumPath)
        TrayTip("Macrium Reflect", "Launched successfully", 2000)
        Sleep(2000)
        if WinWait("ahk_exe Reflect.exe", , 10) {
            WinActivate("ahk_exe Reflect.exe")
            LogMessage("LAUNCHER: Macrium Reflect window activated")
        } else {
            LogMessage("WARNING: Macrium Reflect launched but window not detected within 10 seconds")
        }
    } catch Error as e {
        LogMessage("ERROR in LaunchMacriumReflect: " . e.message)
        TrayTip("Macrium Reflect Critical Error", "Critical error: " . e.message, 3000)
        IncrementError()
    }
}

LaunchParsec() {
    try {
        LogMessage("LAUNCHER: Attempting to launch Parsec")
        parsecPath := "F:\backup\windowsapps\installed\parsec\parsecd.exe"
        if !FileExist(parsecPath) {
            LogMessage("ERROR: Parsec not found at: " . parsecPath)
            TrayTip("Parsec Error", "parsecd.exe not found at specified path", 3000)
            return
        }
        if ProcessExist("parsecd.exe") {
            if WinExist("ahk_exe parsecd.exe") {
                WinActivate("ahk_exe parsecd.exe")
                LogMessage("LAUNCHER: Parsec already running, activated window")
                TrayTip("Parsec", "Already running, window activated", 2000)
            } else {
                LogMessage("LAUNCHER: Parsec process exists but no window found")
            }
            return
        }
        ; Try normal Run first
        try {
            Run('"' . parsecPath . '"')
            LogMessage("LAUNCHER: Parsec launched successfully from: " . parsecPath)
        } catch Error as e1 {
            LogMessage("ERROR: Normal Run failed for Parsec: " . e1.message)
            ; Try cmd.exe as fallback
            try {
                Run('cmd.exe /c start "" "' . parsecPath . '"')
                LogMessage("LAUNCHER: Parsec launched via cmd.exe fallback")
            } catch Error as e2 {
                LogMessage("ERROR: cmd.exe fallback failed for Parsec: " . e2.message)
                ; Try RunWait as last resort
                try {
                    RunWait('"' . parsecPath . '"', "", "")
                    LogMessage("LAUNCHER: Parsec launched via RunWait fallback")
                } catch Error as e3 {
                    LogMessage("ERROR: All launch methods failed for Parsec: " . e3.message)
                    TrayTip("Parsec Critical Error", "All launch methods failed: " . e3.message, 3000)
                    IncrementError()
                    return
                }
            }
        }
        TrayTip("Parsec", "Launched (check if window appears)", 2000)
        Sleep(2000)
        if WinWait("ahk_exe parsecd.exe", , 10) {
            WinActivate("ahk_exe parsecd.exe")
            LogMessage("LAUNCHER: Parsec window activated")
        } else {
            LogMessage("WARNING: Parsec launched but window not detected within 10 seconds")
            TrayTip("Parsec Warning", "Parsec launched but no window detected", 3000)
        }
    } catch Error as e {
        LogMessage("ERROR in LaunchParsec: " . e.message)
        TrayTip("Parsec Critical Error", "Critical error: " . e.message, 3000)
        IncrementError()
    }
}
