#+build linux
package process

import "base:intrinsics"

import "core:sys/linux"
import "core:sys/posix"

import "core:fmt"
import "core:strings"
import os "core:os/os2"

Proc_Handle :: linux.Pid
Proc_Pipe :: [2]linux.Fd

start :: proc(cmd: []string, redirect := Proc_Redirect{}, allocator := context.temp_allocator) -> (Proc, Proc_Error) {
    new_proc := Proc{}

    if .Stdout in redirect || .Stderr in redirect {
        err1 := linux.pipe2(&new_proc.out_pipe, {})
        if err1 != .NONE {
            return {}, .Failed_To_Create_Pipe
        }
    }

    if .Stdin in redirect {
        err1 := linux.pipe2(&new_proc.in_pipe, {})
        if err1 != .NONE {
            return {}, .Failed_To_Create_Pipe
        }
    }

    cmd_with_cstring := make([]cstring, len(cmd) + 1, allocator)
    for str, i in cmd {
        cmd_with_cstring[i] = strings.clone_to_cstring(str, allocator)
    }

    pid, err2 := linux.fork()
    if err2 != nil {
        return {}, .Failed_To_Start
    }

    if pid < 0 {
        return {}, .Failed_To_Start
    } else if pid == 0 {
        success := true
        if .Stdin in redirect {
            _, err := linux.dup2(new_proc.in_pipe[0], linux.STDIN_FILENO)
            if err != .NONE {
                success = false
            }

            linux.close(new_proc.in_pipe[1])
        }

        if .Stdout in redirect {
            _, err := linux.dup2(new_proc.out_pipe[1], linux.STDOUT_FILENO)
            if err != .NONE {
                success = false
            }

            linux.close(new_proc.out_pipe[0])
        }

        if .Stderr in redirect {
            _, err := linux.dup2(new_proc.out_pipe[1], linux.STDERR_FILENO)
            if err != .NONE {
                success = false
            }

            linux.close(new_proc.out_pipe[0])
        }

        if !success {
            os.exit(1)
        } else {
            posix.execvp(cmd_with_cstring[0], raw_data(cmd_with_cstring))
            fmt.eprintln("Couldn't start process")
            os.exit(1)
        }
    }

    new_proc.handle = pid
    linux.close(new_proc.out_pipe[1])
    linux.close(new_proc.in_pipe[0])

    return new_proc, nil
}

run :: proc(cmd: []string, redirect := Proc_Redirect{}, allocator := context.temp_allocator) -> Proc_Error {
    new_proc := start(cmd, redirect, allocator) or_return

    linux.close(new_proc.out_pipe[0])
    linux.close(new_proc.in_pipe[1])

    return wait(new_proc)
}

wait1 :: proc(using process: Proc) -> Proc_Error {
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

wait_many :: proc(processes: []Proc) -> Proc_Error {
    err := Proc_Error(nil)
    for process in processes {
        err = wait1(process)
    }
    return err
}

wait :: proc{wait1, wait_many}
