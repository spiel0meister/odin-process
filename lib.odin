package process

import "core:strings"

Proc :: struct {
    handle: Proc_Handle,
    out_pipe: Proc_Pipe,
    in_pipe: Proc_Pipe,
}

Proc_Redirect_Bits :: enum {
    Stdin,
    Stdout,
    Stderr,
}

Proc_Redirect :: bit_set[Proc_Redirect_Bits]

Proc_Error :: enum {
    Failed_To_Start,
    Failed_To_Create_Pipe,

    Failed_To_Wait,
    Failed_With_Signal,
    Exit_With_Non_Zero,
}

// Copied from https://github.com/tsoding/nob.h/blob/39028aa9f017aafcb047a92d8a77b5bcf9d8dc84/nob.h#L824
cmd_render :: proc(cmd: []string, builder: ^strings.Builder, allocator := context.allocator) -> string {
    for arg, i in cmd {
        if i > 0 {
            strings.write_string(builder, " ")
        }

        if strings.contains(arg, " ") {
            strings.write_quoted_string(builder, arg)
        } else {
            strings.write_string(builder, arg)
        }
    }

    return strings.clone(transmute(string)builder.buf[:], allocator)
}

cmd_render_cstring :: proc(cmd: []string, builder: ^strings.Builder, allocator := context.allocator) -> cstring {
    for arg, i in cmd {
        if i > 0 {
            strings.write_string(builder, " ")
        }

        if strings.contains(arg, " ") {
            strings.write_quoted_string(builder, arg)
        } else {
            strings.write_string(builder, arg)
        }
    }

    return strings.clone_to_cstring(transmute(string)builder.buf[:], allocator)
}

