#+build windows
package process

import "core:sys/windows"
import "core:unicode/utf16"
import "core:unicode/utf8"
import "core:strings"

Proc_Handle :: windows.HANDLE

start :: proc(cmd: []string, allocator := context.temp_allocator) -> (Proc, Proc_Handle) {
    start_info: windows.STARTUPINFOW
    start_info.cb = size_of(start_info)
    start_info.hStdError = windows.GetStdHandle(windows.STD_ERROR_HANDLE)
    start_info.hStdOutput = windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
    start_info.hStdInput = windows.GetStdHandle(windows.STD_INPUT_HANDLE)
    start_info.dwFlags |= windows.STARTF_USESTDHANDLES

    proc_info: windows.PROCESS_INFORMATION

    builder := strings.builder_make(allocator)
    defer strings.builder_destroy(&builder)
    
    command_line_u8 := cmd_render(cmd, &builder, allocator)
    defer delete(command_line_u8)

    command_line_runes := utf8.string_to_runes(command_line_u8, context.temp_allocator)
    command_line := make([]u16, len(command_line_runes) * 3, context.temp_allocator)
    _ = utf16.encode(command_line, command_line_runes)

    success := windows.CreateProcessW(
        nil,
        raw_data(command_line),
        nil,
        nil,
        windows.TRUE,
        0,
        nil,
        nil,
        &start_info,
        &proc_info
    )

    if !success {
        return {}, .Failed_To_Start
    }

    windows.CloseHandle(proc_info.hThread)

    new_proc := Proc{ handle = proc_info.hProcess }
    return new_proc, nil
}

// Copied from https://github.com/tsoding/nob.h/blob/39028aa9f017aafcb047a92d8a77b5bcf9d8dc84/nob.h#L854
run :: proc(cmd: []string, allocator := context.temp_allocator) -> Proc_Error {
    new_proc := start(cmd, allocator) or_return
    return wait(new_proc.handle)
}

// Copied from https://github.com/tsoding/nob.h/blob/39028aa9f017aafcb047a92d8a77b5bcf9d8dc84/nob.h#L1055
wait :: proc(handle: Proc_Handle) -> Proc_Error {
    result := windows.WaitForSingleObject(
                handle,
                windows.INFINITE
            )
    if windows.FAILED(result) {
        return .Failed_To_Wait
    }

    estatus: windows.DWORD
    if !windows.GetExitCodeProcess(handle, &estatus) {
        return .Failed_To_Wait
    }

    if estatus != 0 {
        return .Exit_With_Non_Zero
    }

    windows.CloseHandle(handle)
    return nil
}

