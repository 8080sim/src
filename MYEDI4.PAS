unit myedi4;
{$i direct.inc}
interface
uses
  crt,dos,            {Standardunits}
  MyWindow,           {Fensterverwaltung}
  myGloerr,
  Mybined,
  asprocs;
var EditorBufferUeberlauf:boolean;
function  initeditor(nr:integer):boolean;
Procedure  filleditor(s:string);
function  geteditor(var ende:boolean):string;
procedure closeeditor;
function  Saveeditor(fname:string):boolean;
function  loadeditor(fname:string):boolean;
function  editor(ch:char):char;
function ModifiedEditor: Boolean;
procedure seteditorfilename(s:string);
implementation


const
  {Coordinates of the editor window}
  MakeBackup = false;          {True to create .BAK files}
var
  EdData : array[0..7] of EdCB;              {Editor control block}
  ExitCode : Word;            {Status code set by binary editor functions}
  ExitCommand : Integer;      {Code for command used to leave editor}
  Fname : string;             {Input name of file being edited}
  Junk : Boolean;
  bufpos:word;
const
  {Commands other than ^K^D to exit editor}
  ExitCommands : array[0..18] of Char =
  (#2, #0,f1,#2, #0,f5,#2,#0,f6,#2,#0,altF1,#2,#0,F10,#2,#0,f8,#0);

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
(* Original:
	EdOptInsert+EdOptTAB,       {Initial editor toggles}
*)
	EdOptIndent+EdOptInsert+EdOptTAB,       {Initial editor toggles}
  '.TXT',                     {Default extension for file names}
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
var  startcom :str2;

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
	 ch:=f1;
	end;
     1 :
	begin
	 ch:=f5;
	 ExitBinaryEditor:=true;
        end;
     2 :
	begin
	 ch:=f6;
	 ExitBinaryEditor:=true;
        end;
      3:begin
	 hilfe(600);
	 ExitBinaryEditor:=false;
	end;
      4:begin
	 ExitBinaryEditor:=true;
	 ch:=f10;
	end;
      5:begin
	 ExitBinaryEditor:=true;
	 ch:=f8;
	end;
       end;
  end;                        {ExitBinaryEditor}
begin
  ResetBinaryEditor(EdData[wndnr]);
{  if EditorbufferUeberlauf then Error(39);}
  bufpos:=0;
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
function geteditor(var ende:boolean):string;
begin
 if bufpos>=EdData[wndnr].EoText then begin ende:=true;geteditor:='';
 end else begin
  ende:=false;
   geteditor:=MoveFromBinaryEditor(EdData[wndnr],Bufpos);
 end;
end;
function Saveeditor(fname:string):boolean;
begin
  setEditorFilename(fname);
  Saveeditor:=SaveFileBinaryEditor(EdData[wndnr],true)=0;
end;
function Loadeditor(fname:string):boolean;
begin
  fname:=fexpand(fname);
  Loadeditor:=ReadFileBinaryEditor(EdData[wndnr],fname)=0;
end;
procedure seteditorfilename(s:string);
begin
  s:=fexpand(s);
  setFilename(EdData[wndnr],s);
end;
function ModifiedEditor: Boolean;
begin
  ModifiedEditor:=ModifiedFileBinaryEditor(EdData [wndnr]);
end;
end.
