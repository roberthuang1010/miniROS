;================================================================
;	File: pm.asm
;	The protect mode of the simple OS 
;================================================================

%include	"pm.inc"	;

	org		07c00h
			jmp		LABEL_BEGIN

	[SECTION .gdt]
	;
	;
	LABEL_GDT:		Descriptor	0,				 0,	0	;
	LABEL_DESC_CODE32:	Descriptor	0,	SegCode32Len - 1,	DA_C + DA_32	;
	LABEL_DESC_VIDEO:	Descriptor 0B8000h,	0ffffh,	DA_DRW	;
	;

	GdtLen	equ	$ - LABEL_GDT	;
	GdtPtr	dw	GdtLen - 1		;
			dd	0				;

	;
	SelectorCode32	equ	LABEL_DESC_CODE32	-	LABEL_GDT
	SelectorVideo	equ	LABEL_DESC_VIDEO	-	LABEL_GDT
	; END of [SECTION .gdt]

	[SECTION .s16]
	[BITS 16]
	LABEL_BEGIN:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ss, ax
		mov	sp, 0100h

		;initialize 32 bit code segment descriptor
		xor	eax, eax
		mov	ax, cs
		shl	eax, 4
		add	eax, LABEL_SEG_CODE32
		mov	word [LABEL_DESC_CODE32 + 2], ax
		shr	eax, 16
		mov	byte [LABEL_DESC_CODE32 + 4], al
		mov	byte [LABEL_DESC_CODE32 + 7], ah

		;prepare to mount GDTR
		xor	eax, eax
		mov	ax, ds
		shl	eax, 4
		add	eax, LABEL_GDT		;eax <- gdt
		mov	dword [GdtPtr + 2], eax	;[GdtPtr + 2] <- gdt

		;mount GDTR
		lgdt	[GdtPtr]

		;
		cli

		;open A20 address line
		in	al, 92h
		or	al, 00000010b
		out	92h, al

		;prepare to shift to protect mode
		mov	eax, cr0
		or	eax, 1
		mov	cr0, eax

		;now we enter protect mode
		jmp	dword SelectorCode32:0	;
									;
		; END of [SECTION .s16]


	[SECTION .s32];	32 bits code segment, jump from real mode
	[BITS 32]

	LABEL_SEG_CODE32:
		mov	ax, SelectorVideo
		mov	gs, ax			;Video segment Selector

		mov	edi, (80 * 11 + 79) * 2	;the 11 col 79 row of the screen
		mov	ah, 0Ch			;0000:black background 1100: red font
		mov	al, 'Protected Mode of Arbutus OS'
		mov	[gs:edi], ax;

		;the end of jmp
		jmp	$

	SegCode32Len	equ	$ - LABEL_SEG_CODE32
	;END of [SECTION .s32]
