org 0x7C00	; Tell the assembler that the BIOS will be loaded from this area in memory
BITS 16		; Tells the assembler that we will be working in 16-bit real mode

start:
	cli		; Clear interrupts
	xor ax, ax	; xoring a register with itself sets it to zero
	mov ds, ax	; set the data segment to zero
	mov es, ax	; set the extra segment to zero
	
	mov si, msg	; let the si register point to our message string
	call print_string

halt_loop:
	cli
	hlt
	jmp halt_loop

print_string:
	lodsb		; load the next character from si and store it in al
	or al, al	; verify if al is the null terminatior or not
	jz .done	; if al was the null terminator, we would have had a zero flag
	mov ah, 0x0E	; BIOS teletype function
	int 0x10	; call the video interrupt
	jmp print_string	

.done:
	ret

msg:
	db "Hello from OliveOS", 0

times 510 - ($ - $$) db 0 	;Fill the remaining 512-byte sector with zeros, ending at the memory address 0xAA55
dw 0xAA55
