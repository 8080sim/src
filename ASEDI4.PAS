unit asedi4;
{$i direct.inc}
interface
uses
  crt,dos,
  procs,               {Standardunits}
  MyWindow,             {Fensterverwaltung}
  myGloerr,
	Mybined,
	astypdea,
  asprocs;

var
  EditorBufferUeberlauf : boolean;
  editorerrornr         : integer;

function  initeditor(nr:integer):boolean;

function  geteditorerror:integer;

Procedure  filleditor(s:LongStr);

procedure cleareditor(fname:LongStr);

function  geteditor(var ende:boolean;wndnr:byte):LongStr;

procedure closeeditor;

function  Saveeditor(fname:LongStr):boolean;

function  loadeditor(Dname:LongStr):boolean;

function  editor(ch:char):char;

function ModifiedEditor: Boolean;

procedure seteditorfilename(s:LongStr);

procedure resetbufpos;

var
  EdData : array[0..1] of EdCB;              {Editor control block}
  EdBufpos:word;

implementation

Const
  MakeBackup  = false;          {True to create .BAK files}

var
  ExitCode : Word;            {Status code set by binary editor functions}
  ExitCommand : Integer;      {Code for command used to leave editor}
  Fname : LongStr;             {Input name of file being edited}
  Junk : Boolean;

const
  {Commands other than ^K^D to exit editor}
  ExitCommands : array[0..36] of Char =
  (#2, #0,f2,#2, #0,f3,#2, #0,f5,#2,#0,f6,#2,#0,
   F1,#2,#0,F10,#2,#0,f8,#2,#0,ctrlf1,#2,#0,ctrlf2,
   #2,#0,altf3,#2,#0,altf1,#2,#0,altf2,#0);

function  geteditorerror:integer;
begin
   geteditorerror:= editorerrornr ;
end;

procedure resetbufpos;
begin
  EdBufpos:=0;
end;

function initeditor;
begin
  pushwin(nr);
  {Initialize a window for the file}
  ExitCode :=
  InitBinaryEditor(
  EdData[wndnr],                     {Editor control block, initialized by InitBinaryEditor}
  MaxFileSize,                {Size of data area to reserve for binary editor text buffer, $FFE0 max}
  wd[wndnr].x+2,
  wd[wndnr].y+2,
  wd[wndnr].x+ wd[wndnr].dx,
  wd[wndnr].y+ wd[wndnr].dy,
  True,                       {True to wait for retrace on color cards}
  EdOptInsert+EdOptTAB,       {Initial editor toggles}
  '.ASM',                     {Default extension for file names}
  ExitCommands,               {Commands which will exit the editor}
  nil);                       {No event handler in this example}
  EdData[wndnr].EoText:=0;
{  setFilename(EdData[wndnr],'');}
  EditorBufferUeberlauf:=false;
  initeditor:=exitcode=0;

end;

procedure filleditor;
begin
  if not EditorBufferUeberlauf then
  EditorBufferUeberlauf:= not Movetobinaryeditor(eddata[wndnr],s);
end;

procedure closeeditor;
begin
  {Release heap space used by the editor data structure}
  ReleaseBinaryEditorHeap(EdData[wndnr]);
  popwin(true); edsetcursor($2020);
end;

function editor;
var
  startcom :str2;

  function ExitBinaryEditor(var EdData : EdCB; ExitCommand : Integer) : Boolean;
    {-Handle an editor exit - save or abandon file}
  var
    ExitCode : Word;

  begin                       {ExitBinaryEditor}
    case ExitCommand of
     -1: ExitBinaryEditor:=true;


      0 :
        begin
	 ExitBinaryEditor:=true;
	 ch:=f2;
	end;
      1 :
        begin
	 ExitBinaryEditor:=true;
	 ch:=f3;
	end;
     2 :
	begin
	 ch:=f5;
	 ExitBinaryEditor:=true;
        end;
     3 :
	begin
	 ch:=f6;
	 ExitBinaryEditor:=true;
        end;
      4:begin
{Original
	 hilfe(600);
}
{neu}
	 hilfe(0);
	 ExitBinaryEditor:=false;
	end;
      5:begin
	 ExitBinaryEditor:=true;
	 ch:=f10;
	end;
      6:begin
	 ExitBinaryEditor:=true;
	 ch:=f8;
	end;
      7:begin
	 ExitBinaryEditor:=false;
	 wia(1,1,rahmattr,'É'+cstr('Í',33)+'µ');
         if lfehler>1 then  begin
           dec(lfehler);
           eddata.cursorpos:=errata[lfehler].errpos;
           wia(1,1,llinattr,erm[errata[lfehler].err]);
         end;
        end;
      8:begin
	 ExitBinaryEditor:=false;
	 wia(1,1,rahmattr,'É'+cstr('Í',33)+'µ');
         if lfehler<maxerrors then begin
           inc(lfehler);
           eddata.cursorpos:=errata[lfehler].errpos;
           wia(1,1,llinattr,erm[errata[lfehler].err]);
         end;
        end;
      9 :
        begin
	 ExitBinaryEditor:=true;
	 ch:=altf3;
	end;
      10 :
        begin
	 ExitBinaryEditor:=true;
	 ch:=altf1;
	end;
      11 :
        begin
	 ExitBinaryEditor:=true;
	 ch:=altf2;
	end;
    end;
  end;                        {ExitBinaryEditor}

begin
  ResetBinaryEditor(EdData[wndnr]);
{  if EditorbufferUeberlauf then Error(39);}
  EdBufpos:=0;
  if ch=f8 then startcom:='' else startcom:='';
  {Edit the file}
  repeat
    ExitCommand :=
    UseBinaryEditor(
      EdData[wndnr],                     {Editor control block for this window}
     startcom);                        {No startup commands passed to editor}
  {Handle the exit by saving the file or whatever}
    Junk := ExitBinaryEditor(EdData[wndnr], ExitCommand);
   until junk;
   editor:=ch;
end;

function geteditor(var ende:boolean;wndnr:byte):LongStr;
begin
 if EdBufpos>=EdData[wndnr].EoText then begin ende:=true;geteditor:='';
 end else begin
  ende:=false;
   geteditor:=MoveFromBinaryEditor(EdData[wndnr],EdBufpos);
 end;
end;

function Saveeditor(fname:LongStr):boolean;
begin
  setEditorFilename(fname);
   editorerrornr:=SaveFileBinaryEditor(EdData[wndnr],true);
  Saveeditor:=editorerrornr=0;
end;

function Loadeditor(Dname:LongStr):boolean;
Var
  Dir   : LongStr;
  Name  : String [8];
  Ext	: String [3];

begin
  wia(1,1,rahmattr,'É'+cstr('Í',33)+'µ');
  If DName [2] <> ':' Then Dname:=fexpand(Dname)
  Else Begin
    FSplit (DName,Dir,Name,Ext);
    Dir:=Copy (Dir,1,Ord (Dir [0])-1);
    ChDir (Dir);
  End;
  editorerrornr:=ReadFileBinaryEditor(EdData[wndnr],Dname);
  Loadeditor:=  editorerrornr=0;
end;

procedure cleareditor(fname:LongStr);
begin
  seteditorfilename(fname);
  with eddata[wndnr] do begin
    EOtext := 0;
    Buffer^[EOtext] := #0;
  end;
end;

procedure seteditorfilename(s:LongStr);
begin
  s:=fexpand(s);
  setFilename(EdData[wndnr],s);
end;

function ModifiedEditor: Boolean;
begin
  ModifiedEditor:=ModifiedFileBinaryEditor(EdData [wndnr]);
end;

end.
