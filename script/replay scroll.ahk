; Replay menu scroll script
; by mawwwk
; v0.9
; Updated 8/19/21

; REQUIRED images in script folder:
; replays_end.png
; replays_text.png
; replays_empty.png

; OPTIONAL images for auto-uploading:
; upload_button.png
; upload_button2.png
; uploading_text.png

; Recommended: disable any real Gamecube/USB controllers in Dolphin
; Special thanks:
; Fracture for rebuilding PM/P+ replays, as well as the autosave feature, both of which make this possible
; Bird for designing the Netplay replay-saving system

#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode Pixel Screen
CoordMode Mouse Screen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONFIG (you can change these!)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CLOSE_DOLPHIN: Set to true if you want to close the Dolphin window automatically after scrolling finishes, otherwise set to false.

global CLOSE_DOLPHIN := true

; OPTIONAL OBS hotkeys to start and stop video recording directly from the script.
; Use lowercase true/false to set
; Configure in OBS: File > Settings > Hotkeys
; Pause or ScrollLock used by default. Quote marks needed around the keys
; Reference https://www.autohotkey.com/docs/KeyList.htm

global USE_OBS_HOTKEYS = true
OBS_START_RECORDING := "ScrollLock"
OBS_STOP_RECORDING := "Pause"

; Buttons on the keyboard that correspond to buttons in Dolphin controller settings.
; Not recommended to change unless needed.
; X is recommended for A press, and Right arrow for right. Quote marks are needed on these lines

A_PRESS := "X"
RIGHT_PRESS := "Right"

; OUTPUT_VIDEO_PATH: Configure in OBS: File > Settings > Advanced > "Filename Formatting"
OUTPUT_VIDEO_PATH := "C:\Users\m\Videos\OBS_output.mp4"

; REPLAYS_TEXT: Configure for screen size. These coordinate-pairs form a square around a portion of the Dolphin screen that must cover the full "REPLAYS" image used in the corresponding png file.
; Quote marks needed around the filename
REPLAYS_TEXT_PNG := "replays_text.png"
REPLAYS_TEXT_UPPERLEFT_X := 200
REPLAYS_TEXT_UPPERLEFT_Y := 50
REPLAYS_TEXT_LOWERRIGHT_X := 650
REPLAYS_TEXT_LOWERRIGHT_Y := 200

; REPLAYS_END: See above. Used for the right-facing "arrow in a circle" design to detect end of the list
REPLAYS_END_PNG := "replays_end.png"
REPLAYS_END_UPPERLEFT_X := 1165
REPLAYS_END_UPPERLEFT_Y := 366
REPLAYS_END_LOWERRIGHT_X := 1869
REPLAYS_END_LOWERRIGHT_Y := 1070

; REPLAYS_EMPTY: See above. Used for detecting an empty P2 port in the replay menu
REPLAYS_EMPTY_PNG := "replays_empty.png"
REPLAYS_EMPTY_UPPERLEFT_X := 1010
REPLAYS_EMPTY_UPPERLEFT_Y := 630
REPLAYS_EMPTY_LOWERRIGHT_X := 1075
REPLAYS_EMPTY_LOWERRIGHT_Y := 695

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; THE PARTS THAT DO THINGS
; (shouldn't change stuff after this line)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Show user interface to choose end behavior
Gui, Add, Text,, PM/P+ replay screen recorder v0.9`n`nChoose behavior after reaching the end of replays:
Gui, Add, Radio, Checked vRadioSleep, Set PC to sleep
Gui, Add, Radio, vRadioShutDown, Shut down PC
Gui, Add, Radio, vNothing, Do nothing
if (USE_OBS_HOTKEYS) {
	Gui, Add, Text,, `nOBS hotkeys set:`n  Start: %OBS_START_RECORDING%`n  Stop: %OBS_STOP_RECORDING%`n
}
else {
	Gui, Add, Text,, `nOBS hotkeys not set. Recording must be`nstarted and stopped manually.`n
}
Gui, Add, Checkbox, vDO_UPLOAD, Begin auto-upload to YouTube after recording
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

; If OBS hotkeys aren't configured, don't auto-upload since there's no finished mp4
if (DO_UPLOAD and not USE_OBS_HOTKEYS) {
	DO_UPLOAD := false
	MsgBox 1, Error, OBS recording hotkeys must be configured to use auto-upload. Configure these within the AHK file.`n`nAuto-uploading disabled. Press OK to continue.
}

; Check if output file exists, and show an error if so
while DO_UPLOAD and FileExist(OUTPUT_VIDEO_PATH) {
	MsgBox File already exists at:`n%OUTPUT_VIDEO_PATH%`n`nRename the file, then press OK to continue.
}


; Preliminary loop for initial replay
Loop {
	; Check for "replays" menu text once per second
	waitSeconds(1)
	ImageSearch, X, Y, %REPLAYS_TEXT_UPPERLEFT_X%, %REPLAYS_TEXT_UPPERLEFT_Y%, %REPLAYS_TEXT_LOWERRIGHT_X%, %REPLAYS_TEXT_LOWERRIGHT_Y%, %REPLAYS_TEXT_PNG%
	
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
		
		inputButton(A_PRESS, 3)
		waitSeconds(5)
		break
	}
}

; Main loop to cycle through all replays after the first
Loop {
		
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
		if (ErrorLevel != 0) {
			inputButton(A_PRESS, 3)
			waitSeconds(6)	; No need to do anything for a while
		}
	}
	
	; If in-game, wait a bit between screen checks
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

if (DO_UPLOAD) {
	UPLOAD_BUTTON_PNG := "upload_button.png"
	UPLOAD_BUTTON_ALT_PNG := "upload_button2.png"
	UPLOADING_TEXT_PNG := "uploading_text.png"
	
	; Begin YouTube upload. Open new Chrome window, then wait for it to load
	Run chrome.exe "https://youtube.com/upload" "--new-window"
	waitSeconds(10)


	ImageSearch, FoundX, FoundY, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOAD_BUTTON_PNG%

	; If not found, check with non-DarkReader image
	if (ErrorLevel = 1) {
		ImageSearch, FoundX, FoundY, 0,0, A_ScreenWidth, A_ScreenHeight, %UPLOAD_BUTTON_ALT_PNG%
		
		; If STILL not found, assume there's an error. End script
		if (ErrorLevel = 1) {
			Goto end
		}
	}

	; Click upload button
	Click, , %FoundX%, %FoundY%

	; Wait for file select window
	waitSeconds(5)

	; Paste video path and start upload
	Send %OUTPUT_VIDEO_PATH%
	Send {Enter}

	Loop {
		; Every 2 minutes, check to see if video is still uploading
		Sleep 2 * 60 * 1000
		ImageSearch, 0,0, 100,100, A_ScreenWidth, A_ScreenHeight, %UPLOADING_TEXT_PNG%
		
		; If uploading text not found, assume upload is complete.
		; OR after 2 hours (60 loops), exit script regardless of upload status
		if (ErrorLevel = 1 or A_Index > 60) {
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
; Used for sending inputs outside of Dolphin

inputKey(inputVar, loopCount:=1) {
	Loop, %loopCount% {
		Send {%inputVar% down}
		Sleep 200
		Send {%inputVar% up}
		Sleep 200
	}
}

waitFrames(framesToWait) {
	Sleep framesToWait * 16.8
}

waitSeconds(secsToWait) {
	Sleep secsToWait * 1000
}
