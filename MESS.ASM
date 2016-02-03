m       macro  nr,text
local   e1
local   e2
dw      nr
e1      equ    $
db      offset e2 -e1-1
db      text
e2      equ  $
        endm
;
;       MESs.ASM

DATA    SEGMENT BYTE PUBLIC

DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

        PUBLIC  EdMessagePtr

;CS-relative data:
;Be sure to terminate list with a pair of 0 bytes

Messages LABEL BYTE
include mymess.inc
db 0,0
;****************************************************** EdMessagePtr

;  function EdMessagePtr(msgno:word) : Pointer; external;

;    {-Return a pointer to the message string, nil if not available}

MsgNo           EQU       WORD PTR [BP+6]

EdMessagePtr    PROC Far

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        PUSH    DS                      ;Save DS

        MOV     BX,MsgNo                ;Get message number to seek

        MOV     AX,CS
        MOV     DS,AX                   ;Put CS into DS
        ASSUME  DS:CODE
        LEA     SI,Messages             ;Now DS:SI points to Messages
	cld
EMPNext:
        LODSW                           ;Next message number into AX
        OR      AX,AX                   ;Last message?
        JZ      EMPNotFound
        CMP     AX,BX                   ;The message we seek?
        JZ      EMPFound
        LODSB                           ;Get length byte of string
        XOR     AH,AH                   ;Clear upper byte
        ADD     SI,AX                   ;Skip over string
        JMP     Short EMPNext           ;Try again

EMPNotFound:
        XOR     DX,DX                   ;Clear pointer if Message not found
                                        ;AX is already zero is we get here
        JMP     Short EMPDone

EMPFound:
                                        ;Return pointer in DX:AX
        MOV     DX,CS                   ;Pointer Segment is current CS
        MOV     AX,SI                   ;SI points to length byte of string

EMPDone:
        POP     DS                      ;Restore DS
        ASSUME  DS:DATA
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     2                       ;Remove parameter from stack

EdMessagePtr    ENDP

CODE    ENDS

        END
