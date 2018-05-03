


#INCLUDE <P16F628A.INC>		;ARQUIVO PADR�O MICROCHIP PARA 16F628A
 __CONFIG _BOREN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON


#DEFINE BANK0	BCF STATUS,RP0		;SETA BANK 0 DE MEM�RIA
#DEFINE BANK1	BSF STATUS,RP0		;SETA BANK 1 DE MEM�RIA

#DEFINE	T0_INTERRUPT	INTCON,	T0IF		;FLAG DE ESTOURO DO TIMER
#DEFINE PC_INTERRUPT	INTCON, RBIF		;FLAG DE INTERRUP��O  EM PORT CHANGE RB4:RB7

#DEFINE ESTADO_BOMBA	ESTADO,1
#DEFINE ESTADO_VALVULA	ESTADO,2
 
 #DEFINE DELAY_CTE  .156
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * * * * * * *
;*							   VARI�VEIS								                               * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * * * * * * *
;DEFINI��O DO BLOCO DE VARI�VEIS
	CBLOCK 0x20				;ENDERE�O INICIAL DA M�MORIA DO USU�RIO
		ESTADO	
		PB
		OLD_ESTADO
	ENDC						;FIM DE BLOCO DE VARI�VEIS


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*						DEFINE ENTRADAS														* 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#DEFINE I_CAIXA			PORTB,4
#DEFINE I_CISTERNA		PORTB,5
#DEFINE I_RUA			PORTB,6
;#DEFINE 			PORTB,7

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*						DEFINE SAIDAS														* 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#DEFINE O_ON_OFF		PORTA,0
#DEFINE O_BOMBA			PORTA,1
#DEFINE O_VALVULA		PORTA,2


	ORG 0x00
	GOTO	INICIO
	
	ORG	0x04
	
	MOVFW	ESTADO
	MOVWF	OLD_ESTADO
	BTFSC	PC_INTERRUPT	    ;CHECA SE A INTERRUP��O OCORREU EM RB7:RB4
	GOTO	INT_RB		    ;VAI PARA ROTINA DE INTERRUP��O CORRESPONDENTE
	BTFSC	T0_INTERRUPT
	GOTO	TIMER
	RETFIE
	
TIMER
	BCF	T0_INTERRUPT
	BTFSC	O_BOMBA
	BCF	O_BOMBA
	BTFSC	O_VALVULA
	BCF	O_VALVULA
	RETFIE
	
PULSA	
	MOVFW	OLD_ESTADO
	XORWF	ESTADO
	MOVWF	OLD_ESTADO
	BTFSC	OLD_ESTADO,1
	BSF	O_BOMBA
	BTFSC	OLD_ESTADO,2
	BSF	O_VALVULA
	CALL	DELAY
	RETFIE
	
INT_RB
	BSF	O_ON_OFF	;acende led de estado
	MOVF	PORTB,W		;l� PORTB e copia em W
	ANDLW	B'01110000'	;opera��o AND para que apenas os valores correspondentes as portas RB6, RB5 e RB4 permane�am
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
	BSF	ESTADO_BOMBA	;ESTADO DA BOMBA = DESLIGADO
	BCF	PC_INTERRUPT	;LIMPA FLAG DE INTERRUP��O
	GOTO	PULSA
	RETFIE		

FECHA_VALVULA
	BCF	ESTADO_VALVULA
	GOTO	CHECA_BOMBA

ABRE_VALVULA
	BSF	ESTADO_VALVULA
	GOTO	CHECA_BOMBA

DELAY	
	CLRF	TMR0
	MOVLW	DELAY_CTE
	MOVWF	TMR0
	RETURN

LIMPA_TUDO
	
	CLRF	PORTA
	CLRF	PORTB
	CLRF	ESTADO
	CLRF	OLD_ESTADO
	
	BSF	O_ON_OFF
	RETURN
	
	
MAIN
	GOTO	MAIN	 


INICIO
	BANK1
	MOVLW	B'11100000'
	MOVWF	TRISA
	MOVLW	B'11111111'
	MOVWF	TRISB

	MOVLW	B'10010001'
	MOVWF	OPTION_REG
	MOVLW	B'10101000'
	MOVWF	INTCON

	BANK0

	CALL 	LIMPA_TUDO
	MOVF 	ESTADO,W
	MOVWF 	PORTA
	;BSF 	O_ON_OFF
	GOTO	MAIN
	



	END