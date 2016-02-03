;       wsSCRN.ASM


DATA    SEGMENT BYTE PUBLIC

        EXTRN   ScreenAdr:WORD,PhyScrCols:WORD  ;Pascal variables
        EXTRN   RetraceMode:BYTE
	EXTRN   CursAttr:Word
;        EXTRN   Aline:BYTE,Tline:BYTE
        EXTRN   WindMin:word,WindMax:Word;
DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

	PUBLIC  wi,EdChangeAttribute;,xorattrib
	PUBLIC  WiA
	PUBLIC  EdMoveFromScreen,EdMoveToScreen
        PUBLIC  EdSetCursor

;******************************************************

;calculate Offset in video memory.
;On entry, AX has Row, DI has Column
;On exit, ES has ScreenAdr, DI has offset

CalcOffset      PROC NEAR

        DEC     AX                      ;Row to 0..24 range
        add     al,byte ptr WindMin+1
        MOV     CX,PhyScrCols           ;CX = Rows per column
        MUL     CX                      ;AX = Row * PhyScrCols
        DEC     DI                      ;Column to 0..79 range
        ADD     DI,AX                   ;DI = (Row * PhyScrCols) + Col
        mov     ax,windMin
        xor     ah,ah
        add     Di,ax
        SHL     DI,1                    ;Account for attribute bytes
        MOV     ES,ScreenAdr            ;ES:DI points to ScreenAdr:Row,Col
        RET                             ;Return

CalcOffset      ENDP

CalcOffsetAbs      PROC NEAR

        DEC     AX                      ;Row to 0..24 range
        MOV     CX,PhyScrCols           ;CX = Rows per column
        MUL     CX                      ;AX = Row * PhyScrCols
        DEC     DI                      ;Column to 0..79 range
        ADD     DI,AX                   ;DI = (Row * PhyScrCols) + Col
        SHL     DI,1                    ;Account for attribute bytes
        MOV     ES,ScreenAdr            ;ES:DI points to ScreenAdr:Row,Col
        RET                             ;Return

CalcOffsetAbs      ENDP

;******************************************************
;procedure wi( x, y, Attr : Integer;St : String);

;Write St at Row,Col absolute in Attr (video attribute) without snow

FWAttr          EQU     BYTE PTR [BP+10]
FWCol           EQU     WORD PTR [BP+14]
FWRow           EQU     WORD PTR [BP+12]
FWSt            EQU     DWORD PTR [BP+6]

Wi             PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        PUSH    DS                      ;Save DS
        MOV     AX,FWRow                ;AX = Row
        MOV     DI,FWCol                ;DI = Column
        CALL    CalcOffset              ;Call routine to calculate offset
wi1:	MOV     CL,RetraceMode          ;Grab this before changing DS
        LDS     SI,FWSt                 ;DS:SI points to St[0]
        CLD                             ;Set direction to forward
        XOR     AX,AX                   ;AX = 0
        LODSB                           ;AX = Length(St); DS:SI -> St[1]
        XCHG    AX,CX                   ;CX = Length; AL = Wait
        JCXZ    FWExit                  ;If string empty, exit
        MOV     AH,FWAttr               ;AH = Attribute
        RCR     AL,1                    ;If RetraceMode is False...
        JNC     FWMono                  ; use "FWMono" routine
        MOV     DX,03DAh                ;Point DX to CGA status port
FWGetNext:
        LODSB                           ;Load next character into AL
                                        ; AH already has Attr
        MOV     BX,AX                   ;Store video word in BX
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
        MOV     AX,BX                   ;Move word back to AX...
        STOSW                           ; and then to screen
        STI                             ;Allow interrupts!
        LOOP    FWGetNext               ;Get next character
        JMP     FWExit                  ;Done
FWMono:
        LODSB                           ;Load next character into AL
                                        ; AH already has Attr
        STOSW                           ;Move video word into place
        LOOP    FWMono                  ;Get next character
FWExit:
        POP     DS                      ;Restore DS
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     10                      ;Remove parameters and return

Wi      ENDP
;procedure wia( x, y, Attr : Integer;St : String);

;Write St at Row,Col absolute in Attr (video attribute) without snow

FWAttr          EQU     BYTE PTR [BP+10]
FWCol           EQU     WORD PTR [BP+14]
FWRow           EQU     WORD PTR [BP+12]
FWSt            EQU     DWORD PTR [BP+6]

WiA             PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        PUSH    DS                      ;Save DS
        MOV     AX,FWRow                ;AX = Row
        MOV     DI,FWCol                ;DI = Column
	call    CalcOffsetAbs
	jmp     wi1
WiA     EndP
;******************************************************

;procedure EdChangeAttribute(Number : Integer; Row, Col, Attr : Integer);

;Change Number video attributes to Attr starting at Row,Col

CAAttr          EQU     BYTE PTR [BP+6]
CACol           EQU     WORD PTR [BP+8]
CARow           EQU     WORD PTR [BP+10]
CANumber        EQU     WORD PTR [BP+12]

EdChangeAttribute       PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        MOV     AX,CARow                ;AX = Row
        MOV     DI,CACol                ;DI = Column
	CALL    CalcOffsetAbs           ;Call routine to calculate offset
        INC     DI                      ;Skip character
        MOV     AL,CAAttr               ;AL = Attribute
	cmp	al,77h
	jnz     edch1
	mov     cx,es
	cmp     cx,0b000h
	jnz     edch1
	mov	al,00
edch1:	CLD                             ;Set direction to forward
        MOV     CX,CANumber             ;CX = Number to change
        JCXZ    CAExit                  ;If zero, exit
        CMP     RetraceMode,1           ;Get wait state
        JNE     CANoWait                ;If RetraceMode is False
                                        ; use CANoWait routine
        MOV     AH,AL                   ;Store attribute in AH
        MOV     DX,03DAh                ;Point DX to CGA status port
CAGetNext:
        CLI                             ;No interrupts now
CAWaitNoH:
        IN      AL,DX                   ;Get 6845 status
        TEST    AL,8                    ;Check for vert. retrace
        JNZ     CAGo                    ;In progress? Go
        RCR     AL,1                    ;Wait for end of horizontal
        JC      CAWaitNoH               ; retrace
CAWaitH:
        IN      AL,DX                   ;Get 6845 status again
        RCR     AL,1                    ;Wait for horizontal
        JNC     CAWaitH                 ; retrace
CAGo:
        MOV     AL,AH                   ;Move Attr back to AL...
        STOSB                           ; and then to screen
        STI                             ;Allow interrupts
        INC     DI                      ;Skip characters
        LOOP    CAGetNext               ;Look for next opportunity
        JMP     CAExit                  ;Done
CANoWait:
        STOSB                           ;Change the attribute
        INC     DI                      ;Skip characters
        LOOP    CANoWait                ;Get next character
CAExit:                                 ;Next instruction
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     8                       ;Remove parameters and return

EdChangeAttribute       ENDP

;procedure xorAttrib(Number : Integer; Row, Col, Attr : Integer);

;Change Number video attributes to Attr starting at Row,Col

CAttr          EQU     BYTE PTR [BP+6]
CCol           EQU     WORD PTR [BP+8]
CRow           EQU     WORD PTR [BP+10]
CNumber        EQU     WORD PTR [BP+12]

xorAttrib       PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
	MOV     AX,CRow                ;AX = Row
	MOV     DI,CCol                ;DI = Column
	CALL    CalcOffsetAbs           ;Call routine to calculate offset
        INC     DI                      ;Skip character
	MOV     AL,CAttr               ;AL = Attribute
	cmp	al,77h
	jnz     edxo1
	mov     cx,es
	cmp     cx,0b000h
	jnz     edch1
	mov	al,00
edxo1:	CLD                             ;Set direction to forward
	MOV     CX,CNumber             ;CX = Number to change
	JCXZ    CExit                  ;If zero, exit
        CMP     RetraceMode,1           ;Get wait state
	JNE     CNoWait                ;If RetraceMode is False
                                        ; use CANoWait routine
        MOV     AH,AL                   ;Store attribute in AH
        MOV     DX,03DAh                ;Point DX to CGA status port
CGetNext:
        CLI                             ;No interrupts now
CWaitNoH:
        IN      AL,DX                   ;Get 6845 status
        TEST    AL,8                    ;Check for vert. retrace
	JNZ     CGo                    ;In progress? Go
        RCR     AL,1                    ;Wait for end of horizontal
	JC      CWaitNoH               ; retrace
CWaitH:
        IN      AL,DX                   ;Get 6845 status again
        RCR     AL,1                    ;Wait for horizontal
	JNC     CWaitH                 ; retrace
CGo:
        MOV     AL,AH                   ;Move Attr back to AL...
	xor    es:[di],al
        STI                             ;Allow interrupts
	inc    di			; and then to screen
        INC     DI                      ;Skip characters
	LOOP    CGetNext               ;Look for next opportunity
	JMP     CExit                  ;Done
CNoWait:
	xor     es:[di],al
	inc	di   		      ;Change the attribute
        INC     DI                      ;Skip characters
	LOOP    CNoWait                ;Get next character
CExit:                                 ;Next instruction
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     8                       ;Remove parameters and return

xorAttrib       ENDP

;******************************************************

;procedure EdMoveFromScreen(var Source, Dest; Length : Integer);

;Move Length words from Source (video memory) to Dest without snow

MFLength        EQU     WORD PTR [BP+6]
MFDest          EQU     DWORD PTR [BP+8]
MFSource        EQU     DWORD PTR [BP+12]

EdMoveFromScreen        PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        MOV     BX,DS                   ;Save DS in BX
        MOV     AL,RetraceMode          ;Grab before changing DS
        LES     DI,MFDest               ;ES:DI points to Dest
        LDS     SI,MFSource             ;DS:SI points to Source
        MOV     CX,MFLength             ;CX = Length
        CLD                             ;Set direction to forward
        RCR     AL,1                    ;Check RetraceMode
        JNC     MFNoWait                ;False? Use MFNoWait routine
        MOV     DX,03DAh                ;Point DX to CGA status port
MFNext:
        CLI                             ;No interrupts now
MFWaitNoH:
        IN      AL,DX                   ;Get 6845 status
        TEST    AL,8                    ;Check for vertical retrace
        JNZ     MFGo                    ;In progress? go
        RCR     AL,1                    ;Wait for end of horizontal
        JC      MFWaitNoH               ; retrace
MFWaitH:
        IN      AL,DX                   ;Get 6845 status again
        RCR     AL,1                    ;Wait for horizontal
        JNC     MFWaitH                 ; retrace
MFGo:
        LODSW                           ;Load next video word into AX
        STI                             ;Allow interrupts
        STOSW                           ;Store video word in Dest
        LOOP    MFNext                  ;Get next video word
        JMP     MFExit                  ;All Done
MFNoWait:
        REP     MOVSW                   ;That's it!
MFExit:
        MOV     DS,BX                   ;Restore DS
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     10                      ;Remove parameters and return

EdMoveFromScreen        ENDP

;******************************************************

;procedure EdMoveToScreen(var Source, Dest; Length : Integer);

;Move Length words from Source to Dest (video memory) without snow

MTLength        EQU     WORD PTR [BP+6]
MTDest          EQU     DWORD PTR [BP+8]
MTSource        EQU     DWORD PTR [BP+12]

EdMoveToScreen          PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        PUSH    DS                      ;Save DS
        MOV     AL,RetraceMode          ;Grab before changing DS
        LES     DI,MTDest               ;ES:DI points to Dest
        LDS     SI,MTSource             ;DS:SI points to Source
        MOV     CX,MTLength             ;CX = Length
        CLD                             ;Set direction to forward
        RCR     AL,1                    ;Check RetraceMode
        JNC     MTNoWait                ;False? Use MTNoWait routine
        MOV     DX,03DAh                ;Point DX to CGA status port
MTGetNext:
        LODSW                           ;Load next video word into AX
        MOV     BX,AX                   ;Store video word in BX
        CLI                             ;No interrupts now
MTWaitNoH:
        IN      AL,DX                   ;Get 6845 status
        TEST    AL,8                    ;Check for vertical retrace
        JNZ     MTGo                    ;In progress? Go
        RCR     AL,1                    ;Wait for end of horizontal
        JC      MTWaitNoH               ; retrace
MTWaitH:
        IN      AL,DX                   ;Get 6845 status again
        RCR     AL,1                    ;Wait for horizontal
        JNC     MTWaitH                 ; retrace
MTGo:
        MOV     AX,BX                   ;Move word back to AX...
        STOSW                           ; and then to screen
        STI                             ;Allow interrupts
        LOOP    MTGetNext               ;Get next video word
        JMP     MTExit                  ;All done
MTNoWait:
        REP     MOVSW                   ;That's all!
MTExit:
        POP     DS                      ;Restore DS
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     10                      ;Remove parameters and return

EdMoveToScreen          ENDP

;procedure EdSetCursor(ScanLines : Word);

;Set the scan lines of the hardware cursor

ScanLines       EQU     WORD PTR [BP+6]

EdSetCursor     PROC FAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame

        PUSH    BP                      ;Protect BP
        MOV     CX,ScanLines
	mov     cursAttr,CX
	MOV     AH,1
        INT     10H
        POP     BP

        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     2                       ;Remove parameters and return

EdSetCursor     ENDP



CODE    ENDS

        END
