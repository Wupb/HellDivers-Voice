#Include JSON.ahk
#Include Object TreeView.ahk
#Include Splash Tooltip.ahk
#include Lib/HotVoice.ahk
#SingleInstance force
#Persistent
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
Menu, Tray, Icon, helldivers.ico
Menu, Tray, NoStandard
Menu, Tray, Add, Exit, GuiClose

hv := new HotVoice()
recognizers := hv.GetRecognizerList()
stp := new SplashTooltip(6000, 800, 20)

; Create GUI
guiWidth := 480
Gui, Margin,, 4

; Speech settings
Gui, Font, s16 bold
Gui, Add, Text, xm w%guiWidth% Center, Speech
Gui, Font

Gui, Add, ListView, xm w%guiWidth% r4 hwndrecognizerListview -Multi, #|Name|Language
LV_ModifyCol(1, "25 Integer")
LV_ModifyCol(2, "325 Text")
LV_ModifyCol(3, "125 Text")
Loop % recognizers.Length() {
    rec := recognizers[A_index]
    if (rec.TwoLetterISOLanguageName == "iv")
        continue ; Invariant culture does not seem to be supported
    LV_Add(, A_index, rec.Name, rec.LanguageDisplayName)
}
if (!LV_GetCount()) {
    MsgBox, No speech recognition languages found
    ExitApp
}
LV_Modify(1, "Select") ; Select the first recognizer on the list by default

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Activation Word
Gui, Add, Edit, vactivationWord Limit100 x+20 yp w200, strategem

; Keybinds settings
Gui, Font, s16 bold
Gui, Add, Text, xm w%guiWidth% y+40 Center, Keybinds
Gui, Font

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Strategem
Gui, Add, Edit, vstrategemKey x+20 yp w120, LCtrl
Gui, Add, Link, x+10 yp Left, <a href="https://www.autohotkey.com/docs/KeyList.htm">Possible key names</a>

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Up
Gui, Add, Hotkey, vU Limit190 x+20 yp, w

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Down
Gui, Add, Hotkey, vD Limit190 x+20 yp, s

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Left
Gui, Add, Hotkey, vL Limit190 x+20 yp, a

Gui, Add, Text, % "xm w" guiWidth/3 " Right", Right
Gui, Add, Hotkey, vR Limit190 x+20 yp, d

Gui, Add, Text, xm w%guiWidth% Disabled Center, Note: the directional keybinds may show the Ctrl + Alt modifier, but it will be ignored

; Misc settings
Gui, Font, s16 bold
Gui, Add, Text, xm w%guiWidth% y+40 Center, Misc
Gui, Font

Gui, Add, Text, % "xm w" guiWidth/2 " Right", Strategem source
Gui, Add, Radio, vgame x+20 yp, Helldivers 1
Gui, Add, Radio, Checked x+10 yp, Helldivers 2

Gui, Add, Text, % "xm w" guiWidth/2 " Right", Delay (in milliseconds) between inputs
Gui, Add, Edit, vdelay Number x+20 yp w50
Gui, Add, UpDown, Range0-1000, 50

; Start
Gui, Font, s12 bold
Gui, Add, Button, % "gStart w150 xm+" guiWidth/2 - 75 " y+40  Center", Start
Gui, Font

Gui, Show,, Helldivers Voice
return

; ......... ;
; Functions ;
; ......... ;

Start() {
    global JSON, hv, recognizers, activationWord, strategems, aliasDict, strategemKey, U, D, L, R, game

    Gui, Submit, NoHide

    ; Validation
    validationError := ""
    if (!LV_GetNext()) {
        validationError .= "Select a recognizer from the list.`n`n"
    }

    if (GetKeyState(strategemKey) == "") {
        validationError .= strategemKey " is not a valid key name.`n`n"
    }

    ; The Ctrl + Alt combination cannot be limited, so remove them if they are filled by the user
    ; https://www.autohotkey.com/docs/commands/GuiControls.htm#Hotkey
    U := StrReplace(U, "^!")
    D := StrReplace(D, "^!")
    L := StrReplace(L, "^!")
    R := StrReplace(R, "^!")

    if (!U || !D || !L || !R) {
        validationError .= "The directional keys cannot be empty.`n`n"
    }

    if (validationError) {
        MsgBox, % SubStr(validationError, 1, -2) ; Remove the two trailing line feeds
        return
    }

    ; Initialize Hot Voice with the selected recognizer
    LV_GetText(recognizerIndex, LV_GetNext(), 1)
    hv.Initialize(recognizers[recognizerIndex].Id)

    Gui, Destroy ; All inputs have been retrieved and the GUI can be destroyed

    ; Load strategems.json saswwd sasdd dwawda sawas
    FileRead, jsonText, strategems.json
    if (ErrorLevel && !jsonText) {
        MsgBox, Could not read strategems.json
        ExitApp
    }
    try {
        strategems := JSON.Load(jsonText)["Helldivers " game]
    } catch e {
        MsgBox, % "Error parsing strategems.json:`n`n" e.Message
        ExitApp
    }

    ; Create a menu for viewing strategems.json
    ViewStrategems := Func("ObjectTreeView").Bind(strategems, "strategems.json TreeView", 1, "")
    Menu, Tray, Insert, Exit, View strategems.json, % ViewStrategems

    ; Create a map where each alias points to its strategem object
    ; Objects/associative arrays in AHK_L are case insensitive, so a COM dictionary is used instead
    ; https://docs.microsoft.com/en-us/office/vba/language/reference/user-interface-help/dictionary-object
    ; https://www.autohotkey.com/boards/viewtopic.php?t=66677
    aliasDict := ComObjCreate("Scripting.Dictionary")
    for name, object in strategems {
        for index, alias in object.aliases {
            if aliasDict.Item[alias]
                MsgBox, % "Duplicate alias: " name " and " aliasDict.Item[alias] " both share " alias " as its alias. The latter will override the former."
            aliasDict.Item[alias] := name
        }
    }

    ; Create the HotVoice choices (from a comma-separated string of aliases)
    for alias in aliasDict.Keys {
        alias := StrReplace(alias, ",") ; Aliases should not have comma in them, but filter them anyway
        choiceListString .= alias ","
    }
    choiceListString := SubStr(choiceListString, 1, -1) ; Remove the trailing comma
    choices := hv.NewChoices(choiceListString)

    ; Create the HotVoice grammar
    grammar := hv.NewGrammar()
    grammar.AppendString(activationWord) ; The first word to listen for
    grammar.AppendChoices(choices) ; The subsequent choices/aliases to choose from

    ; Start HotVoice
    hv.LoadGrammar(grammar, "Helldivers strategems", Func("StrategemCallback"))
    hv.StartRecognizer()
}

StrategemCallback(grammarName, words) {
    global aliasDict, stp, strategems, activationWord

    ; Join the words and omit the activation word
    Loop % words.Length()
        wordString .= words[A_Index] " "
    wordString := SubStr(wordString, 1, -1) ; Remove the trailing space
    wordString := StrReplace(wordString, activationWord " ",,, 1)

    strategemName := aliasDict.Item[wordString]

    stp.show("Words: " wordString "`nStrategem: " strategemName)

    if (WinActive("ahk_exe helldivers.exe") || WinActive("ahk_exe helldivers2.exe")) {
        RunStrategem(strategems[strategemName].code)
    }
}

; Sends inputs to activate a strategem, given the up/down/left/right sequence string
; Example (Reinforce strategem):
;   RunStrategem("UDRLU")
RunStrategem(udlrString) {
    global strategemKey, U, D, L, R, delay

    ; Normalize parameter
    ; StringUpper, udlrString, udlrString

    BlockInput, On
    Send, {%strategemKey% down}
    Sleep, %delay%

    Loop, Parse, udlrString
    { ; Specialized loops do not support One True Brace https://www.autohotkey.com/docs/commands/Loop.htm#Remarks
        Send, % %A_LoopField%
        Sleep, %delay%
    }

    Send, {%strategemKey% up}
    BlockInput, Off
}

GuiClose() {
    ExitApp
}
