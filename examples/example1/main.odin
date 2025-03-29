package example1

import process "../.."
import "core:fmt"

import "core:sys/linux"

ARGS :[]string: { "ls", "-l" } when ODIN_OS == .Linux else { "dir" }

main :: proc() {
    gf2_proc, err := process.start(ARGS, { .Stdout })
    if err != nil {
        fmt.eprintln("Couldn't start process:", err)
        return
    }

    err = process.wait(gf2_proc)
    if err != nil {
        fmt.eprintln("Couldn't wait for process:", err)
        return
    }

    buffer: [1024]u8
    for {
        n, err := linux.read(gf2_proc.out_pipe[0], buffer[:])
        if err != .NONE {
            break
        } else if n == 0 {
            break
        }

        fmt.print(string(buffer[:n]))
    }
}
