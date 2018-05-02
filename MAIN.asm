


#INCLUDE <P16F628A.INC>		;ARQUIVO PADRÃO MICROCHIP PARA 16F628A
 __CONFIG _BOREN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _LVP_OFF & _MCLRE_ON


#DEFINE BANK0	BCF STATUS,RP0		;SETA BANK 0 DE MEMÓRIA
#DEFINE BANK1	BSF STATUS,RP0		;SETA BANK 1 DE MEMÓRIA

#DEFINE THAB 		INTCON, TOIE		;HABILITA A INTERRUPÇÃO DO TIMER
#DEFINE	TFLAG		INTCON,	T0IF		;FLAG DE ESTOURO DO TIMER
#DEFINE	PFLAG		INTCON,	INTF		;FLAG  DE INTERRUPÇÃO EM RB0
#DEFINE PC_INTERRUPT	INTCON, RBIF		;FLAG DE INTERRUPÇÃO  EM PORT CHANGE RB4:RB7

#DEFINE ESTADO_BOMBA	ESTADO,1
#DEFINE ESTADO_VALVULA	ESTADO,2
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * * * * * * *
;*							   VARIÁVEIS								                               * 
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *;* * * * * * * * * * * * * * * * *
;DEFINIÇÃO DO BLOCO DE VARIÁVEIS
	CBLOCK 0x20				;ENDEREÇO INICIAL DA MÉMORIA DO USUÁRIO
		ESTADO	
		PB
	ENDC						;FIM DE BLOCO DE VARIÁVEIS


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
	
	BTFSS	PC_INTERRUPT
	RETFIE
	BSF	O_ON_OFF
	MOVF	PORTB,W
	MOVWF	PB
	ANDLW	B'01110000'
	MOVF	PB,W
	MOVWF	PORTA
	BCF	PC_INTERRUPT
	RETFIE


LIMPA_TUDO
	
	CLRF	PORTA
	CLRF	PORTB
	CLRF	ESTADO
	
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
	MOVLW	B'10001000'
	MOVWF	INTCON

	BANK0

	CALL 	LIMPA_TUDO
	MOVF 	ESTADO,W
	MOVWF 	PORTA
	;BSF 	O_ON_OFF
	GOTO	MAIN
	



	END