global polynomial_degree

; r12 - stores the value of n
; r13 - stores the length of one bignum (number of 64-bit words making up one bignum)
; r14 - stores pointer to the beginning of bignum array (with space for n bignums)

polynomial_degree:
        push    r12
        push    r13
        push    r14

        mov     r12, rsi                ; store the value of n in R12 registry
        mov     r13, rsi                ; copy the value of n to R13 registry
        shr     r13, 6                  ; equivalent to dividing R13 by 2^6 to get no. of 64-bit words per bignum
        lea     r13, [r13 + 2]          ; add two 64-bit words - one for divison insufficiency and one for initial value

        lea     rdx, [r13 * 8]          ; multiply bignum length by 8 to get number of bytes per bignum; store in RDX registry
        imul    rdx, r12                ; multiply the value by number of bignums n
        sub     rsp, rdx                ; reserve memory on stack
        mov     r14, rsp                ; store the pointer to beginning of bignum array in R14 registry

        mov     rdx, r12                ; copy the value of n to RDX registry (this is copy_data_loop counter)
        mov     r8, rdi                 ; copy the pointer to provided integer array to R8 registry
        mov     r9, r14                 ; copy the pointer to beginning of bignum array to R9 registry

copy_data_loop:
        movsxd  rax, DWORD [r8]         ; copy one 32-bit number from provided array; expand to 64-bit
        mov     [r9], rax               ; store inside bignum array
        lea     rdi, [r9 + 8]           ; save pointer to next bignum section in RDI registry (bignums always have min. 2 sections)
        lea     rcx, [r13 * 8 - 8]      ; save to RCX how many bytes are left in the bignum having already filled 8 bytes
        sar     rax, 63                 ; flush the RAX registry with the most significant bit of processed number
        rep     stosb                   ; fill the rest of the bignum with the most significant bit of processed number
        lea     r8, [r8 + 4]            ; move pointer to the next provided 32-bit number
        lea     r9, [r9 + r13 * 8]      ; move pointer to the next bignum beginning
        dec     rdx
        jne     copy_data_loop

copy_data_exit:
        mov     rax, QWORD -1           ; set RAX registry to smallest possible polynomial degree
        mov     rdi, r12                ; set RDI value to n (how many bignums should be processed by loops inside find_degree_loop)
find_degree_loop:                       ; we will use finite differences method to determine the smallest possible polynomial degree
        mov     rsi, rdi                ; copy the value from RDI registry and save in RSI registry (zero_polynomial_loop counter)
        mov     rdx, r14                ; copy the pointer to the beginning of bignum array
zero_polynomial_loop:
        mov     rcx, r13                ; copy the length of one bignum and save in RCX registry (zero_bignum_loop counter)
zero_bignum_loop:
        cmp     QWORD [rdx], QWORD 0    ; check if 64-bit section of bignum is equal to zero
        jne     zero_polynomial_exit    ; if not, skip the rest and proceed to zero_polynomial_exit
        lea     rdx, [rdx + 8]          ; move pointer to the next bignum section
        loop    zero_bignum_loop

        dec     rsi
        jne     zero_polynomial_loop
        
        jmp find_degree_exit            ; if this instruction is reached, all significant bignums are equal to zero; result is in RDI registry

zero_polynomial_exit:
        inc     rax             
        dec     rdi
        je      find_degree_exit        ; if no bignums are left to process, proceed to zero_polynomial_exit 
        mov     rsi, rdi                ; copy the value from RDI registry and save in RSI registry (compute_differences_loop counter)
        mov     rdx, r14                ; copy the pointer to the beginning of bignum array
compute_differences_loop:
        mov     rcx, r13                ; copy the length of one bignum and save in RCX registry (zero_bignum_loop counter)
        clc                             ; reset the Carry Flag to zero
subtract_bignums_loop:
        mov     r8, [rdx + r13 * 8]     ; store the subsequent bignum's segment in R8 registry
        sbb     r8, [rdx]               ; subtract the current bignum's corresponding segment
        mov     [rdx], r8               ; overwrite the current bignum's segment with the result
        lea     rdx, [rdx + 8]          ; move the pointer
        loop    subtract_bignums_loop
                
        dec     rsi
        jne     compute_differences_loop

        jmp     find_degree_loop

find_degree_exit:
        lea     rdx, [r13 * 8]          ; multiply bignum length by 8 to get number of bytes per bignum; store in RDX registry
        imul    rdx, r12                ; multiply the value by number of bignums n
        lea     rsp, [rsp + rdx]        ; reserve memory on stack

        pop     r14
        pop     r13
        pop     r12
        ret
