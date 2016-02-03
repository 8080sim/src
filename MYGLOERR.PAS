unit MyGloerr;
{$i direct.inc}
interface
 uses crt,
	 astypdea,procs;
type jaNeinTyp=(esc,ja,nein);
var AktLastLine:Integer;
    AktHelpNr:integer;
    LstTopic:string[30];
procedure llin(i:integer);
procedure ilin(x,l:integer);
procedure rlin;
procedure error(err:integer);
function JaNein(err:integer;s:string):JaNeinTyp;
PROCEDURE select(x:INTEGER; term: charset; VAR tc: CHAR);
function EdMessagePtr(Msgno : Integer) : Pointer;
function EdGetMessage(Msgno : Integer) : string;
procedure druckfrage(var ch:char);
procedure abbruch(var ch:char);
procedure hilfe(Cmd:integer);

Implementation
   uses
	 MyWindow;
   {$L Mess}
  type
  HelpIndexRec =             {File position and block length of help sections}
  record
    Start : LongInt;
    Len : Word;
  end;
  HelpStackRec =
  record
    cmd:integer;
    pageNr:integer;
  end;
  const  TopOfHelp:integer=-1;

  var helpf:file;
      helpname:str80;
      HelpAvail:boolean;
      HelpStack:array[0..20] of HelpStackRec;
  function EdMessagePtr(Msgno : Integer) : Pointer; external;
  {-Return a pointer to the message string, nil if not available}

  function EdGetMessage(Msgno : Integer) : string;
    {-Get message from packed message buffer or return number to caller}
  var
    P : Pointer;
    St : string;

  begin                      {EdGetMessage}
    P := EdMessagePtr(Msgno);
    if P = nil then begin
      {String not available, return the error number}
      Str(Msgno, St);
      St := ' Meldung '+St;
    end else
      Move(P^, St, Succ(Byte(P^)));
    EdGetMessage := St;
  end;                       {EdGetMessage}
(*L \tp\ws\llin *)
procedure llin(i:integer);
var s:str80;
begin
 AktLastLine:=i;
 s:=EdGetMessage(i);
 wia(1,25,Llinattr,s);
end;
procedure ilin(x,l:integer);
var s:str80;
begin
  s:=cstr(' ',80);
    wia(1,25,llinattr,s);
  s:=EdgetMessage(AktLastLine);
  s:=copy(s,x,l);wia(x,25,eaAttr,s);
end;
procedure rlin;
var s:str80;
begin
  s:=EdgetMessage(AktLastLine);
  wia(1,25,llinattr,s);
end;

PROCEDURE select;
VAR
  ch: CHAR;
  esc:BOOLEAN;
BEGIN
  esc:=FALSE;
  llin(x);
  REPEAT
    repeat
      tc:=readkey;
      if not keypressed then beep;
    until ((tc=#0) and keypressed) or ((tc=#13) and (tc in term));
    if not ((tc=#13) and (tc in term)) then tc:=readkey;

    if tc=AltF1 then begin
     if AktHelpNr=0 then hilfe(x) else Hilfe(AktHelpNr)
    end else IF NOT(tc IN term) THEN beep;
  until tc in term;
END;

procedure error(err:integer);
var i:integer;
   ch:char;
   s1:str80;
const s:str80='F1=Hilfe oder weiter mit bel. Taste';
begin
 s1:=EdGetMessage(err);
 i:=length(s1);
 if i<length(s) then i:=length(s);
 i:=i div 2+2;
 with wd[FehlerWindow] do begin
	 x:=40-i;y:=21;
   dx:=i+i;dy:=3;
   xp:=1;yp:=1;
   bp:=nil;s:='';
 end;
 pushwin(FehlerWindow);
 wi(2,1,EaAttr,s1);
 wiC(2,EaAttr,s);
 while keypressed do ch:=readkey;
 beep;
 ch:=readkey;
 popwin(True);
 if (ch=#0) and keypressed then begin
{Original
    ch:=readkey;if ch=f1 then hilfe(err);
}
{Neu}
    ch:=readkey;
    if ch=f1 then Begin
      If err in [151..154] Then hilfe(150) Else hilfe (err);
    End;
 end;
end;
Function JaNein;
var i:integer;
   s1:string[60];
   auswahl:integer;
   m_pos:byte;
begin
 s1:=EdGetMessage(err);
 i:=length(s1) div 2 + 2;
 with wd[FehlerWindow] do begin
   x:=40-i;y:=12;
   dx:=i+i;dy:=2;
   xp:=1;yp:=1;
   bp:=nil;s:='';
 end;
 pushwin(FehlerWindow);
 wi(2,1,EaAttr,s1);m_pos:=1;
 auswahl:=flipmenue(40,19,'#J$a_#N$ein_(ต '+s+' ฦ_',7,m_pos,0,false);
 closewin(7);
 JaNein:=janeintyp(auswahl);
 popwin(True);
end;

function ZeigHilfe(Cmd : Integer;Var PageNum:Word):integer;
    {-Display help for the specified command}
  const
    Xmin = 5;
    Ymin = 7;
    MaxHelpPages = 20;       {Max number of pages in one help section}
  type
    PageIndexRec =           {Indexes the pages of a help section}
    record
      StartOfs : Word;
      Startattr : Byte;
    end;
    TopicType = record
      x,y,l  :integer;
      hlpnr  :integer;
      namstr :string[30];
    end;

    PageArray = array[1..MaxHelpPages] of PageIndexRec;
    StringBuffer = array[1..MaxInt] of Char;

  var
    topics:array[1..25] of TopicType;
    Ch : Char;
    Attr : Byte;
    HelpWidth,HelpLen,MaxTopics:integer;
    Redraw, Quitting : Boolean;
    MaxPage, BytesRead : Word;
    SbPtr : ^StringBuffer;
    HelpRec : HelpIndexRec;
    Pages : PageArray;

    procedure EdBuildPageIndex(var S : StringBuffer; var Pages : PageArray; var MaxPage : Word);
      {-Initialize the page index}
    var
      Spos, PageNum : Word;
      Attr : Byte;
      EndOfSection : Boolean;
      col,lin:Integer;
    begin                    {EdBuildPageIndex}
      Spos := 1;HelpWidth:=20;Helplen:=3;
      PageNum := 1;col:=0;lin:=0;
      EndOfSection := False;
      Attr := hochattr;

      {Keep track of the byte offset and initial video attribute of each page}
      Pages[PageNum].StartOfs := Spos;
      Pages[PageNum].Startattr := Attr;

      repeat
        if s[spos]='@' then spos:=spos+2 else
{	if s[spos]='$' then begin
	   inc(spos);
	   Inc(Col,ord(s[spos]));
	  end else               }
        if s[spos]='#' then begin
         inc(spos);
         case S[Spos] of

          ^L :               {New page}
            begin
	       if lin>HelpLen then HelpLen:=lin;
              col:=0;lin:=0;
              Inc(PageNum);
              Pages[PageNum].StartOfs := Succ(Spos);
              Pages[PageNum].Startattr := Attr;
            end;

          ^Z :               {End of section}
            begin
              if lin>HelpLen then HelpLen:=lin;
              EndOfSection := True;
              if (Spos > 1) and (S[Pred(Spos)] = ^L) then
                MaxPage := Pred(PageNum)
             else
                MaxPage := PageNum;
            end;
	 end
	end else begin
	 if s[spos]= #13 then  begin
	   if col>HelpWidth then HelpWidth:=Col;
	    inc(lin);col:=0;
	   end else inc(col);
	end;
	Inc(Spos);
      until EndOfSection;
    with wd[HilfeWindow] do begin
      x:=38-(HelpWidth div 2);y:=11 -(Helplen div 2);
      dx:=Helpwidth+3;dy:=helplen+1;s:='ต BZL Hilfe-System ฦ';
      xp:=1;yp:=1;
    end;
    end;                     {EdBuildPageIndex}

    procedure EdDrawFullPage( var S : StringBuffer; var Pages : PageArray; PageNum : Word);
      {-Draw help page pagenum}
    const strich:string[13]='อออออออออออออ';
    var
      Attr : Byte;
      Ch : Char;
      EndOfPage : Boolean;
      Spos, Row, Col,l : Integer;
      msg : String;
      s1 :str80;

    begin                    {EdDrawFullPage}
      s1[0]:=#1;
      with Pages[PageNum] do begin
        Spos := StartOfs;
        Attr := Startattr;
      end;
        {Initialize help message}
	if PageNum > 1 then msg := 'ESC / ALT F1 / PgUp' else msg:='ESC / ALT F1 ';
        textattr:=hochattr;
	clrscr;
        Row := 1;
        Col := 1;
        EndOfPage := False;
        maxtopics:=0;
        repeat
          Ch := S[Spos];
          if ch='@' then begin
            topics[maxtopics].hlpnr:=ord(s[spos+1])+(ord(s[spos+2]) shl 8);
            spos:=spos+2 end else
{	  if ch='$' then begin
	   inc(spos); l:=ord(s[spos]);
	   s1:=cstr(' ',l);
	   wi(col,Row,attr,s1);
	   Inc(Col,l);
	  end else
}
	  if ch='#' then begin
           inc(spos);
           Ch := S[Spos];
           case Ch of
            ^L, ^Z :         {new page or section}
              EndOfPage := True;
            ^A :begin
		  Attr := HelpIndAttr;
                  inc(MaxTopics);
                  with topics[maxTopics] do begin
		    x:=col+wd[HilfeWindow].x+2;y:=row+wd[HilfeWindow].y+1;l:=1;
                  end;
                end;
            ^B :
	      Attr := HelpIndAAttr;
            ^C :begin
		  Attr := hochattr;
		  with topics[maxTopics] do begin
		    l:=wd[HilfeWindow].x+col+2-x;
		    move(s[spos-l-1],namstr[1],l);
		    namstr[0]:=chr(l);
		  end;
		end;
           end
	  end else begin
            if ch=#13 then begin
                Inc(Row);
                Col := 1;
	      end else begin
		if ch='๘'then ch:=#26;
		s1:=ch;
		wi(col,Row,attr,s1);
		Inc(Col);
	      end;
          end;
          Inc(Spos);
        until EndOfPage;

        {Add prompt for next page}
        if PageNum < MaxPage then begin
	  if not(msg='') then
	    msg := msg+'/';
	  msg := msg+'PgDn';
	end;
	if msg<>'' then msg:='ต '+msg+' ฦ';
        {Display prompt}
	with wd[HilfeWindow] do wia(X+dx-Length(strich)-4, Y+dy+1,hochattr,strich);
	with wd[HilfeWindow] do wia(X+dx-Length(msg)-4, Y+dy+1,hochattr,Msg);
    end;                     {EdDrawFullPage}
var hlpNr:integer;
procedure putbuffer(var s:Stringbuffer;st:string;var len,zz:word);
begin
  if pos('#'+#12,st)=0 then st:=st+#13;
  move(st[1],s[len+1],length(st));
  len:=len+length(st);
  inc(zz);
end;
function seitenlaenge(var zzahl:word):word;
var slaenge,sp1,speicher:word;
begin
  slaenge:=18;
  speicher:=zzahl+(zzahl) div slaenge;
  if speicher mod slaenge <>0 then inc(speicher);
  sp1:=speicher;
  if zzahl>17 then begin
    while (speicher mod slaenge <>0) and (speicher=sp1) do begin
     dec(slaenge);
     speicher:=zzahl+(zzahl) div slaenge;
     if speicher mod slaenge <>0 then inc(speicher);
    end;
    if speicher<>sp1 then inc(slaenge);
  end;
  seitenlaenge:=slaenge;
  zzahl:=sp1;
end;

function ShowTopics:char;
var i:integer;
    ch:char;
begin
  i:=1;hlpnr:=-1;
  repeat
    if maxtopics>0 then
    with topics[i] do EdChangeAttribute(l,y,x,HelpIndaAttr);
    ch:=readkey;
    if keypressed then ch:=readkey;
    if maxtopics>0 then begin
      with topics[i] do EdChangeAttribute(l,y,x,HelpIndAttr);
      case ch of
       cDwn,cRght:begin inc(i);if i>maxtopics then i:=1;end;
	cUp,cLft : begin dec(i);if i<1 then i:=maxtopics;end;
	      #13: begin hlpnr:=Topics[i].hlpnr;lsttopic:=Topics[i].namstr;end;
      end;
    end;
  until ch in [#13,#27,PgDn,PgUp,Home,Ende,f1,AltF1];
  showtopics:=ch;
end;
begin
  zeighilfe:=-1;
  if not(HelpAvail) then begin  Error(50); Exit; end;
  Quitting := False;
  begin
    Seek(Helpf, Cmd*SizeOf(HelpIndexRec));
    BlockRead(Helpf, HelpRec, SizeOf(HelpIndexRec), BytesRead);
    if BytesRead <> SizeOf(HelpIndexRec) then begin Error(51);Exit; end;
    with HelpRec do  begin
      if (Len = 0) or (Start = 00) then begin zeighilfe:=999;exit; end;
      if MemAvail>len then GetMem(SbPtr, Len) else
      begin Error(54); Exit;end;
      Seek(Helpf, Start);
      BlockRead(Helpf, SbPtr^[1], Len, BytesRead);
      if BytesRead <> Len then begin  Error(53); Exit; end;
    end;
  end;
  lsttopic:='';
  if quitting then exit;
  with HelpRec do  begin
    if (TopOfHelp=-1) or (cmd<>HelpStack[TopOfHelp].cmd) then begin
      if TopOfHelp<20 then inc (TopOfHelp) else
      move(HelpStack[1],HelpStack[0],20*sizeof(HelpstackRec));
      HelpStack[TopOfHelp].cmd:=cmd;  HelpStack[TopOfHelp].pagenr:=1;
    end;
    EdBuildPageIndex(SbPtr^, Pages, MaxPage);
{    PageNum := 1;}
    Redraw := True;
    pushwin(HilfeWindow);
    repeat
      {Update the window}
      if Redraw then begin
	EdDrawFullPage( SbPtr^, Pages, PageNum);
	Redraw := False;
      end;
      ch:=showtopics;
      case ch of
   PgUp : if PageNum > 1 then begin
	    Dec(PageNum);
	    Redraw := True;
	  end;
   PgDn : if PageNum < MaxPage then begin
	    Inc(PageNum);
	    Redraw := True;
	  end;
   Home : if PageNum > 1 then begin
	    PageNum := 1;
	    Redraw := True;
	  end;
   Ende : if PageNum < MaxPage then begin
	    PageNum := MaxPage;
	    Redraw := True;
	  end;
 f1,AltF1,#13,#27 :begin
		     Quitting := True;
		     HelpStack[TopOfHelp].PageNr:=PageNum;
		   end;
      end; { case }
    until Quitting;
    popwin(true);
    FreeMem(SbPtr, Len);PageNum:=1;
    case ch of
{
Original
     #13: zeighilfe:=hlpnr;
}
{neu}
     #13: If HlpNr <> -1 Then zeighilfe:=hlpnr Else Begin
            HlpNr := 0;
            ZeigHilfe := HlpNr;
          End;
     F1 : zeighilfe:=0;
  AltF1 : if TopOfHelp>0 then begin
	    dec(TopOfHelp);
	    zeighilfe:=HelpStack[TopOfHelp].cmd;
	    PageNum:=HelpStack[TopOfHelp].PageNr;
	    dec(TopOfHelp);
	  end else zeighilfe:=cmd;
    end;
  end;
end;

procedure hilfe(cmd:integer);
var lastline:integer;
    PageNum,Cursor:word;
begin
 lastline:=AktLastline;
 llin(349);
 PageNum:=1;
 Cursor:=CursAttr;
 EdSetCursor($2020);
 repeat
  cmd:=zeighilfe(cmd,PageNum);
 until cmd=-1;
 EdSetCursor(Cursor);
 llin(lastline);
end;

procedure druckfrage(var ch:char);
begin
  select(33,[f6,f8],ch);
end;
procedure abbruch(var ch:char);
begin
  if keypressed then ch:=readkey;
  if (ch=#0) and keypressed then begin
    ch:=readkey;
    case ch of
      '@': begin error(32);ch:=F6;exit;end;
      'C': begin error(31);llin(30);end;
    end;
	end;ch:=f8;
end;

begin
	AktLastLine:=0;AktHelpNr:=0;
	helpname:=copy(paramstr(0),1,pos('.',paramstr(0)))+'HLP';
	FileMode := 0;
	assign(Helpf,helpname);
 {$i-} reset(Helpf,1);{$i+}
	HelpAvail:= IoResult=0;
end.
