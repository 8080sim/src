data            segment byte public
        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
        EXTRN   RetraceMode:BYTE
	EXTRN   Tafelattr:BYTE
data            ends
public          tafel1
code            segment byte public
		assume  cs:code,ds:data
tafel1          proc    far
                push    bp
                mov     bp,sp
                push    es
		mov     es,ScreenAdr
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     p6
                mov     dx,3d8h
		mov     al,5h
                out     dx,al
p6:             mov     Di,0
		mov     ax,es
		mov     al,32
		cmp     ah,0b8h
		jz      p2
		mov     al,177
p2:		mov     ah,tafelAttr
		mov     cx,80*25
                cld
p1:             rep     stosw
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     end1
                mov     dx,3d8h
		mov     al,9h
                out     dx,al
end1:           pop     es
                mov     sp,bp
                pop     bp
		ret
tafel1          endp
code            ends
                end
