#SingleInstance Force
#Requires AutoHotkey v2.0
#Include ../memory.ahk
#Include outputDebugOverload.ahk

; usage examples:
memLogBefore := Memory.Used()

; ; load data...
loaded := Memory.Used() - memLogBefore
; do something with loaded here like...
OutputDebug Memory.ToString(loaded, 'KB'), ':loaded memory'

; Or you could just output a string directly with the Memory.Loaded() method...
OutputDebug "Loaded: " . Memory.Loaded(memLogBefore, true)
OutputDebug "Loaded: " . Memory.Loaded(memLogBefore, true,,11)
OutputDebug "Loaded: " . Memory.Loaded(memLogBefore, true, "B")
OutputDebug "Loaded: " . Memory.Loaded(memLogBefore, true, "kb", 6)
OutputDebug "Loaded: " . Memory.Loaded(memLogBefore, true, "GB")

; if Memory.IsOver(2, "GB") {
;     ; do whatever you want
; }