# assembly-calculator
Calcuator in x86 32-bit assembly
instructions:
    open containing folder on terminal
    write make
    write ./calc
    
    the calculator supports the following commands:
   1.‘q’ – quit
   2.‘+’
   3.‘p’ – pop-and-print-
     pop one operand from the operand stack, and print its value to stdout
   4.‘d’ – duplicate
    push a copy of the top of the operand stack onto the top of the operand stack
   5.‘^’ - X*2^Y
    (with X being the top of operand stack and Y the element next to x in the operand stack.
    If Y>200 his is considered an error)
   6.‘v’ – X*2^(-Y)
   7.‘n’ – number of '1' bits
