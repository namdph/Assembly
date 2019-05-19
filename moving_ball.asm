#-------------------------------------------------------------------------------------------------------
# @name			MIPS Moving Ball
# @brief		The user enter letter A - D - W - S - N - Q from keyboard to Keyboard and Display MMIO Simulator, 
#                             (a - left, d - right, w - up, s - down, n - standby, q - quit),
#				the program will start displaying the moving ball on Bitmap Display
# @method		The program uses Mid-Point Circle Drawing Algorithm to draw the ball and using loops to
#                             moving the ball in directions 		
#-------------------------------------------------------------------------------------------------------

.eqv KEY_CODE 0xFFFF0004 		# ASCII code from keyboard, 1 byte	
.eqv KEY_READY 0xFFFF0000 		# =1 if has a new keycode 
.data
base: .word 0x10010000 		#Starting address of bitmap screen
color: .word 0x00FFFFFF 		#color of the circle
bgcolor: .word 0x00000000 		#color of the background
radius: .word 32 			#default radius
dis_width: .word 512 			#bitmap display width
dis_height: .word 512 			#bitmap display height
center_x: .word 256 			#center of the circle
center_y: .word 256
.text
main:
	lw 	$t2, radius		#set radius of the circle	
	lw 	$t3, color		#set color
	li 	$t7, 1		     	#set distance to bounce
	lw 	$t8, center_x 		#set center in x 
	lw	$t9, center_y		#set center in y
	li 	$t1, 1			#set $t1 = 1
	jal 	draw_circle		#initiate circle
#Control direction of the circle using MMIO
control: 
	li 	$k0, KEY_CODE 				
	li 	$k1, KEY_READY
	lw 	$t1, 0($k1) 			#$t1 = [$k1] = KEY_READY
	beq 	$t1, $zero, control 	
looping: 	
	lw 	$t0, 0($k0) 		
	beq 	$t0, 97, main_loop_left	#enter a, bounce left
	beq 	$t0, 100, main_loop_right	#enter d, bounce right	
	beq 	$t0, 119, main_loop_up		#enter w, bounce up			
	beq 	$t0, 115, main_loop_down	#enter s, bounce down
	beq     $t0, 98, main_loop_skew    	#b
	beq     $t0, 99, main_loop_skew_reserve	#c
	beq     $t0, 101, main_loop_skew    	#e
	beq     $t0, 102, main_skew_reserve	#f
	beq	$t0, 110, control		#enter n, stand by 
	beq     $t0, 113, main_done		#enter q, quit
	
	j 	read_key_code
read_key_code:
	li 	$k0, KEY_CODE 				
	li 	$k1, KEY_READY
	lw 	$t1, 0($k1) 			#$t1 = [$k1] = KEY_CODE
	bne 	$t1, $zero, looping
	jr 	$ra	
main_loop_left:
	blt 	$t8, 32, main_loop_right	#x < radius, bounce back
	nop					#do nothing :) 
	jal 	delete			       	#delete current circle
	sub 	$t8, $t8, $t7			#change position
	jal 	bounce				#return new circle
	jal 	read_key_code			#read key code
	j 	main_loop_left			#if nothing changes, loop
main_loop_right:	
	bgt 	$t8, 480, main_loop_left	#x > radius, bounce back
	nop					#do nothing :) 
	jal 	delete			    	#delete current circle
	add 	$t8, $t8, $t7			#change position
	jal 	bounce				#return new circle
	jal 	read_key_code			#read key code
	j	main_loop_right			#if nothing changes, loop
main_loop_up:			
	blt 	$t9, 32, main_loop_down	# y < radius, bounce back		
	jal	delete				#delete current circle
	sub 	$t9, $t9, $t7			#change position
	jal 	bounce				#return new circle
	jal 	read_key_code			#read key code
	j 	main_loop_up			#if nothing changes, loop
main_loop_down:	
	bgt 	$t9, 480, main_loop_up		# y > radius, bounce back
	jal	delete				#delete current circle
	add 	$t9, $t9, $t7			#change position
	jal 	bounce				#return new circle
	jal	read_key_code			#read key code
	j	main_loop_down 			#if nothing changes, loop
main_loop_skew: #b
	blt	$t9, 32, main_skew_reserve
	blt	$t8, 32, main_skew
	jal 	delete
	sub	$t9,$t9,$t7
	sub	$t8,$t8,$t7
	jal 	bounce
	jal	read_key_code
	j	main_loop_skew		
main_loop_skew_reserve: #c
	bgt	$t9, 480, main_skew
	bgt	$t8, 480, main_skew_reserve
	jal 	delete
	add	$t9,$t9,$t7
	add	$t8,$t8,$t7
	jal 	bounce
	jal	read_key_code
	j	main_loop_skew_reserve
main_skew: #e
	blt	$t9, 32, main_loop_skew_reserve
	bgt	$t8, 480, main_loop_skew
	jal 	delete
	sub	$t9,$t9,$t7
	add	$t8,$t8,$t7
	jal 	bounce
	jal	read_key_code
	j	main_skew
main_skew_reserve: #f
	bgt	$t9, 480, main_loop_skew
	blt	$t8, 32, main_loop_skew_reserve
	jal 	delete
	add	$t9,$t9,$t7
	sub	$t8,$t8,$t7
	jal 	bounce
	jal	read_key_code
	j	main_skew_reserve

delete:
	subi 	$sp, $sp, 8
	sw 	$ra, 0($sp)			
	li 	$t1, 0				#set $t1 = 0
	jal 	draw_circle			#draw circle with bg color
	lw 	$ra, 0($sp)			
	addi 	$sp, $sp,8
	jr 	$ra				
bounce:		
	subi 	$sp, $sp, 8
	sw 	$ra, 0($sp)			
	li 	$t1, 1				#set $t1 = 1
	jal 	draw_circle 			#draw circle with color 
	lw 	$ra, 0($sp)			
	addi 	$sp, $sp,8
	jr 	$ra				
bounce_done:	
	j 	control
main_done:	
	li 	$v0, 10
	syscall
#C code for midpoint circle algorithm
#int x = r, y = 0;      
#    // Printing the initial point on the axes  
#    // after translation 
#    printf("(%d, %d) ", x + x_centre, y + y_centre);       
#    // When radius is zero only a single 
#    // point will be printed 
#    if (r > 0) 
#        printf("(%d, %d) ", x + x_centre, -y + y_centre); 
#        printf("(%d, %d) ", y + x_centre, x + y_centre); 
#        printf("(%d, %d)\n", -y + x_centre, x + y_centre); 
#    // Initialising the value of P 
#    int P = 1 - r; 
#    while (x > y)   
#        y++;           
#        // Mid-point is inside or on the perimeter 
#       if (P <= 0) 
#           P = P + 2*y + 1; 
#        // Mid-point is outside the perimeter 
#        else
#           x--; 
#            P = P + 2*y - 2*x + 1; 
#       // All the perimeter points have already been printed 
#        if (x < y) 
#            break; 
#        // Printing the generated point and its reflection 
#               // in the other octants after translation 
#        printf("(%d, %d) ", x + x_centre, y + y_centre); 
#        printf("(%d, %d) ", -x + x_centre, y + y_centre); 
#        printf("(%d, %d) ", x + x_centre, -y + y_centre); 
#        printf("(%d, %d)\n", -x + x_centre, -y + y_centre);           
#        // If the generated point is on the line x = y then  
#        // the perimeter points have already been printed 
#        if (x != y)
#            printf("(%d, %d) ", y + x_centre, x + y_centre); 
#            printf("(%d, %d) ", -y + x_centre, x + y_centre); 
#            printf("(%d, %d) ", y + x_centre, -x + y_centre); 
#            printf("(%d, %d)\n", -y + x_centre, -x + y_centre);          
draw_circle:
	subi 	$sp, $sp, 8
	sw 	$ra, 0($sp)			
	lw 	$k0, base 		#display
	lw 	$s0, radius		#x = radius
	li 	$s1, 0			#y = 0
	sub	$s3, $t2, 1
	sub	$s3, $zero, $s3 	#set P = 1-r 
#draw octants
	jal 	setpixel
main_loop:
	blt 	$s0, $s1, main_loop_done		#x < y,break
	blt 	$s3, $0, inside_circle		 	#P < 0,plot (X, Y + 1)
	beq 	$s3, $0, outside_circle		#P = 0,plot (X - 1, Y + 1)
	bgt 	$s3, $0, outside_circle		#P > 0,plot (X - 1, Y + 1)
continue:
	j 	main_loop
main_loop_done:
	lw 	$ra, 0($sp)			
	addi 	$sp, $sp, 8
	jr 	$ra				
inside_circle:	#P = P + 2 * y + 1
	addi 	$s1, $s1, 1		#y = y+1	
	add 	$s4, $s1, $s1		#2y	
	addi 	$s4, $s4, 1		#2y+1	
	add 	$s3, $s3, $s4		#P	
	jal 	setpixel
	j 	continue
outside_circle:	 #P = P + 2 * y - 2 * x + 1
	subi 	$s0, $s0, 1		#x = x-1	
	addi 	$s1, $s1, 1		#y = y+1
	add 	$s4, $s1, $s1		#2y		
	addi 	$s4, $s4, 1		#2y+1	
	sub 	$s7, $0, $s0		#-x
	sub 	$s7, $s7, $s0		#-2x	
	add 	$s7, $s7, $s4		#2x+2y-1	
	add 	$s3, $s3, $s7		#P
	jal 	setpixel
	j 	continue
setpixel:	
	subi 	$sp,$sp,8
	sw 	$ra,0($sp)			
	# draw (X, Y)
	add 	$s6,$t8,$s0
	add 	$s5,$t9,$s1		
	jal 	setpixel_go		
	# draw (Y, X)
	add 	$s6,$t8,$s1
	add 	$s5,$t9,$s0		
	jal 	setpixel_go
	# draw (-X, -Y)
	sub 	$s6,$t8,$s0
	sub 	$s5,$t9,$s1
	jal 	setpixel_go
	# draw (-Y, -X)
	sub 	$s6,$t8,$s1		
	sub 	$s5,$t9,$s0
	jal 	setpixel_go
	# draw (X, -Y)
	add 	$s6,$t8,$s0		
	sub 	$s5,$t9,$s1		
	jal 	setpixel_go
	# draw (Y, -X)
	add 	$s6,$t8,$s1		
	sub 	$s5,$t9,$s0
	jal 	setpixel_go
	# draw (-Y, X)
	sub 	$s6,$t8,$s1	
	add 	$s5,$t9,$s0		
	jal 	setpixel_go
	# draw (-X, Y)
	sub 	$s6,$t8,$s0		
	add 	$s5,$t9,$s1
	jal 	setpixel_go
	lw 	$ra,0($sp)
	addi 	$sp,$sp,8
	jr 	$ra
setpixel_go:	
	subi 	$sp, $sp, 8
	sw 	$ra, 0($sp)			
	mul 	$s5, $s5, 512			#display circle
	add 	$k1, $s5, $s6 			#set position of circle
	mul 	$k1, $k1, 4			#
	add 	$k1, $k1, $k0			#set color
	beq 	$t1, $0, delete_circle		#if $t1 = 0, delete		
	add 	$t0, $zero, $t3 		#set color
	sw 	$t0, 0($k1)
drawing:	
	lw 	$ra, 0($sp)			
	addi 	$sp, $sp,8
	jr 	$ra				
delete_circle:		
	lw 	$t0, bgcolor			#change to bg color
	sw 	$t0, 0($k1)	
	j drawing
	


