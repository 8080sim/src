
unit Myinput;
{$i Direct.inc}
interface
uses
  crt,dos,
  Procs,              {Cstr,valui u.Ñ.}
	MyWindow,   {Fensterverwaltung}
	astypdea,
  MyGloErr;
var editmode,gesaved:boolean;
    fc:char;
    plausptr:pointer;
PROCEDURE schreibrecord(VAR usrec,usmask;receintrzahl : BYTE);
PROCEDURE input(x,y,l,typ:INTEGER;VAR eingabe:string;VAR ch:CHAR);
PROCEDURE liesrecord(VAR usrec,usmask ; receintrzahl : BYTE;
		     VAR ch:char;
		     ter:charset;abbruch:char);

implementation
const
 vgl               :array[1..10] of charset =
		      ([#32..#126,'Ñ','î','Å','·','é','ô','ö'],
		      ['0'..'9','.','-','+','%','x','X','*','/','k','K'],
		      ['0'..'9'],
		      ['0'..'9','a'..'f','A'..'F'],
		      ['J','N'],
		      ['0'..'9'],
		      ['1'..'9','<','>'],
		      ['1'..'4'],
		      ['0'..'9','a'..'f','A'..'F'],
		      ['B'..'F']);


(*$f+*)
function plausi(var s:str80;i:integer):boolean;
inline ($ff/$1e/plausptr);
function plaus(var s:str80;i:integer):boolean;
begin
  plaus:=true;
end;
(*$f-*)


PROCEDURE schreibrecord(VAR usrec,usmask;receintrzahl : BYTE);
VAR
  temp : string;
  ler  :str80;
  i    : BYTE;
  maske : ARRAY[1..255] OF RECORD
                            xp,yp,xe,le,te :BYTE;
                            m              :STRING[80];
                          END absolute usmask;

  recfeld : ARRAY[0..2000] OF BYTE absolute usrec;
  egal,oldmode:boolean;
  ch:char;
PROCEDURE copyrectemp(x:BYTE);
VAR i,s:INTEGER;
BEGIN
 s:=0; FOR i:=1 TO x-1 DO s:=s+maske[i].le+1;
 if recfeld[s]>succ(maske[x].le) then temp:='' else
 move(recfeld[s],temp,recfeld[s]+1);
END;

BEGIN
 i:=1;oldmode:=editmode;editmode:=false;
 repeat
  if i<=RecEintrZahl then WITH maske[i] DO
    BEGIN
      wi(xp,yp,tattr,m);
      copyrectemp(i);
      ler:=temp+cstr(' ',le-length(temp));
      wi(xe,yp,enattr,ler);egal:=plausi(temp,i);
    end;
    inc(i);
  until i>RecEintrZahl;editmode:=oldmode;
END;

PROCEDURE input(x,y,l,typ:INTEGER;VAR eingabe:string;VAR ch:CHAR);
CONST
  term : charset =
	   [CtrlHome,CtrlEnde,home,Ende,
	    Cup,CDwn,Clft,Crght,Pgup,PgDn,
	    F2,F3,F4,F5,F6,F7,F8,F9,F10,#13,#27];
VAR
  p: INTEGER;
  s  : charset;
  esc,einsetz,first:BOOLEAN;
  temp : str80;
BEGIN
  if wndnr=0 then fc:=' ' else fc:='_';
  temp:=eingabe;
  s:=vgl[typ];
  esc:=FALSE;first:=true;
  einsetz:=FALSE;edsetcursor(cursortype);
  if l>1 then wi(x,y,InEAttr,temp) else wi(x,y,EaAttr,temp);
  wi(x+length(temp),y,EaAttr,cstr(fc,l-length(temp)));
  textattr:=EAAttr;
  p:=0;
  REPEAT
    IF ((kb_flag AND 128)=0) AND einsetz THEN begin
      einsetz:=FALSE ;edsetcursor(cursortype); end;
    IF ((kb_flag AND 128)=128) AND NOT einsetz THEN begin
      einsetz:=TRUE ;edsetcursor(bigcursor); end;
    gotoxy(x+p,y);
    ch:=readkey;
    CASE ch OF
      #0:
        BEGIN;
          esc:= TRUE; ch:=readkey;
        END;
      #13,#27:esc:=TRUE;
      else
        esc:=FALSE ;
    END;
    IF NOT esc THEN
    BEGIN
      CASE ch OF
        ^H,#127:begin
           IF p>0 THEN
           BEGIN
	     DELETE(temp,p,1);gesaved:=false;
	     p:=pred(p);
	     wi(x+p,y,tattr,copy(temp,p+1,81)+cstr(fc,l-length(temp)));
           END
         end;
       ELSE
	 begin
	  if (typ=4) or (typ=5) then ch:=cap(ch);
	  if ch in s then BEGIN
	    if first then temp:='';
	    insert(ch,temp,p+1);gesaved:=false;
	    IF NOT einsetz THEN delete(temp,p+2,1);
	    delete(temp,l+1,1);
	    p:=succ(p);IF p=l THEN begin p:=l-1;write(ch) end else
	    write(copy(temp,p,81),cstr(fc,l-length(temp)));gotoxy(x+p,y);
	 END;
       end;
     end;
    END
   ELSE
   BEGIN
     CASE ch OF
      F1 : begin
		if AktHelpNr=0 then hilfe(AktLastLine) else Hilfe(AktHelpNr);
                if wndnr=0 then window(1,1,80,24);
		if lsttopic<>'' then temp:=copy(lsttopic,1,l);
	      end;
      Clft  : IF p>0 THEN  begin p:=PRED(p);ch:=' ';end;
      CRght : IF p<length(temp) THEN begin p:=SUCC(p);ch:=' ';end;
      Home  : if (p>0) or first then begin p:= 0;ch:=' ';end;
      Ende  : if p<length(temp) then begin p:=length(temp);ch:=' ';end;
      Del   : IF p<length(temp) THEN BEGIN
		gesaved:=false;
		DELETE(temp,p+1,1);
		write(COPY(temp,p+1,l),cstr(fc,l-length(temp)));
	      END;
    CtrlcLft: BEGIN
		gesaved:=false;
		write(cstr(fc,length(temp)-p));
		DELETE(temp,p+1,l);
	      END;
   CtrlcRght: BEGIN
		gesaved:=false;
		Delete(temp,1,p-1);p:=0;
		gotoxy(x,y);
		write(temp,cstr(fc,l-length(temp)));
	      END;
     CtrlDel: BEGIN
		gesaved:=false;
		temp:='';p:=0;
		gotoxy(x,y);
		write(cstr(fc,l));
	      END;
      AltDel: BEGIN
		gesaved:=false;
		temp:=Eingabe;p:=0;
		gotoxy(x,y);
		write(temp,cstr(fc,l-length(temp)));
	      END;
     END;
   END;
   if first then begin first:=false;
     wi(x,y,EaAttr,temp);
   end;
 UNTIL ((ch IN term) AND (esc=TRUE));
  wi(x,y,EnAttr,temp+cstr(' ',l-length(temp)));
  textattr:=Tattr;
  eingabe:=copy(temp,1,l);
  edsetcursor($2020);
END;

PROCEDURE liesrecord(VAR usrec,usmask ; receintrzahl : BYTE;VAR ch:char;
  ter:charset;abbruch:char);
VAR temp:string;
    maske : ARRAY[1..255] OF RECORD
                            xp,yp,xe,le,te :BYTE;
                            m              :STRING[80];
                          END absolute usmask;
      recfeld : ARRAY[0..2000] OF BYTE absolute usrec;

PROCEDURE copyrectemp(x:BYTE);
VAR i,s:INTEGER;
BEGIN
 s:=0; FOR i:=1 TO x-1 DO s:=s+maske[i].le+1;
 if recfeld[s]>succ(maske[x].le) then temp:='' else
 move(recfeld[s],temp,recfeld[s]+1);
{ temp:='';
 FOR i:=1 TO recfeld[s] DO temp:=temp+chr(recfeld[s+i]);}
END;
PROCEDURE copytemprec(x:BYTE);
VAR i,s:INTEGER;
BEGIN
 s:=0; FOR i:=1 TO x-1 DO s:=s+maske[i].le+1;
 move(temp,recfeld[s],length(temp)+1);
 { recfeld[s]:=length(temp);
FOR i:=1 TO length(temp) DO recfeld[s+i]:=ord(temp[i]); }
END;

VAR
 min,i : INTEGER;
esc   : BOOLEAN;

BEGIN
  enterwin(wndnr);
  schreibrecord(usrec,maske,receintrzahl);
  min:=1;
  i:=ord(ch);
  if (i<1) or (i>receintrzahl) then i:=1;
  REPEAT
    REPEAT
      IF maske[i].le=0 THEN i:=SUCC(i);
      IF i>receintrzahl THEN i:=1;
     UNTIL maske[i].le>0;
    copyrectemp(i);
    repeat
      WITH maske[i] DO input(xe,yp,le,te,temp,ch);
    until (ch =abbruch) or plausi(temp,i);
   copytemprec(i);
    CASE ch OF
      cUp: begin
	     repeat
	       IF I>min THEN dec(i) ELSE i:= receintrzahl;
	       IF maske[i].le=0 THEN dec(i);
	     until maske[i].le>0;
	   end;
     cDwn: begin
             inc(i);
             if i>receintrzahl then i:=1;
	   end;
      #13: begin
             inc(i);
	   end;
 CtrlHome: i:=1;
 CtrlEnde: i:=RecEintrZahl;
   END;
  UNTIL   (ch=#13) and (i>receintrzahl) or (ch in ter) or (ch=abbruch);

  if ch<>abbruch then begin
   i:=1;
   repeat
     copyrectemp(i);
     if not plausi(temp,i) then
     repeat
       WITH maske[i] DO input(xe,yp,le,te,temp,ch);
     until (ch =abbruch) or plausi(temp,i);
     copytemprec(i);inc(i);
   until (ch=abbruch) or (i>receintrzahl);
  end;
  edsetcursor($2020);
END;
begin
  Plausptr:=@plaus;
  fc:='_';editmode:=false;gesaved:=true;
end.
