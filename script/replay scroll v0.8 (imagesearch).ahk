; Replay menu scroll script
; by mawwwk
; v0.8
; Updated 8/18/21

; REQUIRED images in script folder:
; replays_end.png
; replays_text.png
; replays_empty.png

; Recommended: disable any real Gamecube/USB controllers in Dolphin
; Special thanks:
; * Fracture for rebuilding PM/P+ replays, as well as the autosave feature, both of which make this possible
; * Bird for designing the Netplay replay-saving system

#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONFIG (you can change these!)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; CLOSE_DOLPHIN: Set to true if you want to close the Dolphin window automatically after scrolling finishes, otherwise set to false.

global CLOSE_DOLPHIN := true

; OPTIONAL OBS hotkeys to start and stop video recording directly from the script.
; Use lowercase true/false to set
; Configure in OBS: File > Settings > Hotkeys
; Pause or ScrollLock recommended. Quote marks needed around the keys
; Reference https://www.autohotkey.com/docs/KeyList.htm

global USE_OBS_HOTKEYS = true
OBS_START_RECORDING := "ScrollLock"
OBS_STOP_RECORDING := "Pause"

; Buttons on the keyboard that correspond to buttons in Dolphin controller settings.
; Not recommended to change unless needed.
; X is recommended for A press, and Right arrow for right. Quote marks are needed on these lines

A_PRESS := "X"
RIGHT_PRESS := "Right"

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
Gui, Add, Text,, PM/P+ replay screen recorder v0.8`n`nChoose behavior after reaching the end of replays:
Gui, Add, Radio, Checked vRadioSleep, Set PC to sleep
Gui, Add, Radio, vRadioShutDown, Shut down PC
Gui, Add, Radio, vNothing, Do nothing
if (USE_OBS_HOTKEYS) {
	Gui, Add, Text,, `nOBS hotkeys set:`n  Start: %OBS_START_RECORDING%`n  Stop: %OBS_STOP_RECORDING%
}
else {
	Gui, Add, Text,, `nOBS hotkeys not set. Recording must be`nstarted and stopped manually.
}
Gui, Add, Text,, Navigate to the first replay in the replay menu,`nthen press OK to continue, or Cancel to quit.
Gui, Add, Button, Default w120 gContinue, OK
Gui, Add, Button, x+5 w120 gExit, Cancel
Gui, Show
Return

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
	GoSub main

Exit:
	ExitApp

main:
waitSeconds(1)

; Preliminary loop for initial replay
Loop {
	
	; Check for "replays" menu text
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

; Exit the script based on END_BEHAVIOR
end(END_BEHAVIOR)

ExitApp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper methods
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; end()
; Terminate the script based on config

end(shutdownVar) {
	if (CLOSE_DOLPHIN) {
		inputKey("Escape")	; Escape key to close Dolphin
		waitSeconds(1.5)
		;inputKey("Enter")	; "End the emulation?" window: Yes			
		;waitSeconds(1)
	}
	
	waitSeconds(2)
	
	; Put PC to sleep if 1
	if (shutdownVar = 1)	{			
		DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
		ExitApp
	}
	
	; Shut down PC if 2
	else if (shutdownVar = 2)	{
		Shutdown, 1
		ExitApp
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
