; Replay menu scroll script
; by mawwwk
; v0.7
; Updated 3/11/21

; Use Wiimote and Nunchuck controls in Dolphin. Disable any other controllers!
; Thanks to Fracture for rebuilding PM replays, and conceiving the Wiichuck control scheme for this script

#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONFIG (you can change these!)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; END_BEHAVIOR: Decide what to do after the script ends
; 0: Do nothing
; 1: Set PC to sleep
; 2: Shut down PC

END_BEHAVIOR = 1

; CLOSE_DOLPHIN: Set to true if you want to close the Dolphin window automatically after scrolling finishes, otherwise set to false.

global CLOSE_DOLPHIN := true

; OBS_STOP_RECORDING: OPTIONAL OBS hotkey to stop video recording at the end of the script.
; This can be used as an alternative to OBS's output timer.
; Configure in OBS: File > Settings > Hotkeys > Stop recording
; Pause or ScrollLock recommended. Quote marks needed on this line
; Reference https://www.autohotkey.com/docs/KeyList.htm

OBS_STOP_RECORDING := "Pause"
USE_OBS_STOP = False

; SCROLL_INTERVAL: Time, in seconds, between scroll attempts
; Smaller value makes duplicates or permanent loops more likely, though too high of value means more empty menu time, and longer videos.
; 10 to 12 recommended. Only change this if repeats occur too often

SCROLL_INTERVAL = 11

; PUSH_INTERVAL: Time, in frames, between scrolling and press A
; With large amounts of replays (100's), Dolphin may need more time to load the replay list.
; 7 is recommended, increase only if needed

PUSH_INTERVAL = 7

; Buttons on the keyboard that correspond to buttons on Wiimote+Nunchuck in Dolphin controller settings.
; Not recommended to change unless needed for whatever reason.
; X is recommended for A press, and Right arrow for right. Quote marks are needed on these lines

A_PRESS := "X"
RIGHT_PRESS := "Right"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; THE PARTS THAT DO THINGS
; (shouldn't change stuff after this line)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Confirm program start with message box
GoSub, initMessage

; Wait after closing MsgBox
waitSeconds(2)

; Press A, beginning from first replay in the menu	
inputButton(A_PRESS)			

; Derive loop count from parameters
; Assuming scroll interval of 10 secs, 360 loops is approximately 1 hour
LOOP_COUNT := HOURS_TO_RUN * (3600 / SCROLL_INTERVAL)

; Scroll loop
Loop, %LOOP_COUNT% {					
	waitSeconds(SCROLL_INTERVAL)
	GoSub, scroll
}

; Stop OBS recording (optional)
if (USE_OBS_STOP) {
	inputKey(OBS_STOP_RECORDING, 2)
}

; Shut down or sleep PC (optional)
end(END_BEHAVIOR)

ExitApp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper methods
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; initMessage:
; Dialog boxes to get run duration and confirmation from user

initMessage:
	; Get run duration from user input
	; Width 340, height 160
	HOURS_TO_RUN = 0
	INPUT_MESSAGE := "Enter how long the script will run for, in hours. `nDecimals are valid here (for 90 minutes, input 1.5). `nEnter 0 to run indefinitely."
	
	InputBox, HOURS_TO_RUN, Enter script run duration, %INPUT_MESSAGE%, , 340, 160
	
	; Quit if user pressed cancel
	if ErrorLevel {
		ExitApp
	}
	
	; Quit if invalid input
	if HOURS_TO_RUN is not number
	{
		MsgBox, Invalid input. Closing script
		ExitApp
	}
	
	if (HOURS_TO_RUN <= 0) {
		HOURS_TO_RUN = 99
	}
	
	MINS_TO_RUN := Round(Mod(HOURS_TO_RUN, 1) * 60)
	HOURS_TRUNC := Floor(HOURS_TO_RUN)
	MsgString = Replay script set to run for %HOURS_TRUNC%h %MINS_TO_RUN%m.`n`n
	
	if (END_BEHAVIOR = 1) {
		MsgString = %MsgString%PC will sleep after.`n
	}
	else if (END_BEHAVIOR = 2) {
		MsgString = %MsgString%PC will shut down after.`n
	}
	else {
		MsgString = %MsgString%PC will not sleep or shut down after.
	}
	
	MsgString = %MsgString%`nBe sure to enable Wiimote controls and disable Gamecube controls.`n`nNavigate to the first replay in the replay menu, then press OK to continue, or Cancel to quit.
	
	; Display message box containing contents of msgString
	
	MsgBox, 1, Dolphin replay scroll, %MsgString%,
	
	; If user presses cancel, quit the script
	IfMsgBox Cancel
		ExitApp

	return

; scroll:
; Input sequence to move on to the next replay in the replay menu. Doesn't affect anything if a game is currently running

scroll:
	inputButton(RIGHT_PRESS)			; input right to scroll
	waitFrames(PUSH_INTERVAL)			; wait for the cursor to move
	inputButton(A_PRESS, 4)				; make attempts to press A to start replay. laggier PCs may need a higher value?
	return

; end()
; Terminate the script based on END_BEHAVIOR in config

end(shutdownVar) {
	if (CLOSE_DOLPHIN) {
		inputKey("Escape")	; Escape key to close Dolphin
		waitSeconds(1.5)
		;inputKey("Enter")	; "End the emulation?" window: Yes			
		;waitSeconds(1)		; Not needed sometimes
	}
	
	; Put PC to sleep if 1
	if (shutdownVar = 1)	{			
		DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
		ExitApp
	}
	
	; Shut down PC if 2
	else if (shutdownVar = 2)	{
		Shutdown, 1		; Shut down PC
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
