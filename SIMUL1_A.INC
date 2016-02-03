{$R-}
procedure werror(err:integer);
begin
	error(err);
	window(1,1,80,24);
	step:=true;
end;

procedure putbyte(b:byte;i:word);
begin
	if (i<=ramhigh) and (i>=ramlow) then mem[ramseg:i]:=b else
	if (i>=romlow) and (i<=romhigh) then begin
		if writerom then mem[ramseg:i]:=b else werror(153)
 end else werror(150);
end;

procedure sta_inc(b:byte;var i:word);
begin
 putbyte(b,i);inc(i);
end;

function getbyte(i:word):byte;
begin
 getbyte:=mem[ramseg:i];
 if not ((i<=ramhigh) and (i>=ramlow) or (i>=romlow) and (i<=romhigh)) then
 if not adresserror then begin
	 werror(151);adresserror:=true;
 end;
end;

function lad_inc(var i:word):byte;
begin
 lad_inc:=getbyte(i);inc(i);
end;

function nibbles(var h,l:byte):boolean;
var
	base:byte;

begin
	base:=l and $Fc;
	l:=l and $3;
	h:=0;
	while (h<4) and (base<>porttab[h]) do inc(h);
	nibbles:=( h<=maxport) or (h=3);
	if (h>3) and (simtyp< MFA_Typ) then werror(152);
end;

procedure readhex_cmd;
var
		s:string;
		by,Pruefsumme,Recordtyp:byte;
		i,spos,anzahl,adresse,start,
		laenge,summe,err:Word;
		first:boolean;
		obj:text;

function readbyte:byte;
var bs:string[2];
begin
	bs:=copy(s,spos,2);inc(spos,2);
	readbyte:=Hexdez(bs,err);
end;

function readword:word;
var bs:string[4];
begin
  bs:=copy(s,spos,4);inc(spos,4);
	readword:=Hexdez(bs,err);
end;

label ende;

begin
	 WriteRom:=true;
   llin(35);
   assign (obj,i2);
   (*$I-*) reset(obj) (*$I+*);
   if ioresult<>0 then begin error(38);exit end;
   start:=0;first:=true;summe:=0;err:=0;
	 while (not eof(obj)) and (err=0) do begin
		 readln(obj,s);
     laenge:=length(s);
     if (laenge<9) or (s[1]<>':') then begin
       error(37);goto ende;
     end;
     spos:=2;
     anzahl:=readbyte;
     pruefsumme:=anzahl;summe:=summe+anzahl;
     if (anzahl>0) and (err=0) then begin
       adresse:=Readword;
       if first then begin reg.pc:=adresse;first:=false end;
       pruefsumme:=pruefsumme+Lo(adresse)+hi(adresse);
       Recordtyp:=Readbyte;
			 pruefsumme:=pruefsumme+ Recordtyp;
       for i:=1 to anzahl do begin
         by:=readbyte;
         pruefsumme:=pruefsumme+by;
				 mem[ramseg:adresse]:=by;inc(adresse);
			 end;
       pruefsumme:= not Pruefsumme;
       inc(pruefsumme);
       if readbyte<>pruefsumme then begin
         error(36);goto ende;
       end;
     end;
   end;
   if err<>0 then error(37);
ende:
   close(obj);
end;

var p_s,p_w:t_var;

PROCEDURE SpeichereVariable(x0:longint;x:str30;var p:t_var;var h:boolean);
var p1,p2:t_var;
begin
	if p=nil then
  begin
    new(p);h:=true;
    with p^ do begin
      name:=x;adresse:=x0;
      links:=nil;rechts:=nil;bal:=0;
    end
  end else
  if x0<p^.adresse then begin
   SpeichereVariable(x0,x,p^.links,h);
    if h then
    case p^.bal of
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
  end else
  if x0>p^.adresse then
  begin
	 SpeichereVariable(x0,x,p^.rechts,h);
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
   end else begin h:=false; end;
end;

var ok:boolean;

PROCEDURE HoleVariablenWert(x0:word;var x:str30;var p:t_var);
begin
  ok:=false;
  while (p<>nil) and  not ok do begin
    if p^.adresse=x0 then begin
      ok:=true;x:=p^.name;
      end else
    if x0<p^.adresse then p:=p^.links else p:=p^.rechts;
	end;
end;

procedure readsym(fname:LongStr);
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
      SpeichereVariable(x,na,p_s,h);
    end;
    close(sym);
 end;
end;

procedure disass(var i:word);
var e,x:word;
   na:str30;
   mne,arg1,arg3:str5;
   arg2:string[50];
begin
  by:=mem[ramseg:i];
  inc(i);
	arg1:=''; arg2:=''; arg3:='';
	hexstr:=hex(by)+' ';
  o0:=(by and $c0) shr 6;
  o1:=(by and $38) shr 3;
  o2:=(by and $7) ;
  case o0 of
    0: begin
         mne:=opc0[o2,o1];
         ot:=opt0[o2,o1];
       end;
		1: if by=$76 then begin
        mne:='HLT';
        ot:=1
       end
       else begin
         mne:='MOV';
         ot:=7;
       end;
		2: begin
				 mne:=opc2[o1];
         ot:=5;
       end;
    3: begin
         mne:=opc3[o2,o1];
         ot:=opt3[o2,o1];
       end;
  end;
   if (ot and 2)=2 then begin
     arg1:=rbn[o1];
     if (ot and 4=4) or (ot and 16=16) then arg1:=arg1+',';
	 end;
   if (ot and 4)=4 then arg2:=rbn[o2];
   if (ot and 8)=8 then begin
     arg1:=rwn[o1 shr 1];
     if (o0=3) and ((o2=1) or (o2=5)) and (o1=6) then arg1:='PSW';
     if (ot and 32)=32 then arg1:=arg1+',';
	 end;
	 if (ot and 16)=16 then begin
     arg2:=hex(mem[ramseg:i]);inc(i);
     p_w:=p_s;
		 x:=hexdez(arg2,e);Holevariablenwert(x,na,p_w);
     hexstr:=hexstr+arg2+ ' ';
     if ok then arg2:=na+' ('+arg2+')';
   end;
   if (ot and 32)=32 then begin
     arg3:=hex(mem[ramseg:i]);inc(i);hexstr:=hexstr+arg3+ ' ';
     arg2:=hex(mem[ramseg:i]);inc(i);hexstr:=hexstr+arg2+ ' ';
     p_w:=p_s;arg2:=arg2+arg3;
		 x:=hexdez(arg2,e);Holevariablenwert(x,na,p_w);
     if ok then arg2:=na+' ('+arg2+')';
	 end;
   if (ot and 64)=64 then mne:=mne+hex(o1);
   disstr:=mne+ cstr(' ',5-length(mne))+arg1+arg2;
   disstr:=disstr+cstr(' ',25-length(disstr));
end;

var switch:boolean;

procedure varliste(p:t_var);
begin
  if p^.links<>nil then varliste(p^.links);
  if p^.name>' ' then begin
  if not switch then
    writeln('':10,p^.name,'':23-length(p^.name),HEX(HI(p^.adresse)),HEX(LO(p^.adresse)))
    else
  write(p^.name,'':23-length(p^.name),HEX(HI(p^.adresse)),HEX(LO(p^.adresse)));
  switch:=not switch;end;
  if p^.rechts<>nil then varliste(p^.rechts);
end;

procedure listvars;
var ch:char;
begin
	if p_s<>nil then begin
		with wd[6] do begin
			x:=0;y:=0;dx:=79;dy:=24;xp:=1;yp:=1;s:='π Variablenliste Ã';BP:=nil;
		end;
		pushwin(6);llin(4);
		WRITELN('Symbol                 Wert          Symbol                 Wert') ;
		writeln('----------------------------------------------------------------');
		switch:=true;
		varliste(p_s);
		ch:=readkey;
		popwin(true);window(1,1,80,24);
	end;
end;

procedure anzeige;
(*
const tran:array[0 ..127] of char =
{ 0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f }
(' ',' ',' ',' ','i',' ','1','7','_',' ',' ',' ',' ',' ',' ','J', {00..0f}
 'i',' ',' ',' ',' ',' ',' ',' ',' ','i',' ',' ','u',' ',' ',' ', {10..1f}
 ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ', {20..2f}
 ' ',' ',' ',' ',' ',' ',' ',' ','L','C',' ','Q',' ','G','U','O', {30..3f}
 '-',' ',' ',' ',' ',' ',' ',' ','=',' ',' ',' ',' ',' ',' ','3', {40..4f}
 'r',' ',' ',' ','n',' ',' ',' ','c',' ',' ','2','o',' ','d',' ', {50..5f}
 ' ',' ',' ',' ',' ',' ','4',' ',' ',' ',' ',' ',' ','5','Y','9', {60..6f}
 'k','F','Y','P','h',' ','H','A','t','E',' ',' ','b','6',' ','8'); {70..7f}
*)
const tran:array[0 ..127] of char =
{ 0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f }
(' ',' ',' ',' ',',',' ','1','7','_',' ',' ',' ',' ','i','!',']', {00..0f}
 'i',' ',' ',' ',';',' ',' ',' ',' ','i',' ',' ','u',' ','J',' ', {10..1f}
 ' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ', {20..2f}
 ' ',' ',' ',' ',' ',' ',' ','M','L','C',' ','Q',' ','G','V','0', {30..3f}
 '-',' ',' ',' ',' ',' ','+',' ','=',' ',' ',' ',' ',' ',' ','3', {40..4f}
 'r',' ',' ','?','n',' ',' ',' ','c',' ','Z','2','o','Ñ','d','a', {50..5f}
 ' ',' ',' ',' ',' ',' ','4','Q',' ',' ',' ',' ','S','5','Y','9', {60..6f}
 'k','F','Y','P','h','k','X','A','t','E',' ',' ','b','6','W','8');{70..7f}

var b,m,ma:byte;
		i,j:word;
		hell:boolean;
		vc,bc:word;
		s:string[16];
begin
	if simtyp > P5_8K then exit;
	i:=ramhigh-7;
	s[0]:=#16;j:=1;
	repeat
		 b:=lad_inc(i);     s[j]:=tran[b and $7f];
		 if b and $80=$80 then Begin
			s[j+1]:='.';
		 End
		 else s[j+1]:=' ';
		 inc(j,2);
	until i>ramhigh;
	wia(60,3,eaattr,s);
end;

function dezbin(var by:byte):str8;
Var
	i   : Byte;
	s   : Str8;
	Bool: Record
					 Case Byte of
						 0 : (Bin : Set of 0..7);
						 1 : (Hex : Byte);
				 End Absolute by;

Begin
	For i:=7 Downto 0 Do If i in Bool.Bin Then s [8-i] := '1' Else s [8-i] := '0';
	dezbin := s;
End;

procedure Meldung(err:integer);
var i:integer;
   ch:char;
const
   s1:array[1..2] of str20 =('     TastD/TastM','UP Zeit > 1min');
   s='Taste drÅcken (F1=Hilfe)';
begin
  i:=length(s1[err]);
  if i<length(s) then i:=length(s);
  i:=i div 2+2;
  with wd[FehlerWindow] do begin
		x:=40-i;y:=12;
		dx:=i+i;dy:=3;
    xp:=1;yp:=1;
    bp:=nil;s:='';
  end;
	pushwin(FehlerWindow);
	wi(2,1,EaAttr,s1[err]);
  wiC(2,EaAttr,s);
end;

procedure zeigport(k,b:byte);
var i,j,by,stb,b4:byte;
		s:str8;
		x,y:integer;

procedure  dira;
begin
	if (by and 16)=16 then wia1(x+6,y-7,eaattr,'IN') else begin  {Kanal a}
		 wia1(x+5,y-7,eaattr,'OUT');port80[k,4]:=port80[k,4] or 4;end;
end;

procedure dirb;
begin
	if (by and 2)=2 then wia1(x+6,y-5,tattr,'IN') else begin       {Kanal b}
		wia1(x+5,y-5,eaattr,'OUT');port80[k,4]:=port80[k,4] or 8;end;
end;

procedure DirLoC;
begin
 if (by and 1)=1 then wia1(x+4,y-3,eaattr,'IIII')
 else begin {KaC 3-0}
	 wia1(x+4,y-3,eaattr,'OOOO');
	 port80[k,4]:=port80[k,4] or 16;
 end;
end;

begin
	If MaxPort = 0 Then x := 51 Else x:=51+k*9;
	y:=2*b+15;
	by:=port80[k,b];
	s:=dezbin(by);
	wia1(x,y,eaattr,s);
	if b=3 then begin
{		stb := 0;
}
		if by and $80=$80 then begin
			wia1(x+1,y-7,tattr,'ƒƒƒƒƒƒ');wia1(x+1,y-5,tattr,'ƒƒƒƒƒƒ');
			If Not Userpage Then fillchar(inte,sizeof(inte),0);
			stb:= by and $60 shr 5;
			port80[k,4]:=stb;
			case stb of
			0:begin
					wia1(x,y-1,eaattr,'Mode 0/0');
					DirA;
					DirB;
					DirLoC;
					if by and 8=8 then wia1(x,y-3,eaattr,'IIII')
					else begin {KaC 7-4}
						wia1(x,y-3,eaattr,'OOOO');
						port80[k,4]:=port80[k,4] or $20;
					end;
				end;
			1:begin
					wia1(x,y-1,eaattr,'Mode 1/1');
					DirA;
					DirB;
					if by and 8=8 then s:='II' else s:='OO';
					if port80[k,4] and 4=4 then s:= 'AA'+s+'ABBB' else s:=s+'AAABBB';
					wia1(x,y-3,eaattr,s);
					port80[k,2]:=port80[k,2] and $f6  or $c6;
					zeigport(k,2);
				 end;
		 2,3:begin
					 s:='AAAAA';
					 if by and 4=0 then begin
						 wia1(x,y-1,eaattr,'Mode 2/0');
						 if by and 1=1 then s:=s+'III' else s:=s+'OOO';
					 end else  begin
						wia1(x,y-1,eaattr,'Mode 2/1');
						port80[k,4]:=port80[k,4] or 64;
						s:=s+'BBB';
					end;
					DirB;
					wia1(x+6,y-7,eaattr,'BI');
					wia1(x,y-3,eaattr,s)
				end;
			end;
		end else begin
			stb:=(by and $e) shr 1;
			j:=1 shl stb;b4:=port80[k,4];
			if b4 and 3 =1 then begin  {Interrupt Control in Mode 1}
			 if stb=2 then begin inte[k,1]:=by and 1 =1;by:=$ff;end;
			 if inte[k,1] then   wia1(x+1,y-5,eaattr,'EI') else  wia1(x+1,y-5,eaattr,'DI');
			 if stb=4 then begin inte[k,0]:=by and 1 =1;by:=$ff;end;
			 if stb=6 then begin inte[k,2]:=by and 1 =1;by:=$ff;end;
			 if inte[k,0] then   wia1(x+1,y-7,eaattr,'EI') else  wia1(x+1,y-7,eaattr,'DI');
			end;
			if b4 and 3 >1 then begin  {Interrupt Control in Mode 2}
				if stb=4 then begin inte[k,0]:=by and 1 =1;by:=$ff;end;
				if stb=6 then begin inte[k,2]:=by and 1 =1;by:=$ff;end;
				if inte[k,0] then   wia1(x+1,y-7,eaattr,'EI') else  wia1(x+1,y-7,eaattr,'DI');
				if inte[k,2] then   wia1(x+3,y-7,eaattr,'EO') else  wia1(x+3,y-7,eaattr,'DO');
				if b4 and 64=64 then begin
					if stb=2 then begin inte[k,1]:=by and 1 =1;by:=0;end;
					if inte[k,1] then   wia1(x+1,y-5,eaattr,'EI') else  wia1(x+1,y-5,eaattr,'DI');
				end;
			end;
			if (by and $80)=0 then begin
				if (by and 1) = 1
				then
					port80[k,2] := port80[k,2] or j
				else
					port80[k,2] := port80[k,2] and (not j);
			end;
			zeigport(k,2);
		end;
	end;
end;

Procedure ZeigPorts;
Var i,j : Byte;

Begin
	If ShowRegs Then Begin
		If SimTyp = EZ80_Typ Then Begin
			For j:= 0 to 3 Do Begin
				ZeigPort (0,j);
			End;
		End
		Else Begin
			For i:= 0 to 2 Do Begin
				For j:= 0 to 3 Do Begin
					ZeigPort (i,j);
				End;
			End;
		End; {Else SimTyp..}
	End; {ShowRegs}
End;

procedure ProcessOutPort(bnr,ka,by:byte);
var stb,modus,b2:byte;
begin
	If bnr >= 3 Then Begin
		Port [ioadr+ka] := by;
		exit;
	End;
	port80[bnr,ka]:=by;
	stb:=port80[bnr,4];
	modus:=stb and 3;
	Begin
		b2:=port80[bnr,2];
		case modus of
			0	:	begin
						case ka of
							0	:	if stb and 4=4 then  port80[bnr,ka]:=by else werror(154);
							1	:	if stb and 8=8 then  port80[bnr,ka]:=by else werror(154);
							2	:	begin
										if stb and $10=$10 then b2:=(b2 and $f0) or (by and $0f);
										if stb and $20=$20 then b2:=(b2 and $0f) or (by and $f0);
									end;
						end; { Modus 0, Case ka }
					end; { Modus 0 }
			1:	begin
						case ka of
							0	:	begin
										if stb and 4=4 then begin
											port80[bnr,ka]:=by;
											b2:=b2 and $F7; {Reset Intr}
											b2:=b2 and $7f; {OBF low}
										end else werror(154);
									end;
							1	:	begin
										if stb and 8=8 then begin
											port80[bnr,ka]:=by;
											b2:=b2 and $Fe; {Reset Intr}
											b2:=b2 and $fd; {OBF low}
										end else werror(154);
									end;
						end; { Modus 1, Case ka }
					end;	{ Modus 1 }
			2,3:	case ka of
							0	:	begin
										port80[bnr,ka]:=by;
										b2:=b2 and $F7; {Reset Intr}
										if b2 and $40=0 then b2:=b2 or $80 {ack low => OBF high}
										else b2:=b2 and $7f; {ack high => OBF low}
										if inte[bnr,2] and (b2 and $c0=$c0) then b2 :=b2 or 8; {set Intr }
									end;
							1	: if stb and 8=8 then begin
										port80[bnr,ka]:=by;
										b2:=b2 and $fc;{ obf= low; intrb =low anyway }
									end else werror(154);
						end; { Modus 2,3 Case ka }
		end; { Case Modus }
	end; { Else ( kein Drucker und kein 8255 !) }
	if pc8255 And (bnr= pradr) then Begin
		port[pcadr + ka]:=port80 [bnr,ka];
	End
	Else if DoLpt  And (bnr = 2) then Begin
		port	 [lptadr + ka] := port80 [bnr,ka];
	End;
	If bnr <= MaxPort Then zeigport(bnr,ka);
end;

procedure Processinput(bnr,ka,by:byte);
var stb,modus,b2:byte;

procedure mode1b;
begin
	if stb and 8=0 then begin
		if (by and 4=0) and (b2 and 4=4) then begin
			port80[bnr,1]:=port80[bnr,6];
			b2:=b2 and $fb or 2;
		end else  if (by and 4=4) and (b2 and 4=0) then begin
			b2:=b2 or 4;
			if inte[bnr,1] then b2:=b2 or 1;
		end;
	end else begin
		if (by and 4=0) and (b2 and 4 = 4) then b2:=b2 and $fb or 2 else
		if (by and 4=4) and (b2 and 4 = 0) then begin
			b2:=b2 or 4;
			if inte[bnr,1] then b2 :=b2 or 1; {set Intr }
		end;
	end;
end;

begin
	If bnr > MaxPort Then Exit;
	if ka<3 then begin
		b2:=port80[bnr,2];
		stb:=port80[bnr,4];
		modus:=stb and 3;
		case modus of
		0:begin
				case ka of
				 0:if stb and 4=0 then  port80[bnr,ka]:=by;
				 1:if stb and 8=0 then  port80[bnr,ka]:=by;
				 2:begin
						 if stb and $10=$0 then
							b2:=(b2 and $f0) or (by and $0f);
						 if stb and $20=$0 then
							b2:=(b2 and $0f) or (by and $f0);
					 end;
				 end;
			 end;
		1:begin
				case ka of
				 0:if stb and 4=0 then port80[bnr,ka+5]:=by;
				 1:if stb and 8=0 then port80[bnr,ka+5]:=by;
				 2: begin
							if stb and 4=0 then begin
								if (by and $10=0) and (b2 and $10=$10) then begin
									port80[bnr,0]:=port80[bnr,5];
									b2:=b2 and $ef or $20;
								end else
								if (by and $10=0) and (b2 and $10=$10) then begin
									b2:=b2 or $10;
									if inte[bnr,0] then b2:=b2 or 8;
								end;
							end else begin
								if (by and $40=0) and (b2 and $40=$40) then
									b2:=b2 and $df or $80 else
								if (by and $40=$40) and (b2 and $40=0) then
								begin
									b2:=b2 or $40;
									if inte[bnr,0] then b2 :=b2 or 8; {set Intr }
								end;
						 end;
						 mode1b;
						end;
				 end;
			end;
	2,3:case ka of
			 0:port80[bnr,ka+5]:=by;
			 1:if stb and 8=0 then port80[bnr,ka+5]:=by;
			 2:begin
					 if stb and 64=64 then mode1b;
					 if (by and $10=0) and (b2 and $10=$10) then begin
						 port80[bnr,0]:=port80[bnr,5];
						 b2:=b2 and $ef or $20;
					 end else
					 if (by and $10=$10) and (b2 and $10=$0) then begin
						 b2:=b2 or $10;
						 if inte[bnr,0] then b2:=b2 or 8;
					 end;
					 if (by and $40=0) and (b2 and $40=$40) then begin
						 b2:=b2 and $bf or $80;
					 end else
					 if (by and $40=$40) and (b2 and $40=0) then begin
						 b2:=b2 or $40;
						 if inte[bnr,2] then b2:=b2 or 8;
					 end;
				 end;
			end;
		end;
		port80[bnr,2]:=b2;
		zeigport (ka,by);
	 end;
end;

procedure cpureadport(bnr,ka:byte);
var
	stb,modus,b2 : byte;
	temp         : byte;

begin
	If bnr >= 3 Then Begin
		reg.a := Port [ioadr+ka];
		exit;
	End;
	if pc8255 And (bnr= pradr) then begin
		reg.a:=port[pcadr+ka];
		port80[bnr,ka]:= reg.a;
		port80[bnr,2]:=Port [pcadr+2];
	end
	Else if DoLpt And (bnr =2) then Begin
		reg.a:=port[lptadr+ka];
		If ka=1 Then Begin         { Busy invertieren PC - spezifisch!}
			If (reg.a And $80) > 0
				Then reg.a := reg.a And $7F
				Else reg.a := reg.a Or  $80;
		End;
		port80[bnr,ka]:=reg.a;
	end;
	Begin
		b2:=port80[bnr,2];
		stb:=port80[bnr,4];
		modus:=stb and 3;
		case modus of
			0	:		reg.a:= port80[bnr,ka];
			1	:		case ka of
							0	: begin
										reg.a:=port80[bnr,ka];
										if stb and 4=0 then b2:=b2 and $d7;
									end;
							1	: begin
										reg.a:=port80[bnr,ka];
										if stb and 8=0 then b2:=b2 and $Fc;
									end;
							2	: reg.a:=port80[bnr,ka];
						end; { Modus 1, Case ka }
			2,3:	case ka of
							0	: begin
										reg.a:=port80[bnr,ka];
										b2:=b2 and $d7;
									end;
							1	: begin
										reg.a:=port80[bnr,ka];
										if stb and 8=0 then b2:=b2 and $Fc;
									end;
							2	: reg.a:=port80[bnr,ka];
						end; { Modus 2,3, Case ka }
		end; { Case Modus }
		port80[bnr,2]:=b2;
	end;
	ZeigPorts;
end;
