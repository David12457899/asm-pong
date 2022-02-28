STACK SEGMENT PARA STACK
	DB 64 DUP(' ') ; Fills stack with 64 empty spaces
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	; Game
	MAX_GAME_POINTS DB 5
	
	; Players
	TEXT_PLAYER_ONE_POINTS DB '0', '$'
	TEXT_PLAYER_TWO_POINTS DB '0', '$'
	
	; Screen dimensions
	WINDOW_WIDTH DW 320 ; 320 pixels
	WINDOW_HEIGHT DW 200 ; 200 pixels
	WINDOW_BOUNDS DW 6 ; arbitrary, to check collisions early
	
	; Time
	TIME_AUX DB 0 ; Last ms time, check for time delta
	
	; Ball properties, DW because using 16 bit registers
	BALL_ORIGINAL_X DW 160 ; Initial position of the ball
	BALL_ORIGINAL_Y DW 100
	BALL_COLOR DW 03h
	
	BALL_X DW 0Ah
	BALL_Y DW 0Ah
	BALL_SIZE DW 04h ; N x N
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	
	; Paddle properties
	PADDLE_LEFT_X DW 0Ah;
	PADDLE_LEFT_Y DW 0Ah;
	PLAYER_ONE_POINTS DB 0; points of the left player
	
	PADDLE_RIGHT_X DW 130h;
	PADDLE_RIGHT_Y DW 0Ah;
	PLAYER_TWO_POINTS DB 0; points of the right player
	
	PADDLE_WIDTH DW 05h;
	PADDLE_HEIGHT DW 1Fh;
	
	PADDLE_VELOCITY DW 05h
	
	PADDLE_COLOR DW 03h
	
	
	
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
			
			CALL CLEAR_SCREEN
			
			CALL MOVE_BALL
			CALL DRAW_BALL
			
			CALL MOVE_PADDLES
			CALL DRAW_PADDLES
			
			CALL DRAW_UI
			
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
			JL GIVE_POINT_TO_PLAYER_TWO
			
			MOV AX, WINDOW_WIDTH
			SUB AX, BALL_SIZE
			SUB AX, WINDOW_BOUNDS
			CMP BALL_X, AX
			JG GIVE_POINT_TO_PLAYER_ONE
			JMP MOVE_Y
		
		; Increment points of round winner
		GIVE_POINT_TO_PLAYER_ONE:
			INC PLAYER_ONE_POINTS
			CALL RESET_BALL_POSITION
			
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			
			; Check if player 1 has reached max points
			CMP PLAYER_ONE_POINTS, 5 ; comparing to the max game points
			JGE GAME_OVER
			RET
			
		GIVE_POINT_TO_PLAYER_TWO:
			INC PLAYER_TWO_POINTS
			CALL RESET_BALL_POSITION
			
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			
			; Check if player 2 has reached max points
			CMP PLAYER_TWO_POINTS, 5 ; comparing to the max game points
			JGE GAME_OVER
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS
			RET
		
		GAME_OVER:
			MOV PLAYER_ONE_POINTS, 00h
			MOV PLAYER_TWO_POINTS, 00h
			RET
		
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
			JMP CHECK_COLLISION_WITH_RIGHT_PADDLE
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y;
			RET
		
		CHECK_COLLISION_WITH_RIGHT_PADDLE:
			; Check right paddle collision
			MOV AX, BALL_X
			ADD AX, BALL_SIZE
			CMP AX, PADDLE_RIGHT_X
			; No collision
			JNG CHECK_COLLISION_WITH_LEFT_PADDLE
			
			MOV AX, PADDLE_RIGHT_X
			ADD AX, PADDLE_WIDTH
			CMP BALL_X, AX
			; No collision
			JNL CHECK_COLLISION_WITH_LEFT_PADDLE
			
			MOV AX, BALL_Y
			ADD AX, BALL_SIZE
			CMP AX, PADDLE_RIGHT_Y
			JNG CHECK_COLLISION_WITH_LEFT_PADDLE
			
			MOV AX, PADDLE_RIGHT_Y
			ADD AX, PADDLE_HEIGHT
			CMP BALL_Y, AX
			; No collision
			JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
			
			; Collision detected
			JMP NEG_VELOCITY_X
			
		; Check left paddle collision
		CHECK_COLLISION_WITH_LEFT_PADDLE:
			; Check right paddle collision
			MOV AX, BALL_X
			ADD AX, BALL_SIZE
			CMP AX, PADDLE_LEFT_X
			; No collision
			JNG END_FUNC
			
			MOV AX, PADDLE_LEFT_X
			ADD AX, PADDLE_WIDTH
			CMP BALL_X, AX
			; No collision
			JNL END_FUNC
			
			MOV AX, BALL_Y
			ADD AX, BALL_SIZE
			CMP AX, PADDLE_LEFT_Y
			JNG END_FUNC
			
			MOV AX, PADDLE_LEFT_Y
			ADD AX, PADDLE_HEIGHT
			CMP BALL_Y, AX
			; No collision
			JNL END_FUNC
		
			; Collision detected
			JMP NEG_VELOCITY_X
			
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X
			RET
			
		END_FUNC:
			RET
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR
		
		; Check if key is pressed
		MOV AH, 01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT
		
		; Check which key is pressed
		MOV AH, 00h
		INT 16h
		
		; Left paddle
		CHECK_LEFT_PADDLE_MOVEMENT:
			; Moving the paddle up
			CMP AL, 77h ; 'w'
			JE MOVE_LEFT_PADDLE_UP
			CMP AL, 57h ; 'W'
			JE MOVE_LEFT_PADDLE_UP
			
			; Moving the paddle down
			CMP AL, 73h ; 's'
			JE MOVE_LEFT_PADDLE_DOWN
			CMP AL, 53h ; 'S'
			JE MOVE_LEFT_PADDLE_DOWN
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
			MOVE_LEFT_PADDLE_UP:
				mov AX, PADDLE_VELOCITY
				SUB PADDLE_LEFT_Y, AX
				
				; Check boundaries
				MOV AX, WINDOW_BOUNDS
				CMP PADDLE_LEFT_Y, AX
				JL FIX_PADDLE_LEFT_TOP_POSITION
				; If boundaries are okay
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
				
				; If boundaries are not okay
				FIX_PADDLE_LEFT_TOP_POSITION:
					MOV PADDLE_LEFT_Y, AX
					JMP CHECK_RIGHT_PADDLE_MOVEMENT
				
			MOVE_LEFT_PADDLE_DOWN:
				mov AX, PADDLE_VELOCITY
				ADD PADDLE_LEFT_Y, AX
				
				; Check boundaries
				MOV AX, WINDOW_HEIGHT
				SUB AX, WINDOW_BOUNDS
				SUB AX, PADDLE_HEIGHT
				CMP PADDLE_LEFT_Y, AX
				JG FIX_PADDLE_LEFT_BOTTON_POSITION
				; If boundaries are okay
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
				
				; If boundaries are not okay
				FIX_PADDLE_LEFT_BOTTON_POSITION:
					MOV PADDLE_LEFT_Y, AX
					JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		
		; Right paddle
		CHECK_RIGHT_PADDLE_MOVEMENT:
			
			; Moving the paddle up
			CMP AL, 6Fh ; 'o'
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL, 4Fh ; 'O'
			JE MOVE_RIGHT_PADDLE_UP
			
			; Moving the paddle down
			CMP AL, 6Ch ; 'l'
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL, 4Ch ; 'L'
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP END_PADDLE_FUNC
		
			MOVE_RIGHT_PADDLE_UP:
				
				mov AX, PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y, AX
				
				; Check boundaries
				MOV AX, WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y, AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				; If boundaries are okay
				JMP END_PADDLE_FUNC
				
				; If boundaries are not okay
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV AX, WINDOW_BOUNDS
					MOV PADDLE_RIGHT_Y, AX
					JMP END_PADDLE_FUNC
				
			MOVE_RIGHT_PADDLE_DOWN:
				mov AX, PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y, AX
				
				; Check boundaries
				MOV AX, WINDOW_HEIGHT
				SUB AX, WINDOW_BOUNDS
				SUB AX, PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y, AX
				JG FIX_PADDLE_RIGHT_BOTTON_POSITION
				; If boundaries are okay
				JMP END_PADDLE_FUNC
				
				; If boundaries are not okay
				FIX_PADDLE_RIGHT_BOTTON_POSITION:
					MOV PADDLE_RIGHT_Y, AX
					JMP END_PADDLE_FUNC
		
		
		END_PADDLE_FUNC:
			RET
	MOVE_PADDLES ENDP
	
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
				MOV AL, 0Fh ; Cyan
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
				MOV AL, 0Fh ; Cyan
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
				MOV AL, 0Fh ; Cyan
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
	
	DRAW_UI PROC NEAR
	
		; Draw the points of the left player
		
		; Move cursor to wanted position
		MOV AH, 02h
		MOV BH, 00h
		MOV DH, 04h
		MOV DL, 06h
		INT 10h
		
		; Draw the text
		MOV AH, 09h
		LEA DX, TEXT_PLAYER_ONE_POINTS
		INT 21h
		
		; Draw the points of the right player
		
		; Move cursor to wanted position
		MOV AH, 02h
		MOV BH, 00h
		MOV DH, 04h
		MOV DL, 1Fh
		INT 10h
		
		; Draw the text
		MOV AH, 09h
		LEA DX, TEXT_PLAYER_TWO_POINTS
		INT 21h
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
		
		XOR AX, AX
		MOV AL, PLAYER_ONE_POINTS
		
		; Convert from number to ascii number like adding '0' in c
		ADD AL, 30h
		MOV [TEXT_PLAYER_ONE_POINTS], AL
		
		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
		
		XOR AX, AX
		MOV AL, PLAYER_TWO_POINTS
		
		; Convert from number to ascii number like adding '0' in c
		ADD AL, 30h
		MOV [TEXT_PLAYER_TWO_POINTS], AL
		
		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
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

