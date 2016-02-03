unit asprocs;

interface

uses astypdea;

FUNCTION hexdez(t:str8 ;var e:word):longint;

FUNCTION bindez(t:str80;var e:word):longint;

FUNCTION caps(s:string):string;

FUNCTION cap(ch:char):char;

FUNCTION hex(x:byte):str2;

const
 maxfehler=100;
 erm:  array[1..27] of str40=
       ('Syntaxfehler',
        'Falsches Register',
        'Doppeltes Label ',
        'Doppeltes Symbol',
        'RST nur 0-7 zul„ssig',
        'Ungltige Konstante',
        'Symbol darf nicht mit Ziffer anfangen',
        'Symbol nicht gefunden',
        'Fehler in Rechenformel',
        'END - Anweisung erwartet',
        'Konstante zu groá',
        'Klammerfehler',
        'Symbol nicht gefunden',
        'ENDM nicht gefunden',
        'zus„tzliche Zeichen ignoriert',
        'Label ohne Doppelpunkt',
        'Unzul„ssige Vorw„rtsreferenz',
        'Komma erwartet',
        'Konstante fehlt',
        'Include-File nicht gefunden',
        'Zu viele Include-Files',
        'ENDIF ohne IF oder ELSE',
        'Zu viele verschachtelte If',
        'ELSE ohne IF',
        'Endif erwartet',
        'Vom Benutzer erzeugter Fehler',
        'Anweisung nur in Macros erlaubt');
type
  t_errata =record
              errpos:word;
              err:byte;
            end;
var
  errata :  array[1..maxfehler] of T_errata;
  fehler,
  maxerrors,
  lfehler : word;

implementation

FUNCTION cap(ch:char):char;

BEGIN
	if (ch='„') then cap:='Ž' else
	if (ch='”') then cap:='™' else
	if (ch='') then cap:='š' else
	if (ch='á') then cap:='S' else
	if (ch>='a') and (ch<='z') then cap:=UpCase (ch) else cap:=ch;
END;

FUNCTION caps(s:string):string;
var i:integer;
		asci:boolean;
begin
	asci:=false;
	for i:=1 to length(s) do begin
		if s[i]=#39 then asci:=not asci;
		if not asci then s[i]:=cap(s[i]);
	end;
 caps:=s;
end;

FUNCTION hex(x:byte):str2;
 const
 har : array[0..15] of char='0123456789ABCDEF';
 begin
	 hex:=har[(x shr 4)] + har[x and 15];
 end;

FUNCTION hexdez(t:str8;var e:word):longint;
var a,j,b:word;
		x:longint;
begin
	j:=1;e:=0;
{
	IF NOT (t[j]  IN ['0'..'9','A'..'F']) THEN BEGIN e:=j; EXIT END;
}
	X:=ord(t[j])-$30;if X>9 then dec (X,7);inc(j);B:=1;
	WHILE (j<=length(t)) AND (B<9) DO BEGIN
		X:=X SHL 4;
		IF NOT (t[j]  IN ['0'..'9','A'..'F']) THEN BEGIN e:=j; EXIT END;
		a:=ord(t[j])-$30;if a>9 then dec (a,7);
		inc (X,a);inc(j);inc(b);
	END;
	hexdez:=x;
end;

FUNCTION bindez(t:str80;var e:word):longint;
var a,j,x,b:word;
begin
	j:=1;e:=0;
{
	WHILE t[j]='0' DO inc (j);
	IF NOT (t[j]='1')  THEN BEGIN
		e:=j;
		EXIT
	END;
}
	X:=ord(t[j])-$30;inc(j);B:=1;
	WHILE (j<=length(t)) AND (B<17) DO BEGIN
		X:=X SHL 1;
		IF (t[j] <> '1') And (t [j] <> '0') THEN BEGIN e:=j; EXIT END;
			a:=ord(t[j])-$30;
			inc (X,A);inc(j);inc (B);
		END;
		bindez:=x;
	end;
end.
