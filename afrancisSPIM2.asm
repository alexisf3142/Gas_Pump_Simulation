#---------------------------------------------------------------------------------------------#
# afrancisSPIM2.asm
# Alexis Francis 
# Description: This program is a simulation of a gas pump. Manipulating floating
# point variables to calculate things like price/gal, total cost etc.
# Input: The user will first be prompted to input a char representing their payment
# type "d" "c" or "q"(q = quit, ends the simulation) then they will enter their gas type "r"
# "p" or "s" from there they will enter a floating point number of gallons (or whole number)
# Output: The program outputs multiple strings for prompts, such as asking to select payment
# type or gas type. I also output a "receipt" to show all the calculations from the current
# transaction, in this receipt I output floating point numbers as well as integers combine with
# string (".") to make the total look like a floating point. I also output a message when the
# the program ends.
# I have abided by the Wheaton College Honor Code in this work x Alexis Francis
#---------------------------------------------------------------------------------------------#
	.data
paymentprompt: .asciiz "Please select your payment type - SmahtPay/Credit/Quit"
gastypeprompt: .asciiz "Please select your gas type - Regular/Plus/Super"
gallonsprompt: .asciiz "Number of gallons: "
endprompt: .asciiz "Pump is shutting down ... Thanks for choosing Cowberland Farms!"
paymentInput: .byte 'x'
gasInput: .byte 'x'
smahtPay: .asciiz "d"
credit: .asciiz "c"
quit: .asciiz "q"
regularGas: .asciiz "r"
plusGas: .asciiz "p"
superGas: .asciiz "s"
priceReg: .float 2.619
pricePlus: .float 2.819
priceSuper: .float 2.959
pricePerGallon: .float 0.0
smahtPayDiscount: .float 0.1
fhundred: .float 100.0
rounding: .float 0.5
#---------------------------------------------------------------------------------------------#
	.text
	.globl main
main:	
	lb $s0, quit				#load 'q' into register $s0
	lb $s1, smahtPay			#load 'd' into register $s1
	lb $s2, credit				#load 'c' into register $s2
	
	lb $s3, regularGas			#load "r" into register $s3
	lb $s4, plusGas				#load "p" into register $s4
	lb $s5, superGas			#load "s" into register s5
	li $s6, 10					#load 10 into $s6 for output assistance
	li, $s7, 100				#load 100 int $s7 for multiplication later
	
	l.s $f1, pricePerGallon
	l.s $f2, smahtPayDiscount
	l.s $f6, fhundred
	l.s $f7, rounding

maincontd:
	li $v0, 4					#print paymentprompt
	la $a0, paymentprompt
	syscall
	jal endlfunct				#print endl/newline
	
	li $v0, 12					#input payment type character
	syscall
	
	move $t0, $v0				#move input char to $t0
	sb $t0, paymentInput		#store the input char in paymentInput
	beq $s0, $t0, exit			#check if quit
	jal endlfunct				#print endl/newline
	jal gastypefunct			#jump to gastypefunct
	jal endlfunct				#print endl/newline
	li $v0, 4					#print gallonsprompt
	la $a0, gallonsprompt
	syscall
	jal endlfunct
	
	li $v0, 6					#input number of gallons (float)
	syscall

	mov.s $f3, $f0				#move gallons to $f3
	jal endlfunct
	jal totalCostfunct
	j receipt

#prints out "\n" to put us on a new line
#------endline function------#
	.data
endl:	.asciiz "\n"
#----------------------------#
	.text
endlfunct:
	li $v0, 4
	la $a0, endl
	syscall
	jr $ra

#prompts for the type of gas and returns the price, also calls the smahtPay function
#to apply a discount of $0.10 if using debit
#------gastype function------#
	.text
gastypefunct:
	li $v0, 4					#print gastypeprompt
	la $a0, gastypeprompt
	syscall
	
	li $v0, 4					#print endl/newline
	la $a0, endl				#cant call endl because $ra is in use
	syscall
	
	li $v0, 12
	syscall
	
	move $t1, $v0				#move the input char to $t1
	sb $t1, gasInput			#store the input char in gasInput
	beq $t1, $s3, returnReg
	beq $t1, $s4, returnPlus
	beq $t1, $s5, returnSup
#returns regular price, checks for smahtPay discount
returnReg:
	l.s $f1, priceReg
	beq $t0, $s1, spdfunct		#if they are using smahtPay apply discount
	jr $ra
#returns plus price, checks for smahtPay discount	
returnPlus:
	l.s $f1, pricePlus
	beq $t0, $s1, spdfunct		#if they are using smahtPay apply discount
	jr $ra
#returns super price, checks for smahtPay discount
returnSup:
	l.s $f1, priceSuper
	beq $t0, $s1, spdfunct		#if they are using smahtPay apply discount
	jr $ra

#this function takes $0.10 cents off the price per gallon amount
#----SmahtPayDis function----#
	.text
spdfunct:
	#cost per gallon is in $f1
	sub.s $f1, $f1, $f2
	jr $ra

#calculates the total cost based on amount of gallons purchased. This function also splits up the total
#cost into two integers and rounds to the nearest penny.
#-----totalcost function-----#
	.text
totalCostfunct:
	#number of gallons is in $f3
	#cost per gallon is in $f1
	#total cost is in $f4
	mul.s $f4, $f3, $f1

	cvt.w.s $f5, $f4			#convert fl.pt to interger
	mfc1 $t2, $f5				#move to int register $t2
	#rounding, multiply by 100, add 0.5, then divide by 100
	mul.s $f5, $f4, $f6		
	add.s $f5, $f5, $f7		
	div.s $f5, $f5, $f6
	#multiply by 100 again to save the decimals
	mul.s $f8, $f5, $f6		
	cvt.w.s $f8, $f8			#convert to integer
	mfc1 $t3, $f8				#move to int register $t3
	#to find the decimals, multiply dollar amount by 100
	#then subtract, and you are left with the "decimals"
	mul $t5, $t2, $s7		
	subu $t3, $t3, $t5
	jr $ra

#this is the start of the receipt, here we print out the header, the type of fuel
#based on the user input.
#-----receipt function-----#
	.data
headerprompt: .asciiz "------Cowberland Farms------"
fuelprompt: .asciiz "   FUEL TYPE       "
costgaloutput: .asciiz "   PRICE/GAL       $"
galloutput: .asciiz "   GALLONS         "
crdeoutput: .asciiz "   CREDIT/DEBIT    "
totaloutput: .asciiz "   TOTAL           $"
strCredit: .asciiz "credit"
strDebit: .asciiz "debit"
regular: .asciiz "regular"
plus: .asciiz "plus"
super: .asciiz "super"
strGasType: .asciiz ""
dot: .asciiz "."
#--------------------------#	
	.text
receipt:	
	li $v0, 4					#print headerprompt
	la $a0, headerprompt
	syscall	
	
	jal endlfunct				#endl
	li $v0, 4					#print fuelprompt
	la $a0, fuelprompt
	syscall	
	
	beq $t1, $s3, printReg
	beq $t1, $s4, printPlus
	beq $t1, $s5, printSuper

#print out the string "regular"
printReg:
	li $v0, 4					#print regular
	la $a0, regular
	syscall
	jal endlfunct
	j receiptcontd
#print out the string "plus"	
printPlus:	
	li $v0, 4					#print plus
	la $a0, plus
	syscall
	jal endlfunct
	j receiptcontd
#print out the string "super"
printSuper:
	li $v0, 4					#print super
	la $a0, super
	syscall
	jal endlfunct
	j receiptcontd
#a continuation of the reciept function, here we print out gallons, cost per
#gallon and the start of credit or debit
receiptcontd:
	li $v0, 4					#print galloutput
	la $a0, galloutput
	syscall
	
	li $v0, 2					#print gallons
	mov.s $f12, $f3 
	syscall
	jal endlfunct
	
	li $v0, 4					#print costgaloutput
	la $a0, costgaloutput
	syscall
	
	li $v0, 2					#print cost per gallon
	mov.s $f12, $f1 
	syscall
	jal endlfunct
	
	li $v0, 4					#print credit or debit
	la $a0, crdeoutput
	syscall
	
	beq $t0, $s1, printdebit
	beq $t0, $s2, printcredit
#prints out the string "credit"	
printcredit:
	li $v0, 4					#print "credit"
	la $a0, strCredit
	syscall
	jal endlfunct
	j receiptend
#prints out the string "debit"
printdebit:	
	li $v0, 4					#print "debit"
	la $a0, strDebit
	syscall
	jal endlfunct
	j receiptend
#the last part of the receipt, here we print out the formatted
#total combined of 2 integers and a string to make the output nice
receiptend:
	li $v0, 4					#print "total"
	la $a0, totaloutput
	syscall
	
	li $v0, 1					#print dollar amount
	add $a0, $t2, $zero
	syscall
	
	li $v0, 4					#print "."
	la $a0, dot
	syscall
	
	blt $t3, $s6, printzero		#check if we need to print a zero such as $6.6 versus $6.06
	li $v0, 1					#print cents	
	add $a0, $t3, $zero
	syscall
	jal endlfunct
	j main
#this prints a zero to show the correct output if the cents is less than 10
printzero:
	li $v0, 1					#print 0
	li $a0, 0
	syscall
	li $v0, 1					#print cents	
	add $a0, $t3, $zero
	syscall
	jal endlfunct
	j main
#this prints out our endprompt and ends the simulation if the user inputs "q"	
exit:
	jal endlfunct
	li $v0, 4					#print endprompt
	la $a0, endprompt
	syscall
	
	li	$v0, 10			
	syscall	
#---------------------------------------------------------------------------------------------#