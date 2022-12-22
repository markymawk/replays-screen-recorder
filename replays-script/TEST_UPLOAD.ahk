#SingleInstance force
SetWorkingDir %A_ScriptDir%

INI_PATH := "config.ini"

IniRead, OUTPUT_VIDEO_PATH, %INI_PATH%, Behavior, OBSOutputVideoPath

; Window detection mode
SetTitleMatchMode, 2

; Set & initialize parameters
IniRead, TAB_PRESS_COUNT, %INI_PATH%, Behavior, UploadPageTabPresses, 3
IniRead, BROWSER, %INI_PATH%, Behavior, UploadBrowser, chrome
StringLower, BROWSER, BROWSER

; Begin YouTube upload. Open new browser window, then wait for it to load
if (%BROWSER% = chrome) {
	Run chrome.exe "https://youtube.com/upload" "--new-window"
}
else if (%BROWSER% = firefox) {
	Run firefox.exe "https://youtube.com/upload" "--new-window"
}
else {
	errorText = Browser setting invalid. In config.ini, set "UploadBrowser" to either chrome or firefox, then try again.
	MsgBox %errorText%
	ExitApp
}

; Wait for browser window to open, then maximize
waitSeconds(10)
WinActivate, YouTube
WinMaximize, YouTube
waitSeconds(1)

; Tab to upload button, then click it
Loop %TAB_PRESS_COUNT% {
	Send {Tab}
}
Send {Enter}

; Wait for file select window to load (up to 60 secs)
Loop 30 {
		waitSeconds(2)
		WinGetActiveTitle, WINDOW_TITLE
		if (%WINDOW_TITLE% = Open) {
			break
		}
	}

; Paste video path and start upload
Send %OUTPUT_VIDEO_PATH%
Send {Enter}

ExitApp

waitSeconds(secsToWait) {
	Sleep secsToWait * 1000
}