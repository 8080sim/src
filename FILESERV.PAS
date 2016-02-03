unit fileserv;

{$I direct.inc}
{$F+}
{$R+}

interface
uses crt,dos,procs,printer,
     astypdea,
     asprocs,
     mywindow,
     mygloerr,
     myinput,
		 asedi4,
		 minitool,
		 transfil;

procedure fileservice(_pos:byte;auto:boolean);
procedure savefile;
procedure fragespeichern;
procedure filefrage(var Fname,ffname:LongStr);
procedure drucken;
function pick:boolean;
procedure laden(fname1:String);
procedure speichern;
const m_pos:byte=1;
var
    linecount:integer;
    Titel:string;
    CH:CHAR;
    errors:integer;
    maxcount,startcount,endcount:longint;
    HasBeenChanged:boolean;
implementation

procedure Inhalt(suchstr:string;var fname:String);

Var
	Execom,Datei           : DirPointer;
	dmb,DirAttr,SysAttr,sp : Byte;
	dmw                    : Word;
	Path,Name,Ext,
	DateiName              : String;
	Directory              : Boolean;

Begin
	ExeCom := Nil;
	DirAttr:= StrToAttr ('d');
	SysAttr:= StrToAttr ('dshv');
	fsplit(Suchstr,Path,name,ext);
	If Path [Length (Path)] = '\' Then Path := Copy (Path,1,Length (Path)-1);
	Repeat
		FreeDir (ExeCom);
		ExeCom := Nil;
		ReadDir (Path + '\*.*' ,DirAttr, NoAttr,dmb,dmw,execom);
		ReadDir (path + '\' + name + ext,NoAttr,SysAttr,dmb,dmw,execom);
		Datei := SelectDirRec (Path,ExeCom,False);
		If Datei <> Nil Then Begin
			Directory := (Datei^.Attr And DirAttr) <> 0;
			Path := Path + '\' + Datei^.Name;
			If (Datei^.Name = '..') Then Begin
				Sp := Length (Path)-3;
				Path := Copy (Path,1,Sp);
				While Path [Sp] <> '\' Do Dec (Sp);
				Path := Copy (Path,1,Sp-1);
			End;
		End
		Else Directory := False;
	Until (Not Directory);
	If Datei <> Nil Then FName := Path Else FName := '';
End;


procedure showfiles(var Fname,ffname:LongStr);
var
	Temp : LongStr;
	dir,aktdir:dirstr;
		nr:byte;
		name:namestr;
		ext:extstr;
begin
	Temp := ffName;
	repeat
	 pushwin(3);
	 input(4,1,35,1,ffname,ch);
	 popwin(true);
	if ch<>#27 Then begin
		 if (pos('*',ffname)>0) or (pos('?',ffname)>0) then Begin
			 fsplit(ffname,dir,name,ext);
			 if dir = '' Then Begin
				 GetDir (0,AktDir);
				 ffname := Aktdir  + '\' + name + ext;
			 End;
			 inhalt(ffname,fname)
		 End
		 else fname:=caps(ffname);
		 if fname='' then ch:=#0 else ch:=#13;
	 end else fname:='';
	until (ch=#13) or (ch=#27);
	If Ch = #27 Then FFName := Temp;
	nr:=0;
	fname:=fexpand(fname);
	getdir(nr,aktdir);
	fsplit(fname,dir,name,ext);
	if aktdir[length(aktdir)]<>'\' then aktdir:=aktdir+'\';
{
	if dir=aktdir then fname:=name+ext;
}
	if ext='' then fname:=fname+'.ASM';
end;

procedure filefrage(var Fname,ffname:LongStr);
begin
	wd[3].s:='¹ Dateiname Ì';
	showfiles(fname,ffname);
end;

procedure zerror(s:LongStr;linecount:integer);
begin
		inc(errors);
		enterwin(5);
		writeln(s);
		writeln('Zeile ',linecount);
		leavewin(5);
		enterwin(1);
end;

procedure drucken;
const
	ESC = #27;
	lm='';
{
	InitLen = 5;
}
	ESCP_Init   = (ESC+'@'+ESC+'P'+ #15 + ESC + 'l' + #10);
	PCL_Init	  = (ESC + 'E' + ESC + '(s 0p 20h 12v 0s 0b 3t 2Q' + ESC + '&a10 L');

var s:LongStr;
		ch:char;
		Err : Integer;

Function Init_PRN (Var PRN_Init : String) : Integer;
Var
		i,err : Integer;

Begin
	 {$I-}
	 i:=1;
	 Repeat
		 write(lst,PRN_Init [i]);
		 inc (i);
		 Err := IoResult;
	 Until (i> Length (PRN_Init)) Or (Err <> 0);
	 {$I+}
	Init_Prn := Err;
End;

label exit1;
begin
	 druckfrage(ch);if ch=f6 then exit;
	 llin(30);
	 s:=copy(fname[0],1,pos('.',fname[0])-1)+'.lst';
	 assign(lfi,s);
	 {$i-}
	 reset(lfi);
	 Err := IoResult;
	 {$i+}
	 if Err <> 0 then begin
		 error(34);
		 exit
	 end;
	 IF CUSTOM Then s:= CUST_Init;
	 If PCL Then s := PCL_Init;
	 IF ESCP Then s := ESCP_Init;
	 Err := Init_PRN (s);
	 If Err <> 0 Then Begin
		 PushWin (5);
		 Beep;
		 Wi (13,7,textattr,'Druckerfehler!');
		 Wi (7,9,Textattr,'-> Abbruch mit bel. Taste');
		 Repeat Until Keypressed;
		 PopWin (True);
		 Exit;
	 End;
	 While not eof(lfi) do begin
		 abbruch(ch);if ch=f6 then goto exit1;
		 readln(lfi,s);
		 writeln(lst,lm,s);
	end;
exit1:
	If ESCP Then write(lst,#18);
	write(lst,#12);
	close(lfi);
end;

procedure frageUeberschreiben;
var i:janeintyp;
begin
 if exist(fname[0]) then i:=JaNein(304,'šberschreiben?') else i:=ja;
 if i=ja then savefile;
end;

procedure umbenennen(var fname,ffname:string);
begin
	wd[3].s:='¹ Datei umbenennen Ì';
	showfiles(fname,ffname);
end;

procedure savefile;
var lnr:integer;

Function CheckFName (Var FName : String) : Boolean;
Var
	Err : Boolean;
Begin
	Repeat
		Err := True;
		fname:=caps(fname);
		Err := (Pos (' ',FName) > 0);
		if (FName = 'NONAME.ASM') Or Err then Begin
			umbenennen(fname,fname);
			CheckFName := True;
		End
		Else CheckFName := False;
	Until Err = False;
End;

begin
	lnr:=aktlastline;
	llin(306);
	Repeat
		Umbenennen (FName [0],FName [0]);
	Until Not CheckFName (FName [0]);
	if not saveeditor(fname[0]) then error(176) else hasBeenChanged:=false;
	llin(lnr);
end;


procedure speichern;
begin
 fname[0]:=caps(fname[0]);
 if fname[0]='NONAME.ASM' then begin
	 umbenennen(fname[0],fname[0]);
	 if ch=#13 then begin frageueberschreiben;exit;end;
 end else ch:=#13;
 If FName [0] = '' Then FName [0] := 'NONAME.ASM';
 IF POS('.',FNAME[0])=0 THEN FNAME[0]:=FNAME[0]+'.ASM';
	if ch=#13 then  savefile;
end;

procedure fragespeichern;
var i:janeintyp;
begin
	if HasBeenChanged then begin
	 i:=JaNein(305,'Speichern?');
	 case i of
		esc:ch:=' ';
		ja:begin speichern;ch:=f10;end;
	 end;
	end;
end;

procedure pickliste(fname1:string);
var
	i:integer;

begin
	If FName1 = 'NONAME.ASM' Then Exit;
	i:=0;
	fname1:=caps(fname1);
	while (i<10) and (fname[i]<>fname1) do inc(i);
	while i<10 do begin
		fname[i]:=fname[i+1];
		inc(i);
	end;
	for i:=10 downto 1 do fname[i]:=fname[i-1];
	fname[0]:=fname1;
	fname [10] := '';
end;

procedure laden(fname1:String);
var err:integer;

begin
	fragespeichern;
	err:=0;lfehler:=0;
	if not LoadEditor(FNAME1) then begin
		err:=geteditorerror;
		case err of
			1:begin
					 error(354);
					 seteditorfilename(fname1);
					 hasbeenchanged:=false;fehler:=0;
				end;
			2: begin
					 error(355);
					 seteditorfilename(fexpand(fname[0]));
				 end;
		end;
	end;
	if err<2 then pickliste(fname1);
end;

function pick:boolean;
var auswahl,anzahl:integer;
		m_pos:byte;
		fffname:str35;
		s:LongStr;
begin
 s:='';
 anzahl:=0;m_pos:=2;
 while (anzahl<11) and (fname[anzahl]>'') do begin
   s:=s+fname[anzahl]+'_';inc(anzahl);
 end;s:=s+'#F$ile laden_(µ Pick Æ_';
 auswahl:=flipmenue(3,21,s,7,m_pos,0,false);
 closewin(7);
 if auswahl=0 then begin pick:=false;exit end;
 if Auswahl<=anzahl then laden(fname[pred(auswahl)]) else begin
   filefrage(fffname,ffname[1]);
   if ch=#13 then laden(fffname);
 end;
 pick:=true;
end;


procedure fileservice(_pos:byte;auto:boolean);
var auswahl:integer;
		fffname:str35;
    lnr:integer;
begin
 if auto then m_pos:=_pos;
 repeat
   ilin(10,9);
   auswahl:=flipmenue(7,24,
                       '#L$aden        Alt-F1'+
                       '_#P$ick         Alt-F2'+
                       '_#N$eu'+
                       '_#S$peichern'+
                       '_Speichern #a$ls'+
                       '_#D$irectory    Alt-F3'+
                       '_#š$bertragen -> RS232'+
                       '_#E$nde_(µ Textauswahl Æ_',
                       6,m_pos,100,auto);
   ch:=' ';
   auto:=false;
	 case  auswahl of
     1: begin
          filefrage(fffname,ffname[1]);
          if ch=#13 then laden(fffname) else auswahl:=8;
        end;
     2: if not pick then auswahl:=6;
     3: begin
          fragespeichern;
          ClearEditor('NONAME.ASM');
          pickliste('NONAME.ASM');
        end;
     4: begin
          speichern;
          if ch<>#13 then auswahl:=6;
         end;
     5: begin
          umbenennen(fname[0],fname[0]);
          if ch=#13 then frageueberschreiben else auswahl:=6;
				end;
     6: begin
          filefrage(fffname,ffname[2]);
        end;
     7: begin
          If Not DoSRC Then Begin
            TempStr := Copy (fname [0],1,Pos ('.',Fname [0]))+'HEX';
            filefrage(fffname,TempStr);
            if ch=#13 then SendHex (fffname) else auswahl:=6;
          end
          Else begin
            TempStr := fname [0];
            filefrage(fffname,TempStr);
            if ch=#13 then SendSource (fffname) else auswahl:=6;
          end;
        End;
   end;
 until auswahl in [0..8];
 ch:=#13;
 closewin(6);llin(3);
end;
end.
