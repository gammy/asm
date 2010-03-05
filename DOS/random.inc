; ========================= RANDOM.INC =========================
; 
; Call with,	NOTHING
; Returns,	AL = random number between 0-255,
;		AX may be a random number too ?
;		DW RNDNUM holds AX=random_number_in AL
; http://www.programmersheaven.com/mb/x86_asm/219366/219366/a-random-number-generator-routine/

RANDOM:
	PUSH	DX
	MOV	AX,[SEED]	;; AX = seed
	MOV	DX,8405h	;; DX = 8405h
	MUL	DX		;; MUL (8405h * SEED) into dword DX:AX

	CMP	AX,[SEED]
	JNZ	GOTSEED		;; if new SEED = old SEED, alter SEED
	MOV	AH,DL
	INC	AX
GOTSEED:
	MOV	WORD [SEED],AX	;; We have a new seed, so store it
	MOV	AX,DX		;; AL = random number
	MOV	WORD [RNDNUM],AX

	POP	DX
	RET

SEED	DW 3749h
RNDNUM	DW 0
