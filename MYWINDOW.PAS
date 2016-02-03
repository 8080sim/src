unit mywindow;
{$i direct.inc}
interface
uses
	crt,dos,Astypdea,procs;

const
  MaxWindows = 23;
  HilfeWindow =10;
  FehlerWindow= 9;
	LogoWindow = 8;

  f1=';';        f2='<';      f3='=';      f4='>';       f5='?';
  f6='@';        f7='A';      f8='B';  	   f9='C';      f10='D';

 CtrlF1='^'; CtrlF2='_';  CtrlF3='`';  CtrlF4='a';   CtrlF5='b';
 CtrlF6='c'; CtrlF7='d';  CtrlF8='e';  CtrlF9='f';  CtrlF10='g';

 AltF1='h';  AltF2='i';   AltF3='j';   AltF4='k';    AltF5='l';
 AltF6='m';  AltF7='n';   AltF8='o';   AltF9='p';   AltF10='q';

  PgUp='I';  	PgDn='Q';    Home='G';	  Ende='O';   Ins='R';
  cUp='H';     cDwn='P';     cRght='M';   cLft='K';   Del='S';

  CtrlPgUp='Ñ';  CtrlPgDn='v';   CtrlHome='w';   CtrlEnde='u'; CtrlIns=#146;
  CtrlcUp=#141;  CtrlcDwn=#145; CtrlcRght='s';   CtrlcLft='t'; CtrlDel=#147;

  AltPgUp='ô';  AltPgDn=#161;  AltHome=#151;   AltEnde=#159;
  Altcup=#152;  AltcDwn=#160; AltcRght=#157;   AltcLft=#155;   AltDel=#162;

	DefNoRows = 25;            {Default number of rows/physical screen}
  DefNoCols = 80;            {Default number of cols/physical screen}
  rahmattr    :byte=$17;    {Bildschirmfarben }
  tafelattr   :byte=$06;
	schattenAttr:byte=$01;
  eNattr      :byte=$17;     {Eingabe nicht aktuell}
  eAattr      :byte=$1f;    {Aktuelle Eingabe}
	InEAttr     :byte=$70;   {Eingabe invert}
  tattr       :byte=$16;     {Textausgabe }
  llinAttr    :byte=$70;   {Letzte Zeile}
  HelpIndAttr :Byte=$17;   {HelpIndex }
  HelpindaAttr:Byte=$70;   {Helpindex akt.}
  HochAttr    :Byte=$61;
type
 t_Attrib=Array[1..11] of byte;
{
	str2 = STRING[2];  str3 = STRING[3];  str4 = STRING[4];  str5 = STRING[5];
	str6 = STRING[6];  str7 = STRING[7];  str8 = STRING[8];  str10 = STRING[10];
	str12 = STRING[12];str15 = STRING[15];str17 = STRING[17];str20 = STRING[20];
	str24 = STRING[24];str25 = STRING[25];str40 = STRING[40];str80 = STRING[80];
}
Type
	charset = SET OF char;

wdrec=record
      x,y,dx,dy,
      xp,yp:integer;
			s:str80;
      bp:pointer;
end;
wdArray=array[0..maxwindows] of wdrec;
const
	 colorAttr:t_attrib=($70,$11,$00,$71,$74,$0f,$70,$60,$74,$61,$71);
   MonoAttr:t_attrib= ($07,$07,$07,$07,$0f,$70,$07,$70,$0f,$70,$70);

var

 kb_flag                  :BYTE Absolute $40:$17;
	ErrorFilename           :Str80;
	ErrorFileRec            :LongInt;
	wndnr:integer;
  ScreenAttr:t_Attrib absolute Rahmattr;
  wd         :wdarray;
  ScreenAdr : Word;          {Base address of video memory}

  PhyScrCols : Integer;      {Columns per screen row}
  CursAttr   : Word;         {Aktuelle Cursorform}
  CursorType : Word;         {Scan lines for normal blinking cursor}
  BigCursor : Word;          {Scan lines for "fat" cursor used in insert mode}
  LogScrRows : Integer;      {No. lines/logical screen}
  LogTopScr : Integer;       {Physical line no. for logical line #1}
  PromptRow : Integer;       {Physical line for signals, etc.}



procedure EdChangeAttribute(Number, Row, Col, Attr : Integer);
 { -Changes Number video attributes to Attr starting at Row,Col}

procedure EdMoveToScreen(var Source, Dest; Length : Integer);
  {-Moves Length words from Source to Dest (video memory) without snow}

procedure EdMoveFromScreen(var Source, Dest; Length : Integer);
  {-Moves Length words from Source (video memory) to Dest without snow}

procedure EdSetCursor(ScanLines : Word);
  {-Change the scan lines of the hardware cursor}

procedure EdRestoreScreenMode;
  {-Clean up screen upon exit}

procedure wi1(x,y,attr:integer;s:str80);   {Schreiben in Fenster}
procedure wiA1(x,y,attr:integer;s:str80);  {Schreiben absolut   }
procedure wi(x,y,attr:integer;s:str80);   {Schreiben in Fenster}
procedure wiA(x,y,attr:integer;s:str80);  {Schreiben absolut   }
procedure wiC(y,a:integer;s:str80);           {Schreiben zentriert }

procedure tafel(i:integer);
procedure tafel1;
procedure savescr(var wd:wdrec;i:pointer);
procedure switchscreen(var i);
procedure restscr(var wd:wdrec;i:pointer);
procedure makewin(nr:integer);
procedure enterwin(nr:integer);
procedure leavewin(nr:integer);
procedure movewin(nr:integer);
procedure rahm(x1,y1,x2,y2:integer;r1,t1:byte);
procedure openwin(nr:integer);
procedure closewin(nr:integer);
procedure pushwin(nr:integer);
procedure popwin(modus:boolean);
procedure schatten(nr:integer);
procedure keinschatten(nr:integer);
Function FlipMenue(x,yy:byte;
											 str:string;
									 wndnr:byte;
			 var position:byte;
			 Hilfsnummer:Integer;auto:boolean ):integer;

implementation
	uses FileServ,mygloerr;
  var
      windowstack : array[0..maxwindows] of integer;
      stckptr     : integer;

procedure keinschatten(nr:integer);
var ss:str80;
    i:integer;
begin
  with wd[nr] do begin
   ss:=cstr(#177,2);
		for i:=y+2 to succ(y+dy) do begin wiA1(x+dx+2,i,tafelattr,ss);end;
		ss:=cstr(#177,dx+1);wiA1(x+3,y+dy+2,tafelattr,ss);
 end;
end;
procedure schatten(nr:integer);
var ss:str80;
    i:integer;
begin
  with wd[nr] do begin
   ss:=cstr(#176,2);
		for i:=y+2 to y+dy+1 do begin wiA1(x+dx+2,i,Schattenattr,ss);end;
		ss:=cstr(#176,dx+1);wiA1(x+3,y+dy+2,SchattenAttr,ss);
 end;
end;


procedure switchscreen(var i);external;
{$l switchscr}
procedure rahm(x1,y1,x2,y2:integer;r1,t1:byte);external;
(*$l rahm1*)
procedure savescr;external;
procedure restscr;external;
(*$l restscr*)
{Original
procedure wi(x,y,attr:integer; s:str80);external;
procedure wiA1(x,y,attr:integer; s:str80);external;
(*$L tafel*)
}
procedure wi(x,y,attr:integer; s:str80);external;
procedure wiA(x,y,attr:integer; s:str80);external;
(*$L tafel*)

procedure wi1(x,y,attr:integer; s:str80);
Begin
  If ((Not Userpage) And ShowRegs) Then wi (x,y,attr,s);
End;

procedure wiA1(x,y,attr:integer; s:str80);
Begin
	If ((Not Userpage) And ShowRegs) Then wiA (x,y,attr,s);
End;

procedure tafel(i:integer);external;
(*$L tafel1*)

procedure tafel1;external;
{procedure xorattrib;external;}
function Center(Len, Left, Right : integer) : integer;
begin
  Center := (succ(Right - Left) div 2) - (Len div 2);
end;

procedure wiC(y,a:integer;s:str80);
begin
  Wi(center(length(s),1,wd[wndnr].dx),y,a,s);
end;

procedure makewin(nr:integer);
var ss:str80;
     i:integer;
     bufgro:integer;
     xdel,xs,ys,xds,yds:integer;
     r1,t1:byte;
begin
  window(1,1,80,25);
  r1:=rahmattr;t1:=tattr;
  if nr=hilfewindow then begin r1:=hochattr;t1:=hochattr end;
  with wd[nr] do begin
    bufgro:=(dx+3)*(dy+1)*2;
    if bp=nil then getmem(bp,bufgro);
     savescr(wd[nr],bp);
{    if dx<75 then begin}
       xdel:=500 div (dx+dy);
       xs:=x+ dx div 2 -2;ys:=y+dy div 2-1;
       xds:=2;yds:=2;
			 while (xds<dx) or (xs>x) or  (yds<dy) or (ys>y) do begin
	rahm(xs,ys,xs+xds,ys+yds,r1,t1);
	delay(xdel);
	if xs>x then dec(xs);
	if xds<dx then inc(xds,2);
	if xds>dx then xds:=dx;
	if odd(yds) then if ys>y then dec(ys);
	if yds<dy then inc(yds);
	if yds>dy then yds:=dy;
      end;
{     end; }
     rahm(x,y,x+dx,y+dy,r1,t1);
     s:=copy(s,1,dx-2);
		 wiA(x+center(length(s),x,x+dx),y+1,r1,s);
  end;
end;

procedure enterwin(nr:integer);
begin
 with wd[nr] do begin
   window(x+3,y+2,x+dx,y+dy);
   gotoxy(xp,yp);
 end;
end;

procedure leavewin(nr:integer);
begin
 with wd[nr] do begin
   xp:=wherex;yp:=wherey;
   window(1,1,80,25);
 end;
end;

procedure movewin(nr:integer);
var ch:char;
    bufgro:integer;
    p:pointer;
    i:integer;
begin
  kb_flag:=(kb_flag) or 16;
  with wd[nr] do begin
    bufgro:=(dx+3)*(dy+1)*2;
    getmem(p,bufgro);
    savescr(wd[nr],p);
{    leavewin(nr); }
    repeat
      repeat ch:=readkey; until (ch=#0) and keypressed;
      ch:=readkey;
      case ch of
        crght:begin
               restscr(wd[nr],bp);
							 if x+dx<79 then inc(x);
               makewin(nr);
               restscr(wd[nr],p)
              end;
         clft:begin
               restscr(wd[nr],bp);
                if x>0 then dec(x);
                 makewin(nr);
                restscr(wd[nr],p)
              end;
        cdwn :begin
                restscr(wd[nr],bp);
                if y+dy<23 then inc(y);
                makewin(nr);
                restscr(wd[nr],p)
              end;
          cup:begin
								restscr(wd[nr],bp);
                if y>0 then dec(y);
                makewin(nr);
                restscr(wd[nr],p)
             end;
       end;
     until ch=f9;
   end;
   freemem(p,bufgro);
end;

procedure closewin;
var bufgro:integer;
begin
 if wd[nr].bp<>nil then begin
   leavewin(nr);
   restscr(wd[nr],wd[nr].bp);
	 with wd[nr] do begin
     bufgro:=(dx+3)*(dy+1)*2;
     freemem(bp,bufgro);
     bp:=nil;
   end;
 end;
end;

procedure openwin(nr:integer);
begin
  makewin(nr);
  enterwin(nr);
end;

procedure pushwin(nr:integer);
begin
  if stckptr<maxwindows then leavewin(wndnr);
{$ifdef debug}
  if stckptr>0 then begin
{$endif}
    dec(stckptr);
    windowstack[stckptr]:=wndnr;
    if wd[nr].bp=nil then makewin(nr);
    enterwin(nr) ;wndnr:=nr;
{$ifdef debug}
  end else abort('Fehler in Routine Pushwin (StckPtr zu klein)');
{$endif}
end;

procedure popwin(modus:boolean);
begin
{$ifdef debug}
  if stckptr<maxwindows then begin
{$endif}
		if modus then closewin(wndnr) else leavewin(wndnr);
    if stckptr<maxwindows then begin
       wndnr:=windowstack[stckptr];
       inc(stckptr);
       enterwin(wndnr);
    end else window(1,1,80,25);
{$ifdef debug}
  end else abort('Fehler in Routine Popwin (wndnr>20)');
{$endif}
end;

Function FlipMenue(x,yy:byte;
                       str:string;
                   wndnr:byte;
		   var position:byte;
		   Hilfsnummer:Integer;auto:boolean ):integer;
var
	i,breite,ausgewaehlt,anzahl:integer;
  auswahl:array[1..24] of string[70];
  foot,header,leerstr:string[70];
  hotkeys:string[24];
  hkcolor:byte;
  kontrolle,antwort:char;
  no_mark,hotkey:boolean;

procedure inv;
var i,j:integer;
begin
  i:=pos('#',auswahl[ausgewaehlt]);
  j:=pos('$',auswahl[ausgewaehlt]);
  j:=j-i;
  if i=0 then i:=71;
  wi(2,Ausgewaehlt,inEattr,copy(auswahl[ausgewaehlt],1,i-1));
  if i<71 then begin
		wi(1+i,Ausgewaehlt,inEattr,copy(auswahl[ausgewaehlt],i+1,j-1));
  end;
  wi(i+j,Ausgewaehlt,inEattr,copy(auswahl[ausgewaehlt],i+j+1,70));
end;

procedure norm;
var i,j:integer;
begin
  i:=pos('#',auswahl[ausgewaehlt]);
  j:=pos('$',auswahl[ausgewaehlt]);
  j:=j-i;
  if i=0 then i:=71;
  wi(2,Ausgewaehlt,Tattr,copy(auswahl[ausgewaehlt],1,i-1));
  if i<71 then begin
    wi(1+i,Ausgewaehlt,EaAttr,copy(auswahl[ausgewaehlt],i+1,j-1));
  end;
  wi(i+j,Ausgewaehlt,Tattr,copy(auswahl[ausgewaehlt],i+j+1,70));
	{off_cursor;}
end;

begin
  breite:=1;anzahl:=1;
  hotkeys:='';Header:='';foot:='';no_mark:=true;
  while pos('_',str)<>0 do begin
    auswahl[anzahl]:=copy(str,1,pos('_',str)-1);
    delete(str,1,pos('_',str));
    if length(auswahl[anzahl])>breite then begin
      breite:=length(auswahl[anzahl]);
      if (auswahl[anzahl][1]<>'(') and
       (auswahl[anzahl][1]<>')') and
       (pos('#',auswahl[anzahl])=0) then inc(breite);
    end;
    case auswahl[anzahl][1] of
      '(':header:=copy(auswahl[anzahl],2,70);
			')':foot:=copy(auswahl[anzahl],2,70);
      else begin
        if pos('#',auswahl[anzahl])<>0 then begin
          no_mark:=false;
          foot:=copy(auswahl[anzahl],pos('#',auswahl[anzahl])+1,pos('$',auswahl[anzahl])-2);
          if foot='F1' then hotkeys:=hotkeys+f1 else
          if foot='F2' then hotkeys:=hotkeys+f2 else
          if foot='F3' then hotkeys:=hotkeys+f3 else
          if foot='F4' then hotkeys:=hotkeys+f4 else
          if foot='F5' then hotkeys:=hotkeys+f5 else
          if foot='F6' then hotkeys:=hotkeys+f6 else
          if foot='F7' then hotkeys:=hotkeys+f7 else
          if foot='F8' then hotkeys:=hotkeys+f8 else
          if foot='F9' then hotkeys:=hotkeys+f9 else
          if foot='F10' then hotkeys:=hotkeys+f10 else
          hotkeys:=hotkeys + auswahl[anzahl][pos('#',auswahl[anzahl])+1];
        end  else hotkeys:=hotkeys+#0;
				inc(anzahl);
      end;
    end;
  end;
  dec(anzahl);
  inc(breite);
  if no_mark then inc(breite);
  fillchar(leerstr,succ(breite),' ');
  fillchar(leerstr,1,chr(breite));
  for ausgewaehlt:=1 to anzahl do begin
    hotkeys[ausgewaehlt]:=upcase(hotkeys[ausgewaehlt]);
    if pos('#',auswahl[ausgewaehlt])=0 then i:=1 else i:=0;
    if length(auswahl[ausgewaehlt])<breite then auswahl[ausgewaehlt]:=auswahl[ausgewaehlt]
       +copy(leerstr,1,breite-length(auswahl[ausgewaehlt])-1-i);
  end;
 wd[wndnr].x:=x;
 with wd[wndnr] do if bp=nil then begin
	 xp:=1;yp:=1;
   if x=0 then  x:=(80-breite-2) shr 1;
   y:=(yy-anzahl-2);
   dx:=breite+3;dy:=anzahl+1;
  s:=header;
 end;
 pushwin(wndnr);
 edsetcursor($2020);
 For ausgewaehlt:=1 to anzahl do norm;
 ausgewaehlt:=position;
 if (ausgewaehlt>anzahl) or (ausgewaehlt<1) then ausgewaehlt:=1;
 inv;
 antwort:=#0;
 hotkey:=false;
 repeat
   if not auto then begin
   if keypressed then begin
		 antwort :=readkey;
     norm;
     if antwort=#0 then begin
       if keypressed then begin
         kontrolle:=readkey;
         case kontrolle of
	  F1 : hilfe(Hilfsnummer);
	  #80,#77: if ausgewaehlt<anzahl then inc(ausgewaehlt) else ausgewaehlt:=1;
          #72,#75: if ausgewaehlt>1 then dec(ausgewaehlt) else ausgewaehlt:=anzahl;
              #71: ausgewaehlt:=1;
              #79: ausgewaehlt:=anzahl;
          else begin
            antwort:=kontrolle;hotkey:=pos(cap(antwort),hotkeys)>0;
          end;
         end;
       end;
     end else begin
			 i:=pos(cap(antwort),hotkeys);
       if i<>0 then begin
       antwort:=#13;ausgewaehlt:=i;
     end;
   end;
   inv;
 end;
 end else begin antwort:=#13;ausgewaehlt:=position;end;
 until (antwort=#13) or (antwort=#27) or hotkey;
 norm;
 if antwort<>#27 then begin
   if antwort<>#13 then ausgewaehlt:=pos(antwort,hotkeys);
   position:=ausgewaehlt;
   inv;
 end else ausgewaehlt:=0;
 Flipmenue:=ausgewaehlt;
 popwin(false);
 edsetcursor(cursortype);

end;

type
  TAarray = array[0..160] of Char; {Combined line of char and attr for screen}

const
  {Default modes - shared by all windows}
	GoodColorCard : Boolean = true; {False to remove snow on color card}

var
	InitScreenMode : Byte;     {The video mode on entry to program}
	InitRetraceMode : Boolean; {Set if wait for retrace is needed}
	EgaPresent : Boolean;      {True if EGA card selected}
	RetraceMode : Boolean;     {Check for snow on color cards?}
	PhyScrRows : Integer;      {No. lines/physical screen}
	dummy : pointer; { fÅr Heapfreigabe bei Runtime-Error}
	{$L wsSCRN}

	procedure EdChangeAttribute(Number, Row, Col, Attr : Integer); external;
	procedure EdMoveToScreen(var Source, Dest; Length : Integer); external;
	procedure EdMoveFromScreen(var Source, Dest; Length : Integer); external;
	procedure EdSetCursor(ScanLines : Word); external;
{$F+}
var Exitsave:Pointer;

procedure EdRestoreScreenMode;
		{-Clean up screen upon exit}
	var
			ch :char;
			 s:str5;
			 regs:Registers;

(*
{$ifdef Debug}
*)
function TurboError(ErrorCode : word) : str80;
begin
	case ErrorCode of
			1: TurboError := 'Invalid DOS function code';
			2: TurboError := 'File nicht gefunden';
			3: TurboError := 'Pfad nicht gefunden';
			4: TurboError := 'Zu viele offene Dateien';
			5: TurboError := 'Dateizugriff verweigert';
			6: TurboError := 'File handle ungÅltig';
			8: TurboError := 'Zu wenig Speicher';
		 12: TurboError := 'UngÅltiger Dateimodus';
		 15: TurboError := 'Laufwerksnummer unzulÑssig';
		 16: TurboError := 'Aktuelles Directory kann nicht gelîscht werden';
		 17: TurboError := 'Rename kann nicht kopieren';
		100: TurboError := 'Fehler beim Lesen von Platte';
		101: TurboError := 'Fehler beim Schreiben auf Platte';
		102: TurboError := 'Datei-Variable keine Datei zugeordnet';
		103: TurboError := 'Datei nicht geîffnet';
		104: TurboError := 'Datei nicht fÅr Leseoperationen geîffnet';
		105: TurboError := 'Datei nicht fÅr Schreiboperationen geîffnet';
		106: TurboError := 'UngÅltiges numerisches Format';
		159: TurboError := 'Drucker nicht bereit';
		200: TurboError := 'Division durch Null';
		201: TurboError := 'BereichsÅberprÅfung : Fehler entdeckt';
		202: TurboError := 'StackÅberlauf';
		203: TurboError := 'kein Platz mehr im Heapbereich';
		204: TurboError := 'ungÅltige Zeiger-Operation';
 {$ifdef myaccess}
	RecTooLarge : TurboError := 'DatensatzlÑnge ist grî·er als MaxDataRecSize';
	RecTooSmall : TurboError := 'DatensatzlÑnge ist zu klein';
	KeyTooLarge : TurboError := 'SchlÅssellÑnge ist grî·er als MaxKeyLen';
	RecSizeMismatch : TurboError := 'Datei wurde mit andere DatensatzlÑnge erzeugt';
	KeySizeMismatch : TurboError := 'Index wurde mit anderer SchlÅssel oder SeitenlÑnge erzeugt';
	MemOverflow : TurboError := 'Nicht genug Speicher fÅr Seitenstack';
{$endif}
		else
			 TurboError := 'nicht bekannter Fehler';
	end;
end; { TurboError }

(*
{$Endif}
*)

function hex(h:byte):str4;
 const
	hexarray:array[0..15] of char = '0123456789ABCDEF';
 begin
	hex:=hexarray[h shr 4] + hexarray[h and $f];
 end;

function hexw(w:word):str4;
begin
	hexw:=hex(hi(w))+hex(lo(w));
end;

Var Io : Integer;

	begin                      {EdRestoreScreenMode}
		Io := IOResult;
		ExitProc:=Exitsave;
		if ErrorAddr<>nil then begin
			Io := IOResult;
			Astypdea.FName [0] := 'Fehler.asm';
			FileServ.SaveFile;
			If OldDir[Length (OldDir)]='\' Then ChDir (Copy (OldDir,1,Length(OldDir)-1))
																	 Else ChDir (OldDir);
			if wd[HilfeWindow].bp <>nil then closewin(HilfeWindow);
			release(dummy);
			with  wd[HilfeWindow] do begin
				x:=5;dx:=70;y:=4;dy:=18;s:='µ Fehlermeldung ∆';xp:=1;yp:=1;
			end;
			pushwin(HilfeWindow);
			wic(2,tAttr,'Es ist ein Laufzeitfehler aufgetreten');
			wic(4,tAttr,'Bitte notieren Sie Fehlernummer, Fehleradresse, Progammname');
			wic(5,tAttr,'und Version, und informieren den Programmautor :');
			Wic(6,tAttr,'M. Flume, Gewerbliche Schulen I, Wuppertal');
			str(exitcode,s);
			wic(8,tAttr,'Fehler: '+s+' an Adresse:'
			+hexw(seg(erroraddr^))+':'+hexw(ofs(erroraddr^))
			 +' in '+' Version '+Programmversion);
(*
			{$ifdef Debug}
			wic(9,tAttr,Turboerror(ExitCode));
			{$endif}
*)
			wic (11,tAttr,Turboerror(ExitCode));
			If ErrorFilename<>'' then begin
			 str(ErrorFileRec,s);
			 Wic(10,tAttr,'Datei : '+ErrorFileName+' Satz : '+s);
			end;
			wic(14,tAttr,'Das Programm kann leider nicht fortgesetzt werden.');
			wic(16,tAttr,' - Bitte eine Taste drÅcken - ');
			while keypressed do ch:=readkey;
			ch:=Readkey;
			{$IfNDef Debug}
			erroraddr:=nil;
			{$EndIf}
		end;
		EdSetCursor(CursorType);
		with regs do begin
			Ah := 0;
			Al := InitScreenMode;
			intr($10, regs);
		end;
	end;                       {EdRestoreScreenMode}
	{$f-}
	{***}

	procedure EdGetScreenMode;
		{-determine screen address and colors}
	var
		regs : registers;

		function EdEgaPresent : Boolean;
			{-Return True if an EGA card is installed and selected}
		var
			regs : registers;

		begin                    {EdEgaPresent}
			with regs do begin
				Ah := $12;
        Bl := $10;
        Cx := $FFFF;
        intr($10, regs);
        EdEgaPresent := (Cx <> $FFFF);
      end;
    end;                     {EdEgaPresent}

  begin                      {EdGetScreenMode}

    PhyScrCols := DefNoCols; {Number of columns on the screen}
    PromptRow := 24;          {Command Line is line 24 of screen}
    LogTopScr := 1;          {Text windows don't use line 1 of screen}
    PhyScrRows := DefNoRows;
    LogScrRows := Succ(PhyScrRows-LogTopScr);

    with regs do begin
      {Get current screen mode}
      ax := $0F00;
      intr($10, regs);
      InitScreenMode := Al;

      {Set screen mode to appropriate 80 column mode}
      Ah := 0;
      case InitScreenMode of
        0 : Al := 2;         {Switch from BW40 to BW80}
        1 : Al := 3;         {Switch from CO40 to CO80}
      else
        Al := InitScreenMode; {Assure color burst correct}
      end;
      intr($10, regs);
    end;

    InitRetraceMode := (InitScreenMode <> 7);
    EgaPresent := EdEgaPresent;

    if InitRetraceMode then begin
      {Color card}
      ScreenAdr := $B800;
			ScreenAttr := ColorAttr;
(*      PORT[$3D9]:=TAFELATTR AND $0F;*)
      CursorType := $0607;
      BigCursor := $0507;
      if EgaPresent then
        GoodColorCard := True;
    end else begin
      ScreenAdr := $B000;
      ScreenAttr:=MonoAttr;
      CursorType := $0B0C;
      BigCursor := $090C;
    end;

      with regs do begin ax:=$1003;bl:=0; end;
      intr($10,regs);


    {Don't slow down for good color cards}
    RetraceMode := InitRetraceMode and not(GoodColorCard);
  end;                       {EdGetScreenMode}

var f:file;
begin
  assign(f,'Colors.Sim');
  {$i-} reset(f,1);{$i+}
  if ioresult=0 then begin
	 blockread(f,colorattr,2*sizeof(colorattr));
   close(f);
  end;
	mark(dummy);
	ErrorFileName:='';
	stckptr:=maxwindows;fillchar(wd,Sizeof(wd),0);
  EdGetScreenMode;
  ExitSave:=ExitProc;
  Exitproc:=@EdRestoreScreenMode;
  EdSetcursor($2020);
end.
