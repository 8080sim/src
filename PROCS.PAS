unit procs;

interface
uses
	AsTypdea,Dos,crt;

Const
	Programmversion : String [8] = 'Ver 2.83';
	TitelZeile			: String [40] = ' 1990/95 | Berufskolleg Haspel, Wuppertal';


{
type
	str2=String[2];
	str3=string[3];
	str4=string[4];
	str6=string[6];
	str10=string[10];
	str12=String[12];
	str15=string[15];
	str35=string[35];
	str40=string[40];
	str80=string[80];
	LongStr  = String [255];
}
Type
	charset=set of char;

Const
	WoTag:array[0..6] of str3=
  ('Mon','Die','Mit','Don','Fre','Sam', 'Son');

Var
	LPT_InitStr,
	ROMDir, { <- siehe COM.DAT }
  TempStr,
	PrgDir,
	OldDir,
	AktDir : LongStr;
Const
	DoLpt   : Boolean = True;
	LPT_Swap: Boolean = False;
	Lptadr  : Word    = $378;
	ESCP		: Boolean = False;
	PCL 		: Boolean = False;
	CUSTOM	: Boolean = False;
	CUST_Init		: String = ' '+^H;



Var
	DoBAK,DoBIN,DoLST,DoSYM,DoHEX,DoSRC,DoISO,DoAdr : Boolean;
	UserPage : Boolean;
	showregs : Boolean;

PROCEDURE remove(VAR s:LongStr);             {fhrende Leerzeichen entfernen}
PROCEDURE value(s:LongStr;VAR rr:REAL);      {Umwandeln String in Realzahl}
PROCEDURE valui(s:LongStr;VAR rr:INTEGER);   {umwandeln String in INTEGER-Zahl }
PROCEDURE findzahl(s:LongStr;var rr:integer);{Zahl in String suchen}
FUNCTION cstr(c: CHAR; n: INTEGER): LongStr;
FUNCTION cap(ch: CHAR): CHAR;
FUNCTION caps(s: LongStr): LongStr;
FUNCTION strip(s:LongStr):LongStr;
Function getdate:str6;
(*     Nicht benutzt
PROCEDURE evaluate(expr: str15; VAR erg:str15; VAR errpos: integer);
*)
function pu(r:str10):str10;
procedure MehrFiles(Anzahl:byte);
function Exist(FN : LongStr) : boolean;
procedure Abort(M : LongStr);
function NumStr(Num:longint;i : integer) : LongStr;
function bytstr(x:byte):str2;
function strbyte(var s:str2):byte;
{procedure fileerror(name:LongStr);}
Function WochenTag(Tag,
                   Monat,
			 Jahr:integer):str3;
function Tagesdatum(s:str6):str12;
Procedure Beep;

Implementation

FUNCTION strip(s:LongStr):LongStr;
var
  s1:LongStr;
	j:integer;
begin
  s:=caps(s);s1:='';
  for j:=1 to length(s) do
   if s[j] in ['0'..'9','A'..'Z'] then s1:=s1+s[j];
 strip:=s1;
end;

Function JulianischerTag (tag,
                          monat,
													jahr:integer):longint;

(* berechnet aus dem Gregorianischen Datum die sog. Julianischen Tage.
	 Aus den Julianischen Tagen l„át sich sehr leicht der Wochentag eines
   Datums ermitteln. Auch die Anzahl der Tage, die zwischen 2 Terminen
   liegt, l„át sich aus der Differenz der Julianischen Tage errechnen.*)

Var c,ja:longint;

begin
  if monat >2 then monat:=monat-3 else begin
    monat :=monat+9;jahr:=pred(jahr);
  end;
  c:= jahr div 100;
  ja:=jahr mod 100;
	JulianischerTag:=146097*c div 4 + 1461*ja div 4 + (153*Monat+2) div 5 + Tag +1721119;
end;

Procedure GregorDatum (var Tag,
                           Monat,
			   Jahr:integer;
			   JulTag:longint);

(* berechnet aus den Julianischen Tagen unser Gregorianisches Datum. *)

Var
	y,d:longint;

begin
  JulTag:=JulTag - 1721119;
  y:=(4*JulTag - 1 ) div 146097;
  JulTag:=4*JulTag - 1 - 146097*y;
  d:=JulTag  div 4;
  JulTag:=(4*d + 3) div 1461;
  d:=(4*d + 7 - 1461*JulTag) div 4;
	Monat:=(5*d - 3) div 153; d:=5*d - 3 - 153*Monat;
  Tag:=(d+5) div 5;
  Jahr:=100*y + JulTag;
  if Monat<10 then Monat:=Monat+3 else begin
		Monat:=Monat-9;Jahr:=Jahr+1;
  end;
end;

Function WochenTag(Tag,
                   Monat,
			 Jahr:integer):str3;

(* ermittelt die Nummer des Wochentags zu einem Datum.
  Mo=0 bis So=6 *)

begin
	WochenTag:=WoTag[JulianischerTag(Tag,Monat,Jahr) mod 7];
end;

function TagesDatum;
var t,m,j:integer;
begin
 valui(copy(s,1,2),t);
 valui(copy(s,3,2),m);
 valui(copy(s,5,2),j);j:=j+1900;
 Tagesdatum:=wochentag(t,m,j)+' '+copy(s,1,2)+'.'+copy(s,3,2)+'.'+copy(s,5,2);
end;

procedure Beep;
begin
	Sound(220);
  Delay(200);
  NoSound;
end; { Beep }

function Exist(FN : LongStr) : boolean;
{ Returns true if file named by FN exists }
var
  F : file;
  found : boolean;
begin
  Assign(f, FN);
	{$I-}
  Reset(f);
  Found := (IOResult = 0);
  if Found then
    Close(f);
  {$I+}
  Exist := Found;
end; { Exist }

procedure Abort(M : LongStr);
{ Simple fatal error reporter: Goes to the bottom of the screen,
  Prints M and terminates execution of the program. }

begin
  Window(1, 1, 80, 25);
  TextColor(White);
  TextBackground(Black);
  LowVideo;
  GotoXY(1, 24);
  Write(M);
	ClrEol;
	runerror(2);
end; { Abort }

function NumStr(Num:longint;i : integer) : LongStr;
{ Converts an integer to a string with leading zeros.   }
var
  S : LongStr;

begin
  Str(Num:1, S);
  while length(s)<i do s:='0'+s;
  NumStr := S;
end;

procedure MehrFiles(Anzahl:byte);

const
  GetDosVersion= $30;
var
	MaxFiles     : ^Word;
  FileIndexPtr : ^Pointer;
  Neu          : ^Byte;
  Regs         : Registers;
begin
  Regs.ah:=GetDosVersion;
  MsDos(Regs);
  if Regs.al<3 then begin
		Writeln('Dos-Version kleiner 3.0, Programm abgebrochen.');
    halt(1);
  end;
  GetMem(Neu,Anzahl);
  FillChar(Neu^,Anzahl,$ff);
  FileIndexPtr:=Ptr(PrefixSeg,$34);
  MaxFiles:=Ptr(PrefixSeg,$32);
  Move(FileIndexPtr^^,Neu^,MaxFiles^);
  MaxFiles^:=Anzahl;
  FileIndexPtr^:=Neu;
end;

PROCEDURE remove;
BEGIN
  while (s>'') and (s[1]=' ') do delete(s,1,1);
END;

(*umwandeln String in REAL-Zahl*)
PROCEDURE value;
VAR i :INTEGER;
BEGIN
  remove(s);
  i:=POS(' ',s);
  IF i>0 THEN s:=COPY(s,1,i-1);
	IF s='' THEN s:='0';
  VAL(s,rr,i);
END;

(* umwandeln String in INTEGER-Zahl *)
PROCEDURE valui;
VAR i :INTEGER;
BEGIN
	remove(s);
  i:=POS(' ',s);
  IF i>0 THEN s:=COPY(s,1,i-1);
  IF s='' THEN s:='0';
	VAL(s,rr,i);
END;
PROCEDURE findzahl;
var i:integer;
begin
  i:=0;
  repeat i:=succ(i) until (s[i]>='0') and (s[i]<='9') or (i>length(s));
  s:=copy(s,i,80);
  valui(s,rr);
end;

FUNCTION cap(ch: CHAR): CHAR;
BEGIN
 if (ch='„')  then cap:='Ž'else
 if (ch='”')  then cap:='™'else
 if (ch='')  then cap:='š'else
 if (ch='á')  then cap:='S'else
 IF (ch>='a') AND (ch<='z') THEN
  cap:=CHR(ORD(ch)-32) ELSE cap:=ch;
END;

FUNCTION caps(s: LongStr): LongStr;
var i:integer;
    quotes:boolean;
begin
  quotes:=false;
  for i:=1 to length(s) do begin
    if s[i]=#39 then quotes:=not quotes;
    if not quotes then s[i]:=cap(s[i]);
  end;
  caps:=s;
end;

FUNCTION cstr(c: CHAR; n: INTEGER): LongStr;
VAR
  s: LongStr;

BEGIN
  IF n<0 THEN n:=0; s[0]:=CHR(n); fillchar(s[1],n,c);
  cstr:=s;
END;
Function getdate:str6;
var
  stag,smon,sja :str4;
  tage,monate,jahre:integer;
  var regs:registers;
BEGIN
  regs.ax:=$2A00; msdos(regs);
	tage:=lo(regs.dx);monate:=hi(regs.dx);jahre:=regs.cx;
  str(tage,stag);str(monate,smon);str(jahre,sja);
  sja:=copy(sja,3,2);
 if length(stag)=1 then stag:='0'+stag;
  if length(smon)=1 then smon:='0'+smon;
 getdate:=stag+smon+sja;
END;

(*

var valu:real;

PROCEDURE evaluate(expr: str15; VAR erg:str15; VAR errpos: integer);
CONST
	errch = '?';
	eofline = #13;
PROCEDURE upcase(VAR s: LongStr);
VAR
	i: integer;
BEGIN
	FOR i:=1 TO length(s) DO BEGIN
		IF (s[i]>='a') AND (s[i]<='z') THEN s[i]:=chr(ord(s[i])-32);
    if i>1 then
    if (s[i]='-') and (s[i-1]='.') then begin
			s[i]:='0';
      if (i=length(s)-1) and (s[i+1]='-') then s[i+1]:='0';
    END;
  END;
END;
VAR
	pos: integer;
  ch: char;

PROCEDURE nextchar;
BEGIN
  REPEAT
		pos:=pos+1;
    IF pos<=length(expr) THEN
    ch:=expr[pos] ELSE
    ch:=eofline;
  UNTIL ch<>' ';
END;

FUNCTION expression: real;
VAR
  e: real;
  opr: char;

FUNCTION simexpr: real;
VAR
	s: real;
  opr: char;

FUNCTION term: real;
VAR
  t: real;

FUNCTION signedfactor: real;

FUNCTION factor: real;
TYPE
	stdf = (fabs,fsqrt,fsin,fcos,farctan,fln,fexp);
  stdflist = ARRAY[stdf] OF STRING[6];
CONST
	stdfun: stdflist = ('ABS','SQRT','SIN','COS','ARCTAN','LN','EXP');
VAR
  p,e,sl: integer;
  found: boolean;
	f: real;
  sf: stdf;
BEGIN
  IF ch IN ['0'..'9'] THEN
	BEGIN
    p:=pos;
		REPEAT nextchar UNTIL NOT(ch IN ['0'..'9','.']);
    val(copy(expr,p,pos-p),f,e);
    IF e<>0 THEN
    BEGIN
      pos:=p+e-1; ch:=errch;
    END;
  END ELSE
	IF ch='X' THEN
  BEGIN
    nextchar; f:=valu;
	END ELSE  ch:=errch;
	factor:=f;
END {factor};

BEGIN {signedfactor}
	IF ch='-' THEN
	BEGIN
		nextchar; signedfactor:=-factor;
	END ELSE
	signedfactor:=factor;
END {signedfactor};

BEGIN {term}
	t:=signedfactor;
	term:=t;
END {term};

var intdm:integer;

BEGIN {simexpr}
	s:=term;
	WHILE ch IN ['*','/','%','K'] DO
	BEGIN
		opr:=ch; nextchar;
		CASE opr OF
			'*': s:=s*term;
			'/': s:=s/term;
			'%': s:=e*s/100;
			'K': begin s:=valu+valu*s/100;
						if s<20.0 then s:=int(s)+0.90 else
			if s<95.0 then begin
			 intdm:=trunc(s/5)*5;
			 if intdm mod 10=0 then
			 s:=intdm+5 else s:=intdm+4.90
			end else
			if s<100.0 then s:=98.00 else
			if s<200.0 then begin
			 intdm:=trunc(s/5)*5;
			 if intdm mod 10=0 then
			 s:=intdm+5 else s:=intdm+4.0
			end else
			s:=trunc(s/10)*10+9.0
					 end;
		END;
	END;
	simexpr:=s;
END {simexpr};

BEGIN {expression}
	e:=simexpr;
	WHILE ch IN ['+','-'] DO
	BEGIN
		opr:=ch; nextchar;
		CASE opr OF
			'+': e:=e+simexpr;
			'-': e:=e-simexpr;
		END;
	END;
	expression:=e;
END {expression};

BEGIN {evaluate}
	upcase(expr);
	pos:=0; nextchar;
	valu:=expression;
	IF ch=eofline THEN errpos:=0 ELSE errpos:=pos;
	if errpos=0 then str(valu:7:2,erg) ;
	remove(erg);
END {evaluate};
*)

function pu(r:str10):str10;
var rr:real;
		s:str10;
begin
 value(r,rr);str(rr:7:2,s);
 pu:=s;
end;
{ procedure fileerror(name:LongStr);
 begin
	 if not ok then abort('Dateifehler in '+name);
 end;
}

function strbyte(var s:str2):byte;
var a,b:byte;
begin
	s:=caps(s);
	b:=ord(s[1])-$30;
	if b>9 then b:=b-7;
	a:=ord(s[2])-$30;
	if a>9 then a:=a-7;
	strbyte:=b*16+a;
end;

function bytstr(x:byte):str2;
 const
 har : array[0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
 begin
	 bytstr:=har[(x shr 4)] + har[x and 15];
 end;


end.
