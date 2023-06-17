#SingleInstance force
SetWorkingDir %A_ScriptDir%

INI_PATH := "config.ini"

IniRead, OUTPUT_VIDEO_PATH, %INI_PATH%, Behavior, OBSOutputVideoPath

; Window detection mode
SetTitleMatchMode, 2

; Set & initialize parameters
IniRead, UPLOAD_BUTTON_PNG, %INI_PATH%, Images, UploadButton
IniRead, BROWSER, %INI_PATH%, Behavior, UploadBrowser, chrome
StringLower, BROWSER, BROWSER

; Begin YouTube upload. Open new browser window, then wait for it to load
if (BROWSER = "chrome") {
	Run chrome.exe "https://youtube.com/upload" "--new-window"
}
else if (BROWSER = "firefox") {
	Run firefox.exe "https://youtube.com/upload" "--new-window"
}
else {
	errorText = Browser setting invalid. In config.ini, set "UploadBrowser" to either chrome or firefox, then try again.
	MsgBox %errorText%
	ExitApp
}

; Wait for browser window to load (up to 60 secs)
	Loop 30 {
		waitSeconds(2)
		WinGetActiveTitle, WINDOW_TITLE
		if (InStr(WINDOW_TITLE, YouTube)) {
			break
		}
	}
	
	waitSeconds(2)
	WinActivate, YouTube
    WinMaximize, YouTube
	waitSeconds(1)

	ImageSearch, buttonX, buttonY, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOAD_BUTTON_PNG%
	
	MouseClick,, buttonX, buttonY

; Wait for file select window to load (up to 60 secs)
	Loop 30 {
		waitSeconds(2)
		WinGetActiveTitle, WINDOW_TITLE
		if (WINDOW_TITLE = "Open" or WINDOW_TITLE = "File Upload") {
			break
		}
	}

; Paste video path and start upload
Send %OUTPUT_VIDEO_PATH%
waitSeconds(1)
Send {Enter}
waitSeconds(10)

ExitApp

waitSeconds(secsToWait) {
	Sleep secsToWait * 1000
}