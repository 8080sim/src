Program MFACONV;

Uses Dos,crt;

{ Entfernt unerwuenschte Zeichen aus dem Quellcode }

Const
	RecSize = 256;

Var
	RFile,WFile : File;
	RF,WF : Text;
	RBuffer : Array [0..MaxInt] of Byte;
	s : String Absolute RBuffer;
	RCount,WCount,RecsGot,Result : Word;
	ZCount,i,j	: Word;
	Data : Byte;
	RDatei,WDatei : PathStr;
	Dir  : DirStr;
	Name : NameStr;
	Ext  : ExtStr;

Begin
	If ParamCount = 0 Then Begin
		WriteLn;
		WriteLn;
		WriteLn ('MFACONV: (c) M.Flume 10/95');
		WriteLn;
		WriteLn ('MFACONV entfernt TABs und LineFeeds aus Textdateien');
		WriteLn ('Die neue Datei wird unter dem Namen <Dateiname>.MFA gespeichert.');
		WriteLn;
		WriteLn ('Aufruf: MFACONV <Dateiname>');
		Halt;
	End
	Else RDatei := Paramstr (1);
	ZCount := 1;
	FSplit (RDatei,Dir,Name,Ext);
	WDatei := Dir + Name + '.MFA';
	WriteLn ('Lese ',RDatei,', Schreibe ',WDatei);
	Assign (RFile,RDatei);
	Reset (RFile);
	Assign (WFile,WDatei);
	Rewrite (WFile,1);
	RCount := SizeOf (RFile);
	BlockRead (RFile,RBuffer,RCount,RecsGot);
	WCount := RecsGot * RecSize;
	For i := 0 to WCount Do Begin
		If RBuffer [i] = Ord (^I) Then Begin
			Data := Ord (' ');
			For j:=1 to 5 Do BlockWrite (WFile,Data,1);
		End
		Else If (RBuffer [i] <> $0A) Then BlockWrite (WFile,RBuffer [i],1,Result)
		Else Begin
			GotoXY (1,WhereY); Write ('Zeile : ',ZCount);
			Inc (ZCount);
		End;
	End;
	Data := Ord (^Z);
	BlockWrite (WFile,Data,1,Result);
	WriteLn ('Fettig!');
	Close (RFile);
	Close (WFile);
End.