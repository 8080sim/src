data            segment byte public
        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
        EXTRN   RetraceMode:BYTE
	EXTRN   Tafelattr:BYTE
data            ends
public          tafel
code            segment byte public
		assume  cs:code,ds:data
tafel           proc    far
                push    bp
                mov     bp,sp
                push    es
		mov     ax,ScreenAdr
		mov     bl,20h
		cmp     ah,0b8h
		jz      p0
		mov     bl,177
p0:		mov     es,ax
		mov	cl,RetraceMode
		rcr     cl,1
		jnc     p6
                mov     dx,3d8h
		mov     al,5h
                out     dx,al
p6:             mov     ax,[bp+6]
		mov     di,PhyScrCols
                mul     di
                mov     di,ax
		mov     al,bl
		mov     ah,tafelAttr
                mov     cx,1920
                sub     cx,di
                shl     di,1
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
                ret     2
tafel           endp
code            ends
                end
