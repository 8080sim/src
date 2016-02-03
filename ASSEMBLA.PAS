unit assembla;
{$i direct.inc}

{$O+,F+,R-}

interface

uses astypdea,asprocs,asedi4,procs;

type
  t_xarr=array[0..3] of byte;

const
  maxif=20;
  tabs:byte=8;

var
  fertig,pass2,ende,ok,keyfound :boolean;
  err             : byte;
  line,prline,maxprline,maxprlength,localcount  : word;
  adresse : longint;
	obj,er,lfi  : TEXT;
  var_n,var_s                              : t_var;
  ifstckptr:integer;
	listaktline,nolist,noctls,noincl,
  nomacs,noconds,nosyms :boolean;
  ifstck:array[0..maxif] of byte;

procedure a_error(err:word;l:integer);

procedure writevars (FName : String);

procedure readsym(Var fname:String);

function getnextline:string;

procedure assem(s:String);

procedure ass_start;

procedure ass_init;

procedure SchreibBuffer;

PROCEDURE SpeichereVariable(x:str30;x0:word;var p:t_var;var h:boolean);

PROCEDURE HoleVariablenWert(x:str30;var x0:word;var p:t_var);

procedure listvars;

implementation

VAR
  laktiv:_lptr;
  mstart,mwork,Maktiv                      : _mptr;
  ps                                       : _pseudo;
  ch                                       : CHAR;
  mne,arg1,arg2,arg3                       : str5;
  checksum,var_typ,incl,rept,seite         : word;
  s                                        : str255;
{  op1,op2                                  : str8;}
  o0,o1,o2,ot,flags,bufferzeiger       	   : byte;
  switch,labell,doppelt,repaktiv,exitm     : boolean;
  eject                                    : boolean;
  zeile                                    : _zeile;
  buffer                                   : _buffer;
  incname :str35;
  fileaktiv                                :text;
  macaktiv :integer;

procedure Entferne_Leerzeichen(var s:string;var j:word);
begin
  while ((s[j]=' ') or (s[j]=#9)) and (j<=length(s)) do inc(j);
end;
procedure replace(vwork:_vptr;var s1:string);
var j,k,l:word;
    t:str80;
begin
  while vwork<>nil do begin
    l:=length(vwork^.name);
    j:=1;
    while j<length(s1) do begin
      t:='';
      Entferne_Leerzeichen(s1,j);
      if (s1[j]=',') then inc(j);
      if j<=length(s1) then begin
        if s1[j]='&' then delete(s1,j,1);
        k:=j;
        if s1[j]='=' then begin t:='=';inc(j) end else
        if s1[j]='+' then begin t:='+';inc(j) end else
        if s1[j]='-' then begin t:='-';inc(j) end else
        if s1[j]='*' then begin t:='*';inc(j) end else
        while  (s1[j] <>' ') and
	  (s1[j] <>',') and
	  (s1[j] <> #9) and
	  (s1[j] <>'=') and
	  (s1[j] <>'+') and
	  (s1[j] <>'-') and
	  (s1[j] <>'*') and
          (s1[j]<>'&') and
	  (j<=length(s1)) do begin
            t:=t+s1[j]; inc(j);
        end;
        if s1[j]='&' then delete(s1,j,1);
        if t=vwork^.name then begin
          delete(s1,k,l);
          insert(vwork^.repl,s1,k);
        end;
      end;
    end;
    vwork:=vwork^.next;
  end;
end;

function getnextline:string;
var
  s:string;

begin
  if macaktiv>0 then begin
    if laktiv<>nil then begin
      s:=laktiv^.s;laktiv:=laktiv^.next;fertig:=false;
      replace(maktiv^.vars,s);replace(maktiv^.locals,s);
    end
    else fertig:=true;
  end
  else if incl>0 then begin
    if not eof(fileaktiv) then readln(fileaktiv,s) else s:='';
  end
  else begin
    s:=geteditor(fertig,1);
    inc(line);
  end;
  getnextline:=s;
end;

procedure seterr(errnr:byte);
begin
  if (err=0) or (err=16) then err:=errnr;
end;

procedure SchreibBuffer;
var
  i:word;
  s:str80;

begin
  if bufferzeiger>0 then begin
    buffer.null:=0;
    buffer.anzahl:=BufferZeiger;
    checksum:=checksum+BufferZeiger;
    s:=':';
    for i:=1 to bufferzeiger+4 do s:=s+hex(buffer.schreib[i]);
    s:=s+hex(lo(256-lo(checksum)));
    writeln(obj,s);
    bufferzeiger:=0;
  end;
end;

procedure putbyte(b:byte;var i:Word);
begin
  if pass2 then begin
    if BufferZeiger=0 then begin
      buffer.adresse:=swap(i);
      checksum:=lo(i)+hi(i);
    end;
    buffer.daten[BufferZeiger]:=b;checksum:=checksum+b;
    inc(BufferZeiger);
    if bufferzeiger=32 then SchreibBuffer;
  end;
  inc(i);
end;

PROCEDURE search(x:str35;x0,x1,x2,xt:byte;var p:t_sp;var h:boolean);
var
  p1,p2 : t_sp;

begin
  if p=nil then begin
    new(p);h:=true;
    with p^ do begin
      opc:=x;o0:=x0;o1:=x1;o2:=x2;t:=xt;
      links:=nil;rechts:=nil;bal:=0;
    end
  end
  else if x < p^.opc then begin
    search(x,x0,x1,x2,xt,p^.links,h);
    if h then case p^.bal of
      1: begin
	   p^.bal:=0;h:=false;
	 end;
      0: p^.bal:=-1;
     -1: begin
           p1:=p^.links;
	   if p1^.bal=-1 then begin
	     p^.links:=p1^.rechts;p1^.rechts:=p;
	     p^.bal:=0;p:=p1;
	   end
           else begin
	     p2:=p1^.rechts;
	     p1^.rechts:=p2^.links;p2^.links:=p1;
	     p^.links:=p2^.rechts;p2^.rechts:=p;
	     if p2^.bal=-1 then p^.bal:=+1 else p^.bal:=0;
	     if p2^.bal=+1 then p1^.bal:=-1 else p1^.bal:=0;
	     p:=p2;
	   end;
	   p^.bal:=0;h:=false;
         end
       end
     end
     else if x>p^.opc then begin
       search(x,x0,x1,x2,xt,p^.rechts,h);
       if h then case p^.bal of
         -1: begin
	       p^.bal:=0;h:=false;
	     end;
          0: p^.bal:=+1;
         +1: begin
	       p1:=p^.rechts;
	       if p1^.bal=+1 then begin
	         p^.rechts:=p1^.links;p1^.links:=p;
	         p^.bal:=0;p:=p1;
	       end else begin
	         p2:=p1^.links;
	         p1^.links:=p2^.rechts;p2^.rechts:=p1;
	         p^.rechts:=p2^.links;p2^.links:=p;
	         if p2^.bal=+1 then p^.bal:=-1 else p^.bal:=0;
	         if p2^.bal=-1 then p1^.bal:=+1 else p1^.bal:=0;
	         p:=p2;
               end;
	       p^.bal:=0;h:=false;
             end
       end
  end
  else h:=false;
end;

PROCEDURE SpeichereVariable(x:str30;x0:word;var p:t_var;var h:boolean);
var p1,p2:t_var;
begin
  doppelt:=false;
  if p=nil then
  begin
    new(p);h:=true;
    with p^ do begin
      name:=x;adresse:=x0;
      if labell Then var_typ:=3;typ:=var_typ;
      links:=nil;rechts:=nil;bal:=0;
    end
  end else
  if x<p^.name then begin
    SpeichereVariable(x,x0,p^.links,h);
    if h then case p^.bal of
      1: begin
	  p^.bal:=0;h:=false;
	 end;
      0: p^.bal:=-1;
     -1: begin
	  p1:=p^.links;
	  if p1^.bal=-1 then begin
	    p^.links:=p1^.rechts;p1^.rechts:=p;
	    p^.bal:=0;p:=p1;
	 end else begin
	   p2:=p1^.rechts;
	   p1^.rechts:=p2^.links;p2^.links:=p1;
	   p^.links:=p2^.rechts;p2^.rechts:=p;
	   if p2^.bal=-1 then p^.bal:=+1 else p^.bal:=0;
	   if p2^.bal=+1 then p1^.bal:=-1 else p1^.bal:=0;
	   p:=p2;
	 end;
	 p^.bal:=0;h:=false;
       end
     end
  end else if x>p^.name then begin
   SpeichereVariable(x,x0,p^.rechts,h);
   if h then
    case p^.bal of
     -1: begin
	  p^.bal:=0;h:=false;
	 end;
      0: p^.bal:=+1;
     +1: begin
	  p1:=p^.rechts;
	  if p1^.bal=+1 then begin
	    p^.rechts:=p1^.links;p1^.links:=p;
	    p^.bal:=0;p:=p1;
	 end else begin
	   p2:=p1^.links;
	   p1^.links:=p2^.rechts;p2^.rechts:=p1;
	   p^.rechts:=p2^.links;p2^.links:=p;
	   if p2^.bal=+1 then p^.bal:=-1 else p^.bal:=0;
	   if p2^.bal=-1 then p1^.bal:=+1 else p1^.bal:=0;
	   p:=p2;
	 end;
	 p^.bal:=0;h:=false;
       end
     end
   end else begin h:=false;doppelt:=true end;
end;

procedure readsym(Var fname:String);
var
  sym:text;
  ad:str8;
  na :str30;
  s:str80;
  i:word;
  h:boolean;
  x:longint;

begin
 assign(sym,fname);
 {$i-} reset(sym);{$i+};
 if ioresult=0  then begin
   while not eof(sym) do begin
      readln(sym,s);
      i:=pos(' ',s);
      ad:=copy(s,1,i-1);na:=copy(s,i+1,80);
      h:=false;x:=hexdez(ad,i);
      SpeichereVariable(na,x,var_s,h);
    end;
    close(sym);
 end;
end;

PROCEDURE find(x:str8;var x0,x1,x2,xt:byte;var p:t_sp);
begin
  keyfound:=false;
  while (p<>nil) and not keyfound do begin
    if p^.opc=x then with p^ do begin
      keyfound:=true;
      x0:=o0;x1:=o1;x2:=o2;xt:=t;
    end else
    if x<p^.opc then p:=p^.links else p:=p^.rechts;
  end;
end;

function macrofind(var p:_mptr;x:str35):boolean;
var found:boolean;
begin
 p:=mstart;found:=false;
 while (p<>nil) and not found do begin
   found:=x=p^.name;
   if not found then p:=p^.next;
 end;
 macrofind:=found;
end;

PROCEDURE HoleVariablenWert(x:str30;var x0:word;var p:t_var);
begin
  ok:=false ;
  while (p<>nil) and  not ok do begin
    if p^.name=x then begin
      ok:=true;x0:=p^.adresse;
      end else
    if x<p^.name then p:=p^.links else p:=p^.rechts;
  end;
end;

PROCEDURE SpeichereVariablenWert(x:str30;var x0:word; p:t_var);
begin
  ok:=false;
  if (x[1]>='0') and (x[1]<='9') then begin seterr(7);exit end;
  while (p<>nil) and  not ok do begin
    if p^.name=x then     with p^ do begin
      ok:=true;
      adresse:=x0;
      if labell Then var_typ:=3;typ:=var_typ;
    end else
    if x<p^.name then p:=p^.links else p:=p^.rechts;
  end;
end;

procedure ass_init;
var
  o0,o1,o2:byte;
  h:booleaN;
  ps:_pseudo;
begin
  sp:=nil;
  o2:=0;
    for o1:=0 to 7  do
    for o0:=0 to 7 do begin
      h:=false;
      search(opc0[o0,o1],o0,o1,o2,opt0[o0,o1],sp,h);
    end;
    h:=false;
    search('MOV',0,0,1,7,sp,h);
    h:=false;
    search('HLT',6,6,1,1,sp,h);
   o2:=2;
   for o1:=0 to 7 do begin
     h:=false;
     search(opc2[o1],o0,o1,o2,5,sp,h);
   end;
   o2:=3;
   for o1:=0 to 7  do
   for o0:=0 to 7 do  begin
     h:=false;
     search(opc3[o0,o1],o0,o1,o2,opt3[o0,o1],sp,h);
   end;
  for ps:=flist to fsymbol do begin
   h:=false;
   search(ptext[ps],ord(ps),0,0,$80,sp,h);
  end;
  sp_start:=sp;
end;

procedure printline;

var s:string;
{Original ? Was soll das hier ?
label exit1;
}
procedure Titel;
begin
	Writeln(lfi,'8085-Assembler | ',Programmversion,',',TitelZeile,
	'| (c) W. Marquart, Vogelsberg / M.Flume, W-tal | ',
	tagesdatum(getdate));
{

	Writeln(lfi,'8085-Assembler | ',
			Programmversion,', 1990/95 | Gewerbl. Schulen I, W-tal  | (c) W. Marquart, Vogelsberg / M.Flume, W-tal | ',

			Programmversion,', 1990/95 | Schule fr E-Technik, Essen | (c) W.Marquart, Vogelsberg / M.Flume, W-tal | ',
	tagesdatum(getdate));
}
	writeln(lfi,astitel,'':maxprlength-length(astitel)-5,'Seite ',Seite:2);
	writeln(lfi);
	prline:=3;inc(seite);
end;

begin
	if Not DoLST or not pass2 or nolist or (not listaktline AND NOCONDS ) then exit;
	if eject then begin
		writeln(lfi,#12);eject:=false; titel;
	end;
	if (ps<=fnosyms) and noctls then exit;
	if (ifstckptr>0) and (ifstck[ifstckptr]<>1) and noconds then exit;
	if (repaktiv or (rept>0) or (macaktiv>0)) and  (nomacs or
		( (ps<>fmnemo) and (ps<>fdb) and (ps<>fdw) and (ps<>fdd))) and (err=0) then exit;
	if (incl>0) and noincl then exit;
	if seite=1 then titel;
	if length(zeile.ausd)<=maxprlength then writeln(lfi,zeile.ausd)
	else begin
    writeln(lfi,copy(zeile.ausd,1,maxprlength));
    writeln(lfi,cstr(' ',21),copy(zeile.ausd,maxprlength+1,255));
    inc(prline);
  end;
  inc(prline);
  if prline>maxprline then eject:=true;
end;

procedure a_error;
begin
  if ifstck[ifstckptr]<>1 then exit;
  If DoLST Then Begin
    writeln(lfi,erm[err],' in Zeile ',line:5);inc(prline);
  End;
  if prline>maxprline then eject:=true;
  writeln(erm[err]);
  if incl>0 then write('Include-File: ',incname);
  writeln(' in Zeile ',line);
	if err<>15 then inc(fehler);
	if (fehler<=maxfehler) and (incl=0) and not repaktiv then begin
		inc(lfehler);
		if edbufpos>1 then errata[lfehler].errpos:=edbufpos-2-l else
		errata[lfehler].errpos:=0;
		errata[lfehler].err:=err;
  end;
end;

procedure assem(s:String);
var
  op1,op2                                  :str80;
  o0,o1,o2,ot,reg1,reg2,by                 :byte;
  j,oz,zaehler                             :word;
  x                                        :longint;
  asci,found                               :boolean;
  vrs                                      :t_var;
  name                                     :str30;
  z,fptr,oldptr                            :_lptr;


function Naechstes_Word(var s:string;var j:word):str80;
var t:str80;
    klammer:boolean;
begin
  t:='';
  Entferne_Leerzeichen(s,j);
  if j<=length(s) then begin
  if (s[j]='=') then begin
     Naechstes_Word:=s[j];inc(j);exit
  end;
  klammer:=s[j]='<';
  if klammer then inc(j);
  while  ((not klammer and
         (s[j] <>' ') and
	 (s[j] <>',') and
	 (s[j] <>#9) and
	 (s[j] <>'=')) or
         ( klammer
          and (s[j]<>'>')))
         and
	 (j<=length(s)) do begin
           t:=t+s[j]; inc(j);
         end;
  if klammer then inc(j);
  end;
  Naechstes_Word:=t;
end;

procedure controlrep(var s:string;var tiefe:word);
var nw:str35;
    k:word;
begin
  k:=1;nw:=naechstes_word(s,k);
  if nw='ENDM' then dec(tiefe);
  if (nw='REPT') or (nw='IRP') or (nw='IRPC') then inc(tiefe);
end;

FUNCTION SucheRegister(var r:BYTE):BOOLEAN;
const regnamen='BCDEHLMA';
var t:str80;

begin
  t:=Naechstes_Word(s,j);
  if length(t)<>1 then r:=9 else r:=pos(t,regnamen)-1;
  SucheRegister:=r<=8;
end;

function SucheRegisterpaar(var r:byte):boolean;
const
 reg_paar_namen='BDHPSWSP';
var
  ok:boolean;
  t:str80;
begin
  t:=Naechstes_Word(s,j);
  if length(t)=0 then r:=14 else r:=pos(t,reg_paar_namen);
  if r>0 then dec(r) else r:=14;
  ok:=((r in [0,1,2]) AND (length(t)=1)) or ((r=3) and (length(t)=3)) or ((r=6) and (length(t)=2));
  if r=3 then ok:=ok and not((o2=0) and(o0 in [1,3]));
  if r=6 then ok:=ok and ((o2=0) and (o0 in [1,3]));
  if r>3 then r:=3;
  SucheRegisterpaar:=ok;
end;

function getkomma(var s:string;var j:word):boolean;
begin
  Entferne_Leerzeichen(s,j);
  getkomma:=(s[j]=',') and (j<length(s));inc(j);
end;

function getzahl(var x:byte):boolean;
var ok:boolean;
begin
  Entferne_Leerzeichen(s,j);
  ok:=(j<=length(s)) and (s[j] in ['0' ..'7']);
   if ok then X:=ORD(S[j])-ORD('0');
   getzahl:=ok; inc(j);
end;


PROCEDURE evaluate(VAR expr: str80; VAR value: longint);
 CONST
  delim=[' ',',',')','(','+','-','*','/','^'];
VAR
  pos: word;
  ch: char;

PROCEDURE nextchar;
BEGIN
  REPEAT
    inc(pos);
    IF pos<=length(expr) THEN
    ch:=expr[pos] ELSE
    ch:=#0;
  UNTIL (ch<>' ') or asci;
END;

function orlogik:longint;
var o:longint;

function andlogik:longint;
var a:longint;

function notlogik:longint;

function vergleich:longint;

FUNCTION expression: longint;
VAR
  e: longint;
  opr: char;

FUNCTION simexpr: longint;
TYPE
  stdf = (fmul,fdiv,fmod,fshl,fshr);
  stdflist = ARRAY[stdf] OF STRING[3];

CONST
  stdfun: stdflist = ('*','/','MOD','SHL','SHR');
VAR
  s: longint;
  opr: char;
  found: boolean;
  sf: stdf;
  sl:byte;

FUNCTION term: longint;
VAR
  t: longint;

FUNCTION signedfactor: longint;

function hilow:longint;

FUNCTION factor: longint;
VAR
  p,e,sl,x: word;
  f: longint;
  tt:str80;

BEGIN
  IF (ch>='0') and (ch<='9') THEN BEGIN
    p:=pos;
    REPEAT
       inc(pos);ch:=expr[pos]
    UNTIL (ch IN delim) or (pos>length(expr));
    if pos>length(expr) then ch:=#0;
    tt:=copy(expr,p,pos-p);if ch=' ' then nextchar;
    case tt[length(tt)] of
      'H':begin ;f:=hexdez(copy(tt,1,length(tt)-1),e); end;
      'B':begin ;f:=bindez(copy(tt,1,length(tt)-1),e); end;
      else  val(tt,f,e);
    end;
    IF e<>0 THEN begin ok:=false;seterr(6);end;
  END ELSE
  if ch='('then begin
    nextchar;f:=orlogik;
    if ch=')' then nextchar else begin ok:=false;seterr(12); end;
  end else
  if cap(ch) in ['A'..'Z','_','?'] then begin
    p:=pos;
    repeat inc(pos);ch:=expr[pos] until not(cap(ch) in ['0'..'9','A'..'Z','_','?']) or (pos>length(expr));
    if pos>length(expr) then ch:=#0;
    tt:=copy(expr,p,pos-p);if ch=' ' then nextchar;
    var_n:=var_s;HoleVariablenWert(tt,x,var_n);
    if not pass2 then begin
     if ((ps>=frept) and (ps<=forg)) and not ok then seterr(17) else
     ok:=true end else if not ok then seterr(13);
    f:=x;
  END ELSE
   if ch='$' then begin f:=adresse;nextchar;end
   ELSE  if ch=#39 then begin
     asci:=true;
     nextchar;f:=ord(ch);nextchar;
     while (ch<>#39) and (ch<>#0) do begin
       f:=f shl 8 + ord(ch);nextchar;
     end;asci:=false;nextchar;
    end
   else ok:=false;;
  factor:=f;
END {factor};

TYPE
  stdf = (fhigh,flow);
  stdflist = ARRAY[stdf] OF STRING[4];

CONST
  stdfun: stdflist = ('HIGH','LOW');

VAR
  found: boolean;
  sf: stdf;
  sl:byte;

begin {hilow}
   found:=false;sf:=fhigh;
   repeat
     sl:=Length(StdFun[sf]);
     if (copy(expr,Pos,sl)=StdFun[sf]) AND (EXPR[pos+sl] in delim) then
     begin
       Pos:=Pos+sl-1; NextChar;
       CASE sf OF
         fhigh: hilow:=Hi(factor);
	 flow : hilow:=Lo(factor);
       END;
       found:=true;
     end;
     inc(sf);
   until found or (sf>flow);
   if not found then hilow:=factor;
end; {hilow}

BEGIN {signedfactor}
  IF ch='-' THEN BEGIN
    nextchar; signedfactor:=-hilow;
  END ELSE
  if ch='+' then begin
    nextchar;signedfactor:=hilow;
  end else signedfactor:=hilow;
END {signedfactor};

BEGIN {term}
  t:=signedfactor;
  if ch='^'then begin
   nextchar;t:=trunc(exp(ln(t)*signedfactor));
  end;
  term:=t;
END {term};

BEGIN {simexpr}
  s:=term;
  repeat
   found:=false;
   for sf:=fmul to fshr do if not found then
   begin
     sl:=Length(StdFun[sf]);
     if (copy(expr,Pos,sl)=StdFun[sf])  AND ((sl=1) or (EXPR[pos+sl] in delim)) then
     begin
       Pos:=Pos+sl-1; NextChar;
       CASE sf OF
         fmul: s:=s*term;
	 fdiv: s:=s div term;
	 fmod: s:=s mod term;
	 fshl: s:=s shl term;
	 fshr: s:=s shr term;
       END;
       found:=true;
     END;
   end;
 until not found;
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
TYPE
  stdf = (fEq,fge,fgt,fLe,flt,fne);
  stdflist = ARRAY[stdf] OF STRING[2];

CONST
  stdfun: stdflist = ('EQ','GE','GT','LE','LT','NE');
  var
   v:longint;
   found:boolean;
   sf:stdf;
   sl:integer;
begin {Vergleich}
  v:=expression;
  repeat
   found:=false;
   for sf:=feq to fne do if not found then
   begin
     sl:=Length(StdFun[sf]);
     if (copy(expr,Pos,sl)=StdFun[sf]) AND (EXPR[pos+sl] in delim)  then
     begin
       Pos:=Pos+sl-1; NextChar;
       CASE sf OF
         feq: v :=-longint(V = expression);
         fGe: v :=-longint(V >= expression);
         fGT: v :=-longint(V > expression);
         fLE: v :=-longint(V <= expression);
         fLT: v :=-longint(V < expression);
         fNE: v :=-longint(V <> expression);
       END;
       found:=true;
     END;
   end;
 until not found;
 Vergleich:=v;
end; {Vergleich}

begin {notlogik}
  IF (copy(expr,pos,3)='NOT') AND (EXPR[pos+3] in delim)  THEN
  BEGIN
    pos:=pos+2;
    nextchar; notlogik:= not vergleich;
  END ELSE
  notlogik:=vergleich;
end; {notlogik}

begin {andlogik}
  a:=notlogik;
 while (copy(expr,pos,3)='AND') AND (EXPR[pos+3] in delim)  do begin
   pos:=pos +2;nextchar;
   a:=a and notlogik;
 end;
 andlogik:=a;
end; {andlogik}

type
   sorf = (f_or,f_xor);
   sorflist = ARRAY[sorf] OF STRING[3];

CONST
  sorfun: sorflist = ('OR','XOR');
  var orfound:boolean;
       orf:sorf;
       so:integer;

Begin {Orlogik}
  o:=andlogik;
  repeat
   orfound:=false;
   for orf:=f_or to f_xor do if not orfound then
   begin
     so:=Length(SorFun[orf]);
     if (copy(expr,Pos,so)=SorFun[orf])  AND (EXPR[pos+so] in delim)  then
     begin
       Pos:=Pos+so-1; NextChar;
       CASE orf OF
         f_or: o:=o or andlogik;
	 f_xor: o:=o xor andlogik;
       END;
       orfound:=true;
     END;
   end;
 until not orfound;
 orlogik:=o;
end;{orLogig}

BEGIN {evaluate}
  pos:=0; nextchar;ok:=true;
  value:=orlogik;
  if pos<=length(expr) then begin
    ok:=false;
    seterr(9);
  end;
END {evaluate};

function konst(var x:longint):boolean;

VAR
  e: word;
  r: longint;
  ss: str80;


BEGIN {calculator}
   Entferne_Leerzeichen(s,j);
   ss:='';
   while (s[j] <> ',') and (j<=length(s)) do begin
    ss:=ss+s[j];inc(j);
   end;
   if ss='' then seterr(19) else evaluate(ss,r);
{
   if ((r>65535) or (r<-32768)) and ok then begin seterr(11);ok:=false end
     else if r<0 then r:=65536 + r;
}
   if ok then X:=R else x:=0; konst:=ok;
END {calculator};

FUNCTION GetByte(VAR X:BYTE):BOOLEAN;
VAR b:longint;
    a:integer absolute b;
 dummy:boolean;
BEGIN
  if not asci then Entferne_Leerzeichen(s,j);
    getbyte:=konst(b);
  if pass2 then begin
    X:=LO(A);if (a>255) or (a<-128) then seterr(11);
  end else begin
    getbyte:=true;x:=0;
  end;
END;

FUNCTION GetdB(VAR X,count:BYTE):BOOLEAN;
VAR A:longint;
 dummy:boolean;
BEGIN
  count:=1;
  if not asci then Entferne_Leerzeichen(s,j);
  if s[j]=#39 then begin
    asci:=not asci;count:=0;inc(j);
    exit;
  end;
  if asci then begin
       GetdB:=(j<length(s));x:=ord(s[j]);inc(j);
    end else
   begin GetdB:=KONST(A) and (hi(a)=0); X:=LO(A);end;
END;

function GetTwoBytes(var x,y:BYTE):boolean;
var
  A:longint;
begin
  GetTwoBytes:=konst(A);
  if (a>65535) or (a<-32768) then seterr(11);

  Y:=HI(A);X:=LO(A);
  if not pass2 then begin
  GettwoBytes:=true;x:=0;y:=0;
  end;
end;

function GetFourBytes(var x:t_xarr):boolean;
var
  A:longint absolute x;
begin
  GetfourBytes:=konst(A);
  if not pass2 then begin GetfourBytes:=true;fillchar(x,sizeof(x),0);end;
end;

procedure VariablenSuche(var name:str30);
var
   h:boolean;
begin
  if pos(':',name)=length(name) then begin labell:=true;
    dec(name[0]);
  end else labell:=false;
  if name>'' then begin
    h:=false;var_n:=var_s;
    if not pass2   then SpeichereVariable(name,adresse,var_s,h)
    else if labell then SpeichereVariablenWert(name,word(adresse),var_n);
  end;
end;

procedure putadresse(x:word);
var
  xx:str4;
begin
  xx:=hex(hi(x))+hex(lo(x));
  move(xx[1],zeile.adr[1],4);
end;

procedure putoz(b:byte);
var xx:str2;
begin
  xx:=hex(b);
  move(xx[1],zeile.opcode[oz],2);oz:=oz+3;
end;

procedure  processreptline(var s:string;ps:_pseudo;var x:word;var rptr:_lptr;var j:word);
var repl:string;
    i:integer;
    lptr:_lptr;
   xx:longint;

begin
   case ps of
    frept:begin
            ok:=konst(xx);
            x:=word(xx);
            rptr:=nil;
          end;
    firpc:begin
           new(rptr);rptr^.s:=Naechstes_word(s,j);
            if not getkomma(s,j) then seterr(18);
            repl:=naechstes_word(s,j);rptr^.next:=nil;
             x:=length(repl);lptr:=rptr;
            for i:=1 to x do begin
              new(lptr^.next);lptr:=lptr^.next;
              lptr^.s:=repl[i];
            end;
            lptr^.next:=nil;
           end;
    firp:begin
           new(rptr);rptr^.s:=Naechstes_word(s,j);
            if not getkomma(s,j) then seterr(18);
            rptr^.next:=nil;
            x:=0;lptr:=rptr;
            repeat
              new(lptr^.next);lptr:=lptr^.next;inc(x);
              lptr^.s:=naechstes_word(s,j);
            until not getkomma(s,j);
            lptr^.next:=nil;
           end;
    end;
end;

procedure machrep(var z:_lptr;x:word;saveps:_pseudo;repl:_lptr);
var  i,y:word;
     ss:str80;
     fptr,rptr:_lptr;
     ch:char;
     op1:str35;

procedure replace(op1:str35;ch:str35);
var k:integer;
    ampersand:boolean;
begin
      k:=pos(op1,s);
      ampersand:=(k>1) and (s[pred(k)]='&');
      if k>0 then begin
	if (k=1) or (s[pred(k)] in [',',' ','&']) then begin
	  delete(s,k,length(op1));
	  insert(ch,s,k);
        end;
	if ampersand then delete(s,pred(k),1);
      end;
end;

begin
  fptr:=z;
  if repl<>nil then op1:=repl^.s;
  i:=1;
  while (i<=x) and not exitm do begin
    z:=fptr;inc(i);
    j:=1;s:=z^.s;
    if repl<>nil then repl:=repl^.next;
    ss:=Naechstes_Word(s,j);
    while (z<>nil) and (ss<>'ENDM') and not exitm do begin
      j:=1;s:=z^.s;
     if repl<>nil then replace(op1,repl^.s);
      ss:=Naechstes_Word(s,j);
      exitm:=(ss='EXITM') and (ifstck[ifstckptr]=1);
      if not exitm then begin
        sp:=sp_start;
        find(ss,o0,o1,o2,ot,sp);
        if ot and $80=$80 then ps:=_pseudo(o0) else ps:=fmnemo;
        if (ps=frept) or (ps=firp) or (ps=firpc) then begin
          processreptline(s,ps,y,rptr,j);
          if ok then begin
	    z:=z^.next; machrep(z,y,ps,rptr);
            j:=1;s:=z^.s;
            ss:=Naechstes_Word(s,j);
          end else begin
            fillchar(zeile.ausd[1],80,#32);
            move(s[1],zeile.label1,length(s));
            zeile.l:=length(s)+21;
            exit
          end;
        end;
        if ss<>'ENDM' then assem(s);
        z:=z^.next;
        if z<>nil then begin
          j:=1;
          s:=z^.s;
         ss:=Naechstes_Word(s,j);
       end;
     end;
   end;
  end;
end;

procedure neuzeile(l:integer);
begin
  fillchar(zeile.ausd[1],80,#32);
  zeile.l:=l+21;
  if repaktiv then zeile.info[3]:='R';
  if macaktiv>0 then zeile.info[2]:='M';
  if incl>0 then zeile.info[1]:='I';
end;

procedure newline(l:integer);
begin
  printline;neuzeile(l);
  oz:=1;
end;

procedure liesrept;
begin
  z^.next:=nil;
  z^.s:=getnextline;
  while pos(#9,z^.s)>0 do z^.s[pos(#9,z^.s)]:=' ';
  z^.s:=caps(z^.s);
  controlrep(z^.s,rept);
  if pass2 then begin
    neuzeile(length(z^.s));
    move(z^.s[1],zeile.label1,length(z^.s));
    printline;
  end;
end;

procedure include(fname:str35);
var t,ts:text;
    e:integer;
    s:string;
   oldline:word;

begin
 assign(t,fname);
 {$i-}reset(t);{$i+};
 e:=ioresult;
 if e=0 then begin
   if incl>0 then move(fileaktiv,ts,sizeof(ts));
   move(t,fileaktiv,sizeof(t));
   inc(incl);oldline:=line;line:=0;
   while not eof(fileaktiv) do begin
     readln(fileaktiv,s);inc(line);
     assem(s);
   end;
   dec(incl);close(fileaktiv);err:=0;line:=oldline;
   if incl>0 then move(ts,fileaktiv,sizeof(ts));
  end else if (e=4) then err:= 21 else err:=20;
end;

var xx:integer;
    xarr:t_xarr;
    linlen:integer;

procedure processif;
var
  egal:boolean;
  x:longint;
  y:word;

begin
  if ifstckptr=maxif then err:=23 else begin
    listaktline:=false;
    inc(ifstckptr);if ifstck[ifstckptr-1]<>1 then begin
      ifstck[ifstckptr]:=2;
      exit end else   ifstck[ifstckptr]:=0;
    case ps of
    fif :begin
           egal:=Konst(x);
           if x<>0 then ifstck[ifstckptr]:=1;
         end;
    fife :begin
           egal:=Konst(x);
           if x=0 then ifstck[ifstckptr]:=1;
         end;
 fifdef,
 fifndef:begin
          op1:=Naechstes_word(s,j);
          HoleVariablenWert(op1,y,var_n);
          ok:=ok xor (ps=fifndef);
          ifstck[ifstckptr]:=byte(ok) and 1;
        end;
 fifb:begin
          op1:=Naechstes_word(s,j);
          ifstck[ifstckptr]:=byte(op1='') and 1;
        end;
 fifnb:begin
          op1:=Naechstes_word(s,j);
          ifstck[ifstckptr]:=byte(op1<>'') and 1;
        end;
 fifdif:begin
          op1:=Naechstes_word(s,j);
	  if not getkomma(s,j) then seterr(18);
          ifstck[ifstckptr]:=byte(op1<>naechstes_word(s,j)) and 1;
        end;
 fifidn:begin
          op1:=Naechstes_word(s,j);
	  if not getkomma(s,j) then seterr(18);
	  ifstck[ifstckptr]:=byte(op1=naechstes_word(s,j)) and 1;
        end;
    end;
  end;
end;

procedure processEndIf;
begin
  if ifstckptr=0 then err:=22 else begin
    dec(ifstckptr);
    listaktline:=false;
  end;
end;

procedure processElse;
begin
  if ifstckptr=0 then err:=23 else begin
    if ifstck[ifstckptr]>0 then ifstck[ifstckptr]:=2 else ifstck[ifstckptr]:=1;
    listaktline:=false;
  end;
end;

procedure processElseIf;
var egal:boolean;
    x:longint;
begin
  if ifstckptr=0 then err:=23 else
  begin
    if ifstck[ifstckptr]>0 then ifstck[ifstckptr]:=2 else begin
     egal:=Konst(x);
     ifstck[ifstckptr]:=x and 1;
     listaktline:=false;
    end;
  end;
end;

procedure processmacro;
var vwork,lwork:_vptr;
    lptr:_lptr;
        s1:string;

   tiefe:word;
        h:boolean;
var jj:word;

procedure schreibptr;
begin
  lwork^.next:=nil;
  lwork^.name:=naechstes_word(s1,jj);
end;

procedure processlocals;
begin
  if mwork^.locals=nil then begin
    new(mwork^.locals);lwork:=mwork^.locals;
  end else begin
    new(lwork^.next);lwork:= lwork^.next;
  end;
  schreibptr;
  while getkomma(s1,jj) do begin
    new(lwork^.next);lwork:= lwork^.next;
    schreibptr;
  end;
end;

procedure getnext;
var lok:boolean;
    nw:str35;
begin
  lok:=false;
  repeat
    s1:=getnextline;
    while pos(#9,s1)>0 do s1[pos(#9,s1)]:=' ';
    s1:=caps(s1);
    jj:=1;
    nw:=naechstes_word(s1,jj);
    if not pass2 then begin
      lok:=nw='LOCALS';
      if lok then processlocals;
    end;
   until not lok;
  controlrep(s1,tiefe);
end;

begin
   if pass2 then begin
     tiefe:=1;
     repeat
       getnext;
       newline(length(s1));
       move(s1[1],zeile.label1,length(s1));
     until (tiefe=0) or fertig;
     newline(length(s1));listaktline:=false;j:=length(s);
     if (tiefe>0) then err:=14;
     exit;
   end;
   var_typ:=6;name:=naechstes_word(s,j);
{
  speicherevariable(name,word(adresse),var_s);
}
  if mstart=nil then begin
    new(mstart);
    mwork:=mstart
  end else begin
    mwork:=mstart;
    while mwork^.next<>nil do mwork:=mwork^.next;
    new(mwork^.next);mwork:=mwork^.next;
  end;
  mwork^.next:=nil;mwork^.vars:=nil;
  mwork^.locals:=nil;lwork:=nil;
  mwork^.name:=name;
  op1:=Naechstes_Word(s,j);
  if op1>'' then begin
    new(mwork^.vars);vwork:=mwork^.vars;
    vwork^.name:=op1;
    vwork^.next:=nil;
    while getkomma(s,j) do begin
      op1:=Naechstes_Word(s,j);
      new(vwork^.next);vwork:=vwork^.next;
      vwork^.name:=op1;
      vwork^.next:=nil;
    end;
  end;
  tiefe:=1; getnext;
  if tiefe>0 then begin
    new(mwork^.lines);lptr:=mwork^.lines;
    lptr^.s:=s1;
    lptr^.next:=nil;
  end;
  while (tiefe>0) and not fertig do begin
    getnext;
    if tiefe>0  then begin
      new(lptr^.next);lptr:=lptr^.next;
      lptr^.s:=s1;
      lptr^.next:=nil;
    end;
  end;
end;

procedure macro(mwork:_mptr);
var stckstart,i,k:integer;
    tiefe:word;
    name:str35;
    s1:string;
    gefunden:boolean;
    vwork:_vptr;
    lwork:_lptr;

procedure getnext;
begin
  s1:=getnextline;
  s1:=caps(s1);
  controlrep(s1,tiefe);
end;

procedure putrepl;
var x:longint;
begin
  if (length(op1)>1) and (op1[1]='%') then begin
    delete(op1,1,1);
    evaluate(op1,x);
    str(x,op1);
  end;
  vwork^.repl:=op1;
  vwork:=vwork^.next;
end;

begin
  exitm:=false;
  if pass2 then if (macaktiv=0) or not nomacs then printline;
  inc(macaktiv);
  op1:=naechstes_Word(s,j);
  vwork:=mwork^.vars;
  if vwork<>nil then putrepl;
  while getkomma(s,j) and (vwork<>nil) do begin
    op1:=Naechstes_Word(s,j);
    putrepl;
  end;
  while (vwork<>nil) do begin
    vwork^.repl:='';
    vwork:=vwork^.next;
  end;
  vwork:=mwork^.locals;
  while vwork<>nil do begin
    vwork^.repl:='??'+hex(hi(localcount))+hex(lo(localcount));
    vwork:=vwork^.next;
    inc(localcount);
  end;
  lwork:=mwork^.lines;tiefe:=0;
  stckstart:=ifstckptr;
  while (lwork<>nil) and not exitm do begin
    s1:=lwork^.s;
    lwork:=lwork^.next;
    vwork:=mwork^.vars;
    replace(mwork^.vars,s1);
    replace(mwork^.locals,s1);
    maktiv:=mwork;
    laktiv:=lwork;
    if tiefe=0 then assem(s1);
    controlrep(s1,tiefe);
  end;
  if exitm then ifstckptr:=stckstart;
  dec(macaktiv);listaktline:=false;j:=length(s);
  exitm:=false;
end;

procedure keywordsuche;
begin
  if macrofind(mwork,op1) then begin
    keyfound:=true;ot:=$80;o0:=ord(fmac);
  end else begin
    sp:=sp_start;
    find(op1,o0,o1,o2,ot,sp);
  end;
end;

procedure formatlist;
var stab:string;
    tp,x:byte;

begin
  stab:=s;
  tp:=pos(#9,stab);
  while tp>0 do begin
    delete(stab,tp,1);
    x:=tabs- tp mod tabs;
    insert(cstr(' ',x),stab,tp);
  tp:=pos(#9,stab);
  end;
  neuzeile(length(stab)-1);
  move(stab[1],zeile.label1,length(stab));
end;

var rptr:_lptr;
    dummy:pointer;

begin
 if pass2 then formatlist;
  j:=1;linlen:=length(s);
  IF POS(';',S)>0 THEN  S:=COPY(S,1,POS(';',S)-1);
  While POS(#9,S)>0 do  S[POS(#9,S)]:=' ';
  While S[LENGTH(S)]=' ' do  DEC(S[0]);
  s:=caps(s);
  err:=0;oz:=1;rept:=0;listaktline:=true;
  doppelt:=false;
  op1:=Naechstes_Word(s,j);
  if op1[1]='.' then op1[1]:='%';
  keywordsuche;
  if not keyfound and (ifstck[ifstckptr]=1) then begin
     name:=op1;VariablenSuche(name);end else name:='';
  IF (j<length(S)) or keyfound THEN BEGIN
    if not keyfound then begin
      op1:=Naechstes_Word(s,j);
      keywordsuche;
    end;
    if ot and $80=$80 then ps:=_pseudo(o0) else ps:=fmnemo;
    if doppelt and (ps<>fdef) Then begin
      if labell then seterr(3) else seterr(4)
    end
    else if (ps=fmnemo) and not labell and (name>'') then seterr(16);
    putadresse(adresse);asci:=false;
    if (ifstck[ifstckptr]=1) or ((ps>=fif) and (ps<=felseif)) then
    case ps of
     fmnemo: begin
              if not keyfound or ((ot and 1) = 0) then seterr(1) else begin
{
                begin
}
                by:=o0+(o1 shl 3) + (o2 shl 6);
                if (ot and 2)=2 then BEGIN
                  if not SucheRegister(reg1) then seterr(2)
                  else by:=(by AND $C7) or (reg1 shl 3);
                  if ((ot and 20)>0) then
                    if not getkomma(s,j) then seterr(18);
                END;
                if (ot and 4)=4 then begin
                  if not SucheRegister(reg2) then seterr(2)
                  else by:=(by AND $F8) or reg2 ;
                  if by=$76 then seterr(2);
                end;
                if (ot and 8)=8 then begin
                  if not SucheRegisterpaar(reg1) then seterr(2)
                  else begin
                    by:=by or (reg1 shl 4) or ((o1 and 1) shl 3);
                    if (by=$2a) or (by=$22) then seterr(2);
                    if (ot and 32) =32 then
                      if not getkomma(s,j) then seterr(18);
                  end;
                end;
                if (ot and 64) = 64 then
                  if not getzahl(reg1) then seterr(5)
                  else by:=(by AND $C7) or (reg1 shl 3);
                if err=0 then begin
                  putbyte(by,word(adresse));putoz(by);
                  if (ot and 16)=16 then
                    if not GetByte(reg1) then seterr(6) else begin
                      putbyte(reg1,word(adresse));
                      putoz(reg1);
                    end;
                  if (ot and 32)=32 then
                    if GetTwoBytes(reg1,reg2) then begin
                      putbyte(reg1,word(adresse));
                      putbyte(reg2,word(adresse));
                      putoz(reg1);
                      putoz(reg2);
                    end
                    else begin
                      putbyte(0,word(adresse));putbyte(0,word(adresse));putoz(0);putoz(0);end;
                end;
{
	      end;
}
              end;
            end;
       fdb: begin
              x:=1;
              if name>''then begin
                var_typ:=0;
                speicherevariablenwert(name,word(adresse),var_s);
              end;
              ok:=true;
	      while (j<=length(s)) and GetdB(reg1,reg2) and ok do begin
                if reg2>0 then begin
                  listaktline:=true;
                  putbyte(reg1,word(adresse));
                  if pass2 then begin
                    putoz(reg1);
                    if oz>10 then begin
                      newline(0);
                      listaktline:=false;
                    end;
                  end;
                end;
                if not asci then ok:=getkomma(s,j);
              end;
            end;
       fdw: begin
              x:=1;ok:=true;
              if name>''then begin
                var_typ:=1;
                speicherevariablenwert(name,word(adresse),var_s);
              end;
              while (j<length(s)) and GetTwoBytes(reg1,reg2) and ok do begin
                putbyte(reg1,word(adresse));putbyte(reg2,word(adresse));
                if pass2 then begin
                  putoz(reg1);putoz(reg2);
                  if oz>10 then newline(0);
                end;
                ok:=getkomma(s,J);
              end;
            end;
       fdd: begin
              x:=1;
              ok:=true;
              if name>''then begin
                var_typ:=2;
                speicherevariablenwert(name,word(adresse),var_s);
              end;
              while (j<length(s)) and GetfourBytes(xarr) and ok do begin
                for xx:=0 to 3 do putbyte(xarr[xx],word(adresse));
                if pass2 then begin
                  for xx:=0 to 3 do putoz(xarr[xx]);
                  if oz>10 then newline(0);
                end;
                ok:=getkomma(s,j);
              end;
            end;

      fequ: begin
              vrs:=var_s;
              ok:=konst(x);
              var_typ:=4;
              SpeichereVariablenWert(name,word(x),vrs);
              if pass2 then putadresse(x);
             end;

       fdef: begin
              vrs:=var_s;ok:=konst(x);if not ok then seterr(9);
              var_typ:=5;
              SpeichereVariablenWert(name,word(x),vrs);
              if pass2 then putadresse(word(x));
             end;

       fmac: macro(mwork);
     fmacro: processmacro;
     fexitm: if macaktiv=0 then seterr(27) else exitm:=true;
     frept,
     firp,
     firpc:  begin
               mark(dummy);
               rept:=1;
               printline;
               processreptline(s,ps,word(x),rptr,j);
               if err=0 then begin
                 new(z);fptr:=z;oldptr:=z;
								 liesrept;
								 while (rept>0) and not fertig do begin
								 new(z);liesrept;
									 if rept>0 then oldptr^.next:=z;
									 oldptr:=z;
								 end;
								 if fertig then begin a_error(14,0);
								 release(dummy);
								 exit;
							 end;
							 repaktiv:=true;
							 machrep(fptr,word(x),ps,rptr);s:='';
							 repaktiv:=false;
							 if ok then begin
								 listaktline:=false;
							 end;
							 release(dummy);
						 end;
					 end;
 finclude: begin
						 Incname:=Naechstes_Word(s,j);
						 printline;
						 include(incname);listaktline:=false;
					 end;
	 fif,
	 fife,
	 fifb,
	 fifnb,
	 fifdif,
	 fifidn,
	 fifndef,
	 fifdef: ProcessIf;
	 fendif: ProcessEndif;
	 felse : ProcessElse;
	 felseif: ProcessElseIf;
	 forg:   begin
						 ok:=konst(adresse);
						 putadresse(adresse);
						 if pass2 then schreibbuffer;
						end;
			fend: begin
							ende:=true;
						end;
			ferr: seterr(26);
		 fendm: seterr(27);
		 flist: nolist:=false;
	 fnolist: nolist:=true;
		 fmacs: nomacs:=false;
	 fnomacs: nomacs:=true;
		fconds: noconds:=false;
	fnoconds: noconds:=TRUE;
		 fctls: noctls:=false;
	 fnoctls: noctls:=true;
		 fsyms: nosyms:=false;
	 fnosyms: nosyms:=true;
	 fNoincl: Noincl:=true;
	feject,
	fnewpage: if not nolist and pass2 then eject:=true;
		ftitel: begin
							astitel:=copy(s,j,255);
							remove(astitel);j:=length(s);
						end;
		 fpage: begin
							if konst(x) Then begin
								if (x>=10) and (x<=255) then maxprline:=x;
								if getkomma(s,j) then if konst(x) then
									if (x>=55) and (x<=255) then maxprlength:=x;
							end
							else if not nolist and pass2 then eject:=true;
							err:=0;
						end;
		end;
	end else
	 if doppelt and labell then seterr(3)
	 else if (name>'') and not labell then seterr(16);
	 if err=0 then begin
		 Entferne_Leerzeichen(s,j);
		 if (j<length(s)) and (ifstck[ifstckptr]=1) then seterr(15);
	 end;
	 printline;
	 if ((err>0) and pass2)
				or (not pass2 and ((err=3)
				or (err=4) or (err=17))) then begin
		 dec(j);
		 while (j>2) and (s[j]=' ') do dec(j);
		 a_error(err,linlen-j+1);
	 end;
end;

procedure varliste(p:t_var);
begin
	if p^.links<>nil then varliste(p^.links);
	if p^.name>' ' then begin
	if not switch then
		If DoLST Then writeln(lfi,'':10,p^.name,'':23-length(p^.name),varbez[p^.typ],HEX(HI(p^.adresse)),HEX(LO(p^.adresse)))
		else
		If DoLST Then write(lfi,p^.name,'':23-length(p^.name),varbez[p^.typ],HEX(HI(p^.adresse)),HEX(LO(p^.adresse)));
	switch:=not switch;end;
	if p^.rechts<>nil then varliste(p^.rechts);
end;

procedure listvars;
 begin
	 if Not DoLST Or nosyms then exit;
	 if var_s<>nil then begin
		 writeln(lfi,#12);
		 writeln(lfi);
		 WRITELN(lfi,'Symbol                 Typ   Wert          Symbol                 Typ   Wert') ;
		 writeln(lfi,'----------------------------------------------------------------------------');
		 switch:=true;
		 varliste(var_s);
		 writeln(lfi);
		 writeln(lfi);
	 end;
end;

procedure writevars (FName : String);

var
	sym : text;

procedure varwrite(p:t_var);
begin
  if p^.links<>nil then varwrite(p^.links);
  if p^.name>' ' then
    writeln(sym,HEX(HI(p^.adresse)),HEX(LO(p^.adresse)),' ',p^.name);
	if p^.rechts<>nil then varwrite(p^.rechts);
end;

begin
  If Not DoSYM Then exit;
  if var_s<>nil then begin
    assign(sym,copy(FName,1,pos('.',FName))+'SYM');
    rewrite (sym);
    varwrite(var_s);
    close(sym);
  end;
end;

procedure ass_start;
begin
	adresse:=0;     lfehler:=0;       mstart:=nil;
  ifstckptr:=0;   ifstck[0]:=1;     localcount:=0;
	nolist:=False;  noconds:=true;    noincl:=false;
	nomacs:=true;   noctls:=true;     nosyms:=True;
	fehler:=0;      line:=0;
	If Not ESCP Then maxprline:=57 Else MaxPrline := 58;
  maxprlength:=120;
  ende:=false;     seite:=1;
  eject:=false;    repaktiv:=false;  macaktiv:=0;
  var_s:=nil;      BufferZeiger:=0;  incl:=0;
  var_typ:=0;      pass2:=false;     astitel:='';
end;

end.
