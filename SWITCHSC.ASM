i               equ     [bp+6]
data            segment byte public
        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
        EXTRN   RetraceMode:BYTE
data            ends
public          switchscreen

code            segment byte public
		assume  cs:code,ds:data
switchscreen    proc    far
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
rp6:            xor     di,di
                mov     cx,2000
                lds     si,i
                cld
rp8:            mov     ax,es:[di]
                movsw
                mov     [si-2],ax
                loop    rp8
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
		ret     4
switchscreen    endp
code            ends
                end


