STACK SEGMENT PARA STACK
	DB 64 DUP(' ') ; Fills stack with 64 empty spaces
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	; Ball properties, DB because using 16 bit registers
	BALL_X DW 0Ah
	BALL_Y DW 0Ah
	BALL_SIZE DW 04h ; N x N
	
DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
	
	; Moves DATA to the data segment
	ASSUME CS:CODE, DS:DATA, SS:STACK
	PUSH DS			
	XOR AX, AX
	PUSH AX
	MOV AX, DATA
	mov DS, AX
	POP AX				
	POP AX
	
		; Setting video mode
		MOV AH, 00h
		MOV AL, 13h
		INT 10h
		
		; Setting background color
		MOV AH, 0Bh
		MOV BH, 00h
		MOV BL, 00h ; Black
		INT 10h
		
		CALL DRAW_BALL
		
		; Print A for debugging
		;MOV DL, 'A'
		;mov AH, 6h
		;INT 21h
		
		RET
	MAIN ENDP
	
	DRAW_BALL PROC NEAR
		
		MOV CX, BALL_X ; Start X
		MOV DX, BALL_Y ; Start Y
		
		; For the loop
		mov SI, 0
		mov DI, 0
		
		ROW:
			MOV CX, BALL_X
			MOV SI, 0
			COL:
			; Draw a pixel
				MOV AH, 0Ch
				MOV AL, 03h ; Cyan
				MOV BH, 00h
				INT 10h
				
				INC CX
				INC SI
				CMP SI, BALL_SIZE
				JB COL
			
			INC DX
			INC DI
			CMP DI, BALL_SIZE
			JB ROW
		
		
		RET
	DRAW_BALL ENDP
	
CODE ENDS
END

