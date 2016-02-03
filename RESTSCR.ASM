wdrec           struc
x               dw      ?
y               dw      ?
dx1             dw      ?
dy              dw      ?
xp              dw      ?
yp              dw      ?
s               db      80 dup (?)
bpp             dd      ?
wdrec           ends
i               equ     [bp+10]
j               equ     [bp+6]
data            segment byte public
        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
        EXTRN   RetraceMode:BYTE
data            ends
public          restscr
public          savescr

code            segment byte public
		assume  cs:code,ds:data
restscr         proc    far
                push    bp
                mov     bp,sp
                push    es
                push    ds
		mov     es,ScreenAdr
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     rp6
                mov     dx,3d8h
		mov     al,5h
                out     dx,al
rp6:            lds     si,i
                mov     ax,[si.y]
                mov     cx,160
                mul     cx
                add     ax,[si.x]
                add     ax,[si.x]
                mov     dx,[si.dy]
                inc     dx
		inc     dx
		mov     cx,[si.dx1]
		add     cx,3
                lds     si,j
                mov     bx,cx
rp7:            mov     cx,bx
                mov     di,ax
                cld
                rep  movsw
                add     ax,160
                dec     dx
		jnz     rp7
		pop     ds
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     rend1
                mov     dx,3d8h
		mov     al,9h
                out     dx,al
rend1:          pop     es
                mov     sp,bp
                pop     bp
		ret     8
restscr         endp
savescr         proc    far
                push    bp
                mov     bp,sp
                push    es
		push    ds
		mov	cl,RetraceMode
		mov     bx,Screenadr
		rcr     cl,1
		jnc     sp6
                mov     dx,3d8h
		mov     al,5h
                out     dx,al

sp6:            lds     si,i
                les     di,j
                mov     ax,[si.y]
                mov     cx,160
                mul     cx
                add     ax,[si.x]
                add     ax,[si.x]
                mov     dx,[si.dy]
                inc     dx
		inc     dx
		mov     cx,[si.dx1]
		add     cx,3
		mov     ds,bx
                mov     bx,cx
sp7:            mov     cx,bx
                mov     si,ax
                cld
		rep     movsw
                add     ax,160
                dec     dx
		jnz     sp7
		pop     ds
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     send1
                mov     dx,3d8h
		mov     al,9h
                out     dx,al
send1:		pop     es
                pop     bp
		ret     8
savescr         endp
code            ends
                end


