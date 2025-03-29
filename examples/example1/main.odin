package example1

import process "../.."
import "core:fmt"

ARGS :[]string: { "gf2" } when ODIN_OS == .Linux else { "explorer.exe" }

main :: proc() {
    err := process.run(ARGS)
    if err != nil {
        fmt.eprintln("Couldn't start process:", err)
        return
    }
}
