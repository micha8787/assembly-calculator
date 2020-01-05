
; macro that checks if hex num is letter or number in ascii
%macro AsciiToNum 1
    cmp %1, 63 ; to check if numbers or letters (number between numbers and letters in ascii)
    jl %%next
    sub %1, 7
    %%next:
    sub %1, 48
%endmacro

%macro Addition 2
    mov ecx, %1 ; eax is bigger
    mov edx, %2 ; ebx is smaller
    mov eax, ecx
    mov ebx, edx
    ; allocate head of the new list
    pushad
    push 5
    call malloc
    add esp, 4
    mov [current_address], eax
    popad
    push dword [current_address] ; remember the address of the head
    
    mov ch,0 ; used for carry flag
    
%%smaller_loop:
    push eax
    mov cl, [eax]
    add cl, ch
    lahf
    and ah, 1
    mov ch, ah
    add cl, [ebx]
    lahf
    and ah, 1
    or ch, ah
    pop eax
    
    ; copy data to the new node
    mov edx, [current_address]
    mov [edx], cl
    
    ; allocate size for new node
    pushad
    push 5
    call malloc
    add esp, 4
    mov [current_address], eax
    popad
    
    ; copy address to the new node
    inc edx
    mov esi, [current_address]
    mov dword [edx], esi
    
    
    ; move to the next addresses
    inc eax
    mov eax, [eax]
    inc ebx
    mov ebx, [ebx]
    cmp ebx,0
    jnz %%smaller_loop
%%bigger_loop:
    cmp eax,0
    jz %%final_node
    push eax
    mov cl, [eax]
    add cl, ch
    lahf
    and ah, 1
    mov ch, ah
    pop eax
    
    ; edx is now used to traverse the new link
    mov edx, [current_address]
    mov [edx], cl
    
    pushad
    push 5
    call malloc
    add esp, 4
    mov [current_address], eax
    popad
    
    inc edx
    mov esi, [current_address]
    mov [edx], esi
    
    inc eax
    mov eax, [eax]
    jmp %%bigger_loop
%%final_node:
    cmp ch, 1
    jnz %%no_carry
    mov byte [esi], 1
    inc esi
    mov dword [esi], 0
    jmp %%end
%%no_carry:
    pushad
    push esi
    call free
    add esp, 4
    popad
    mov dword [edx], 0
%%end:
    pop dword [current_address]
%endmacro

section .rodata
	format_string: db "%s", 10, 0
	format_string_decimal: db "%d", 10, 0
	format_string_hex: db "%02X",0
    format_string_hex_just_one: db "%X", 0
	format_string_no_newline: db "%s", 0
	backslash: db 10,0

	overFlow_string: db "Error: Operand Stack Overflow",10,0
	Insufficient_string: db "Error: Insufficient Number of Arguments on Stack",10,0
    power_string: db "Bad arguments for power function",10,0

	Calc_string: db "calc: ",0
	stack_size EQU 5
	
section .bss
	input: resb 80
	stack: resb stack_size*4 ; 5 slots for 5 addresses
	current_address: resb 4
    operation_counter: resb 4
    debug_mode: resb 1

section .data
    stack_counter: db 0

section .text
  align 16
     global main 
     extern printf 
     extern fprintf
     extern fflush
     extern malloc 
     extern calloc 
     extern free 
     extern gets 
     extern fgets 
main: 
    mov byte [debug_mode], 0
    ; check debug mode
    cmp dword [esp+4], 2
    jnz main_no_debug
    inc byte [debug_mode]
main_no_debug:
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents (do_Str(...) activation frame)
    

    mov dword [operation_counter], 0
	call myCalc
	add esp,4
	push eax
	push format_string_hex_just_one
	call printf
	add esp,8
	push backslash
    call printf
    add esp, 4

    ;free our stack
    mov ecx, [stack_counter]
    cmp ecx, 0
    jz nothing_to_free
main_free_loop:
    call free_stack
    loop main_free_loop, ecx
nothing_to_free:
    mov esp, ebp			; free function activation frame
    pop ebp				; restore Base Pointer previous value (to returnt to the activation frame of main(...))
    ret
    

myCalc:
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad
get_input:
    push format_string
	push Calc_string
	call printf
	add esp,8
	
	push input
	call gets
	add esp,4
    
	cmp byte [input],'q'
	jz end
	inc dword [operation_counter]
	;  start checking if operation
	cmp byte [input], '+' ; addition
	jz plus
	cmp byte [input], 'p' ; pop-and-printf
	jz pap
	cmp byte [input], 'd' ; duplicate
	jz dupe
	cmp byte [input], '^' ; power
	jz power
	cmp byte [input], 'v' ; also power
	jz power_neg
	cmp byte [input], 'n' ; number of 1 bits
	jz nbits
	
    dec dword [operation_counter]

    cmp byte [debug_mode], 1
    jnz no_debug_input_print
    pushad
    push input
    push format_string
    call printf
    add esp, 8
    popad
no_debug_input_print:
    
	mov ecx, -1 ;  length
	length:
	inc ecx
	cmp byte [input+ecx], 0
	jnz length
	
	call check_availability
	cmp eax, 1 ; check if can enter
	jnz get_input
	
	mov ebx, [stack_counter]
	shl ebx,2
	add ebx,stack
	mov [current_address], ebx
	mov ebx,0
push_ascii:
    mov eax,0
    mov ebx,0
    cmp ecx, 1
    jz next
    mov edx, ecx
    sub edx, 2
    mov byte al, [input+edx]
    AsciiToNum al
    shl al, 4
    next:
    mov edx, ecx
    dec edx
    mov byte bl, [input+edx]
    AsciiToNum bl
    or bl, al
    
    pushad
    push 5
	call malloc
	add esp,4
	mov ebx, [current_address]
	mov [ebx], eax
    popad
    
    mov edx, [current_address]
    mov eax, [edx]
    mov [eax], bl
    mov dword [eax+1], 0
    inc eax
    mov [current_address], eax
    
    sub ecx, 2
    cmp ecx, 0
    jg push_ascii
    inc byte [stack_counter]
	jmp get_input
	;push format_string
	;push input
	;call printf
	;add esp,8

end:
	popad                   ; Restore caller state (registers)
    mov     eax, [operation_counter]    ; place returned value where caller can see it
    pop     ebp             ; Restore caller state
    ret      


;------------operation functions------------

power_neg: ; v
    call check_powers
    cmp eax, 0
    jz get_input
    ; eax holds pointer to first list
    ; ecx holds the power
    cmp ecx, 0
    jz power_neg_zero_case
power_neg_big_loop:
    shr byte [eax], 1
    mov edx, eax ; edx remembers the previous node
    mov ebx, eax
    inc ebx
    cmp dword [ebx],0
    jz power_neg_skip_loop
power_neg_small_loop:
    mov ebx, [ebx]
    shr byte [ebx], 1
    jnc power_neg_no_carry
    or byte [edx], 128
    power_neg_no_carry:
    mov edx, ebx
    inc ebx
    cmp dword [ebx], 0
    jnz power_neg_small_loop
power_neg_skip_loop:
    loop power_neg_big_loop, ecx
power_neg_zero_case:
    dec byte [stack_counter]
    call free_stack
    mov ecx, [stack_counter]
    shl ecx, 2
    mov [stack+ecx], eax
    inc byte [stack_counter]
    jmp get_input



power: ; ^
    call check_powers
    cmp eax, 0
    jz get_input
    cmp ecx, 0
    jz power_dont_do_anything
power_loop:
    call duplicate_stack
    call plus_stack
    loop power_loop, ecx
power_dont_do_anything:
    jmp get_input



plus: ; add two operands from stack and push result
    cmp byte [stack_counter], 2
    jge plus_available
    pushad
    push Insufficient_string
    push format_string
    call printf
    add esp, 8
    popad
    jmp get_input
plus_available:
    call plus_stack
    jmp get_input
    
    
dupe: ; duplicates the top of the stack
    call check_availability
    cmp eax, 0
    jz get_input
    ; check if there's something to dupe at all
    cmp byte [stack_counter],0
    jnz dupe_ok
    push Insufficient_string
    push format_string
    call printf
    add esp, 8
    jmp get_input
dupe_ok:
    call duplicate_stack
    jmp get_input
    
    
pap: ; pop and print
    call peek
    cmp eax, 0
    jz get_input
    mov ecx, 0
pap_loop:
    inc ecx
    mov ebx, 0
    mov bl, [eax]
    push ebx
    inc eax
    mov dword eax, [eax]
    cmp eax, 0
    jnz pap_loop
leading_zero_skip:
    pop ebx
    dec ecx
    cmp ecx, 0
    jz pap_next
    cmp ebx, 0
    jz leading_zero_skip
pap_next:
    pushad
    push ebx
    push format_string_hex_just_one
    call printf
    add esp,8
    popad
    cmp ecx, 0
    jz pap_end
pap_print:
    pop ebx
    pushad
    push ebx
    push format_string_hex
    call printf
    add esp,8
    popad
    loop pap_print, ecx
pap_end:
    push backslash
    push format_string_no_newline
    call printf
    add esp,8
    call free_stack
    jmp get_input

    
nbits: ; prints number of 1 bits
    call peek
    cmp eax, 0
    jz get_input


    pushad
    push 5
	call malloc
	add esp,4
    mov [current_address], eax
    popad

    mov edx, [current_address]
    push edx ; used to get the head of the link later
    mov byte [edx], 0
    mov dword [edx+1], 0
    mov ebx, 0 ; used to store the link data
nbits_outerloop:
    mov bl, [eax] ; bl holds the data of the link
    mov ecx, 8
nbits_innerloop:
    shr bl,1
    jnc nbits_nocarry
    add byte [edx], 1
    jnc nbits_nocarry
    ; allocating new link
    pushad
    push 5
	call malloc
	add esp,4
    mov [current_address], eax
    popad
    mov esi, [current_address]
    mov dword [edx+1], esi
    mov edx, esi
    mov byte [edx], 1
    mov dword [edx+1], 0
nbits_nocarry:
    loop nbits_innerloop, ecx
    inc eax
    mov eax,[eax] ; now eax points to the next link
    cmp eax, 0
    jnz nbits_outerloop

; now it's time to print
    call free_stack
    pop edx ; getting the head of the link
    mov eax, [stack_counter]
    mov dword [stack+eax*4], edx
    inc byte [stack_counter];
    jmp get_input
    
    
;-----------helper functions-----------

check_powers:
    push    ebp             ; Save caller state
    mov     ebp, esp

    mov eax, 0
    cmp byte [stack_counter], 2
    jge power_not_empty
    push eax
    push Insufficient_string
    push format_string
    call printf
    add esp, 8
    pop eax
    jmp power_check_end
    power_not_empty:
    cmp byte [stack_counter], stack_size
    jnz power_available
    push eax
    push overFlow_string
    push format_string
    call printf
    add esp, 8
    pop eax
    jmp power_check_end
power_available:
    call peek
    mov ebx, [stack_counter]
    sub ebx, 2
    mov ebx, [stack+ebx*4]
    ; now eax holds first, and ebx holds second

    ;initialize ecx to 0:
    mov ecx, 0
    mov cl, [ebx] ; holds the data of the seconed element (y)
    cmp ecx, 200
    jle power_checkaddress
power_bad:
    pushad
    push power_string
    push format_string
    call printf
    add esp,8
    popad
    mov eax, 0
    jmp power_check_end
power_checkaddress:
    inc ebx
    cmp dword [ebx], 0
    jnz power_bad
power_check_end:
    pop     ebp             ; Restore caller state
    ret

peek: ; pops an address from the head of the stack
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad
    
    mov eax, [stack_counter]
    cmp eax,0
    jnz canpop
    pushad
    push Insufficient_string
    push format_string
    call printf
    add esp, 8
    popad
    mov dword [ebp-4], 0
    jmp popend
canpop:
    dec eax
    mov dword ebx, [stack+eax*4]
    mov [ebp-4], ebx
popend:
    popad                   ; Restore caller state (registers)
    mov eax, [ebp-4]
    add     esp, 4
    pop     ebp             ; Restore caller state
    ret


free_stack: ; frees the last stack slots
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad
    
    mov eax, [stack_counter]
    dec eax
    mov dword ebx, [stack+eax*4] ; ebx holds current node

free_stack_loop:
    mov dword ecx, [ebx+1] ; ecx holds next node
    
    ; free current node
    pushad
    push ebx
    call free
    add esp,4
    popad
    
    mov ebx, ecx
    cmp ebx, 0
    jnz free_stack_loop
    
    dec byte [stack_counter]
    
    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret
    
    
check_availability: ; checks if stack isn't full
; 1 if free, 0 if full
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad
    
    mov eax, 1
    cmp byte [stack_counter], stack_size
    jnz available
    pushad
    push overFlow_string
    push format_string
    call printf
    add esp, 8
    popad
    dec eax
available:
    mov [ebp-4],eax
    popad                   ; Restore caller state (registers)
    mov eax, [ebp-4]
    add     esp, 4
    pop     ebp             ; Restore caller state
    ret

    
duplicate_stack: ; duplicates our stack
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad
    
    mov eax, [stack_counter]
    dec eax
    mov dword ebx, [stack+eax*4] ; ebx holds current node
    inc eax
    shl eax,2
    add eax, stack
    ;mov eax, [eax]
    
dupe_loop:
    mov dword [current_address], eax
    
    pushad
    push 5
	call malloc
	add esp,4
	mov ebx, [current_address]
	mov [ebx], eax
    popad
    
    mov cl, [ebx]
    mov eax, [current_address]
    mov eax, [eax]
    mov [eax], cl ; copying data from current node to new node
    inc eax
    mov dword [eax],0
    mov [current_address], eax ; updating current address to be the address of the new node
    inc ebx
    mov ebx, [ebx]
    cmp ebx, 0
    jnz dupe_loop
    inc dword [stack_counter]
    
    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret
    
plus_stack: ; adds the top 2 links in the stacks
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad

    call peek
    push eax ; push first address
    mov ebx, 0 ; length of second
    mov ecx, 0 ; length of first
plus_loop:
    inc ecx
    inc eax
    mov eax,[eax]
    cmp eax,0
    jnz plus_loop
    ; now ecx is length of first
    mov eax, [stack_counter]
    sub eax, 2
    mov eax, [stack+eax*4]
    push eax ; push second address
    mov edx, 0
plus_loop2:
    inc edx
    inc eax
    mov eax,[eax]
    cmp eax,0
    jnz plus_loop2
    ; now edx holds length of second
    pop ebx ; holds second address
    pop eax ; holds head address
    cmp ecx, edx
    jl smaller
    Addition eax, ebx
    jmp plus_end
smaller:
    Addition ebx, eax
plus_end:
    call free_stack
    call free_stack
    mov eax, [current_address]
    mov ebx, [stack_counter]
    mov [stack+ebx*4], eax
    inc byte [stack_counter]
    
    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret
