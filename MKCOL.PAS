Program MkCol;
{Einstellung der Farben fuer 8080SIM }

Uses
	Dos,
	Crt,
	astypdea,
	procs,
	printer,
	mywindow,
	mygloerr,
	myinput;

var
	l41:array[1..11] of str2;
	Ch : Char;

const
	l4anz = 11;
	l4: ARRAY[1..l4anz] OF RECORD
	xp,yp,xe,le,te :BYTE;
	m :STRING[80] END =
	 (
		(xp: 1;yp: 1;xe:26;le: 2;te: 9;m :'Rahmen . . . . . . . :'),
		(xp: 1;yp: 2;xe:26;le: 2;te: 9;m :'Hintergrund  . . . . :'),
		(xp: 1;yp: 3;xe:26;le: 2;te: 9;m :'Schatten . . . . . . :'),
		(xp: 1;yp: 4;xe:26;le: 2;te: 9;m :'Eingabefelder  . . . :'),
		(xp: 1;yp: 5;xe:26;le: 2;te: 9;m :'Eingabefeld aktuell  :'),
		(xp: 1;yp: 6;xe:26;le: 2;te: 9;m :'Eingabefeld invers . :'),
		(xp: 1;yp: 7;xe:26;le: 2;te: 9;m :'Textausgaben   . . . :'),
		(xp: 1;yp: 8;xe:26;le: 2;te: 9;m :'Meldungszeile  . . . :'),
		(xp: 1;yp: 9;xe:26;le: 2;te: 9;m :'Hilfsstichworte  . . :'),
		(xp: 1;yp:10;xe:26;le: 2;te: 9;m :'Hilfsstichwort akt.. :'),
		(xp: 1;yp:11;xe:26;le: 2;te: 9;m :'Hilfstexte . . . . . :'));


procedure baufarben;
var i,j:byte;
	 s:str2;
begin
	pushwin(7);schatten(7);
	for j:=0 to 15 do begin s:=bytstr(j);s:=' '+s[2]; wi1(j*2+4,2,tattr,s); end;
	for i:=0 to 15 do begin
		wi(1,i+3,tattr,bytstr(i*16));
		for j:=0 to 15 do begin
			s:=bytstr(i*16+j);
			wi(j*2+4,i+3,i*16+j,s);
		end;
	end;
	pushwin(8);
	schatten(8);
end;

{$F+}
function plaus(var temp:str80;i:integer):boolean;
var
	richtig,neu:boolean;
	ss:str15;
	bs:str2;
	 b:byte;
err,e :integer;
	 r:longint;
begin
	richtig:=true;
	case wndnr of
	4:temp:=caps(temp);
	8:if editmode then begin
			bs := Copy (Temp,1,2);
			b:=strbyte(bs);
			case i of
			 1:begin neu:=rahmattr<>b;rahmattr:=b;end;
			 2:begin
		neu:=tafelattr<>b;tafelattr:=b;
	 end;
			 3:begin neu:=schattenattr<>b;schattenattr:=b;end;
			 4:begin eNattr:=b;neu:=false; end;
			 5:begin eAattr:=b;neu:=false; end;
			 6:begin IneAttr:=b;neu:=false; end;
			 7:begin neu:=tattr<>b;tattr:=b;end;
			 8:begin neu:=llinattr<>b;llinattr:=b;end;
			 9:begin neu:=Helpindattr<>b;Helpindattr:=b;
		 if neu then begin hilfe(1);neu:=false end;
	 end;
			 10:begin neu:=HelpindaAttr<>b;HelpindaAttr:=b;
		 if neu then begin hilfe(1);neu:=false end;
	 end;
			 11:begin neu:=hochattr<>b;hochattr:=b;
		 if neu then begin hilfe(1);neu:=false end;
		end;
			end;
			if neu then begin
			 popwin(true);popwin(true);
			 if i=2 then tafel(0);
			 llin(6);textattr:=tattr;

			 baufarben;
			 l41[i]:=temp;
			 schreibrecord(l41,l4,l4anz);
		 end;
	 end;
	11:Temp:=caps(temp);
	end;
	if not richtig  and editmode and not (ch=F6)  then error(err);
	plaus:=richtig;
end;
{$F-}

procedure farbauswahl;
var i,j:integer;
		 s:str5;
                 TempStr : Str80;
		b:byte;
		test:byte;
		st,st1:t_attrib;
		mono :boolean;
		f:file;
		dummy : boolean;

begin
{
	 (x:38;y:1;dx:38;dy:19;xp:1;yp:1;s:'µ verfÅgbare Farben ∆';BP:nil),
	 (x:1;y:8;dx:32;dy:12;xp:1;yp:1;s:'µ Farbanpassung ∆';BP:nil ));
}
	with wd[7] do begin
		x:=38;y:=1;dx:=38;dy:=19;xp:=1;yp:=1;s:='µ verfÅgbare Farben ∆';bp:=nil;
	end;
	with wd[8] do begin
		x:=1;y:=8;dx:=32;dy:=12;xp:=1;yp:=1;s:='µ Farbanpassung ∆';bp:=nil;
	end;
{
	pushwin(0);
	tafel(0);
}
	llin(6);
	fillchar(l41,sizeof(l41),0);
	st1:=Screenattr;
	mono:=Screenadr=$b000;
	if mono then st:=monoattr else st:=colorattr;
	for i:=1 to 11 do l41[i]:=bytstr(st[i]);
	baufarben;
	editmode:=true;
	repeat
		liesrecord(l41,l4,l4anz,ch,[f6,f8,f5],f6);
		If ch=f5 Then Begin
			for i:=1 to 9 do Begin
				st[i]:=strbyte(l41[i]);
                                TempStr := l41 [i];
				if mono then monoattr:=st else colorattr:=st;
				dummy := plaus (TempStr,i);
			end;
{
			popwin (True);
			popwin (True);
			baufarben;
}
		end;
	until (ch=f6) or (ch=f8);
	if ch=f8 then begin
		for i:=1 to 11 do st[i]:=strbyte(l41[i]);
		if mono then monoattr:=st else colorattr:=st;
		assign(f,OldDir + 'Colors.Sim');
		{$i-} rewrite(f);{$i+}
		if ioresult=0 then begin
			blockwrite(f,colorattr,2*sizeof(colorattr));
			close(f);
		end;
	end
	else screenattr:=st1;
	popwin(true);
	keinschatten(7);
	popwin(true);
	keinschatten(8);
	popwin(true);
end;

Begin
	Farbauswahl;
End.