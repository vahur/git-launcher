                default rel
                extern  ExitProcess, LocalAlloc, LocalFree, GetEnvironmentVariableW, SetEnvironmentVariableW, lstrcpynW
                extern  GetCommandLineW, CreateProcessW, WaitForSingleObject, GetExitCodeProcess, CloseHandle
                global  start

ENV_VAR_SIZE    equ (32 * 1024)

; -----------------------------------------------------------------------------

struc PROCESS_INFORMATION
    .hProcess               resq    1   ; 0
    .hThread                resq    1   ; 8
    .dwProcessId            resd    1   ; 16
    .dwThreadId             resd    1   ; 20
endstruc                                ; 24

struc STARTUPINFOW
    .cb                     resd    1   ; 0
                            alignb  8   ; 4
    .lpReserved             resq    1   ; 8
    .lpDesktop              resq    1   ; 16
    .lpTitle                resq    1   ; 24
    .dwX                    resd    1   ; 32
    .dwY                    resd    1   ; 36
    .dwXSize                resd    1   ; 40
    .dwYSize                resd    1   ; 44
    .dwXCountChars          resd    1   ; 48
    .dwYCountChars          resd    1   ; 52
    .dwFillAttribute        resd    1   ; 56
    .dwFlags                resd    1   ; 60
    .wShowWindow            resw    1   ; 64
    .cbReserved2            resw    1   ; 66
                            alignb  8   ; 68
    .lpReserved2            resq    1   ; 72
    .hStdInput              resq    1   ; 80
    .hStdOutput             resq    1   ; 88
    .hStdError              resq    1   ; 96
endstruc                                ; 104

struc CREATEPROCESSW_args
    .lpApplicationName      resq    1   ; 0
    .lpCommandLine          resq    1   ; 8
    .lpProcessAttributes    resq    1   ; 16
    .lpThreadAttributes     resq    1   ; 24
    .bInheritHandles        resd    1   ; 32
                            alignb  8
    .dwCreationFlags        resd    1   ; 40
                            alignb  8
    .lpEnvironment          resq    1   ; 48
    .lpCurrentDirectory     resq    1   ; 56
    .lpStartupInfo          resq    1   ; 64
    .lpProcessInformation   resq    1   ; 72
endstruc                                ; 80

; -----------------------------------------------------------------------------
                section .text
                %define processInfo rsp + 28h
                %define exitCode    rsp + 28h + PROCESS_INFORMATION_size
start:
                sub     rsp, 28h + PROCESS_INFORMATION_size + 8

                mov     rdx, ENV_VAR_SIZE
                xor     rcx, rcx
                call    LocalAlloc
                mov     r14, rax
                test    rax, rax
                jz      .fail

                mov     r8, s_exe_dir_l / 2 + 1     ; +1 for 0 terminator
                lea     rdx, [s_app]
                mov     rcx, rax
                call    lstrcpynW                   ; Copy exe dir to buffer
                mov     word [r14 + s_exe_dir_l], ';'

                mov     r8, (ENV_VAR_SIZE - s_exe_dir_l - 2) / 2
                lea     rdx, [r14 + s_exe_dir_l + 2]
                lea     rcx, [s_path]
                call    GetEnvironmentVariableW     ; Append PATH env var value to buffer

                cmp     rax, (ENV_VAR_SIZE - s_exe_dir_l - 2) / 2
                jb      .size_ok
.fail:
                mov     ecx, -1
                jmp     ExitProcess
.size_ok:
                mov     rdx, r14
                lea     rcx, [s_path]
                call    SetEnvironmentVariableW

                mov     rcx, r14
                call    LocalFree

                lea     rcx, [processInfo]
                call    create_process

                test    eax, eax
                jz      .fail

                mov     r15, [processInfo + PROCESS_INFORMATION.hProcess]
                lea     r14, [exitCode]
                mov     edx, -1
                mov     rcx, r15
                call    WaitForSingleObject

                mov     rdx, r14
                mov     rcx, r15
                call    GetExitCodeProcess

                mov     rcx, [processInfo + PROCESS_INFORMATION.hThread]
                call    CloseHandle

                mov     rcx, r15
                call    CloseHandle

                mov     rcx, [r14]
                jmp     ExitProcess

create_process:
                %define startupInfo rsp + CREATEPROCESSW_args_size
                %define cp_args     rsp
                sub     rsp, STARTUPINFOW_size + CREATEPROCESSW_args_size

                vxorps  ymm0, ymm0
                xor     rax, rax
                vmovups [startupInfo +  0], ymm0
                vmovups [startupInfo + 32], ymm0
                vmovups [startupInfo + 64], ymm0
                mov     [startupInfo + 96], rax
                mov     dword [startupInfo + STARTUPINFOW.cb], STARTUPINFOW_size

                vmovups [cp_args + CREATEPROCESSW_args.bInheritHandles], ymm0       ; Clears bInheritHandles, dwCreationFlags, lpEnvironment, lpCurrentDirectory
                lea     rax, [startupInfo]
                mov     [cp_args + CREATEPROCESSW_args.lpStartupInfo], rax
                mov     [cp_args + CREATEPROCESSW_args.lpProcessInformation], rcx
                call    GetCommandLineW
                xor     r9, r9                                                      ; lpThreadAttributes
                xor     r8, r8                                                      ; lpProcessAttributes
                mov     rdx, rax                                                    ; lpCommandLine
                lea     rcx, [s_app]                                                ; lpApplicationName
                call    CreateProcessW
                add     rsp, STARTUPINFOW_size + CREATEPROCESSW_args_size
                ret

                section .rdata
s_path          dw      __utf16__('PATH'), 0
s_path_l        equ     $ - s_path
s_app           dw      __utf16__('C:\MSys\usr\bin\git.exe'), 0
s_app_l         equ     $ - s_app
s_exe_dir_l     equ     s_app_l - (9 * 2) ; s_app_l - sizeof('\git.exe', 0)
