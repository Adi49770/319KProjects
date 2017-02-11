;****************** main.s ***************
; Program written by: ***Aditya Tyagi and Jerry Yang***
; Date Created: 2/4/2017
; Last Modified: 2/4/2017
; Brief description of the program
;   The LED toggles at 8 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed) making it a postive logic
;  PE0 is LED output (1 activates external9 LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE0 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 8Hz,
;      which is 8 times per second with a duty-cycle of 20%.
;      Therefore, the LED is ON for (0.2*1/8)th of a second
;      and OFF for (0.8*1/8)th of a second.
;   3) When the button on (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 20% to 40% to 60%
;      to 80% to 100%(ON) to 0%(Off) to 20% to 40% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 8Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 20%.
;      TIP: debugging the breathing LED algorithm and feel on the simulator is impossible.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C

SYSCTL_RCGCGPIO_R  EQU 0x400FE608
       IMPORT  TExaS_Init
       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
      BL  TExaS_Init ; voltmeter, scope on PD3
      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
	  ;Initialize the clock and other port
	  LDR R0, =SYSCTL_RCGCGPIO_R
	  LDR R1, [R0]
	  ORR R1, #0x20
	  NOP
	  NOP
	  ;2 bus cycles
	  ;Unlock PUR
	  LDR R0, =GPIO_PORTF_PUR_R
	  MOV R1, #0x11
	  STR R1, [R0]
;	  LDR R0, =GPIO_PORTE_PUR_R
	 ; STR R1, [R0]
	  ; AFSEL
	  LDR R0,=GPIO_PORTE_AFSEL_R
	  AND R1, #0
	  STR R1, [R0]	;check this one 
	  LDR R0, =GPIO_PORTF_AFSEL_R
	  STR R1, [R0]
	  ;set DEN
	  LDR R0, =GPIO_PORTE_DEN_R
	  LDR R1, [R0]
	  ORR R1, #0x1F
	  STR R1, [R0]
	  LDR R0, =GPIO_PORTF_DEN_R
	  LDR R1, [R0]
	  ORR R1, #0x1F
	  STR R1, [R0]
	  ; set directon
	  LDR R0, =GPIO_PORTE_DIR_R
	  LDR R1, [R0]
	  ORR R1, #0x01 ;PE0 is the ourput, the rest are o and input?
	  STR R1, [R0]
	  LDR R0, =GPIO_PORTF_DIR_R
	  LDR R1, [R0]
	  AND R1, #0xE0	;make sure the check this one out as well
	  STR R1, [R0]
	  ;As of right now, the directions given should be set according to the inputs and outputs
times SPACE 1;
ButtonPressed	SPACE 1
LOOPER SPACE 1
	  

loop  LDR R0, =GPIO_PORTE_DATA_R ; receive the data given by PORT E
;R4 and R5 are dummy registers 
		
	  
	  LDR R1, [R0]
	  AND R2, R1, #0x01 ;isolate bit for PE0 to see if the switch is pressed or not based on positive logic
	  SUB R2, #0x1
	  ;branch if zero to tunroff led and loop back to "loop"
	 ;set the value of LOOPER based on the number of buttons pressed
	  ORR R1, #0x01	;turn on LED
	  STR R1, [R0]
	  LDR R5, times
	  ;LDR R5, [R5]
	  LDR R4, LOOPER
	  LDR R4, [R4]
	  STR R4, [R5]
turnonloop
	  ;call the timer loop
	  LDR R5, times
	  LDR R4, [R5]
	  SUB R4, #1
	  STR R4, [R5]
	  ;branch back if positve
	  AND R1, #0x1E	;turn off LED
	  ADD R4, #100
	  LDR R5, LOOPER
	  LDR R5, [R5]
	  SUB R4, R5
	  LDR R5, times
	  STR R4, [R5]
TurnOffLoop
	  ;call the timer loop
	  LDR R5, times
	  LDR R4, [R5]
	  SUB R4, #1
	  STR R4, [R5]
	  ;branch back if positive
	  
	  B    loop
	  ;;;;;;;;;;;;;;;buttonpressed Method;;;
	  AND R1, #0x1E
	  MOV R4, #1
	  LDR R5, ButtonPressed
	  LDR R5, [R5]
	  ADD R4, R5
	  STR R4, [R5]



;;;;;;;;;;;;;;TIMER LOOP;;;;;;;;;;;;
Timer
		MOV R5, #16
DLoop
		MOV R4, #1000
DLoop1
		SUB R4, #1
		BNE DLoop1
		SUB R5, #1
		BNE DLoop
		;loop and Timer subrountine ended. Branch back
		
	  

      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file

