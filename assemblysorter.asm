.section .data
file_stat:	.space 144	#Size of the fstat struct
newline:	.string "\n"
buffer:		.space 128  #don,t expect number larger than this
.section .text
.globl _start

_start:
	mov 16(%rsp), %r12 
	#mov 24(%rsp), %r? #no 2nd argument

	#r12 will be 1st argument (later is used as local variable both in snippets and my program)
	#r13 will be file descriptor 
	#r14 will be used for byte size of file 
	#r15 will be pointer to memory of raw data as strings

	mov $2, %rax		#2 rax = open file
	mov %r12, %rdi		#put adress from input in rdi
	mov $0, %rsi		#2 rsi = read only
	mov $0, %rdx		#0 rdx mode
	syscall

	mov %rax, %r13		#Push the file descriptor to the stack and
	push %rax    		#get file size to allocate the needed memory.
	call get_file_size	#Pointer to memory will be given in %r15.
	mov %rax, %r14
	push %r14
	call alloc_mem
	mov %rax, %r15
	
	mov %r13, %rdi		#Move all data from file into memory.
	mov $0, %rax		#File descripter from %r13 and memory location %r15,
	mov %r15, %rsi		# %r14 is the size of the file.
	mov %r14, %rdx
	syscall

	mov $3, %rax		#Close file as we don,t need anything from it anymore.
	mov %r13, %rdi	 	# %r13 file descriptor to close.
	syscall

	push %r14		#Get the amount of numbers (strings) in memory.
	push %r15		#Store the numbr in %r13, as FD is not needed anymore.
	call get_number_count
	mov %rax, %r13

	mov %r13, %rax		#Get bytes needed for int memory.
	mov $8, %r12  		#Using r12 for multiplication, as not needed anymore.
	mulq %r12		#Allocate memory for file numbers as ints.
	mov %rax, %r12
	push %r12
	call alloc_mem

		#rax pointer to int memory
		#r12 not important (needed in parse_number_buffer)
		#r13 count of numbers
		#r14 byte size of string input (soon not important)
		#r15 pointer to string memory

				#Make sure nothing important is lost.
				#Get the numbers as ints in new memory.
	mov %r15, %r12  	#r12 is now string pointer	
	mov %rax, %r15  	#r15 is now int pointer			
	push %r15 		#pointer to save the ints
	push %r14 		#bytes of string data
	push %r12 		#pointer to string data
	call parse_number_buffer

	cmp $1, %r13		#check if theres any numbers to sort
	jle my_print_loop

#  %r13 and %r15 must not be changed! Need them for output.
intro_to_sort:
	mov %r13, %rax		#Get other end of workspace
	mov $8, %r12
	mulq %r12
	mov %rax, %r12		# %r12 number of bytes
	mov %r15, %r14							#%r14---unsortednumbers----%r15
	add %r12, %r14							# V 			    V
	sub $8, %r14		# %r14 is pointer to the last element	#1st . 2nd . 3rd . ......  n'th 
	push $0
	push %r15
	push %r14
	#mov $0, %r14		#use %r14 to count cmp operations

sort_loop_1:
	#add $1, %r14 		#count cmp
	cmp $0, (%rsp)		#set to (%rsp) when looking for top 0
	jle quicksort_end

	#call get_pivot  	#pivot is now %r12  #gives errors the second time its called.
	mov 8(%rsp), %r12	#gave up with pivot, now just using top.

	call quicksort 
	pop %rdx
	pop %rdx

	#add $1, %r14 		#count cmp
	cmp $0, %rax
	je not_push_top
	push %rax
	push %r8

not_push_top:
	#add $1, %r14 		#count cmp
	cmp $0, %r9
	je not_push_bottom
	push %r9
	push %rdi
not_push_bottom:		
	#push $0 		#used of i only want 1 computation.
	jmp sort_loop_1   	#loop end

quicksort_end:	
	#push %r14		#print cmp count
	#call print_number
	#pop %r14

	cmp $0, %r13		#check if theres any numbers to print
	jg my_print_loop
	jmp exit

  exit:  			 # Syscall calling sys_exit
	mov $60, %rax            # rax: int syscall number
	mov $0, %rdi             # rdi: int error code
	syscall

  my_print_loop:
	sub $1, %r13		# call print_number for every element.
	push (%r15)
	call print_number
	pop %rax
	add $8, %r15
	cmp $0, %r13
	jg my_print_loop
	jmp exit
#-----------------------------------------------------------------------------------------------
#My quicksort
#requires %r12 to be a pivot. Also needs two pointers on the stack
#First two elements on the stack needs to be a pointer to the top of where to work on, and the next element to be a pointer to the bottom.
#
#returns 4 pointers in %rax, %r8, %rsi and %rdx. Two or all pointers might be the value $0, and should then be discarded.
#-----------------------------------------------------------------------------------------------
quicksort: 	
	push %rbp
	mov %rsp, %rbp 			#Function Prolog

	mov 16(%rbp), %r10  		#get bottom
	mov 24(%rbp), %r11   		#get top
	mov %r11, %rsi		#rsi is my moving from top
	mov %r10, %rdx		#rdx is my moving from bottom

move_top:			#move top down untill a larger than pivot is found, or you meet other pointer.
	mov (%rsi), %rax
	#add $1, %r14 		#count cmp
	cmp (%r12), %rax  	#If smaller than pivot, prepare to swap.
	jg move_bottom 	
	add $8, %rsi		#els, move pointer one element downwards.
	#add $1, %r14 		#count cmp
	cmp %rsi, %rdx  	#do pointers meet?
	je Pointers_have_met
	jmp move_top		#If not, move down again untill greater is found.
	
move_bottom:			#move bottom up untill less than pivot is found.
	mov (%rdx), %rdi
	#add $1, %r14 		#count cmp
	cmp (%r12), %rdi  	#If less than pivot, swap.
	jl swap 	
	sub $8, %rdx		#Else, move pointer one element opwards
	#add $1, %r14 		#count cmp
	cmp %rsi, %rdx  	#pointers meet?
	je Pointers_have_met
	jmp move_bottom		#continue untill smaller is found.

swap:
	mov (%rsi), %rax	#%rdx and %rsi wants to swap
	mov (%rdx), %rdi
	mov %rax, (%rdx)
	mov %rdi, (%rsi)
	jmp move_top

Pointers_have_met:		#%rdx = %rsi
	mov (%r12), %rax 	#pivot
	mov (%rsi), %rdi 	#element
	#add $1, %r14 		#count cmp
	cmp %rdi, %rax		#is pointer element smaller than pivot?
	jle pivot_smallest	#if no, swap them, else do nothing
	mov %rax, (%rsi)	#swapping
	mov %rdi, (%r12)
	jmp this_done_and_recursion

pivot_smallest:
	sub $8, %rsi		#swap pivot with element above, above is to be locked
	sub $8, %rdx
	mov (%rsi), %rdi 	#element
	mov %rax, (%rsi)	#swapping
	mov %rdi, (%r12)

this_done_and_recursion:
	mov %rsi, %r12 		#%rdx = %rsi = %r12
				# %r12 = locked element 
				# %r10 and %r11 are bottom and top respectivly
				#output in %rax, %rdi, %r8 and	%r9
	mov $0, %rax		#top of the above division
	mov $0, %r8		#bottom of the above divison	
	mov $0, %r9		#top of the below devision
	mov $0, %rdi		#bottom of the below deviison

	#add $1, %r14 		#count cmp
	cmp %r11, %rsi		#are we at the top of our memory?
	jle top_done		#pointers must not be larger than %r10 nor smaller than %r11

	sub $8, %rsi
	#add $1, %r14 		#count cmp
	cmp %r11, %rsi		#is the elemement above the only element?
	jle top_done

	mov %r11, %rax #top	#recusive call for top        #    <--------------------------
	mov %rsi, %r8 #bottom 

top_done:
	#add $1, %r14 		#count cmp
	cmp %r10, %rdx		#are we at the bottom of memory?
	jge bottom_done

	add $8, %rdx
	#add $1, %r14 		#count cmp
	cmp %r10, %rdx		#only 1 element below?
	jge bottom_done

	mov %rdx, %r9 #top	#recursive call for bottom  #    <--------------------------
	mov %r10, %rdi #bottom

bottom_done:
	mov %rbp, %rsp			#Function Epilog
	pop  %rbp			
	ret

#-----------------------------------------------------------------------------------------------
# My pivot function. Needs two pointers on the stack, first to the bottom and second to the top.
#
# Returns a pivot pointer in %r12.
# Works the first time i call it, but seems to break when i call it recursively
#------------------------------------------------------------------------------------------------
get_pivot:
	push %rbp
	mov %rsp, %rbp 			#Function Prolog

	mov 16(%rbp), %rax  		#pointer to bottom
	mov 24(%rbp), %r8   		#pointer to top
	mov %r8, %r12 			#pivot will end in r12

	sub %r8, %rax
	add $8, %rax			#rax = number of elements between pointers
	mov $8, %r8
	div %r8
	mov $2, %r8
	div %r8				#rax = number of elements to ca. middle
	mov $8, %r8
	mul %r8
	mov %rax, %r8
	add %r8, %r12 			#pivot now in r12

	mov %rbp, %rsp			#Function Epilog
	pop  %rbp			
	ret

###############################################################################
# This function returns the filesize in rax. It expects the file handler to be
# on the stack.
#
# The function is not register save!
###############################################################################
.type get_file_size, @function
get_file_size:
	push 	%rbp
	mov 	%rsp,%rbp 		#Function Prolog

	#Get File Size
	mov		$5,%rax			#Syscall fstat
	mov		16(%rbp),%rdi	#File Handler
	mov		$file_stat,%rsi	#Reserved space for the stat struct
	syscall
	mov		$file_stat, %rbx
	mov		48(%rbx),%rax	#Position of size in the struct

	mov		%rbp,%rsp		#Function Epilog
	pop 	%rbp			
	ret



###############################################################################
# This function is our simple and naive memory manager. It expects to
# receive the number of bytes to be reserved on the stack.
# 
# The function is not register save!
# 
# The function returns the beginning of the reserved heap space in rax
###############################################################################

.type alloc_mem, @function
alloc_mem:
	push 	%rbp
	mov 	%rsp,%rbp 		#Function Prolog

	#First, we need to retrieve the current end of our heap
	mov		$0,%rdi
	mov		$12,%rax
	syscall					#The current end is in %rax
	push	%rax			#We have to save this, this will be the beginning of the cleared field
	add		16(%rbp),%rax	#Now we add the desired additional space on top of the current end of our heap	
	mov		%rax,%rdi
	mov		$12,%rax
	syscall

	pop		%rax
	mov		%rbp,%rsp		#Function Epilog
	pop 	%rbp			
	ret


###############################################################################
# This function returns the amount of numbers in the given buffer in rax. First
# parameter is the address of the buffer, second parameter is the size of the
# buffer
#
# The function is not register save!
###############################################################################

.type get_number_count, @function
get_number_count:
	push 	%rbp
	mov 	%rsp,%rbp 		#Function Prolog

	mov		16(%rbp),%rbx	#Address of the buffer
	mov		$0,%rcx			#Position in buffer
	mov		$1,%rax			#Number count
num_count:
	mov		(%rbx,%rcx),%dl	#load byte
	inc		%rcx			#increase buffer counter
	cmp		24(%rbp),%rcx	#Compare to buffer length
	je		end_counting	#Are we done with the buffer?
	cmp		$0xA,%dl		#is it the new line sign?
	jne		num_count		#If not, continue in the buffer
	inc		%rax			#completed a number
	jmp		num_count
end_counting:

	mov		%rbp,%rsp		#Function Epilog
	pop 	%rbp			
	ret


###############################################################################
# This function parses the raw data given in a buffer and stores integers
# in a second buffer. Note, this functions only expects unsigns int and does
# no validity check at all.
# 
# Parameters on stack
# 1. Address of raw data buffer
# 2. Length of raw data buffer
# 3. Address of target buffer
#
# The function is not register save!
###############################################################################

.type parse_number_buffer, @function
parse_number_buffer:
	push 	%rbp
	mov 	%rsp,%rbp 			#Function Prolog

	#Now, lets reconstruct the numbers!
	mov		16(%rbp),%r8		#file buffer 
	xor		%r9,%r9				#file buffer position
	mov		32(%rbp),%r10		#Number buffer
	xor		%r11,%r11			#number buffer position
	xor		%r12,%r12			#current number

number_parsing_loop:
	xor		%rax,%rax	
	mov		(%r8,%r9),%al		#read byte
	cmp		$0xA,%rax			#Is the number finished
	je		finish_number
	#No, it isn't, we keep going
	sub		$48,%rax			#From ascii to actual number
	imul	$10,%r12			#Make room for the new digit
	add		%rax,%r12			#Add the new digit
	jmp		finish_parsing_loop
finish_number:
	mov		%r12,(%r10,%r11,8)	#Store the number
	inc		%r11				#Next number
	xor		%r12,%r12
finish_parsing_loop:
	cmp		%r9,24(%rbp)		#Have we processed the last byte of the buffer?
	je		store_last_number	#Yes, there is still one last number in %r12
	inc		%r9
	jmp		number_parsing_loop

store_last_number:
	mov		%r12,(%r10,%r11,8)	#Store the last number
	mov		%rbp,%rsp			#Function Epilog
	pop 	%rbp			
	ret



###############################################################################
# This function prints a number to std-out. The number is given on the stack
#
# The function is register save
###############################################################################

.type print_number, @function
print_number:
	push 	%rbp
	mov 	%rsp,%rbp 		#Function Prolog
	push	%rax			#Saving the registers
	push	%rbx
	push	%rcx
	push	%rdx
	push	%rdi
	push	%rsi
	push	%r9

	mov		16(%rbp),%rax	#The Number to Print

	mov		$1,%r9			#We always print 6 chars: "\n"
	push	$10				#Put '\n' on the stack
loop1:	
	mov 	$0,%rdx
	mov 	$10,%rcx
	idiv 	%rcx     		#Used like that, idiv divides rdx:rax/operand
							#Result is in rax, remainder in rdx
	add		$48,%rdx		#Make the remainder an ASCII code
	push	%rdx			#Save our first ASCII sign on the stack
	inc		%r9				#Counter
	cmp		$0,%rax		
	jne		loop1			#Loop until rax = 0
	

print_loop:
	mov 	$1, %rax    	# In "syscall" style 1 means: write
	mov 	$1, %rdi    	# ... and the first arg. is stored in rdi (not rbx)
	mov		%rsp,%rsi   	# ... and the second arg. is stored in rsi (not rcx)
	mov 	$1,%rdx    		# ... and the third arg. is stored in rdx
	syscall					# Call the kernel, 64Bit vversion
	add		$8,%rsp			# Set stack pointer to next sign
	sub		$1,%r9			
	jne		print_loop

	pop		%r9				#Restoring the registers
	pop		%rsi
	pop		%rdi
	pop		%rdx
	pop		%rcx
	pop		%rbx
	pop		%rax

 	mov		%rbp,%rsp		#Function Epilog
	pop 	%rbp			
	ret



###############################################################################
# This function prints a zero terminated String to the screen. The address of
# the String is given on the stack
#
# The function is not register save
###############################################################################

.type print_string, @function
print_string:
	push 	%rbp
	mov 	%rsp,%rbp 		#Function Prolog

	mov		16(%rbp),%rax	#Address of the String
	xor		%rcx,%rcx		#Counter
string_length:
	movb	(%rax,%rcx), %bl	#Load byte
	cmp		$0,%bl			#End of String?
	jz		string_length_finished
	add		$1,%rcx			#Increase counter
	jmp		string_length	

string_length_finished:
	mov 	$1, %rax    	# In "syscall" style 1 means: write
	mov 	$1, %rdi    	# File descriptor (std out)
	mov		16(%rbp),%rsi   # Address of the String
	mov 	%rcx,%rdx    	# Length of the String
	syscall					#Call the kernel, 64Bit variant
	
	mov		%rbp,%rsp		#Function Epilog
	pop 	%rbp			
	ret
