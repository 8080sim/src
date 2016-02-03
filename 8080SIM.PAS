{
   Project:    8080sim
               PC-Simulator für das 8080/8085 Microcomputer System "Profi-5"
	           und MFA (Mikrocomputer Für Ausbildung):
	           http://de.wikipedia.org/wiki/PROFI-5-Mikrocomputerfamilie
	           http://de.wikipedia.org/wiki/Mikrocomputer_f%C3%BCr_Ausbildung

    Date:      1990, 1995

    Copyright: Willi Marquart, Manfred Flume
  
    Copyleft:  GNU public license - http://www.gnu.org/copyleft/gpl.html
	
    Compiler:  Turbo Pascal 5.0, 5.5; Borland Pascal 7

}  

{$i direct.inc}

uses
{
		 overlay,
}
		 crt,dos,
		 procs,
		 Colors,
		 printer,
		 astypdea,
		 asprocs,
		 assembla,
		 mywindow,
		 mygloerr,
		 myinput,
		 asedi4,
		 simul_a,
     fileserv,
     int05,
     TransFil,
		 FileDel;

(*
{$O assembla}
{$O simul}
{$O fileserv}
*)


procedure assembler;
var
    s:string;
    dummy:pointer;
begin
 wd[5].yp:=1;
 pushwin(5);
 mark(dummy);
 resetbufpos;
 ass_start;
 l11.RomName := Copy (FName [11],1,Pos ('.',FName [11])-1);
 TempStr := ROMDir + l11.RomName + '.SYM';
 readsym (TempStr);
 writeln(#10,'Pass 1 l„uft ');
 i3:=copy(fname[0],1,pos('.',fname[0])-1) +'.LST';;
 TempStr := i3;
 If DoLST Then Begin
	 assign (lfi,TempStr);
	 rewrite(lfi);
	 astitel := TempStr;
 End
 Else AsTitel := ' ';
 s:=geteditor(fertig,1);
 while not fertig do begin
	 inc(line);assem(s);
	 s:=geteditor(fertig,1);
 end;
 if ifstckptr>0 then begin
	 ifstck[ifstckptr]:=1;
	 a_error(25,0);
 end;
 pass2:=true;adresse:=0;assembla.ende:=false;line:=0;
 localcount:=0;
 resetbufpos;
 i2:=copy(fname[0],1,pos('.',fname[0])-1)+'.hex';
 TempStr := i2;
 assign(obj,TempStr);
 rewrite(obj);
 writeln(#10,'Pass 2 l„uft ');
 s:=geteditor(fertig,1);
 while not assembla.ende and not fertig do begin
		inc(line);
		assem(s);
		if lfehler=maxfehler then begin
			writeln(' Mehr als ',lfehler,' Fehler');
			Writeln('Assembler-Lauf abgebrochen');
			assembla.ende:=true;
		end;
	 s:=geteditor(fertig,1);
 end;
 schreibbuffer;
 writeln(obj,':0000000000');
 close(obj);
 If DoLST Then Begin
	 listvars;
	 writeln(lfi,#13,#10,fehler:3,' FEHLER GEFUNDEN');
	 close(lfi);
 End;
 writevars (i3);
 writeln(#13,#10,fehler:3,' FEHLER GEFUNDEN');
 ch:=readkey;
 if lfehler>maxfehler then lfehler:=maxfehler;
 maxerrors:=lfehler;
 wia(1,1,tattr,'É'+cstr('Í',33)+'µ');
 if lfehler>0 then begin
	 eddata[1].cursorpos:=errata[lfehler].errpos;
	 wia(1,1,llinattr,erm[errata[lfehler].err]);
	end;
	release(dummy);
 popwin(true);
end;

procedure optionen;

Procedure Sel_Board;
Var
	Auswahl : Integer;
	m_pos   : Byte;
	t				: File;

Begin
 ilin(58,13);
 repeat
	 m_pos:=SimTyp;
	 auswahl:=flipmenue(57,24,
			'#E$Z80'+
			'_PROFI #2$K'+
			'_PROFI #4$K'+
			'_PROFI #8$K'+
			'_#M$FA'+
			'_#A$nwender'+
			'_#E$nde_(µ Rechnertyp Æ_',
		 4,m_pos,560,false);
		ch:=' ';
		case auswahl of
			1..5 : Begin
							 simtyp:=auswahl;
							 Case SimTyp of
								 1 : l11.RomName := 'EZ80';
								 2 : l11.RomName := 'PROFI_2K';
								 3 : l11.RomName := 'PROFI_4K';
								 4 : l11.RomName := 'PROFI_5E';
								 5 : l11.RomName := 'MFA';
							 End;
							 FName [11] := l11.RomName + '.ROM';
							 FName [12] := l11.RomName + '.SYM';
						 End;
			 6 :   begin
							 with wd[21] do begin
								 x:=35;y:=14;dx:=42;dy:=6;s:='ROM - Auswahl';
							 end;
							 PushWin (21);
							 akthelpnr :=560;
							 editmode:=true;llin(3);
{
							 With l11 Do Begin
								 SRom := '0';
								 ERom := '5FFF';
								 SRam := '6000';
								 ERam := 'FFFF';
							 End;
}
							 liesrecord(l11,l1,l1anz,ch,[],#27);
							 editmode:=false;
							 simtyp:=Auswahl;
							 FName [11] := l11.RomName + '.ROM';
							 FName [12] := l11.RomName + '.SYM';
							 PopWin (True);
						 end;
		end;
	until auswahl in [0..7];
	closewin(4);
	llin(3);
	akthelpnr := 1;
	TempStr := OldDir + '8080sim.msk';
	assign(t,TempStr);
	rewrite(t,1); blockwrite(t,fname,sizeof(fname)+sizeof(l11)+5);
	close(t);
{
}
end;

var auswahl:integer;
    m_pos:byte;
    e:word;
    f:file;
begin
 ilin(58,13);
 repeat
   m_pos:=2;
	 auswahl:=flipmenue(57,24,
			'#R$echner'+
			'_#I$nstallation'+
			'_#E$nde_(µ Rechnertyp Æ_',
			4,m_pos,501,false);
		ch:=' ';
		case auswahl of
			 1 :   Begin
							 CloseWin (4);
							 Sel_board;
						 End;
       2 :   Begin
               CloseWin (4);
               Setup;
						 End;
    end;
	until auswahl in [0..3];
	closewin(4);
	llin(3);
end;

procedure standard;
var
	t  : file;
	otime,ttime:longint;
	dummy:pointer;
	egal:boolean;
	fffname:str35;
	i,j : Byte;
begin
	FileMode := 2;
	hasBeenChanged:=false;lfehler:=0;
	fillchar(fname,sizeof(fname),0);
	TempStr := OldDir + '8080sim.msk';
	assign(t,TempStr);
	{$i-} reset(t,1);{$i+}
  if ioresult=0 then begin
{Original
	blockread(t,fname,sizeof(fname)+sizeof(l11)+5);
}
{neu-> Wichtig !!}
		blockread(t,fname,sizeof(fname)+sizeof(l11)+2);
    close(t);
	end
	else Begin
		fname[0]:='NONAME.ASM';
	End;
  if not initeditor(1) then begin
		error(59);
    popwin(true);
    exit
  end;
	TempStr := FName [0];
  If Not Exist (TempStr) Then Begin
    FName [0] := 'NONAME.ASM';
    FName [11] := 'PROFI_4K.SYM';
    FName [12] := 'PROFI_4K.ROM';
    FName [13] := RomDir;
    FName [15] := PrgDir;
    FName [16] := OldDir;
    AktDir  := PrgDir;
    TempStr := AktDir;
    If TempStr [Length(TempStr)] = '\' Then
      TempStr := Copy (AktDir,1,Length (AktDir)-1);
    ChDir (TempStr);
		TempStr := FName [0];
  End;
  If Exist (TempStr) Then if loadeditor (TempStr) then fehler:=0;
	repeat
		llin(3);
		ch:=editor(' ');
		if not HasbeenChanged then HasbeenChanged:=modifiededitor;
		case ch of
			f2    :  Begin
                 fileservice(0,false);
                 GetDir (0,AktDir);
                 If AktDir [Length (AktDir)] <> '\' Then AktDir := AktDir + '\';
							 End;
      altf1 :  fileservice(1,true);
      altF2 :  fileservice(2,true);
      altf3 :  fileservice(6,true);
      f3    :  begin
                 if hasbeenchanged then speichern;
                 assembler;
               end;

      f5     : begin
                 if hasbeenchanged then begin
									 speichern;
									 assembler;
                 end
                 else begin
                   i2:=copy(fname[0],1,pos('.',fname[0])-1)+'.HEX';
                   TempStr := i2;
                   assign (obj,TempStr);
                   (*$I-*) reset(obj) (*$I+*);
                   if ioresult<>0 then assembler else begin
                     close(obj);
                     TempStr := AktDir + FName [0];
                     assign (t,TempStr);
                     TempStr := i2;
										 assign (obj,TempStr);
                     getftime(obj,otime);
                     getftime(t,ttime);
                     if (otime<ttime) or (fehler<>0) then assembler;
									 end;
                 end;
								 closeeditor;
{
								 Write (MaxAvail);
								 Repeat Until KeyPressed;
}
								 mark(dummy);
								 if fehler=0 then Begin
									 simula;
									 if pc8255 Then Port [PCadr+3] := $93;
								 End;
								 release(dummy);
								 if not initeditor(1) then begin
                   error(59);
                   popwin(true);
                   exit
                 end;
                 TempStr := FName [0];
                 if loadeditor(TempStr) then begin end;
               end;
      f6   :   drucken;
      f8   :   optionen;
      f10  :   fragespeichern;
		end;
  until (ch=f10);
  closeeditor;
	assign(t,OldDir + '8080sim.msk');
	GetDir (0,AktDir);
	If AktDir [Length (AktDir)] <> '\' Then AktDir := AktDir + '\';
	FName [11] := l11.RomName + '.SYM';
	FName [12] := l11.RomName + '.ROM';
	FName [13] := RomDir;
	FName [14] := AktDir;
	FName [15] := PrgDir;
	For i:= 0 to 10 Do Begin
		If (FName [i] = 'NONAME.ASM') Then Begin
			If i < 10 Then FName [i] := '';
		End;
	End;
	j:=0;
	For i:=0 to 9 Do Begin
		if FName [i] = FName [i+1] Then FName [i+1] := '';
	End;
	FName [10] := '';
	rewrite(t,1); blockwrite(t,fname,sizeof(fname)+sizeof(l11)+5);
	close(t);
end;

procedure initsch;

 const AktWd:Array[0..8] of wdrec=
  ((x:0;y:0;dx:79;dy:24;xp:1;yp:1;s:'';BP:nil),
   (x:0;y:0;dx:79;dy:23;xp:1;yp:1;s:'µ Editor Æ';BP:nil),
  (x:1;y:1;dx:64;dy:13;xp:1;yp:1;s:'¹ Sourcefile w„hlen oder Esc Ì';BP:nil),
   (x:1;y:14;dx:44;dy:2;xp:1;yp:1;s:'¹ Dateiname Ì';BP:nil),
   (x:27;y:9;dx:27;dy:3;xp:1;yp:1;s:'';BP:nil),
   (x:32;y:1;dx:45;dy:20;xp:1;yp:1;s:'¹ Fehlermeldungen Ì';BP:nil),
   (x:0;y:0;dx:79;dy:24;xp:1;yp:1;s:'¹ Hex-Dump Ì';BP:nil),
   (x:38;y:1;dx:38;dy:19;xp:1;yp:1;s:'µ verfgbare Farben Æ';BP:nil),
   (x:1;y:8;dx:32;dy:12;xp:1;yp:1;s:'µ Farbanpassung Æ';BP:nil ));
var f:file;
    e:word;
begin
	move(aktwd,wd,sizeof(AktWd));
  with wd[11] do begin
    x:=2;y:=1;dx:=20;dy:=10;xp:=1;yp:=1;s:='';bp:=nil;
	end;
  with wd[12] do begin
    x:=25;y:=1;dx:=51;dy:=10;xp:=1;yp:=1;s:='';bp:=nil;
  end;
  with wd[13] do begin
    x:=2;y:=13;dx:=40;dy:=8;xp:=1;yp:=1;s:='';bp:=nil;
  end;
  with wd[14] do begin
    x:=45;y:=13;dx:=14;dy:=8;xp:=1;yp:=1;s:='';bp:=nil;
  end;
{
	plausptr:=@plaus;
}
	wndnr:=1;textattr:=tattr;
  llin(56);
  TempStr := OldDir + PortInfo;
  assign(f,TempStr);
  {$i-} reset(f,1);{$i+};
  if ioresult = 0 then begin
		blockread(f,l21,sizeof(l21));
    blockread(f,l981,sizeof(l981));
    pc8255:=l21.has8255='J';
		if pc8255 then begin
      Port [PCadr+3] := $93;
      pcadr:=hexdez(l21.pcadr,e);
      pradr:=hexdez(l21.pradr,e) div 16;
    end;
    close(f);
  end;
  Tafel (0);
  pushwin(4);
  writeln('   8080SIM  >'+ Programmversion,'<');
  write ('  Weiter mit bel. Taste');
  ch:=readkey;
  popwin(true);
end;

Var
	TF : Text;
	s  : String;
	Dummy : Word;

begin
{
	OvrInit('8080sim.OVR');
}
	Clrscr;
	Userpage := False;
  ass_init;
  akthelpnr:=1;
	initsch;
  standard;
  If Not DoHEX Then DelFiles ('*.HEX');
  If Not DoLST Then DelFiles ('*.LST');
  If Not DoSYM Then DelFiles ('*.SYM');
  If Not DoBIN Then DelFiles ('*.BIN');
  If Not DoBAK Then DelFiles ('*.BAK');
	If Length (OldDir) > 3 Then OldDir := Copy (OldDir,1,Length (OldDir)-1);
	Chdir (OldDir);
	if pc8255 Then Port [PCadr+3] := $93;
{$Ifdef int}
	If IntInstFlag Then RestoreInt;
{$Endif}
	If Lpt_Swap Then Begin
			Dummy := MemW [$0040:$0008];
			MemW [$0040:$0008]:= MemW [$0040:$000A];
			MemW [$0040:$000A] := Dummy;
			LPT_Swap := False;
	End;
end.
