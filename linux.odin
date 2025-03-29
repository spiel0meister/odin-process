#+build linux
package process

import "core:sys/linux"
import "core:sys/posix"

import "core:strings"
import os "core:os/os2"

Proc_Handle :: linux.Pid

run :: proc(cmd: []string, allocator := context.temp_allocator) -> Proc_Error {
    cmd_with_cstring := make([]cstring, len(cmd) + 1, allocator)

    for str, i in cmd {
        cmd_with_cstring[i] = strings.clone_to_cstring(str, allocator)
    }
    cmd_with_cstring[len(cmd_with_cstring) - 1] = nil

    pid, err := linux.fork()
    if err != .NONE {
        return .Failed_To_Start
    }

    if pid == 0 {
        posix.execvp(cmd_with_cstring[0], &cmd_with_cstring[1])
        os.exit(1)
    }

    return wait(pid)
}

wait :: proc(handle: Proc_Handle) -> Proc_Error {
    for {
        wstatus := u32(0)
        _, err := linux.waitpid(handle, &wstatus, {}, nil)
        if err != .NONE {
            return .Failed_To_Wait
        }

        if linux.WIFEXITED(wstatus) {
            status := linux.WEXITSTATUS(wstatus)
            if status != 0 {
                return .Exit_With_Non_Zero
            }

            break
        }

        if linux.WIFSIGNALED(wstatus) {
            return .Failed_With_Signal
        }
    }

    return nil
}
