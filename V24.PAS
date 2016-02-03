(*////////////////////////////////////////////////////////////////////////////
///                                                                        ///
///         T U R B O  -  P A S C A L  V24-Interrupt-Support V2.00         ///
///                (c) Copyright June 1988 by C.Philipps                   ///
///                                                                        ///
///               (Turbo Pascal V4.0  or higher required)                  ///
///                                                                        ///
//////////////////////////////////////////////////////////////////////////////
///                                                                        ///
///            Low-level interrupt-handling for the serial ports. Speeds   ///
///            up to 115200 bps are supportet, one port at a time.         ///
///            Parts of the basics were taken from Mike Halliday's pop-    ///
///            ular ASYNC-package (Turbo Pascal 3.0, PD).                  ///
///                                                                        ///
///       This module is hereby donated to the public domain.              ///
///                                                                        ///
///       Christian Philipps                                               ///
///       Duesseldorfer Str. 316                                            ///
///       4130 Moers 1                                                     ///
///       West-Germany                                                     ///
///                                                                        ///
///       Last modified: 07/89                                             ///
///                                                                        ///
////////////////////////////////////////////////////////////////////////////*)

{$R-,S-,I-,D-,F-,V-,B-,N-,L- }

UNIT V24;

INTERFACE

USES DOS;

TYPE   ComType      = (Com1,Com2,Com3,Com4,Com5,Com6);
       BaudType     = (b110,b150,b300,b600,b1200,b2400,b4800,b9600,b19200,
                       b38400,b57600,b115200);
       ParityType   = (Space,Odd,Mark,Even,None);
       DataBitsType = (d5,d6,d7,d8);
       StopBitsType = (s1,s2);

CONST  V24Timeout   : BOOLEAN = FALSE;  {SendByte-Timeout}
       IntMasks     : ARRAY[Com1..Com6] OF WORD    = ($EF,$F7,$EF,$F7,$EF,$F7);
       IntVect      : ARRAY[Com1..Com6] OF BYTE    = ($0C,$0B,$0C,$0B,$0C,$0B);

VAR    V24TP        : WORD;         {Buffer Tail-Pointer
                                     Im Interface-Teil, da zur Ereignis-
                                     steuerung im Multi-Tasking benîtigt.}
       ComBaseAdr   : ARRAY[Com1..Com6] OF WORD;

FUNCTION  V24DataAvail:BOOLEAN;
FUNCTION  V24GetByte:BYTE;
PROCEDURE InitCom(ComPort:ComType;Baudrate:BaudType;Parity:ParityType;
                  Bits:DataBitsType;Stop:StopBitsType);
PROCEDURE DisableCom;
PROCEDURE SendByte(Data:BYTE);

{=============================================================================}

IMPLEMENTATION

CONST  Regs       : Registers =
       (AX:0;BX:0;CX:0;DX:0;BP:0;SI:0;DI:0;DS:0;ES:0;FLAGS:0);
       RBR        = $00;          {xF8 Receive Buffer Register            }
       THR        = $00;          {xF8 Transmitter Holding Register       }
       IER        = $01;          {xF9 Interrupt Enable Register          }
       IIR        = $02;          {xFA Interrupt Identification Register  }
       LCR        = $03;          {xFB Line Control Register              }
       MCR        = $04;          {xFC Modem Control Register             }
       LSR        = $05;          {xFD Line Status Register               }
       MSR        = $06;          {xFE Modem Status Register              }
                                  {--- if LCR Bit 7 = 1  ---              }
       DLL        = $00;          {xF8 Divisor Latch Low Byte             }
       DLH        = $01;          {xF9 Divisor Latch Hi  Byte             }
       CMD8259    = $20;          {Interrupt Controller Command Register  }
       IMR8259    = $21;          {Interrupt Controller Mask Register     }
                                  {Should be evaluated by any higher-level
                                   send-routine}
			 LoopLimit  = 1000;         {When does a timeout-error occur        }
       V24BuffSize= 2048;         { Ringpuffer 2 KB }

VAR    BiosComBaseAdr : ARRAY[Com1..Com6] OF WORD ABSOLUTE $0040:$0000;
       ActivePort : ComType;
       { The Com-Port base adresses are taken from the BIOS data area }
       ComBase    : WORD;         {Hardware Com-Port Base Adress          }
       OldV24     : Pointer;
       V24HP      : WORD;         {Buffer Head-Pointer                    }
       V24BuffEnd : WORD;         {Buffer End-Adress                      }
       V24Buff    : ARRAY[0..V24BuffSize] OF BYTE;
       OExitHandler : Pointer;    {Save-Area fÅr Zeiger auf Org.-Exit-Proc}

{============================ lokale Routinen ================================}

PROCEDURE V24Int; external;
{$L V24.obj}

{-----------------------------------------------------------------------------}

PROCEDURE ClearPendingInterrupts;

VAR  N : BYTE;
 
BEGIN {ClearPendingInterrupts}
  WHILE (PORT[ComBase+IIR] AND 1) = 0 DO  {While Interrupts are pending}
  BEGIN
    N := PORT[ComBase+LSR];               {Read Line Status}
    N := PORT[ComBase+MSR];               {Read Modem Status}
    N := PORT[ComBase+RBR];               {Read Receive Buffer Register}
    PORT[CMD8259] := $20;                 {End of Interrupt}
  END;
END;  {ClearPendingInterrupts}

{======================== extern verfÅgbare Routinen =========================}

FUNCTION V24DataAvail:BOOLEAN;

{ This function checks, whether there are characters in the buffer }

BEGIN {V24DataAvail}
  V24DataAvail := (V24HP <> V24TP);
END;  {V24DataAvail}

{-----------------------------------------------------------------------------}

FUNCTION V24GetByte:BYTE;

{ Take a byte out of the ring-buffer and return it to the caller.
  This function assumes, that the application has called V24DataAvail
  before to assure, that there are characters available!!!!
  The ISR only reads the current head-pointer value, so this routine
  may modify the head-pointer with interrupts enabled. }

BEGIN {V24GetByte}
  V24GetByte := Mem[DSeg:V24HP];
  Inc(V24HP);
  IF V24HP > V24BuffEnd
     THEN V24HP := Ofs(V24Buff);
END;  {V24GetByte}

{-----------------------------------------------------------------------------}

PROCEDURE SendByte(Data:BYTE);

VAR   Count:BYTE;

BEGIN {SendByte}
  Count := 0;
  V24Timeout := FALSE;
  IF ComBase > 0
     THEN BEGIN
            REPEAT
              Count := SUCC(Count);
            UNTIL ((PORT[ComBase+LSR] AND $20) <> 0) OR (Count > LoopLimit);
            IF Count > LoopLimit
               THEN V24Timeout := TRUE
               ELSE PORT[ComBase+THR] := Data;
          END;
END;  {SendByte}

{-----------------------------------------------------------------------------}

PROCEDURE InitCom(ComPort:ComType;Baudrate:BaudType;Parity:ParityType;
                  Bits:DataBitsType;Stop:StopBitsType);

CONST BaudConst   : ARRAY[b110..b115200] OF WORD =
                    ($417,$300,$180,$C0,$60,$30,$18,$0C,$06,$03,$02,$01);
      ParityConst : ARRAY[Space..None] OF BYTE =
                    ($38,$08,$28,$18,$00);
      BitsConst   : ARRAY[d5..d8] OF BYTE =
                    ($00,$01,$02,$03);
      StopConst   : ARRAY[s1..s2] OF BYTE =
                    ($00,$04);

BEGIN {InitCom}
  V24HP       := Ofs(V24Buff);
  V24TP       := V24HP;
  V24BuffEnd  := V24HP+V24BuffSize;
  FillChar(V24Buff,Succ(V24BuffSize),#0);
  V24Timeout := FALSE;                             {Reset Timeout-Marker}
  ComBase := ComBaseAdr[ComPort];                  {Get Com-Port base adress}
  ActivePort := ComPort;                           {Keep Active-Port for EOI}
  ClearPendingInterrupts;
  GetIntVec(IntVect[ComPort],OldV24);
  SetIntVec(IntVect[ComPort],@V24Int);
                                                   {Install interrupt routine}
  INLINE($FA);                                     {CLI}
  PORT[ComBase+LCR] := $80;                        {Adress Divisor Latch}
  PORT[ComBase+DLH] := Hi(BaudConst[Baudrate]);    {Set Baud rate}
  PORT[COMBase+DLL] := Lo(BaudConst[Baudrate]);
  PORT[ComBase+LCR] := ($00 OR ParityConst[Parity] {Setup Parity}
                            OR BitsConst[Bits]     {Setup number of databits}
                            OR StopConst[Stop]);   {Setup number of stopbits}
  PORT[ComBase+MCR] := $0B;                        {Set RTS,DTR,OUT2}
(*
  PORT[ComBase+MCR] := $1B;                        {Set RTS,DTR,OUT2,Loop}
*)
  PORT[ComBase+IER] := $01;                        {Enable Data-Available Interrupts}
  PORT[IMR8259] := PORT[IMR8259] AND IntMasks[ComPort]; {Enable V24-Interrups}
  INLINE($FB);                                     {STI}
END;  {InitCom}

{-----------------------------------------------------------------------------}

PROCEDURE DisableCom;

BEGIN {DisableCom}
  IF ComBase = 0
     THEN Exit;
  INLINE($FA);                                     {CLI}
  PORT[ComBase+MCR] := 00;                         {Disable Interrupts, Reset MCR}
  PORT[IMR8259] := PORT[IMR8259] OR $18;           {Disable Interrupt Level 3 and 4}
  PORT[ComBase+IER] := 0;                          {Disable 8250-Interrupts}
  ClearPendingInterrupts;                          {Clean up}
  ComBase := 0;                                    {Reset Combase}
  SetIntVec(IntVect[ActivePort],OldV24);           {Reset old IV}
  INLINE($FB);                                     {STI}
END;  {DisableCom}

{-----------------------------------------------------------------------------}

{$F+}
PROCEDURE V24ExitProc;

BEGIN {V24ExitProc}
  DisableCom;
  ExitProc := OExitHandler;                 { alten Exit-Handler reaktivieren }
END;  {V24ExitProc}
{$F-}

{-----------------------------------------------------------------------------}

BEGIN {Initialisation}
  {Grund-Init, damit irrtuemliche Aufrufe von V24DataAvail nicht zu
   endlosen Ausgaben von Speicherschrott fÅhren!}
  Move(BiosComBaseAdr,ComBaseAdr[Com1],SizeOf(BiosComBaseAdr));
  Move(BiosComBaseAdr,ComBaseAdr[Com3],SizeOf(BiosComBaseAdr));
  Move(BiosComBaseAdr,ComBaseAdr[Com5],SizeOf(BiosComBaseAdr));
  ComBase     := 0;
  V24HP       := Ofs(V24Buff);
  V24TP       := V24HP;
  V24BuffEnd  := V24HP+V24BuffSize;

  OExitHandler := ExitProc;
  ExitProc     := @V24ExitProc;
END.  {Initialisation}

(*////////////////////////////////////////////////////////////////////////////
///                       E N D   O F   M O D U L E                        ///
////////////////////////////////////////////////////////////////////////////*)
