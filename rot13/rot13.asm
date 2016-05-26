; rot13 encryption in x86 assembly language for linux
; written by Florian Weingarten (21.10.2004)

; assemble and link with:
;  nasm -f elf rot13.asm && ld rot13.o -o rot13 && rm -f rot13.o

; reads ascii text from standard input, "encrypts" it and writes it
; back to standard output

section .text
	global _start

bufsize equ 255

_start:	

; read loop
rl:    call read		; read data
       cmp eax, 0		  ; if eof is reached, exit
       jz ende

       mov ebx, buf
       mov cx, bufsize
il:    call rot13		; if not, encrypt
       inc ebx
       loop il
       
       call write		; and write
       jmp rl			      ; and loop

; ende exits the program
ende:  mov eax, 1
       mov ebx, 0
       int 0x80

; read reads from stdin and stores number of read bytes into eax
read:  push ebx	  	; store other registers
       push ecx
       push edx
       mov eax, 3		; sys_read()
       mov ebx, 0		  ; stdin
       mov ecx, buf
       mov edx, bufsize
       int 0x80
       pop edx			; restore registers
       pop ecx
       pop ebx
       ret

; encrypts a string (pointer in ebx, len in ecx) with rot13
rot13:	   cmp byte [ebx], 'A'	; dont change char if its below 'A' in ascii set
	   jb return	   	;
	   
	   cmp byte [ebx], 'Z'	; dont change if above 'Z', but below 'a'
	   ja z1    	   	;
	   jmp rot				;
z1:	   cmp byte [ebx], 'a'			;
	   jb return	   			;

rot:	   cmp byte [ebx], 'M'			; jump if above big m (M) (abm)
	   ja abm   	   			
	   jmp radd

abm:	   cmp byte [ebx], 'Z'	; jump if above big z (Z) (abz)
	   ja abz
	   jmp rsub

abz:	   cmp byte [ebx], 'm'
	   ja alm
	   jmp radd

alm:	   cmp byte [ebx], 'z'
	   ja return
	   jmp rsub

radd:	   add byte [ebx], 13
	   jmp return
rsub:	   sub byte [ebx], 13
return:	   ret

; write writes to stdout, number of bytes to write is taken from eax
write:	mov edx, eax
	push ebx
	push ecx
	mov eax, 4		; sys_write()
	mov ebx, 1		  ; stdout
	mov ecx, buf
	int 0x80
	pop ecx
	pop ebx
	ret 

section .bss
buf resb bufsize