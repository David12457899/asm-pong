STACK SEGMENT PARA STACK
	DB 64 DUP(' ') ; Fills stack with 64 empty spaces
STACK ENDS

DATA SEGMENT PARA 'DATA'
DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
		
		
		; Setting video mode
		MOV AH, 00h
		MOV AL, 13h
		INT 10h
		
		; Setting background color
		MOV AH, 0Bh
		MOV BH, 00h
		MOV BL, 00h ; Black
		INT 10h
		
		; Draw a pixel
		MOV AH, 0Ch
		MOV AL, 03h ; Cyan
		MOV BH, 00h
		MOV CX, 0Ah ; X
		MOV DX, 0Ah ; Y
		INT 10h
		
		; Print A for debugging
		;MOV DL, 'A'
		;mov AH, 6h
		;INT 21h
		
		RET
	MAIN ENDP
	
CODE ENDS
END