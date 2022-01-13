/*
Shows a tooltip for a predefined amount of time, after which, it will auto-hide

Usage:

new SplashTooltip(timeout, x="", y="", whichToolTip="")

    timeout
        Time in miliseconds after which the tooltip will hide itself

    x, y, whichToolTip
        The arguments for the ToolTip command
        https://www.autohotkey.com/docs/commands/ToolTip.htm


SplashTooltip.show(text)

    text
        The text to appear on the tooltip


Example:

; This will show a tooltip for 2 seconds, then disappears for 2 seconds, and finally show another tooltip for 2 seconds
stp := new SplashTooltip(2000)
stp.show("abcd")
Sleep, 4000
stp.show("efgh")

*/

class SplashTooltip {
    state := 0

    __New(timeout, x="", y="", whichToolTip="") {
        this.timeout := timeout * -1
        this.x := x
        this.y := y
        this.whichToolTip := whichToolTip
        this.__hide := ObjBindMethod(this, "hide") ; Required because of the limitation of SetTimer
    }

    __Delete() {
        this.hide()
    }

    show(text) {
        __hide := this.__hide ; SetTimer requires a plain variable reference

        if this.state
            SetTimer, % __hide, Delete

        ToolTip, % text, this.x, this.y, this.whichToolTip
        SetTimer, % __hide, % this.timeout

        this.state := 1
    }

    hide() {
        __hide := this.__hide ; SetTimer requires a plain variable reference

        ToolTip,,,, this.whichToolTip
        SetTimer, % __hide, Delete

        this.state := 0
    }
}