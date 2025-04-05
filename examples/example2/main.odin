package example2

import "core:fmt"
import "core:os"
import "core:strings"

import process "../.."
exit :: os.exit

CFLAGS :: []string{ "-c", "-Wall", "-Wextra", "-Werror" }

files :: []string {
    "src/foo.c",
    "src/bar.c",
    "src/baz.c",
}

get_file_name_from_path :: proc(path: string) -> string {
    for i := len(path) - 1; i >= 0; i -= 1 {
        if os.is_path_separator(auto_cast path[i]) {
            return path[i + 1:]
        }
    }

    return ""
}

run_cmd :: proc(cmd: []string) -> (ok := true) {
    err := process.run(cmd)
    if err != nil {
        fmt.printfln("Couldn't run command: {}", err)
        ok = false
    }
    return
}

build_files :: proc(cmd: ^[dynamic]string) -> (ok := true) {
    for file in files {
        append(cmd, "gcc")
        append(cmd, ..CFLAGS)
        append(cmd, file)

        if !run_cmd(cmd[:]) {
            fmt.eprintln("Couldn't build {}", file)
            return false
        }

        clear(cmd)
    }
    return
}

main :: proc() {
    program_path := os.args[0]
    program_dir := strings.trim_right_proc(program_path, proc(r: rune) -> bool {
        return !os.is_path_separator(r)
    })
    os.set_current_directory(program_dir)

    cmd: [dynamic]string
    defer delete(cmd)

    if !build_files(&cmd) {
        exit(1)
    }

    append(&cmd, "ar", "rcs", "liblib.a")
    for file_path in files {
        file := get_file_name_from_path(file_path)
        file = file[:len(file) - 1]

        object_file := fmt.tprintf("{}o", file)
        append(&cmd, object_file)
    }

    if !run_cmd(cmd[:]) {
        exit(1)
    }

    clear(&cmd)
}
