TITLE String Primitives and Macros    (Proj6_kramepat.asm)

; Author:	Patrick Kramer
; Last Modified:	Dec 4 '22
; OSU email address: kramepat@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date:	12/4/22
; Description:	This program prompts the user for 10 integers, positive or negative.
;				It validates user input using the ReadVal procedure, which reads user input
;				as a string of ASCII characters, checks for invalid characters, and converts it to a signed int to save into an array.
;				It then loops through the int array to calculate the sum and average, all while re-converting the valid numbers
;				back to a string to print back to the user. It then reports the sum and average as well.

INCLUDE Irvine32.inc

; (insert macro definitions here)

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Reads string input from user
;
; Postconditions: userString and userLen will be changed based on user input
;
; Receives:
; prompt		=	string array address to prompt for input
; userInput		=	variable to save user string
; maxSize		=	max possible size of string
; userLen		=	DWORD to record actual input size
;
; returns:
; userInput		=	string inputed by user
; userLen		=	size of user input
; ---------------------------------------------------------------------------------
mGetString	MACRO	prompt, userInput, maxSize, userLen
	PUSH	EAX
	PUSH	ECX
	PUSH	EDX

	MOV		EDX, prompt
	CALL	WriteString
	MOV		EDX, userInput
	MOV		ECX, maxSize
	CALL	ReadString
	MOV		userLen, EAX

	POP		EDX
	POP		ECX
	POP		EAX
ENDM


; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints the passed string to the console
;
; Receives:
; myString = string array address
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	myString
	PUSH	EDX

	MOV		EDX, myString
	CALL	WriteString

	POP		EDX
ENDM

; (insert constant definitions here)
MAX_SIZE = 11


.data

; (insert variable definitions here)
intro1		BYTE	"Fun with low-level I/O",13,10,
					"Coded by: Patrick Kramer",13,10,13,10,0
intro2		BYTE	"Please provide 10 signed decimal integers.",13,10,
					"Each number needs to fit inside a 32-bit register.",13,10,
					"After input, I will display a list of valid inputs,",13,10,
					"the sum, and the average value.",13,10,0

prompt1		BYTE	"Please enter a signed number: ",0
error1		BYTE	"ERROR: You did not enter a signed number or it was too big.",13,10,0

results1	BYTE	13,10,"You entered the following numbers:",13,10,0
results2	BYTE	13,10,"The sum of these numbers is: ",0
results3	BYTE	13,10,"The truncated average is: ",0

comma		BYTE	", ",0

farewell	BYTE	13,10,13,10,"Thank you for using my program. Have a good day!",13,10,0

userInput	BYTE	21 DUP(0)			; holds up to 11 characters plus null terminator
inpLen		SDWORD	?					; length of input
numArray	SDWORD	10 DUP(?)			; array for after numbers are converted from ASCII

sum			SDWORD	0
avg			SDWORD	?

outString	BYTE	MAX_SIZE DUP(0)

.code
main PROC

; (insert executable instructions here)

	; introduce program
	mDisplayString	OFFSET intro1
	mDisplayString	OFFSET intro2

	; get input
	MOV		ECX, LENGTHOF numArray
	MOV		EDI, OFFSET numArray

_getNext:
	PUSH	OFFSET prompt1
	PUSH	OFFSET error1
	PUSH	OFFSET userInput
	PUSH	SIZEOF userInput
	PUSH	OFFSET inpLen
	CALL	ReadVal		; gets next input and validates
	MOV		[EDI], EBX	; move validated input to array
	ADD		EDI, 4		; increment array index
	LOOP	_getNext

	; calculations while printing array
	mDisplayString	OFFSET results1
	SUB		EDI, SIZEOF numArray
	MOV		ECX, 10
_calcNext:
	MOV		EAX, [EDI]
	ADD		EDI, 4
	ADD		sum, EAX
	; call writeVal
	PUSH	OFFSET outString
	PUSH	EAX
	CALL	WriteVal
	CMP		ECX, 1
	JE		_skipComma
	mDisplayString	OFFSET comma
_skipComma:
	LOOP	_calcNext

	MOV		EAX, sum
	MOV		EBX, 10
	CDQ
	IDIV	EBX
	MOV		avg, EAX

	; display results
	mDisplayString	OFFSET results2
	PUSH	OFFSET outString
	PUSH	sum
	CALL	WriteVal

	mDisplayString	OFFSET results3
	PUSH	OFFSET	outString
	PUSH	avg
	CALL	WriteVal

	; goodbye
	mDisplayString	OFFSET farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)

;--------------------------------------------------------------------------
; name: ReadVal
;
; Reads user input and converts from string to integer
;
;
; Postconditions: 	EBX will store the validated input
;
;
; Receives: 		[EBP+24]	- string address for prompt1
;					[EBP+20]	- string address for error1
;					[EBP+16]	- string address for userInput
;					[EBP+12]	- max size of userInput
;					[EBP+8]		- actual length of userInput
;
; Returns: 			validated signed integer in EBX
;--------------------------------------------------------------------------
ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ECX

_prompt:
	mGetString	[EBP + 24], [EBP + 16], [EBP + 12], [EBP + 8]	; prompts for input, saving input in [EBP + 16] and its size in [EBP + 8]
	MOV		ESI, [EBP + 16]		; Mov user string into source register
	MOV		ECX, [EBP + 8]		; Mov string length into counter register
	CMP		ECX, MAX_SIZE		; Check if input is too large
	JG		_badInput
	INC		ECX
	MOV		EAX, 0
	MOV		EBX, 0				; numerified input tracker
	MOV		EDX, 0
	CLD

	; check for +/- sign
	LODSB
	CMP		AL, 0
	JE		_badInput
	CMP		AL, 43		; compare with '+' ASCII
	JE		_positive
	CMP		AL, 45		; compare with '-' ASCII
	JE		_negative
	JMP		_noSign

_positive:
	MOV		EDX, 0		; Set 'sign flag' off
	DEC		ECX
	JMP		_nums

_negative:
	MOV		EDX, 1		; Set 'sign flag' on
	DEC		ECX

_nums:
	LODSB				; get next char from input string
_noSign:
	CMP		AL, 0		; check for end of input
	JE		_end
	CMP		AL, 48		; check bottom range of ASCII numbers
	JB		_badInput
	CMP		AL, 57		; check top range of ASCII numbers
	JA		_badInput

	; char in good range. Sub 48 to get numeric value
	SUB		AL, 48
	; num = 10 * num + AL
	PUSH	EAX
	PUSH	EDX
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX
	MOV		EBX, EAX
	POP		EDX
	POP		EAX
	ADD		EBX, EAX
	LOOP	_nums

_badInput:
	mDisplayString	[EBP+20]	; Display error message
	JMP		_prompt

_end:
	; if sign flag is on, negate EBX
	CMP		EDX, 1
	JNE		_skip
	NEG		EBX
_skip:
	POP		ECX
	POP		EBP
	RET		20
ReadVal ENDP

;--------------------------------------------------------------------------
; name: WriteVal
;
; Converts signed integer to string and prints using mDisplayString
;
;
; Preconditions:	OFFSET outString and an int to print pushed to stack
;
; Postconditions:	String at [EBP+12] changed to ASCII representation of int at [EBP+8]
;
; Receives: 		[EBP+12]	- outString address
;					[EBP+8]		- int to convert
;
;--------------------------------------------------------------------------
WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		EDI, [EBP+12]		; move string address to destination register
	MOV		EAX, [EBP+8]		; move int to print to EAX
	MOV		ECX, 0				; stack counter
	CLD

	; check for negative
	CMP		EAX, 0
	JGE		_readRight
	NEG		EAX					; make positive for uniform string printing later
	PUSH	EAX
	MOV		EAX, 45				; '-' in ASCII
	STOSB
	POP		EAX

	; get characters from right to left by dividing by 10 and pushing remainder to stack.
	; also incriment ECX to keep track of how many to pop later.
_readRight:
	MOV		EBX, 10
	CDQ
	DIV		EBX
	CMP		EAX, 0
	JE		_lastDigit
	ADD		EDX, 48				; add 48 to get from int to the same number in ASCII
	PUSH	EDX
	INC		ECX
	JMP		_readRight
_lastDigit:						; do it one last time without jumping back to _readRight
	ADD		EDX, 48
	PUSH	EDX
	INC		ECX

	; Fill string indicies by popping values from stack
_popDigit:
	POP		EAX
	STOSB
	LOOP	_popDigit
	
	mDisplayString	[EBP+12]

	; nullify string for later
	MOV		EDI, [EBP+12]
	MOV		EAX, 0
	MOV		ECX, 10
_nullify:
	STOSB
	LOOP _nullify

	POPAD
	POP		EBP
	RET		8
WriteVal ENDP

END main