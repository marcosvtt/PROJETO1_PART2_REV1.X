#INCLUDE <P16F628A.INC>		;ARQUIVO PADR�O MICROCHIP PARA 16F628A
 __CONFIG _BOREN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON


#DEFINE BANK0	BCF STATUS,RP0		;SETA BANK 0 DE MEM�RIA
#DEFINE BANK1	BSF STATUS,RP0		;SETA BANK 1 DE MEM�RIA

#DEFINE	T0_INTERRUPT	INTCON,	T0IF	;FLAG DE ESTOURO DO TIMER
#DEFINE PC_INTERRUPT	INTCON, RBIF	;FLAG DE INTERRUP��O  EM PORT CHANGE RB4:RB7

#DEFINE ESTADO_BOMBA	ESTADO,1
#DEFINE ESTADO_VALVULA	ESTADO,2
 
#DEFINE DELAY_CTE  .251			;PRESET PARA TIMER0
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * *
;*						VARI�VEIS				    * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * *
;DEFINI��O DO BLOCO DE VARI�VEIS
	CBLOCK 0x20			;ENDERE�O INICIAL DA M�MORIA DO USU�RIO
		ESTADO	
		PB
		OLD_ESTADO
	ENDC				;FIM DE BLOCO DE VARI�VEIS

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*						DEFINE ENTRADAS				    * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#DEFINE I_CAIXA			PORTB,4
#DEFINE I_CISTERNA		PORTB,5
#DEFINE I_RUA			PORTB,6

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*						DEFINE SAIDAS				    * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#DEFINE O_ON_OFF		PORTA,0
#DEFINE O_BOMBA			PORTA,1
#DEFINE O_VALVULA		PORTA,2
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*						INICIO					    * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG 0x00
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*				ROTINAS DE INTERRUP��O					    * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
	ORG	0x04
	MOVFW	ESTADO		
	MOVWF	OLD_ESTADO
	BTFSC	PC_INTERRUPT	    ;CHECA SE A INTERRUP��O OCORREU EM RB<7:4>
	GOTO	INT_RB		    ;VAI PARA ROTINA DE INTERRUP��O CORRESPONDENTE
	BTFSC	T0_INTERRUPT	    ;CHECA SE A INTERRUP��O OCORREU PELO ESTOURO TO TIMER0
	GOTO	TIMER
	RETFIE
	
TIMER	;ROTINA EXECUTADA APOS ESTOURO DO TIMER0
	BCF	T0_INTERRUPT	    ;LIMPA FLAG DE INTERRUP��O
	BTFSC	O_BOMBA		    ;CASO A SAIDA ESTEJA EM 1
	BCF	O_BOMBA		    ;A SAIDA VAI PARA 0
	BTFSC	O_VALVULA	    ;
	BCF	O_VALVULA	    ;
	BSF	INTCON, RBIE	    ;REHABILITA AS INTERRUPCOES EM RB
	RETFIE
	
PULSA	;ROTINA PARA GERAR UM PULSO
	MOVFW	ESTADO
	XORWF	OLD_ESTADO, F	;OPERA��O XOR PARA IDENTIFICAR A MUDAN�A DE ESTADO
	BTFSC	OLD_ESTADO,1	;CASO HAJA MUDAN�A DE ESTADO EM ESTADO_BOMBA
	BSF	O_BOMBA		;ACIONA O PULSO DA BOMBA
	BTFSC	OLD_ESTADO,2	;CASO HAJA MUDAN�A DE ESTADO EM ESTADO_VALVULA
	BSF	O_VALVULA	;ACIONA O PULSO DA BOMBA
	CALL	DELAY		;CHAMA DELAY (1S)
	RETFIE
	
INT_RB	;ROTINA EXECUTADA AP�S VARIA��O DE ESTADO EM RB<7:4>
	BSF	O_ON_OFF	;acende led de estado
	MOVF	PORTB,W		;l� PORTB e copia em W
	ANDLW	B'01110000'	;opera��o AND para que apenas os valores correspondentes as portas RB<6:4> permane�am
	MOVWF	PB		;copia o novo valor de W na variavel PB
	GOTO	CHECA_CAIXA	
	
CHECA_CAIXA
	BTFSC	PB,6		;IF RUA and !CISTERNA
	BTFSC	PB,5		
	GOTO	FECHA_VALVULA	;<= CASO FALSO
	GOTO	ABRE_VALVULA	;<= CASO VERDADEIRO
	
CHECA_BOMBA
	BTFSC	PB,5		;IF CISTERNA and !CAIXA
	BTFSC	PB,4		
	GOTO	FECHA_BOMBA	;<= CASO FALSO
	GOTO	ABRE_BOMBA	;<= CASO VERDADEIRO


FECHA_BOMBA
	BCF	ESTADO_BOMBA	;ESTADO DA BOMBA = DESLIGADO
	BCF	PC_INTERRUPT	;LIMPA FLAG DE INTERRUP��O
	GOTO	PULSA
	RETFIE			;FIM DA INTERRUP��O

ABRE_BOMBA
	BSF	ESTADO_BOMBA	;ESTADO DA BOMBA = LIGADO
	BCF	PC_INTERRUPT	;LIMPA FLAG DE INTERRUP��O
	GOTO	PULSA
	RETFIE		

FECHA_VALVULA
	BCF	ESTADO_VALVULA	;ESTADO DA VALVULA = DESLIGADO
	GOTO	CHECA_BOMBA

ABRE_VALVULA
	BSF	ESTADO_VALVULA	;ESTADO DA VALVULA = LIGADO
	GOTO	CHECA_BOMBA

DELAY	
	BCF	INTCON, RBIE	;DESABILITA INTERRUP�OES EM RB<7:4>
	CLRF	TMR0		;LIMPA TIMER0
	MOVLW	DELAY_CTE	;
	MOVWF	TMR0		;PRESETA O TIMER0 COM O VALOR DEFINIDO EM DELAY_CTE
	RETURN

LIMPA_TUDO  ;LIMPA TODOS O REGISTRADORES NO INICIO DO PROGRAMA
	CLRF	PORTA
	CLRF	PORTB
	CLRF	ESTADO
	CLRF	OLD_ESTADO	
	BSF	O_ON_OFF
	RETURN
	
MAIN	;LOOP INFINITO NA MAIN
	GOTO	MAIN	 

INICIO
	BANK1
	MOVLW	B'11100000'
	MOVWF	TRISA	    ;PORTA: SAIDAS: <4:0>;  ENTRADAS: <7:5>
	MOVLW	B'11111111'
	MOVWF	TRISB	    ;PORTB: SAIDAS: <...>;  EMTRADAS: <7:0>

	MOVLW	B'10010001' ;!RBPU  INTEDG  T0CS  T0SE  PSA  PS2  PS1  PS0
	MOVWF	OPTION_REG  ;  1      0      0     1     0    0    0    1
	MOVLW	B'10101000' ;GIE  PEIE  T0IE  INTE  RBIE  T0IF  INTF  RBIF
	MOVWF	INTCON	    ; 1     0    1      0    1     0    0     0

	BANK0

	CALL 	LIMPA_TUDO  ;
	MOVF 	ESTADO,W
	MOVWF 	PORTA
	GOTO	MAIN

	
	END