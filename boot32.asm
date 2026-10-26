; In our previous bootloader, our CPU was sstill in Real Mode. That is, we can only call
; BIOS functions via interrupts, use 16 biy instructions, and address up to 1MB of memory.
; To access more than !MD of memory, we are going to enable th A20 line by calling the
; "A20-Gate Activate" function. 

BITS 16
org 0x7C00

boot:
	cli			; disable interrupts during setup
	cld			; clear direction flag
	mov ax, 0x2401		; moving 0x2401 is used to enables the A20 gate: access memory > 1MB
	int 0x15		; this is the sytem services interrupt, it handles different
				; services based on the value loaded into the AH, AL, AX register

	mov ax, 0x3		; Video mode 3 
	int 0x10		; triggers a BIOS software interrupt that provides video display and graphics	
	
	; Now we will enable 32 bit instructions and access 32 bit registers by entering the Protected Mode. We
	; will have to set up the Global Descriptor Table which will define a 32 bit code segment. We will load
	; the GDT with the lgdt instruction, and then do a long jump to that code segment


	lgdt [gdt_pointer]	; load the gdt table
	mov eax, cr0		; cr0 is the special control register, setting this to one switches the CPU to 32bit mode
	or eax, 0x1		; set the procteded mode bit to 1
	mov cr0, eax
	
	jmp CODE_SEG:boot32

	; The GDT that will set up involves 3 parts: a NULL segemnt, a code segment, and a data segement. 

gdt_start:
	dq 0x0			; NULL descriptot

gdt_code:
	dw 0xFFFF		; Limit (bits 0 - 15)
	dw 0x0			; Base 	(bits 0 - 15)
	db 0x0			; Base 	(bits 0 - 15)
	db 10011010b		; Access Byte
	db 11001111b		; Flags & Limit (bits 16 - 19)
	db 0x0			; Base 	(bits 24 - 31) 

gdt_data:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0
	
gdt_end:

	; To actually load the GDT, we need a GDT pointer structure. This is a 16 bit field containg the GDT size
	; followed by a 32 bit pointer to the structure itself. We will also define the CODE_SEG and DATA_SEG value
	; which are offsets into the gdt for later use

gdt_pointer:
	dw gdt_end - gdt_start - 1; SIZE Minus 1
	dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

	; Now we have enough to enter the 32 bit mode. We will also set the remaining segments to point at the DS

BITS 32
boot32:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esi, msg
	mov ebx, 0xB8000		; text-mode with VRAM base pointer

.print_message:
	lodsb
	or al, al
	jz halt
	or eax, 0x0700			; white text on black background
	mov word [ebx], ax
	add ebx, 2
	jmp .print_message

halt:
	cli
	hlt
	jmp halt

msg:
	db "Welcome to OliveOS 32-bit Mode", 0

times 510 - ($ - $$) db 0		; pad the remainder of 512 bytes with zeros
dw 0xAA55				; Boot sector signature
