Unit Transfil;

{
	1.) Bibliothek zum Transfer von Intel - Hexfiles
	Åber die V24 - Schnittstelle in den EZ80 / Profi5
	2.) Teile der Interruptsteuerung
}

Interface

{$I direct.inc}

Uses
		 crt,
		 procs,
		 printer,
		 astypdea,
		 asprocs,
		 mywindow,
		 mygloerr,
		 myinput,
		 v24,
		 int05;

(*

  Bibliothek zur V24 - Schnittstelle

  Interfaceteil von V24 - TPU:

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

*)

{ Eigentlicher Interfaceteil von Transfile }

Const
  DatInfo = 'DATEI.MSK';

	l98anz  = 5;
	l98     : ARRAY[1..l98anz] OF RECORD
							xp,yp,xe,le,te :BYTE;
							m :STRING[80]
						END =
	 ((xp: 1;yp: 1;xe:15;le: 1;te: 5;m :'Int erlaubt :'),
		(xp: 1;yp: 2;xe:15;le: 1;te: 4;m :'5.5,6.5,7.5 :     (1,2,3)'),
		(xp: 1;yp: 3;xe:15;le: 4;te: 4;m :'Int Adresse :     H'),
		(xp: 1;yp: 4;xe:15;le: 5;te: 1;m :'Int Quelle  :       (TIMER/IRQ5)'),
		(xp: 1;yp: 5;xe:15;le: 3;te: 4;m :'Int Geschw. :       (1..999)')
		);

	 l981:record
		 EI         : String [1];
		 RST				: String [1];
		 ADR        : String [4];
		 Quelle     : String [5];
		 Geschw     : String [3];
	 end=(EI:'N';RST:'1';ADR:'002C';Quelle:'TIMER';Geschw : '70');

	l99anz  = 5;
	l99     : ARRAY[1..l99anz] OF RECORD
							xp,yp,xe,le,te :BYTE;
							m :STRING[80]
						END =
	 ((xp: 1;yp: 1;xe:23;le: 1;te: 5;m :'Erzeuge .BAK :'),
		(xp: 1;yp: 2;xe:23;le: 1;te: 5;m :'Erzeuge .BIN :'),
		(xp: 1;yp: 3;xe:23;le: 1;te: 5;m :'Erzeuge .LST :'),
		(xp: 1;yp: 4;xe:23;le: 1;te: 5;m :'Erzeuge .SYM :'),
		(xp: 1;yp: 5;xe:23;le: 1;te: 5;m :'Erzeuge .HEX :')
		);

	 l991:record
		 DoBAK,DoBIN,DoLST,DoSYM,DoHEX : String [1];
	 end=(DoBak:'N';DoBIN:'N';DoLST:'N';DoSYM:'N';DoHEX:'N');

	l100anz  = 4;
	l100     : ARRAY[1..l100anz] OF RECORD
							xp,yp,xe,le,te :BYTE;
							m :STRING[80]
						END =
		(
		(xp: 1;yp: 1;xe:23;le: 1;te: 5;m :'ASCII (J), BIN (N)  :'),
		(xp: 1;yp: 2;xe:23;le: 1;te: 5;m :'ISO   (J), IBM (N)  :'),
		(xp: 1;yp: 3;xe:23;le: 1;te: 5;m :'Sende Start-/EndAdr :'),
		(xp: 1;yp: 4;xe:23;le: 4;te: 9;m :'Baudrate (110-2400) :')
		);

	 l1001:record
		 DoSRC,DoISO,DoAdr: String [1];
		 bdRate : String [4];
	 end=(DoSRC : 'N';DoISO : 'J';DoAdr : 'J';bdRate : '1200');

Procedure SendSource (DateiName : LongStr);

Procedure SendHex (DateiName : LongStr);

Procedure Setup;

Function UpStr (s:String) : String;

Implementation

{
Uses	 colors;
}

Type
	St3 = String [3];
	St4 = String [4];
	St10 = String [10];

Var
	COM	 : COMType;
	COMStr : String [4];
	RATE	 : BaudType;
	ini	 : text;
	StopTrans  : Boolean;

Function ConvertBdRate (TempStr : Str4) :	BaudType;
Var
	Rate : BaudType;

Begin
	ConvertBdRate := b1200;
	If TempStr = '110'  Then ConvertBdRate:= b110;
	If TempStr = '300'  Then ConvertBdRate:= b300;
	If TempStr = '600'  Then ConvertBdRate:= b600;
	If TempStr = '1200' Then ConvertBdRate:= b1200;
	If TempStr = '2400' Then ConvertBdRate:= b2400;
	If TempStr = '4800' Then ConvertBdRate:= b4800;
	If TempStr = '9600' Then ConvertBdRate:= b9600;
End;

Function ConvertHex (Var s1 : St3) : Byte;
Var
  zw,i,fak,z,l : Word;

Begin
	fak := 1;
  z   := 0;
  l := Length (s1);
  For i := l Downto 2 Do Begin
		If s1[i] in ['A'..'F'] Then
		zw := Ord (s1[i]) - Ord ('A') + 10
		Else zw := Ord (s1[i]) - Ord ('0');
    zw := zw * fak;
    fak := fak * 16;
		z:= z+zw;
	End; (* Downto *)
	ConvertHex := z;
End; (* Ok *)

Procedure WriteDat;
Begin
	assign(ini,OldDir + DatInfo);
	rewrite(ini);
	Write (ini,l991.DoBak);
	Write (ini,l991.DoBin);
	Write (ini,l991.DoLst);
	Write (ini,l991.DoSym);
	Write (ini,l991.DoHex);
	Write (ini,l1001.DoSRC);
	Write (ini,l1001.DoISO);
	Write (ini,l1001.DoAdr);
	Write (ini,l1001.bdRate);
	close(ini);
End;

Procedure Setup;
Var
	Auswahl : Integer;
	m_pos   : byte;
	Ch      : Char;
	e       : word;
	f       : file;

Procedure SaveSetup;
Begin
	assign(f,OldDir + portinfo);
	rewrite(f,1);
	blockwrite(f,l21,sizeof(l21));
	blockwrite(f,l981,sizeof(l981));
	close(f);
End;

Procedure RS232Select;
Var
	LastRate : String [4];
	Error		 : Boolean;

Begin
	Error := False;
	with wd[21] do begin
		x:=35;y:=16;dx:=29;dy:=5;s:=' DatenÅbertragung ';
	end;
	pushwin(21);
	editmode:=true;
	llin(3);
	akthelpnr := 550;
	LastRate := l1001.BdRate;
	Repeat
		liesrecord(l1001,l100,l100Anz,ch,[],#27);
		if ch<>#27 then begin
			DoSRC := l1001.DoSRC [1] = 'J';
			DoISO := l1001.DoISO [1] = 'J';
			DoAdr := l1001.DoAdr [1] = 'J';
			If (l1001.BdRate = '110') or (l1001.BdRate = '300') or
				(l1001.BdRate = '600') or (l1001.BdRate = '1200') or
				(l1001.BdRate = '2400') Then Begin
				Rate := 	ConvertBdRate (l1001.BdRate);
				Error := False;
			End
			Else Begin
				l1001.BdRate := LastRate;
				Error := True;
				Beep;
			End;
			WriteDat;
		end;
	Until Not Error;
	editmode:=false;
	popwin (true);
	akthelpnr :=1;
End;

Procedure DateiSelect;
Begin
	with wd[21] do begin
		x:=35;y:=16;dx:=26;dy:=6;s:='Dateierzeugung';
	end;
	pushwin(21);
	akthelpnr :=530;
	editmode:=true;
	llin(3);
	liesrecord(l991,l99,l99anz,ch,[],#27);
	if ch<>#27 then begin
		DoBAK := l991.DoBAK [1] = 'J';
		DoBIN := l991.DoBIN [1] = 'J';
		DoLST := l991.DoLST [1] = 'J';
		DoSYM := l991.DoSYM [1] = 'J';
		DoHEX := l991.DoHEX [1] = 'J';
		WriteDat;
	end;
	editmode:=false;
	popwin (true);
	akthelpnr :=1;
end;

Procedure Sel8255;
begin
	with wd[22] do begin
		x:=35;y:=16;dx:=30;dy:=4;s:='';
	end;
	pushwin(22);
	editmode:=true;
	llin(3);
	akthelpnr := 520;
	repeat
		liesrecord(l21,l2,l2anz,ch,[],#27);
		e:=0;
		if ch<>#27 then begin
			pc8255:=l21.has8255='J';
			if pc8255 then begin
				pcadr:=hexdez(l21.pcadr,e);
				pradr:=hexdez(l21.pradr,e);
				e:=pradr mod 16;
				pradr:=pradr div 16;
				if pradr>2 then e:=1;
			End;
			if e>0 then error(157) else SaveSetup;
		end;
	until e=0;
	editmode:=false;
	popwin (true);
	CloseWin (22);
	akthelpnr := 1;
end;

{$ifdef int}
Procedure SelInt;
Var
	Error 	: Integer;

Begin
	with wd[21] do begin
		x:=35;y:=14;dx:=35;dy:=6;s:='Interrupt';
	end;
	pushwin(21);
	editmode:=true;
	llin(3);
	akthelpnr :=510;
	liesrecord(l981,l98,l98anz,ch,[],#27);
	if ch<>#27 then begin
		Val (l981.RST,RSTNr,Error);
		If Error <> 0 Then Begin
			RSTNr := 1;
			L981.RST := '1';
		End;
		RSTSIM.OrMask := 1 shl (RSTNr - 1);
		RSTSIM.AndMask:= Not RSTSIM.OrMask;
		RSTRIM.OrMask := 1 shl (RSTNr + 3);
		RSTRIM.AndMask:= Not RSTRIM.OrMask;
		EI     := l981.EI  = 'J';
		Val ('$'+l981.ADR,IntAdr,Error);
		If Error <> 0 Then Begin
			IntAdr := $002C;
			l981.ADR := '002C';
		End;
		If Copy (Caps(l981.Quelle),1,5) = 'TIMER' Then Begin
			l981.Quelle := 'TIMER';
			IRQ := 0;
		End
		Else Begin
			IRQ := 5;
			l981.Quelle := 'IRQ5';
		End;
		Val (l981.Geschw,IntLoop,Error);
		If Error <> 0 Then Begin
			IntLoop := 70;
			l981.Geschw := '70';
		End
		Else Begin
			If IntLoop < 1 Then Begin
				IntLoop := 1;
				l981.Geschw := '1';
			End;
		End;
		RestoreInt;
		If EI Then SetUpInt;
	end;
	editmode:=false;
	popwin (true);
	SaveSetup;
	CloseWin (21);
	akthelpnr := 1;
End;
{$endif}

Begin
	ilin(58,13);
	m_pos := 1;
	auswahl := 0;
{$ifdef int}
	Repeat
		auswahl:=flipmenue(35,24,
			'#I$nterrupt' +
			'_#P$C-Port'+
			'_#D$ateien'+
{
			'_#F$arbanpassung'+
}
			'_#R$S232-Dö'+
			'_#E$nde_(µ Installation ∆_',
		 23,m_pos,500,false);
		Ch := ' ';
		Case Auswahl of
			1 :   SelInt;
			2 :   Sel8255;
			3 :   DateiSelect;
{
			4 :   Farbauswahl;
}
			4 :   RS232Select;
		End; {Case}
	Until (Auswahl = 5) or (Auswahl = Ord (ESC));
{$else if}
	Repeat
		auswahl:=flipmenue(35,24,
			'#P$C-Port'+
			'_#D$ateien'+
			'_#F$arbanpassung'+
			'_#R$S232-Dö'+
			'_#E$nde_(µ Installation ∆_',
		 23,m_pos,500,false);
		Ch := ' ';
		Case Auswahl of
			1 :   Sel8255;
			2 :   DateiSelect;
			3 :   Farbauswahl;
			4 :   RS232Select;
		End; {Case}
	Until (Auswahl = 5) or (Auswahl = Ord (ESC));
{$endif}
	CloseWin (23);
	llin(3);
	Auswahl := 7;
End;

Procedure SendChar (c : Char);
(*$I-*)
Begin
	Repeat
		Write (LST,c);
	Until (IoResult= 0);
(*$I+*)
End;

Procedure SendStr (s : LongStr);
Var
	i : Byte;

Begin
	(*$I-*)
	For i := 1 to Length (s) Do Begin
		SendChar (s [i]);
	End;
	(*$I+*)
End;

Function UpStr ( s : String) : String;
Var
	i : Byte;
Begin
  For i:= 0 to Length (s) Do Begin
    s [i] := UpCase (s[i]);
    If DoISO Then Begin
      if s [i] = '@' Then s [i] := #64;
      if s [i] = 'Ñ' Then s [i] := #91;
      if s [i] = 'é' Then s [i] := #91;
      if s [i] = 'î' Then s [i] := #92;
      if s [i] = 'ô' Then s [i] := #92;
      if s [i] = 'Å' Then s [i] := #93;
			if s [i] = 'ö' Then s [i] := #93;
      if s [i] = '·' Then s [i] := #126;
		End
    Else Begin
      if s [i] = 'Å' Then s [i] := 'ö';
      if s [i] = 'Ñ' Then s [i] := 'é';
      if s [i] = 'î' Then s [i] := 'ô';
    End;
  End;
  UpStr := s;
End;

Procedure Transmit (Var z : LongInt;Data : Byte);
Begin
	If StopTrans Then Exit;
	If Not V24TimeOut Then Begin
		If KeyPressed Then If ReadKey = #27 Then StopTrans := True;
		SendByte (Data);
		Inc (z);
	End
	Else Begin
		Beep;
		Exit;
	End;
End;

Procedure SendSource (DateiName : LongStr);
Var
  f          : File of Byte;
  f1,f2      : Text;
	i,
	Start,Stop : Word;
  z,l        : LongInt;
  s          : String;

Procedure SendLine (Var TempStr : String);
Var
  Data,i,j : Byte;
	Wert     : LongInt;
  s        : String [21];

Begin
	If StopTrans Then Exit;
  GotoXY (1,4);ClrEOL;
	s := Copy (TempStr,1,21);
  For i:= 1 to Length (s) Do Begin
    If s [i] < ' ' Then s[i] := ' ';
  End;
  Write (s);
  For i:=1 to Length (TempStr) Do Begin
		Data := Ord (TempStr [i]);
    GotoXY (1,2);
    Wert := Round (z/l*100);
    Write (z:5,'Byte <> ',Wert:3,'%');
{
		If Data = Ord (^I) Then For j:=1 to 10 Do Transmit (Ord(' '))
    Else
}
		Transmit (z,Data);
  End;
	Transmit (z,$0d);
	Transmit (z,$0a);
End;

Begin
  StopTrans := False;
  If Not Exist (DateiName) Then Begin
    Beep;
    Exit;
  End;
	with wd[21] do begin
    x:=30;y:=14;dx:=25;dy:=5;s:=' Datentransfer ';
  end;
  pushwin(21);
  editmode:=False;
  llin(3);
  Assign (f,DateiName);
  Reset (f);
	l := FileSize (f);
  Close (f);
  z := 0;
	Start := $6000;
	Stop  := Start;
{
	Stop  := Start + (l And $0000FFFF);
}
	InitCom (COM,RATE,none,d8,s2);
  Assign (LST,COMstr);
  Rewrite (LST);
  If DoADR Then Begin
		Transmit (z,Hi(Start));
		Transmit (z,Lo(Start));
		Transmit (z,Hi(Stop));
		Transmit (z,Lo(Stop));
  End;
  Assign (f1,DateiName);
  Reset (f1);
  While (Not StopTrans) And (Not EOF (f1)) Do Begin
		ReadLn (f1,TempStr);
    TempStr := UpStr (TempStr);
    If Pos ('INCLUDE',TempStr) <> 0 Then Begin
      i := Pos (' ',TempStr);
			s:= Copy (TempStr,i+1,Length(TempStr));
{
			WriteLn ('>',s,'<');
}
      If Exist (s) Then Begin
        Assign (f,s);
        Reset (f);
        l := l + FileSize (f);
				l := l - Length (TempStr);
        Close (f);
        Assign (f2,s);
        Reset (f2);
        If IoResult = 0 Then Begin
					While not EOF (f2) Do Begin
            ReadLn (f2,s);
            s := UpStr (s);
						SendLine (s);
          End;
          Close (f2);
        End;
			End
      Else Begin
				Beep;
        ClrScr;
        GotoXY (1,1);
        WriteLn (s);
        WriteLn ('nicht gefunden!');
        WriteLn;
				Write ('Weiter mit bel. Taste');
        Beep;
        Repeat Until KeyPressed;
        ClrScr;
      End;
    End
    Else SendLine (TempStr);
	End;
	Transmit (z,0); {^Z}
  Close (LST);
  Close (f1);
  PopWin (True);
	CloseWin (21);
  Beep;
	DisableCom;
End;

Const
	BufLen = 16384;
Type
  Buf = Array [0..BufLen] of Byte;
Var
	Buffer : ^Buf;
  Heaptop : Pointer;
	Header : Array [1..2] of Word;
  Headbyte : Array [0..3] of Byte Absolute Header;

Procedure SendHex (DateiName : LongStr);


Var
  dat    : File;
  HexDat : Text;
	c1,c2  : Char;
	s 		 : String [3];
	Err		 : Integer;
	data 	 : Byte;
	Init	 : Boolean;
	Start,
	Proof	 : Byte;
  Ctr,
  Offset,
	LineLen,
  ProgLen: Word;
	FirstLine : Boolean;
  f1,f2 : File of Byte;
  Wert,
	i,z   : LongInt;

Procedure IntSwap (Var i : Word);
Var
	a,b : Byte;

Begin
  a := Lo (i);
	b := Hi (i);
	i := 256 * a + b;
End;

Function Getbyte : Byte;
Var
	s     : St3;
	c1,c2 : Char;
	Err	: Integer;

(*$I-*)
Begin
	z := 0;
	Repeat
		Read (HexDat,c1);
		Err := IOResult;
	Until (c1 in ['0'..'9','A'..'F']) Or (Err <> 0);
	If Err = 0 Then Begin
		Read (HexDat,c2);
		Err := IOResult;
	End;
	If Err <> 0 Then Beep;
	s := '$' + c1 + c2;
	GetByte:= ConvertHex (s);
End;
(*$I+*)

Begin
(*$I-*)
	StopTrans := False;
  If Not Exist (DateiName) Then Begin
    Beep;
    Exit;
  End;
  with wd[21] do begin
    x:=30;y:=14;dx:=25;dy:=5;s:=' Datentransfer ';
  end;
	pushwin(21);
	editmode:=False;
	llin(3);
	InitCom (COM,RATE,none,d8,s2);
	Assign (LST,COMstr);
	Rewrite (LST);
	Assign (Hexdat,DateiName);
	Reset (HexDat);
	ProgLen := 0;
	Offset  := 0;
	FirstLine := True;
  New (Buffer);
	FillChar (Buffer^,SizeOf (Buffer^),#0);
	Repeat
		Linelen := GetByte;	 { Daten einer Hexfilezeile }
		If FirstLine Then Begin
			Header [1] := GetByte * 256;		{ Highbyte der Startadresse }
			Header [1] := GetByte + Header [1];	{ Lowbyte der Startadr }
			FirstLine := False;
		End
		Else Begin
			Offset := GetByte * 256;		{ Offset im Puffer }
			Offset := GetByte + Offset;
			If LineLen <> 0 Then Offset := Offset - Header [1];
		End;
		data := GetByte;             { Dummy lesen }
		For i := 1 to LineLen Do Begin
			Ctr := i+Offset+4-1;
			Buffer^ [Ctr] := GetByte;
		End;
		If LineLen <> 0 Then ProgLen := LineLen + Offset;
		data:= GetByte;             { PrÅfsumme lesen }
	Until (EOF (HexDat)) Or (LineLen = 0);
  ProgLen := ProgLen + 5;
	Header [2] := Header [1] + ProgLen;
	IntSwap (Header [1]);
	IntSwap (Header [2]);
  For i:= 0 to 3 Do Buffer^ [i] := HeadByte [i];
	If DoBin Then Begin
		DateiName := Copy (DateiName,1,Pos('.',DateiName)) + 'BIN';
		Assign (f1,DateiName);
		Rewrite (f1);
	End;
	If DoAdr Then Start := 0 Else Start := 3;
	Proof := 0;
	For i:=Start to ProgLen Do Begin
		If Not StopTrans Then Begin
			data := Buffer^ [i];
			If DoBin Then Begin
				If i>3 Then Write (f1,Data);
			End
			Else Transmit (z,data);
			Proof := Proof + Not Data;
			GotoXY (1,2);
			Wert := Trunc (z/ProgLen*100);
			If Wert > 100 Then Wert := 100;
			Write (z:5,'Byte <> ',Wert:3,'%');
		End;
	End;
	If Not DoBin Then Begin
		Transmit (z,Proof);
		Transmit (z,Proof);
		For i:= 1 to 2 Do Begin
			Transmit (z,Ord (^Z));
		End;
	End;
	Beep;
	If DoBin Then Close (f1);
	Close (HexDat);
	DisableCom;
	Close (LST);
	PopWin (True);
	CloseWin (21);
	DisableCom;
  Dispose (Buffer);
(*$I+*)
End;

Function ReadLine (Var f : Text) : String;
Var
	s : String;

Begin
	Repeat
		ReadLn (f,s);
	Until s [1] <> ';';
	ReadLine := s;
End;

Var
	i,ErrNr : Integer;
	Dummy		: Word;

Begin
	GetDir (0,OldDir);
	If OldDir [Length (OldDir)] <> '\' Then OldDir := OldDir + '\';
	TempStr := OldDir + 'COM.DAT';
	If Exist (TempStr) Then Begin
		Assign (ini,TempStr);
		Reset (ini);
		ReadLn (ini,TitelZeile);
		ReadLn (ini,TempStr);
		i:=1;
		Repeat
			If TempStr [i] <> Programmversion [i] Then Begin
				WriteLn;
				WriteLn ('Programmversion ist: ',Programmversion);
				WriteLn ('COM.DAT Version ist: ',TempStr);
				WriteLn;
				WriteLn ('Bitte die Datei COM.DAT aktualisieren!');
				WriteLn;
				WriteLn ('Abbruch mit beliebiger Taste');
				Beep;
				Repeat Until KeyPressed;
				Halt;
			End
			Else Inc (i);
		Until (i >= 99) or (i = (Length (Programmversion)+1));
		TempStr := ReadLine (ini);
		If TempStr = 'COM1' Then COM := COM1;
		If TempStr = 'COM2' Then COM := COM2;
		If TempStr = 'COM3' Then COM := COM3;
		If TempStr = 'COM4' Then COM := COM4;
		COMStr := TempStr;
{
		TempStr := ReadLine (ini);
		l1001.BdRate := Copy (TempStr,1,4);
		Rate := ConvertBdRate (l1001.BdRate);
}
		TempStr := ReadLine (ini);
		if TempStr = 'LPT1' Then Begin
			DoLpt := True;
			LptAdr:= MemW [$0040:$0008];
		End
		Else if TempStr = 'LPT2' Then Begin
			DoLpt := True;
			LptAdr:= MemW [$0040:$000A];
		End
		Else DoLpt := False;
		TempStr := ReadLine (ini);
		if TempStr = 'LPT2' Then Begin
			Dummy := MemW [$0040:$0008];
			MemW [$0040:$0008]:= MemW [$0040:$000A];
			MemW [$0040:$000A] := Dummy;
			LPT_Swap := True;
		End;
		TempStr := ReadLine (ini);
		Val (TempStr,IoAdr,ErrNr);
		If TempStr [Length (TempStr)] = '\' Then ROMDIR := TempStr;
		ROMDir := ReadLine (ini);
		PrgDir := ReadLine (ini);
		{$I-}
{
		TempStr := OldDir + RomDir;
}
		TempStr := RomDir;
		Chdir (Copy (TempStr,1,Length(TempStr)-1));
		{$I+}
		If IoResult <> 0 Then Begin
			WriteLn ('ROM - Verzeichnis nicht gefunden -> COM.DAT prÅfen!');
			WriteLn;
			WriteLn ('Programm beendet! Abbruch mit bel. Taste!');
			Beep;
			Repeat Until KeyPressed;
			Halt;
		End
		Else Chdir (Copy (OldDir,1,Length(OldDir)-1));
		{$I-}
{
		TempStr := OldDir + PrgDir;
}
		TempStr := PrgDir;
		TempStr := Copy (TempStr,1,Length(TempStr)-1);
		ChDir (TempStr);
		if IoResult <> 0 Then Begin
			MkDir (TempStr);
		End
		Else Chdir (Copy (OldDir,1,Length(OldDir)-1));
		ErrNr := IoResult;
		TempStr := ReadLine (ini);
		ESCP   := TempStr = 'ESCP';
		PCL    := TempStr = 'PCL';
		CUSTOM := TempStr = 'CUSTOM';
		If CUSTOM Then Begin
			TempStr := ReadLine (ini);
			If TempStr = '@' Then Begin
				TempStr := '';
				While Tempstr <> '@' Do Begin
					TempStr := ReadLine (ini);
					Val (TempStr,Dummy,ErrNr);
					If ErrNr = 0 Then CUST_Init := CUST_Init + Chr (Dummy);
				End;
			End;
		End;

		{$I+}
		IntInstFlag := False;
		EI          := False;
	End
	Else Begin
		WriteLn;
		WriteLn ('Die Datei COM.DAT fehlt!');
		Beep;
		WriteLn ('Weiter mit bel. Taste!');
		COM := COM1; {CK 15.12.2010}
{
		l1001.BdRate :='110';
		Rate := ConvertBdRate (l1001.BdRate);
}
		DoLpt := True;
		LptAdr:= MemW [$0040:$000A];
		ROMDir := OldDir;
		PRGDir := OldDir;
		CUSTOM	:= True;
		Repeat Until KeyPressed;
	End;
{
	ROMDir := OldDir + RomDir;
	PrgDir := OldDir + PrgDir;
}
	AktDir := PrgDir;
	TempStr:= OldDir + DatInfo;
	If Exist (TempStr) Then Begin
		Assign (ini,TempStr);
		Reset (ini);
		Read (ini,l991.DoBak);
		Read (ini,l991.DoBin);
		Read (ini,l991.DoLst);
		Read (ini,l991.DoSym);
		Read (ini,l991.DoHex);
		Read (ini,l1001.DoSRC);
		Read (ini,l1001.DoISO);
		Read (ini,l1001.DoAdr);
		Read (ini,l1001.BdRate);
		close(ini);
		DoBAK := l991.DoBAK [1] = 'J';
		DoBIN := l991.DoBIN [1] = 'J';
		DoLST := l991.DoLST [1] = 'J';
		DoSYM := l991.DoSYM [1] = 'J';
		DoHEX := l991.DoHEX [1] = 'J';
		DoSRC := l1001.DoSRC [1] = 'J';
		DoISO := l1001.DoISO [1] = 'J';
		DoAdr := l1001.DoAdr [1] = 'J';
		Rate	:= ConvertBdRate (l1001.BdRate);
	End
	else Begin
		DoBAK      := False;
		l991.DoBAK := 'N';
		DoLST      := False;
		l991.DoLST := 'N';
		DoSYM      := False;
		l991.DoSYM := 'N';
		DoBIN      := False;
		l991.DoBIN := 'N';
		DoHEX      := False;
		l991.DoHEX := 'N';
		DoSRC      := False;
		l1001.DoSRC := 'N';
		DoISO      := False;
		l1001.DoISO := 'N';
		DoAdr      := True;
		l1001.DoAdr := 'J';
		l1001.BdRate := '110';
	End;
	DisableCom;
End.
