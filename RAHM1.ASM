y2              equ     [bp+6]
x2              equ     [bp+8]
y1              equ     [bp+10]
x1              equ     [bp+12]
crt_mod         equ     49h
crt_mode_set    equ     65h
data            segment byte public
        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
	EXTRN   RetraceMode:Byte,Rahmattr:byte,Tattr:BYTE
data            ends
public          rahm
code            segment public
		assume  cs:code,ds:data;
rahm            proc    far
                push    bp
                mov     bp,sp
                push    es
		mov     es,ScreenAdr
		mov	cl,RetraceMode
p6:             cld
                mov     bh,y1
                mov     bl,x1
                call    adresse
                push    di
		mov     ah,RahmAttr
		mov     al,0c9h
		rcr    cl,1
;		jc      pwait
		stosw
                mov     dx,x2
                sub     dx,x1
                dec     dx
		mov     al,0cdh
                call    linie
		mov     al,0bbh
                stosw
                mov     bh,y2
                mov     bl,x1
                call    adresse
		mov     al,0c8h
                stosw
		mov     al,0cdh
                call    linie
		mov     al,0bch
                stosw
                mov     cx,y2
                sub     cx,y1
                dec     cx
                pop     di
		mov     al,0bah
lp2:            add     di,160
                push    di
		stosw
		mov	ah,Tattr
		mov     al,20h
                call    linie
		mov	ah,RahmAttr
		mov     al,0bah
                stosw
                pop     di
                loop    lp2
end1:           pop     es
                mov     sp,bp
                pop     bp
                ret     8
pwait:		call     wait
                mov     dx,x2
                sub     dx,x1
                dec     dx
		mov	ah,Rahmattr
		mov     al,0cdh
		call    plinie
		mov     al,0bbh
		call    wait
                mov     bh,y2
                mov     bl,x1
                call    adresse
		mov     al,0c8h
		call    wait
		mov     al,0cdh
		call    plinie
		mov     al,0bch
		call    wait
                mov     cx,y2
                sub     cx,y1
                dec     cx
                pop     di
		mov     ax,0bah
plp2:           add     di,160
                push    di
		call    wait
		mov	ah,Tattr
		mov     al,020h
		call    plinie
		mov	ah,RahmAttr
		mov     al,0bah
		call    wait
                pop     di
		loop    plp2
		jmp     end1
rahm            endp
adresse         proc near
		push	ax
		mov     ax,PhyScrCols
                mul     bh
                xor     bh,bh
                add     ax,bx
                add     ax,ax
                mov     di,ax
		pop	ax
		ret
adresse         endp
linie           proc    near
                push    cx
                mov     cx,dx
		jcxz    w6
		rep     stosw
w6:		pop     cx
		ret
linie           endp
wait:   push    dx
        MOV     DX,03DAh                ;Point DX to CGA status port
	MOV     Si,AX                   ;Store video word in BX
        CLI                             ;No interrupts now
FWWaitNoH:
        IN      AL,DX                   ;Get 6845 status
        TEST    AL,8                    ;Vertical retrace in progress?
        JNZ     FWStore                 ;If so, go
        RCR     AL,1                    ;Else, wait for end of
        JC      FWWaitNoH               ; horizontal retrace
FWWaitH:
        IN      AL,DX                   ;Get 6845 status again
        RCR     AL,1                    ;Wait for horizontal
        JNC     FWWaitH                 ; retrace
FWStore:
	MOV     AX,SI                   ;Move word back to AX...
        STOSW                           ; and then to screen
        STI                             ;Allow interrupts!
	pop	dx
	ret
plinie           proc    near
                push    cx
                mov     cx,dx
		jcxz    pw6
pw7:		call    wait
		loop    pw7
pw6:		pop     cx
		ret
plinie           endp
code            ends
                end
