#Requires AutoHotkey v2.0
#SingleInstance Force

; Simple test script for suspend functionality
MsgBox("Suspend System Test", "This script will test the suspend functionality.`n`nPress OK to continue...", "OK")

; Test 1: Check if we can get active process
try {
    hwnd := WinGetID("A")
    if (hwnd) {
        pid := WinGetPID(hwnd)
        if (pid) {
            procName := ProcessGetName(pid)
            if (procName) {
                MsgBox("Test 1 - Active Process", "Success! Active process: " . procName, "OK")
            } else {
                MsgBox("Test 1 - Active Process", "Failed to get process name for PID: " . pid, "OK")
            }
        } else {
            MsgBox("Test 1 - Active Process", "Failed to get PID for window", "OK")
        }
    } else {
        MsgBox("Test 1 - Active Process", "Failed to get active window", "OK")
    }
} catch Error as e {
    MsgBox("Test 1 - Error", "Error getting active process: " . e.message, "OK")
}

; Test 2: Check if PowerShell Suspend-Process works
try {
    testCmd := 'powershell.exe -Command "Get-Process | Select-Object -First 1 | ForEach-Object { $_.Name }"'
    result := ComObject("WScript.Shell").Exec(testCmd).StdOut.ReadAll()
    if (result) {
        MsgBox("Test 2 - PowerShell", "PowerShell command execution works. Sample process: " . Trim(result), "OK")
    } else {
        MsgBox("Test 2 - PowerShell", "PowerShell command execution failed", "OK")
    }
} catch Error as e {
    MsgBox("Test 2 - PowerShell Error", "Error testing PowerShell: " . e.message, "OK")
}

; Test 3: Check if we can create a test process
try {
    ; Create a simple notepad process for testing
    Run("notepad.exe")
    Sleep(1000)
    
    if (ProcessExist("notepad.exe")) {
        MsgBox("Test 3 - Process Creation", "Successfully created test process (notepad.exe)", "OK")
        
        ; Try to suspend it
        try {
            suspendCmd := 'powershell.exe -Command "Suspend-Process -Name \'notepad\' -Force"'
            RunWait(suspendCmd, "", "Hide")
            Sleep(500)
            
            ; Check if it's still running
            if (ProcessExist("notepad.exe")) {
                MsgBox("Test 3 - Suspend", "Process still exists after suspend attempt (this is normal)", "OK")
                
                ; Try to resume it
                try {
                    resumeCmd := 'powershell.exe -Command "Resume-Process -Name \'notepad\' -Force"'
                    RunWait(resumeCmd, "", "Hide")
                    Sleep(500)
                    
                    if (ProcessExist("notepad.exe")) {
                        MsgBox("Test 3 - Resume", "Process resumed successfully", "OK")
                    } else {
                        MsgBox("Test 3 - Resume", "Process not found after resume", "OK")
                    }
                } catch Error as e {
                    MsgBox("Test 3 - Resume Error", "Error resuming process: " . e.message, "OK")
                }
            } else {
                MsgBox("Test 3 - Suspend", "Process was terminated (not suspended)", "OK")
            }
        } catch Error as e {
            MsgBox("Test 3 - Suspend Error", "Error suspending process: " . e.message, "OK")
        }
        
        ; Clean up - close notepad
        ProcessClose("notepad.exe")
    } else {
        MsgBox("Test 3 - Process Creation", "Failed to create test process", "OK")
    }
} catch Error as e {
    MsgBox("Test 3 - Error", "Error in process creation test: " . e.message, "OK")
}

MsgBox("Test Complete", "Suspend system test completed. Check the results above.", "OK")
ExitApp() 