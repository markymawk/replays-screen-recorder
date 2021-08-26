; Replay menu scroll script
; by mawwwk
; v1.0
; Updated 8/23/21

; REQUIRED images in script folder:
; replays_end.png
; replays_text.png
; replays_empty.png

; OPTIONAL images for auto-uploading:
; upload_button.png
; upload_button2.png
; uploading_text.png

; Recommended: disable any real Gamecube/USB controllers in Dolphin
; Special thanks to:
; Fracture for rebuilding PM/P+ replays, as well as the Autosave Replays feature, both of which make this possible
; Bird for designing the Netplay replay save system, which inspired me to explore this tech to its fullest through 2021

; Todo:
; LRA Start combination for replays that are too long
; Save prompt settings to ini file, and set to default for future runs
; Disable 3+ player replays, using new png+ini+GUI setting
; UploadMinutesMax ini parameter, for time to wait for upload

#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode Pixel Screen
CoordMode Mouse Screen

;;;;;;;;;
; CONFIG
;;;;;;;;;
INI_PATH := "config.ini"

IniRead, CLOSE_DOLPHIN, %INI_PATH%, Behavior, CloseDolphin, false
IniRead, USE_OBS_HOTKEYS, %INI_PATH%, Behavior, UseOBSHotkeys, false
global CLOSE_DOLPHIN := toBool(CLOSE_DOLPHIN)
global USE_OBS_HOTKEYS := toBool(USE_OBS_HOTKEYS)

IniRead, OBS_START_RECORDING, %INI_PATH%, Hotkeys, StartRecordingOBS
IniRead, OBS_STOP_RECORDING, %INI_PATH%, Hotkeys, StopRecordingOBS
IniRead, A_PRESS, %INI_PATH%, Hotkeys, PressA, X
IniRead, RIGHT_PRESS, %INI_PATH%, Hotkeys, PressRight, Right

IniRead, OUTPUT_VIDEO_PATH, %INI_PATH%, Behavior, OBSOutputVideoPath

; Want to auto-calculate replays_text coordinates, but need an efficient way to find height/width of image in order to know lower-right x,y pos
IniRead, REPLAYS_TEXT_PNG, %INI_PATH%, Images, ReplaysText
IniRead, REPLAYS_TEXT_UPPERLEFT_X, %INI_PATH%, ImageCoordinates, ReplaysTextUpperLeftX, 0
IniRead, REPLAYS_TEXT_UPPERLEFT_Y, %INI_PATH%, ImageCoordinates, ReplaysTextUpperLeftY, 0
IniRead, REPLAYS_TEXT_LOWERRIGHT_X, %INI_PATH%, ImageCoordinates, ReplaysTextLowerRightX, A_ScreenWidth
IniRead, REPLAYS_TEXT_LOWERRIGHT_Y, %INI_PATH%, ImageCoordinates, ReplaysTextLowerRightY, A_ScreenHeight

IniRead, REPLAYS_END_PNG, %INI_PATH%, Images, ReplaysEnd, 
IniRead, REPLAYS_END_UPPERLEFT_X, %INI_PATH%, ImageCoordinates, ReplaysEndUpperLeftX, 0
IniRead, REPLAYS_END_UPPERLEFT_Y, %INI_PATH%, ImageCoordinates, ReplaysEndUpperLeftY, 0
IniRead, REPLAYS_END_LOWERRIGHT_X, %INI_PATH%, ImageCoordinates, ReplaysEndLowerRightX, A_ScreenWidth
IniRead, REPLAYS_END_LOWERRIGHT_Y, %INI_PATH%, ImageCoordinates, ReplaysEndLowerRightY, A_ScreenHeight

IniRead, REPLAYS_EMPTY_PNG, %INI_PATH%, Images, ReplaysEmpty, 
IniRead, REPLAYS_EMPTY_UPPERLEFT_X, %INI_PATH%, ImageCoordinates, ReplaysEmptyUpperLeftX, 0
IniRead, REPLAYS_EMPTY_UPPERLEFT_Y, %INI_PATH%, ImageCoordinates, ReplaysEmptyUpperLeftY, 0
IniRead, REPLAYS_EMPTY_LOWERRIGHT_X, %INI_PATH%, ImageCoordinates, ReplaysEmptyLowerRightX, A_ScreenWidth
IniRead, REPLAYS_EMPTY_LOWERRIGHT_Y, %INI_PATH%, ImageCoordinates, ReplaysEmptyLowerRightY, A_ScreenHeight

;;;;;;;;;;;;;;;;;;;;;;;;;;
; THE PARTS THAT DO THINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;

; DEBUG
; DO_UPLOAD := true
; Goto upload

; Show user interface to choose end behavior
Gui, Add, Text,, PM/P+ replay screen recorder v0.9`n`nChoose behavior after reaching the end of replays:
Gui, Add, Radio, Checked vRadioSleep, Set PC to sleep
Gui, Add, Radio, vRadioShutDown, Shut down PC
Gui, Add, Radio, vNothing, Do nothing
if (USE_OBS_HOTKEYS) {
	Gui, Add, Text,, `nOBS hotkeys set:`n  Start: %OBS_START_RECORDING%`n  Stop: %OBS_STOP_RECORDING%`n
	Gui, Add, Checkbox, vDO_UPLOAD, Begin auto-upload to YouTube after recording
}
else {
	DO_UPLOAD := false
	Gui, Add, Text,, `nOBS hotkeys not set. Recording must be`nstarted and stopped manually. Auto-upload disabled.`n
}
Gui, Add, Text,, Navigate to the first replay in the replay menu,`nthen press OK to continue, or Cancel to quit.
Gui, Add, Button, Default w120 gContinue, OK
Gui, Add, Button, x+5 w120 gExit, Cancel
Gui, Show,, Record replays
Return

Exit:
	ExitApp

Continue:
	Gui, Submit
	if (RadioSleep) {
		END_BEHAVIOR = 1
	}
	else if (RadioShutDown) {
		END_BEHAVIOR = 2
	}
	else {
		END_BEHAVIOR = 0
	}

; Check if output file exists, and show an error if so
while DO_UPLOAD and FileExist(OUTPUT_VIDEO_PATH) {
	MsgBox File already exists at:`n%OUTPUT_VIDEO_PATH%`n`nRename the file, then press OK to continue.
}

; Preliminary loop for initial replay
Loop {
	; Check for "replays" menu text once per second
	waitSeconds(1)
	ImageSearch, FoundX, FoundY, %REPLAYS_TEXT_UPPERLEFT_X%, %REPLAYS_TEXT_UPPERLEFT_Y%, %REPLAYS_TEXT_LOWERRIGHT_X%, %REPLAYS_TEXT_LOWERRIGHT_Y%, %REPLAYS_TEXT_PNG%
	
	; If in replays menu, check for valid replay
	if (ErrorLevel = 0) {
		
		; If on a single player replay, skip it and recheck loop
		ImageSearch, X, Y, %REPLAYS_EMPTY_UPPERLEFT_X%, %REPLAYS_EMPTY_UPPERLEFT_Y%, %REPLAYS_EMPTY_LOWERRIGHT_X%, %REPLAYS_EMPTY_LOWERRIGHT_Y%, %REPLAYS_EMPTY_PNG%
		if (ErrorLevel = 0) {
			inputButton(RIGHT_PRESS)
			waitFrames(13)
			Continue
		}
		
		; If on a valid replay, start the replay and exit this loop
		if (USE_OBS_HOTKEYS) {
			inputKey(OBS_START_RECORDING)
			waitSeconds(0.5)
		}
		
		; Align ImageSearch box to found coordinates, for optimization
		REPLAYS_TEXT_UPPERLEFT_X := %FoundX%
		REPLAYS_TEXT_UPPERLEFT_Y := %FoundY%
		
		inputButton(A_PRESS, 3)
		waitSeconds(5)
		break
	}
}

; Count how many times the current replay's ending has been checked
scrollCheckCount = 0

; Time, in seconds, that a game can last before quitting out of the script
SCROLL_CHECK_MAX = 540

; Main loop to cycle through all replays after the first
Loop {
	scrollCheckCount += 1
	; Check for "replays" menu text
	ImageSearch, X, Y, %REPLAYS_TEXT_UPPERLEFT_X%, %REPLAYS_TEXT_UPPERLEFT_Y%, %REPLAYS_TEXT_LOWERRIGHT_X%, %REPLAYS_TEXT_LOWERRIGHT_Y%, %REPLAYS_TEXT_PNG%
	
	; If text is found, check if at the end of the replays list
	if (ErrorLevel = 0) {
	
		; If at the end of the replays list, break the loop
		ImageSearch, X, Y, %REPLAYS_END_UPPERLEFT_X%, %REPLAYS_END_UPPERLEFT_Y%, %REPLAYS_END_LOWERRIGHT_X%, %REPLAYS_END_LOWERRIGHT_Y%, %REPLAYS_END_PNG%
		
		if (ErrorLevel = 0) {
			break
		}
		
		; If not at the end of the list, press right to scroll to the next replay
		inputButton(RIGHT_PRESS)
		waitFrames(13)
		
		; Check for 1-player replay
		ImageSearch, X, Y, %REPLAYS_EMPTY_UPPERLEFT_X%, %REPLAYS_EMPTY_UPPERLEFT_Y%, %REPLAYS_EMPTY_LOWERRIGHT_X%, %REPLAYS_EMPTY_LOWERRIGHT_Y%, %REPLAYS_EMPTY_PNG%
		
		; If not on a 1-player replay, press A to start the replay
		if (ErrorLevel > 0) {
			inputButton(A_PRESS, 3)
			waitSeconds(6)	; No need to do anything for a while
			scrollCheckCount = 0
		}
		
		; If in-game for too long, stop the recording and end script
		if (scrollCheckCount >= SCROLL_CHECK_MAX) {
			if (USE_OBS_HOTKEYS) {
				inputKey(OBS_STOP_RECORDING)
			}
			
			errorText = Replay exceeds time limit. Recording stopped and saved.
			endError(END_BEHAVIOR, errorText)
		}
	}
	
	; If replays menu text not found, wait a sec between screen checks
	else {
		waitSeconds(1)
	}
}

; After finishing the scroll loop, stop OBS recording
if (USE_OBS_HOTKEYS) {
	inputKey(OBS_STOP_RECORDING)
}

; Close Dolphin window
if (CLOSE_DOLPHIN) {
	inputKey("Escape")	; Escape key to close Dolphin
	waitSeconds(1.5)
}

upload:
if (DO_UPLOAD) {
	IniRead, UPLOAD_BUTTON_PNG, %INI_PATH%, Images, UploadButton
	IniRead, UPLOAD_BUTTON_ALT_PNG, %INI_PATH%, Images, UploadButtonAlt
	IniRead, UPLOADING_TEXT_PNG, %INI_PATH%, Images, UploadingText
	IniRead, UPLOAD_WAIT_TIME, %INI_PATH%, Behavior, UploadWaitTimeMinutes, -1
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
		errorText = Browser setting invalid. Replay mp4 should still be saved.`n`nQuitting script without uploading.
		endError(END_BEHAVIOR, errorText)
	}
	
	; Check for upload button, waiting 4 seconds each time (60 secs)
	Loop 15 {
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
	errorText = Upload button not detected. Replay mp4 should still be saved.`n`nQuitting script without uploading
	endError(END_BEHAVIOR, errorText)
	
	; Click upload button
	uploadClick:
	Click, , %FoundX%, %FoundY%

	; Wait for file select window
	waitSeconds(10)
	
	; Paste video path and start upload
	Send %OUTPUT_VIDEO_PATH%
	Send {Enter}
	
	afterUploadWaitLoop:
	Loop {
		; Every 60 seconds, check to see if video is still uploading
		waitSeconds(60)
		ImageSearch, 0,0, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOADING_TEXT_PNG%
		
		; If uploading text not found, assume upload is complete.
		; or, after UPLOAD_WAIT_TIME minutes, exit script regardless of upload status
		if (ErrorLevel = 1 or A_Index > UPLOAD_WAIT_TIME) {
			Goto end
		}
	}
}

end:
end(END_BEHAVIOR)
ExitApp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper methods
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; end()
; Terminate the script based on config

end(shutdownVar) {
	; Put PC to sleep if 1
	if (shutdownVar = 1)	{			
		DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
	}
	
	; Shut down PC if 2
	else if (shutdownVar = 2)	{
		Shutdown, 1
	}
}

endError(shutdownVar, errorMsg) {
	end(shutdownVar)
	waitSeconds(1)
	MsgBox %errorMsg%
	ExitApp
}

; inputButton()
; Used for buttons in Dolphin. Keys need to be held for the length of at least 1 frame in order to be read.

inputButton(inputVar, loopCount:=1) {
	Loop, %loopCount% {
		Send {%inputVar% down}
		Sleep 40
		Send {%inputVar% up}
		Sleep 25
	}
}

; inputKey()
; Used for sending inputs outside of Dolphin. Originally used a different Send function, but keeping this anyways to not break things

inputKey(inputVar, loopCount:=1) {
	Loop, %loopCount% {
		Send {%inputVar% down}
		Sleep 200
		Send {%inputVar% up}
		Sleep 200
	}
}

; toBool()
; Convert ini "true" to bool true
toBool(var) {
	StringLower, var, var
	return (var = "true" or var >= 1)
}

waitFrames(framesToWait) {
	Sleep framesToWait * 16.8
}

waitSeconds(secsToWait) {
	Sleep secsToWait * 1000
}
