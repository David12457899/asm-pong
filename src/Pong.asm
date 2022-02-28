STACK SEGMENT PARA STACK
	DB 64 DUP(' ') ; Fills stack with 64 empty spaces
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	; Screen dimensions
	WINDOW_WIDTH DW 320 ; 320 pixels
	WINDOW_HEIGHT DW 200 ; 200 pixels
	WINDOW_BOUNDS DW 6 ; arbitrary, to check collisions early
	
	; Time
	TIME_AUX DB 0 ; Last ms time, check for time delta
	
	; Ball properties, DB because using 16 bit registers
	BALL_ORIGINAL_X DW 160 ; Initial position of the ball
	BALL_ORIGINAL_Y DW 100
	
	BALL_X DW 0Ah
	BALL_Y DW 0Ah
	BALL_SIZE DW 04h ; N x N
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	
	; Paddle properties
	PADDLE_LEFT_X DW 0Ah;
	PADDLE_LEFT_Y DW 0Ah;
	
	PADDLE_RIGHT_X DW 130h;
	PADDLE_RIGHT_Y DW 0Ah;
	
	PADDLE_WIDTH DW 05h;
	PADDLE_HEIGHT DW 1Fh;
	
	PADDLE_COLOR DW 03h
	BALL_COLOR DW 03h
	
	
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
	
		CALL CLEAR_SCREEN
		
		CHECK_TIME:
			; Getting the system time
			MOV AH, 2Ch
			INT 21h
		
			CMP DL, TIME_AUX
			JE CHECK_TIME
		
		GAME_FRAME:
			MOV TIME_AUX, DL ; Saving time for later checking
			
			CALL MOVE_BALL
			CALL CLEAR_SCREEN
			
			CALL DRAW_PADDLES
			
			CALL DRAW_BALL
			JMP CHECK_TIME
		
		; Print A for debugging
		;MOV DL, 'A'
		;mov AH, 6h
		;INT 21h
		
		RET
	MAIN ENDP
	
	MOVE_BALL PROC NEAR
		; Move the ball
		
		MOVE_X:
			; X axis
			MOV AX, BALL_VELOCITY_X
			ADD BALL_X, AX
			
			; Check x boundaries
			CMP BALL_X, 00h
			JL RESET_POSITION
			
			MOV AX, WINDOW_WIDTH
			SUB AX, BALL_SIZE
			SUB AX, WINDOW_BOUNDS
			CMP BALL_X, AX
			JG RESET_POSITION
		
		MOVE_Y:
			; Y AXIS
			MOV AX, BALL_VELOCITY_Y
			ADD BALL_Y, AX
			
			; check y boundries
			CMP BALL_Y, 00h
			JL NEG_VELOCITY_Y
			
			MOV AX, WINDOW_HEIGHT
			SUB AX, BALL_SIZE
			SUB AX, WINDOW_BOUNDS
			CMP BALL_Y, AX
			JG NEG_VELOCITY_Y
		
		JMP END_FUNC
		
		RESET_POSITION:
			CALL RESET_BALL_POSITION
			JMP END_FUNC
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y
			JMP END_FUNC
		
		END_FUNC:
			RET
	MOVE_BALL ENDP
	
	RESET_BALL_POSITION PROC NEAR
		
		MOV AX, BALL_ORIGINAL_X
		MOV BALL_X, AX
		
		MOV AX, BALL_ORIGINAL_Y
		MOV BALL_Y, AX
		
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR
		
		MOV CX, BALL_X ; Start X
		MOV DX, BALL_Y ; Start Y
		
		; loop
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
	
	DRAW_PADDLES PROC NEAR
		
		; Left paddle
		MOV CX, PADDLE_LEFT_X ; Start X
		MOV DX, PADDLE_LEFT_Y ; Start Y
		
		; loop
		mov SI, 0
		mov DI, 0
		
		LEFT_PADDLE_ROW:
			MOV CX, PADDLE_LEFT_X
			MOV SI, 0
			LEFT_PADDLE_COL:
			; Draw a pixel
				MOV AH, 0Ch
				MOV AL, 03h ; Cyan
				MOV BH, 00h
				INT 10h
				
				INC CX
				INC SI
				CMP SI, PADDLE_WIDTH
				JB LEFT_PADDLE_COL
			
			INC DX
			INC DI
			CMP DI, PADDLE_HEIGHT
			JB LEFT_PADDLE_ROW
		
		; Right paddle
		
		MOV CX, PADDLE_RIGHT_X ; Start X
		MOV DX, PADDLE_RIGHT_Y ; Start Y
		
		; loop
		mov SI, 0
		mov DI, 0
		
		RIGHT_PADDLE_ROW:
			MOV CX, PADDLE_RIGHT_X
			MOV SI, 0
			RIGHT_PADDLE_COL:
			; Draw a pixel
				MOV AH, 0Ch
				MOV AL, 03h ; Cyan
				MOV BH, 00h
				INT 10h
				
				INC CX
				INC SI
				CMP SI, PADDLE_WIDTH
				JB RIGHT_PADDLE_COL
			
			INC DX
			INC DI
			CMP DI, PADDLE_HEIGHT
			JB RIGHT_PADDLE_ROW
		
		RET
	DRAW_PADDLES ENDP
	
	CLEAR_SCREEN PROC NEAR
	
		; Setting video mode
		MOV AH, 00h
		MOV AL, 13h
		INT 10h
		
		; Setting background color
		MOV AH, 0Bh
		MOV BH, 00h
		MOV BL, 00h ; Black
		INT 10h
		
		RET
	CLEAR_SCREEN ENDP
	
CODE ENDS
END

