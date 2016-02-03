{$F+}
Unit Int05;

Interface

Uses Dos;

Const
	RSTNr			: Byte = 1;
	IRQ       : Byte    = $0;
	IntAdr    : Word    = $8100;
	ei        : Boolean = True;
	EnRST			: Boolean = False;
	IntEnable : Boolean = True;
	GotInt    : Boolean = False;
	IntCtr    : Word    = 0;
	Intloop   : Word    = 50;
	IntInstFlag : Boolean = False;
	IoAdr		 : Word		 = $300;

Var
	Intmask  : Byte;
	RSTSIM	 : Record
							 AndMask : Byte;
							 OrMask	 : Byte;
						 End;
	RSTRIM	 : Record
							 AndMask : Byte;
							 OrMask	 : Byte;
						 End;

Procedure SetupInt;

Procedure RestoreInt;

Procedure CLI;

Procedure STI;

Const
  IntDevice    = $20;
  EOI          = $60;
  ChnInt: Byte = $80;

Var
  IntNr          : Byte;
  EndOfInt       : Byte;
  Enable         : Byte;
  OldMask        : Byte;
  OldInt         : Pointer;
  Reg            : Registers;

Implementation


Procedure CLI;
Begin
  Inline ($FA);
End;

Procedure STI;
Begin
  InLine ($FB);
End;

Procedure IntRout (Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP : Word); Interrupt;
Begin
  If Not GotInt Then Begin
    If IRQ = 0 Then Inc (IntCtr) Else IntCtr := Intloop;
    If IntCtr = Intloop Then Begin
      GotInt := True;                { Statusflag einstellen }
{
			IntMask := IntMask Or $10;
}
			IntMask := IntMask Or RSTRIM.OrMask;
			IntCtr := 0;
    End;
  End;
  Reg.ax := ax;                  { Register speichern   }
  Reg.bx := bx;
  Reg.cx := cx;
  Reg.dx := dx;
  Reg.si := si;
  Reg.di := di;
  Reg.ds := ds;
  Reg.es := es;
  Reg.bp := bp;
  Port [IntDevice] := EndOfInt;  { Interrupt quittieren }
  Intr (ChnInt,Reg);            { an alten IRQ weiterleiten }
  ax := Reg.ax;                 { Register restaurieren     }
  bx := Reg.bx;
  cx := Reg.cx;
  dx := Reg.dx;
  si := Reg.si;
  di := Reg.di;
	ds := Reg.ds;
  es := Reg.es;
  bp := Reg.bp;
End;


Procedure SetupInt;
Begin
  CLI;
  If IntInstFlag Then Exit;
  GotInt := False;            { Flag zur Interrupterkennung }
  IntNr := IRQ + $08;         { Nummer des umzuleitenden Interrupts }
  EndOfInt := EOI + IRQ;      { Meldung an den 8259 daá der IRQ erledigt ist }
  GetIntVec (IntNr,OldInt);   { Alten Vektor holen und speichern }
  SetIntVec (ChnInt,OldInt);  { Ersatzvektor initialisieren }
  SetIntVec (IntNr,@IntRout); { Interrupt verbiegen }
  OldMask := Port [IntDevice+1];  { Int-Maske des 8259 speichern }
  Enable  := $01;             { Interrupt Zulassung vorbereiten }
  Enable  := Enable Shl IRQ;
  Enable  := Not Enable;
  Port [IntDevice+1] := OldMask And Enable;
  IntCtr := 0;
  IntInstFlag := True;
  STI;
End;

Procedure RestoreInt;
Begin
  CLI;
  If Not IntInstFlag Then Exit;
  Port [IntDevice+1] := OldMask; { Alte Interruptmaske restaurieren }
  SetIntVec (IntNr,OldInt);     { Alten Interruptvektor restaurieren }
  IntInstFlag := False;
  STI;
End;

End.

{$F-}
