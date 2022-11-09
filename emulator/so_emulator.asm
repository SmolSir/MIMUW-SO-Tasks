global so_emul

section .bss
state:  resq CORES

section .text

; GLOBAL REGISTRIES ;
; r8  - stores the imm8 value extracted from the currently processed code
; r9  - stores the pointer to the beginning of codes array
; r10 - stores the pointer to the currently processed code (R9 + PC)
; r11 - stores the pointer to appropriate state registry or data field, decoded from arg1
; r12 - stores the pointer to appropriate state registry or data field, decoded from arg2
; r13 - stores the pointer to beginning of current thread's state
; r14 - stores the pointer to the beginning of current thread's data array

load_argument_address:
        mov     rax, QWORD 0            ; clear the RAX registry
        and     dil, BYTE 0x07          ; clear the 5 high order bits of DIL registry
        cmp     dil, BYTE 4             ; check if the argument code refers to state register
        jb      load_state_reg_addr     ; if so, proceed to load_state_reg_addr
        cmp     dil, BYTE 6             ; check if the argument code refers to state data offset by a single registry value
        jb      load_state_data_addr    ; if so, proceed to load_state_data_addr
        add     al, BYTE [r13 + 1]      ; add the value of state D to AL registry
        sub     dil, BYTE 2             ; subtract two from argument code to add state X or Y value next
load_state_data_addr:
        add     al, BYTE [r13 + rdi - 2]; add state X or Y value to AL registry
        add     rax, r14                ; add value of R14 registry to get the pointer to correct state data field
        ret
load_state_reg_addr:
        add     al, dil                 ; add the argument code to AL registry
        add     rax, r13                ; add value of R13 registry to get the pointer to correct state registry
        ret

load_state_CF:
        clc                             ; clear real Carry Flag
        cmp     [r13 + 6], BYTE 0       ; check if state C flag is false
        je      load_state_CF_end       ; if so, proceed to load_state_CF_end
        stc                             ; set real Carry Flag
load_state_CF_end:
        ret

update_state_CF:
        mov     [r13 + 6], BYTE 0       ; clear the state C flag
        jnc     update_state_CF_end     ; if it should be false, leave
        mov     [r13 + 6], BYTE 1       ; otherwise set the state C flag to true
update_state_CF_end:
        ret

update_state_ZF:
        mov     [r13 + 7], BYTE 0       ; clear the state Z flag
        jnz     update_state_ZF_end     ; if it should be false, leave
        mov     [r13 + 7], BYTE 1       ; otherwise set the state Z flag to true
update_state_ZF_end:
        ret

so_emul:
        push    r12
        push    r13
        push    r14
        sub     rsp, QWORD 8            ; align stack for function calls

        mov     r9, rdi                 ; save the pointer to instruction codes array inside R9 registry
        mov     r14, rsi                ; save the pointer to state data array inside R14 registry
        lea     r13, [rel state]        ; copy the relative address of states array into R13 registry
        lea     r13, [r13 + rcx * 8]    ; move the pointer according to core number

so_emul_loop:
        cmp     rdx, QWORD 0            ; check if the steps value is equal to zero
        je      return                  ; if so, immediately return

        movzx   r10, BYTE [r13 + 4]     ; copy the state PC value into R10 registry, extending to 64-bit
        shl     r10, 1                  ; multiply the value by 2 (our codes are 2 bytes each)
        add     r10, r9                 ; add value of R9 registry to get the pointer to correct state codes field
        
        inc     BYTE [r13 + 4]          ; increase the state PC
        dec     rdx                     ; decrease steps

decode_arguments:
        mov     r8b, BYTE [r10]         ; copy the low order byte of code (imm8 value) into R8B registry
        movzx   rdi, WORD [r10]         ; prepare function argument (arg1 code)
        shr     rdi, 8                  ; shift the 3 bits containing the code to lowest order bits of RDI registry
        call    load_argument_address   ; call function
        mov     r11, rax                ; save function call result (pointer to arg1) inside R11 registry
        movzx   rdi, WORD [r10]         ; prepare function argument (arg2 code)
        shr     rdi, 11                 ; shift the 3 bits containing the code to lowest order bits of RDI registry
        call    load_argument_address   ; call function
        mov     r12, rax                ; save function call result (pointer to arg2) inside R12 registry

decode_instruction:
        mov     cl, BYTE [r12]          ; copy the value of arg2 into CL registry for instructions that read it (MOV, OR, ADD, SUB, ADC, SBB, XCHG) 
        mov     ax, WORD [r10]          ; restore the original code value inside AX registry
find_no_arguments_instruction:
        cmp     ax, WORD 0x8000         ; compare the code to 0x8000 - specifically for CLC, the code has no variety in form of params
        je      CLC                     ; if the codes match, perform the CLC instruction
        cmp     ax, WORD 0x8100         ; compare the code to 0x8100 - specifically for STC, the code has no variety in form of params
        je      STC                     ; if the codes match, perform the STC instruction
        cmp     ax, WORD 0xFFFF         ; compare the code to BRK code
        je      return                  ; if the codes match, end the loop and proceed to return
find_jump_instruction:
        cmp     ah, BYTE 0xC0           ; check if code is equal to JMP code
        je      JMP                     ; if so, proceed to the instruction
        cmp     ah, BYTE 0xC2           ; check if code is equal to JNC code
        je      JNC                     ; if so, proceed to the instruction
        cmp     ah, BYTE 0xC3           ; check if code is equal to JC code
        je      JC                      ; if so, proceed to the instruction
        cmp     ah, BYTE 0xC4           ; check if code is equal to JNZ code
        je      JNZ                     ; if so, proceed to the instruction
        cmp     ah, BYTE 0xC5           ; check if code is equal to JZ code
        je      JZ                      ; if so, proceed to the instruction
find_arg1_instruction:
        and     ah, BYTE 0xF8           ; clear the 3 bits representing arg1 code
        cmp     ah, BYTE 0x40           ; check if code is equal to MOVI code
        je      MOVI                    ; if so, proceed to the instruction
        cmp     ah, BYTE 0x58           ; check if code is equal to XORI code
        je      XORI                    ; if so, proceed to the instruction
        cmp     ah, BYTE 0x60           ; check if code is equal to ADDI code
        je      ADDI                    ; if so, proceed to the instruction
        cmp     ah, BYTE 0x68           ; check if code is equal to CMPI code
        je      CMPI                    ; if so, proceed to the instruction
        cmp     ax, WORD 0x7001         ; check if code is equal to RCR code
        je      RCR                     ; if so, proceed to the instruction
find_arg1_arg2_instruction:
        and     ah, BYTE 0xC0           ; clear the 3 bits representing arg2 code
        jnz     instruction_not_found   ; at this point we only recognize instruction codes with AH = 0
        cmp     al, BYTE 0x00           ; check if code is equal to MOV code
        je      MOV                     ; if so, proceed to the instruction
        cmp     al, BYTE 0x02           ; check if code is equal to OR code
        je      OR                      ; if so, proceed to the instruction
        cmp     al, BYTE 0x04           ; check if code is equal to ADD code
        je      ADD                     ; if so, proceed to the instruction
        cmp     al, BYTE 0x05           ; check if code is equal to SUB code
        je      SUB                     ; if so, proceed to the instruction
        cmp     al, BYTE 0x06           ; check if code is equal to ADC code
        je      ADC                     ; if so, proceed to the instruction
        cmp     al, BYTE 0x07           ; check if code is equal to SBB code
        je      SBB                     ; if so, proceed to the instruction
        cmp     al, BYTE 0x08           ; check if code is equal to XCHG code
        je      XCHG                    ; if so, proceed to the instruction
instruction_not_found:
        jmp     so_emul_loop

MOV:
        mov     [r11], cl               ; overwrite the arg1 value
        jmp     so_emul_loop
OR:
        or      [r11], cl               ; perform the bitwise OR operation
        jmp     update_ZF               ; update state Z flag
ADD:
        add     [r11], cl               ; add to the arg1 value
        jmp     update_ZF               ; update state Z flag
SUB:
        sub     [r11], cl               ; subtract from the arg1 value
        jmp     update_ZF               ; update state Z flag
ADC:
        call    load_state_CF           ; set real Carry Flag according to state C flag
        adc     [r11], cl               ; add to the arg1 value
        jmp     update_CF_ZF            ; update state C and Z flags
SBB:
        call    load_state_CF           ; set real Carry Flag according to state C flag
        sbb     [r11], cl               ; subtract from the arg1 value
        jmp     update_CF_ZF            ; update state C and Z flags
XCHG:
        mov     ax, WORD [r10]          ; copy the current code into AX registry
        and     ah, BYTE 0x04           ; check if arg1 points to one of the state registries (arg1 code < 4)
        jz      no_swap                 ; if so, no swap of args is needed
        xchg    r11, r12                ; potentially arg2 points to a registry; swap so that arg1 could do it instead
no_swap:
        mov     al, [r11]               ; copy the value of arg1 into AL registry
        xchg    al, [r12]               ; swap values of AL (arg1) and arg2
        mov     [r11], al               ; overwrite arg1 with arg2 value
        jmp     so_emul_loop
MOVI:
        mov     [r11], r8b              ; overwrite arg1 with imm8 value
        jmp     so_emul_loop
XORI:
        xor     [r11], r8b              ; xor arg1 with imm8 value
        jmp     update_ZF               ; update state Z flag
ADDI:
        add     [r11], r8b              ; add imm8 value to arg1
        jmp     update_ZF               ; update state Z flag
CMPI:
        cmp     [r11], r8b              ; compare arg1 with imm8
        jmp     update_CF_ZF            ; update state C and Z flags
RCR:
        call    load_state_CF           ; set real Carry Flag according to state C flag
        rcr     BYTE [r11], BYTE 1      ; perform the bitwise rotation
        jmp     update_CF               ; update state C flag
CLC:
        clc                             ; clear the real Carry Flag
        jmp     update_CF               ; proceed to clear state C flag
STC:
        stc                             ; set the real Carry Flag
        jmp     update_CF               ; proceed to set state C flag
JMP:
        add     [r13 + 4], r8b          ; add the jumped instructions count to state PC
        jmp     so_emul_loop
JNC:
        cmp     [r13 + 6], BYTE 0       ; check if state C flag is false
        je      JMP                     ; if so, perform the jump
        jmp     so_emul_loop
JC:
        cmp     [r13 + 6], BYTE 1       ; check if state C flag is true
        je      JMP                     ; if so, perform the jump
        jmp     so_emul_loop
JNZ:
        cmp     [r13 + 7], BYTE 0       ; check if state Z flag is false
        je      JMP                     ; if so, perform the jump
        jmp     so_emul_loop
JZ:
        cmp     [r13 + 7], BYTE 1       ; check if state Z flag is true
        je      JMP                     ; if so, perform the jump
        jmp     so_emul_loop

update_CF:
        call    update_state_CF
        jmp     so_emul_loop
update_CF_ZF:
        call    update_state_CF
update_ZF:
        call    update_state_ZF
        jmp     so_emul_loop

return:   
        mov     rax, [r13]              ; copy the final state into RAX registry for function return
        add     rsp, QWORD 8            ; restore original stack alignment
        pop     r14
        pop     r13
        pop     r12
        ret
