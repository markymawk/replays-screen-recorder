INI_PATH := "config.ini"

IniRead, UPLOAD_BUTTON_PNG, %INI_PATH%, Images, UploadButton
IniRead, UPLOAD_BUTTON_ALT_PNG, %INI_PATH%, Images, UploadButtonAlt
IniRead, UPLOADING_TEXT_PNG, %INI_PATH%, Images, UploadingText
IniRead, OUTPUT_VIDEO_PATH, %INI_PATH%, Behavior, OBSOutputVideoPath
IniRead, BROWSER, %INI_PATH%, Behavior, UploadBrowser
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

; Check for upload button, waiting 4 seconds each time (100 secs)
Loop 25 {
	; Detect upload button
	ImageSearch, FoundX, FoundY, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOAD_BUTTON_PNG%
	
	; If found, click button
	if (ErrorLevel = 0) {
		Goto uploadClick
	}
	; If not found, check alt button
	else {
		ImageSearch, FoundX, FoundY, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOAD_BUTTON_ALT_PNG%
		
		if (ErrorLevel = 0) {
			Goto uploadClick
		}
	}
	waitSeconds(4)
}

; uploadButtonNotFound label only used if uploadClick is not accessed via the above loop.
uploadButtonNotFound:
errorText = Upload button not detected. Make sure the upload button is visible on-screen, and that it matches upload_button.png in the script folder.
MsgBox %errorText%
ExitApp

; Click upload button
uploadClick:
Click, , %FoundX%, %FoundY%

; Wait for file select window
waitSeconds(10)

; Paste video path and start upload
Send %OUTPUT_VIDEO_PATH%
Send {Enter}

ExitApp

waitSeconds(secsToWait) {
	Sleep secsToWait * 1000
}