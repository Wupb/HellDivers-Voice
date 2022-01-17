/*
Creates a new GUI with a TreeView that represents the given object

Usage:
    ObjectTreeView(object, title="Object TreeView", fold=0, parentItemId="")

    object:
        The object to be represented in the TreeView

    title:
        The title of the new GUI

    fold:
        An integer where each bit that is 1 will fold the level that corrisponds to the bit's place.
        For example, `ObjectTreeView(obj, 131)` (131 is 1000 0011 in binary) will fold the first, second, and eighth level.
        The default is 0, which will expand every level.
        To fold the first 32 levels, use 0xFFFFFFFF.

    parentItemId:
        This is for internal use and should be omitted.
        If present, will add TreeView items to the TreeView item with parentItemId as its ID.

    Return value:
        HWND of the new GUI, if one was created
*/

ObjectTreeView(object, title="Object TreeView", fold=0, parentItemId="") {
    if (parentItemId == "") {
        Gui, New, +HwndguiHwnd +Labelotv +Resize
        Gui, Margin, 8, 6
        Gui, Add, TreeView, HwndtvControlId w600 h800

        GuiControl, -Redraw, %tvControlId% ; For possible performance improvement
        ObjectTreeView(object,, fold, 0)
        GuiControl, +Redraw, %tvControlId%

        Gui, Show,, %title%
    } else {
        itemOptions := fold & 1 ? "" : "+Expand" ; Get the least significant bit, same as mod(fold, 2)
        fold >>= 1

        for key, value in object {
            if ([key].GetCapacity(1)) { ; Check whether or not the key is string
                key := """" key """"
            }
            if (IsObject(value)) {
                ObjectTreeView(value,, fold, TV_Add(key, parentItemId, itemOptions))
            } else {
                TV_Add(key ": " value, parentItemId, itemOptions)
            }
        }
    }

    return guiHwnd

    otvClose:
        Gui, Destroy
    return

    otvSize:
        GuiControl, Move, SysTreeView321, % "w" A_GuiWidth - 16 " h" A_GuiHeight - 12
    return
}