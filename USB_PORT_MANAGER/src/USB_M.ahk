#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, shell32.dll, 21  ; Set a system icon

; === GUI DESIGN ===
Gui, Font, s10, Segoe UI
Gui, Add, Text, x20 y20 w300 h30 +Center, USB Port Manager v1.0
Gui, Add, Button, x20 y60 w120 h40 gDisableUSB, Disable USB
Gui, Add, Button, x160 y60 w120 h40 gEnableUSB, Enable USB
Gui, Add, Button, x20 y110 w120 h40 gCheckStatus, Check Status
Gui, Add, Button, x160 y110 w120 h40 gCreateRestore, Create Restore
Gui, Add, StatusBar,, Ready
Gui, Show, w300 h180, USB Port Manager
return

; === FUNCTIONS ===
DisableUSB:
    if (!IsAdmin()) {
        MsgBox, 48, Admin Required, This action requires administrator privileges.
        return
    }
    RunWait, reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v "Start" /t REG_DWORD /d 4 /f,, Hide
    if (ErrorLevel = 0) {
        SB_SetText("USB Disabled (Reboot Required)")
        MsgBox, 64, Success, USB ports have been disabled.`nA reboot is required.
    } else {
        SB_SetText("Error: Failed to disable USB")
        MsgBox, 16, Error, Failed to modify registry.
    }
return

EnableUSB:
    if (!IsAdmin()) {
        MsgBox, 48, Admin Required, This action requires administrator privileges.
        return
    }
    RunWait, reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v "Start" /t REG_DWORD /d 3 /f,, Hide
    if (ErrorLevel = 0) {
        SB_SetText("USB Enabled (Reboot Required)")
        MsgBox, 64, Success, USB ports have been enabled.`nA reboot is required.
    } else {
        SB_SetText("Error: Failed to enable USB")
        MsgBox, 16, Error, Failed to modify registry.
    }
return

CheckStatus:
    RunWait, %ComSpec% /c reg query "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" /v "Start" > temp.txt,, Hide
    FileRead, status, temp.txt
    FileDelete, temp.txt
    
    if (InStr(status, "0x4")) {
        SB_SetText("Status: USB Disabled")
        MsgBox, 64, Status, USB Storage is currently DISABLED (Start=4).
    } else if (InStr(status, "0x3")) {
        SB_SetText("Status: USB Enabled")
        MsgBox, 64, Status, USB Storage is currently ENABLED (Start=3).
    } else {
        SB_SetText("Status: Unknown")
        MsgBox, 48, Error, Could not determine USB status.
    }
return

CreateRestore:
    if (!IsAdmin()) {
        MsgBox, 48, Admin Required, This action requires administrator privileges.
        return
    }
    RunWait, powershell -command "Checkpoint-Computer -Description 'USB Port Manager Restore Point' -RestorePointType MODIFY_SETTINGS",, Hide
    if (ErrorLevel = 0) {
        SB_SetText("Restore Point Created")
        MsgBox, 64, Success, System restore point created successfully.
    } else {
        SB_SetText("Error: Restore Failed")
        MsgBox, 16, Error, Failed to create restore point.
    }
return

; === UTILITY FUNCTIONS ===
IsAdmin() {
    full_command_line := DllCall("GetCommandLine", "str")
    if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
        try {
            Run *RunAs "%A_ScriptFullPath%" /restart
            ExitApp
        }
        return false
    }
    return true
}

GuiClose:
ExitApp