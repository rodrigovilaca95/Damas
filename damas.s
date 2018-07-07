#################################################
#  Programa de exemplo de uso dos syscalls   	#
#  Versão Polling				#
#  ISC Maio 2018			      	#
#  Marcus Vinicius			      	#
#################################################
# Conecte o BitMap Display Tool E o Keyboard Display MMIO Tool


.data 
FILE: .string "imagens/tabuleiro.bin"	
FILE2: .string "imagens/menu.bin"		# string do nome do arquivo
STR: .string "Placar do sapo:"		# string da mensagem
NUM: .word 2
NOTAS: .word 74,250,80,250
# tabuleiro comeca com pecas pos inicial
#TABULEIRO: .word 
#0, 0, 0, 0, 0, 0, 0, 0, 
#0, 0, 0, 0, 0, 0, 0, 0, 
#0, 0, 0, 0, 0, 0, 0, 0, 
#0, 0, 0, 0, 0, 0, 0, 0, 
#0, 0, 0, 0, 0, 0, 0, 0, 
#0, 0, 0, 0, 0, 0, 0, 0,
#0, 0, 0, 0, 0, 0, 0, 0,
#0, 0, 0, 0, 0, 0, 0, 0
# pecas iniciais
#primeiro byte = jogador 1 (0x01) ou cpu (0x02) ou nao tem peca (0x00). 
#segundo byte = normal (0x00) ou dama (0x01), terceiro byte = pos X, quarto byte = pos Y.
# Exemplo: 0x00000000 = peca do jogador 1, normal, na posicao (0,0) do tabuleiro.
# Exemplo 2: 0x01000107 = peca do cpu, normal, na posicao (1,7) do tabuleiro.
PECAS: .word 
0x00000000, 0x02000001, 0x00000002, 0x02000003, 0x00000004, 0x02000005, 0x00000006, 0x02000007,
0x02000100, 0x00000101, 0x02000102, 0x00000103, 0x02000104, 0x00000105, 0x02000106, 0x00000107,
0x00000200, 0x02000201, 0x00000202, 0x02000203, 0x00000204, 0x02000205, 0x00000206, 0x02000207,
0x00000300, 0x00000301, 0x00000302, 0x00000303, 0x00000304, 0x00000305, 0x00000306, 0x00000307,
0x00000400, 0x00000401, 0x00000402, 0x00000403, 0x00000404, 0x00000405, 0x00000406, 0x00000407,
0x01000500, 0x00000501, 0x01000502, 0x00000503, 0x01000504, 0x00000505, 0x01000506, 0x00000507,
0x00000600, 0x01000601, 0x00000602, 0x01000603, 0x00000604, 0x01000605, 0x00000606, 0x01000607,
0x01000700, 0x00000701, 0x01000702, 0x00000703, 0x01000704, 0x00000705, 0x01000706, 0x00000707

.text
	# seta o exception handler
 	la t0,exceptionHandling		# carrega em t0 o endere?o base das rotinas do sistema ECALL
 	csrrw zero,5,t0 		# seta utvec (reg 5) para o endere?o t0
 	csrrsi zero,0,1 		# seta o bit de habilitaçãoo de interrupçãoo em ustatus (reg 0)
 	
# Abre o arquivo
	la a0,FILE2
	li a1,0
	li a2,0
	li a7,1024
	ecall
	mv s0,a0
	
# Le o arquivos para a memoria VGA
	mv a0,s0
	li a1,0xFF000000
	li a2,76800
	li a7,63
	ecall

#Fecha o arquivo
	mv a0,s0
	li a7,57
	ecall

SOM:	
	la s0,NUM		# define o endereço do número de notas
	lw s1,0(s0)		# le o numero de notas
	la s0,NOTAS		# define o endereço das notas
	li t0,0			# zera o contador de notas
	li a2,68		# define o instrumento
	li a3,25		# define o volume

LOOP:	beq t0,s1, MAINLOOP	# contador chegou no final? então  vá para FIM
	lw a0,0(s0)		# le o valor da nota
	lw a1,4(s0)		# le a duracao da nota
	li a7,31		# define a chamada de syscall
	ecall			# toca a nota
	mv a0,a1		# passa a duração da nota para a pausa
	li a7,32		# define a chamada de syscal 
	ecall			# realiza uma pausa de $a0 ms
	addi s0,s0,8		# incrementa para o endereço da próxima nota
	addi t0,t0,1		# incrementa o contador de notas
	j LOOP			# volta ao loop
		

MAINLOOP: jal KEYBOARD       	# Verifica se houve tecla pressionada

	mv a0,t2		# imprime o código ascii da tecla pressionada
	li a1,300		# coluna
	li a2,0			# linha
	li a3,0xFF00		# cores de frente(00) e fundo(FF) do texto
	li a7,101		# syscall de print int	
	ecall	  
	  
	
	#mv a0,t2		# imprime a tecla lida no nariz do sapo
	#li a1,220		# coluna
	#li a2,100		# linha
	#li a3,0x3807		# cores de frente(0x07) e fundo(0x38) do caracter ASCII do teclado
	#li a7,111		# syscall de print char
	#ecall 

  	j MAINLOOP		# volta ao loop principal


KEYBOARD: 	li t1,0xFF200000	# carrega o endereço de controle do KDMMIO
		lw t0,0(t1)		# le a palavra de controle
		andi t0,t0,0x0001	# mascara o bit menos signifcativo
   		beq t0,zero,PULA   	# Se não há tecla pressionada então vá para PULA
  		lw t2,4(t1)  		# le a tecla pressionada
  		li t4, 106
		sw t2,12(t1)  		# escreve a tecla do no display de texto
	 	beq t2,t4,TABULEIRO	# se tecla pressionada é j, então mostra tabuleiro
	 	bne t2,t4,FIM

						
TABULEIRO: 				#mostra tabuleiro
	# Abre o arquivo
	la a0,FILE
	li a1,0
	li a2,0
	li a7,1024
	ecall
	mv s0,a0
	
	
# Le o arquivos para a memoria VGA
	mv a0,s0
	li a1,0xFF000000
	li a2,76800
	li a7,63
	ecall

#Fecha o arquivo
	mv a0,s0
	li a7,57
	ecall


PULA:	jr ra,0

FIM:	li a7,10		# syscall de Exit
	ecall


.include "SYSTEMv1.s"			# carrega as rotinas do sistema

