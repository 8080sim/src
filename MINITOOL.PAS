Unit Minitool; (* Nach c't 12/88 S.134 *)
{$R+}
Interface
Uses CRT,DOS;
Const
  NoAttr   = $FF;

Type
  Str6       = String [6];
  Str12      = String [12];
  Str80      = String [80];
  DirPointer = ^DirRec;
  DirRec     = Record
                 Name : Str12;
                 Attr : Byte;
                 Time,
                 Size : LongInt;
                 Next : DirPointer;
               End;

Var
  GrTrb,GrMod,Fehler : Integer;
  Attr_Alt           : Byte;

Function UpCaseStr (ST : String) : String;
Function StrToAttr (ST : Str6):Byte;
Function AttrToStr (Attr : Byte) : Str6;
Procedure ReadDir (Path : String;Ja,Nein : Byte;Var Fehler : Byte;
                   Var Anzahl : Word; Var Start : DirPointer);
Procedure FreeDir (Var DP : DirPointer);
Procedure DirectWrite (x,y : byte; AC : Word);
Function DirectRead (x,y : Byte): Word;
Procedure StoreScreen (ULX,ULY,LRX,LRY:Byte; Var Store : Pointer);
Procedure RestoreScreen (Restore : Pointer);
Procedure WindowPaint (ULX,ULY,LRX,LRY:Byte; Titel : Str80);
Procedure WindowStore (ULX,ULY,LRX,LRY:Byte; Titel : Str80; Var Store : Pointer);
Function SelectDirRec (Titel : Str80; Start : DirPointer;
                       Sichern : Boolean ): DirPointer;
Function SelectFile (Path : Str80): Str80;
Procedure WindowClose;

Implementation
Var
  ScrMono : Array [1..25,1..80] of Word Absolute $B000:$0000;
  ScrCGA  : Array [1..25,1..80] of Word Absolute $B800:$0000;
  Mono    : Boolean;
  Regs    : Registers;

Function UpCaseStr (St : String) : String;
Var
  lv : Byte;

Begin
  For lv :=1 to Length (ST) Do ST[lv] := UpCase (ST[lv]);
  UpCaseStr := ST;
End;

Function StrtoAttr;
Var
  B : Byte;

Begin
  B:=0;
  ST := UpCaseStr (ST);
  If Pos ('R',ST) > 0 Then B:=B + ReadOnly;
  If Pos ('H',ST) > 0 Then B:=B + Hidden;
  If Pos ('A',ST) > 0 Then B:=B + Archive;
  If Pos ('S',ST) > 0 Then B:=B + SysFile;
  If Pos ('D',ST) > 0 Then B:=B + Directory;
  If Pos ('V',ST) > 0 Then B:=B + VolumeID;
  If B = 0 Then B:= NoAttr;
  StrtoAttr := B;
End;

Function AttrToStr;
Var
  ST : Str6;

Begin
  If (Attr And ReadOnly ) = 0 Then ST := '-' Else ST := 'R';
  If (Attr And Hidden   ) = 0 Then ST := ST + '-' Else ST := ST + 'H';
  If (Attr And Archive  ) = 0 Then ST := ST + '-' Else ST := ST + 'A';
  If (Attr And SysFile  ) = 0 Then ST := ST + '-' Else ST := ST + 'S';
  If (Attr And Directory) = 0 Then ST := ST + '-' Else ST := ST + 'D';
  If (Attr And VolumeID ) = 0 Then ST := ST + '-' Else ST := ST + 'V';
  AttrToStr := ST;
End;

Function Expand (Name : Str12) : Str12;
Var
  A,B : Byte;
  S   : Str12;

Begin
  A := Pos ('.',Name);
  If A>1 Then Begin
    S := '';
    For B:=A to 8 Do S:=S + ' ';
    InSert (S,Name,A);
  End;
  Expand := Name;
End;

Procedure ReadDir;
Var
  Eintrag : SearchRec;
  Neu     : DirPointer;

  Procedure InsertList (Var Alt,Neu : DirPointer);
  Var
    P : DirPointer;

  Begin
    If Alt = Nil Then Alt := Neu
                 Else
                   If Alt^.Name > Neu^.Name Then Begin
                     P := Alt; Alt := Neu; Neu^.Next := P;
                   End
                   Else
                     If Alt^.Next = Nil Then Alt^.Next:=Neu
                                        Else InsertList (Alt^.Next,Neu);
  End;

  Function Test (Eintrag : SearchRec) : Boolean;
  Begin
    With Eintrag Do
      Test := (((Attr And Ja ) = Ja ) Or (Ja  = NoAttr)) And
              (((Attr And Nein) = 0) Or (Nein = NoAttr)) And
              (Name <> '.');
  End;

Begin
  Anzahl := 0;
  FindFirst (Path,AnyFile,Eintrag);
  Fehler := DosError;
  If (Fehler = 0) And Test (Eintrag) Then Begin
    Inc (Anzahl);
    New (Neu);
    With Neu^ Do Begin
      Name := Eintrag.Name; Attr := Eintrag.Attr;
      Time := Eintrag.Time; Size := Eintrag.Size;
      Next := Nil;
    End;
    InsertList (Start,Neu);
  End;
	While (Fehler = 0) And (MaxAvail > SizeOf (Eintrag)) Do Begin
		FindNext (Eintrag);
		Fehler := DosError;
		If (Fehler = 0) And Test (Eintrag) Then Begin
			New (Neu);
			Inc (Anzahl);
			With Neu^ Do Begin
				Name := Eintrag.Name; Attr := Eintrag.Attr;
				Time := Eintrag.Time; Size := Eintrag.Size;
				Next := Nil;
			End;
			InsertList (Start,Neu);
		End;
	End;
End;

Procedure FreeDir;
Begin
	If DP <> Nil Then Begin
    If DP^.Next <> Nil Then FreeDir (DP^.Next);
    DisPose (DP);
  End;
End;

Procedure DirectWrite;
Begin
  If Mono Then ScrMono [y,x] := AC
  Else ScrCGA  [y,x] := AC;
End;

Function DirectRead;
Begin
  If Mono Then DirectRead := ScrMono [y,x]
  Else DirectRead := ScrCGA  [y,x];
End;

Procedure StoreScreen;
Var
  x,y : Byte;
  S,O : Word;

Begin
  X:= LRX - ULX +1; Y:= LRY - ULY +1;
  GetMem (Store,X*Y*2+4);
  S:= Seg (Store^); O:= Ofs (Store^);
  Mem [S:O]   := ULY; Mem [S:O+1] := ULX;
  Mem [S:O+2] :=   Y; Mem [S:O+3] :=   X;
  O:=O+2;
  For Y:= ULY to LRY Do Begin
    For X:= ULX to LRX Do Begin
      O:=O+2;
      MemW [S:O] := DirectRead (X,Y);
    End;
  End;
End;

Procedure RestoreScreen;
Var
  X,Y,ULX,ULY,LRX,LRY : Byte;
  S,O,O1              : Word;

Begin
  S:=Seg(Restore^); O:=Ofs (Restore^); O1 :=O;
  ULY := Mem [S:O]; ULX := Mem [S:O+1];
  LRY := ULY + Mem [S:O+2]-1; LRX := ULX + Mem [S:O+3]-1; O:=O+2;
  For Y:=ULY to LRY Do Begin
    For X:=ULX to LRX Do Begin
      O:=O+2;
      DirectWrite (X,Y,MemW[S:O]);
    End;
  End;
  FreeMem (Restore,Mem[S:O1] * Mem[S:O1+1] * 2 +4);
End;

Procedure WindowPaint;
Var
  LV  : Byte;
  AC  : Word;

Begin
  AC := TextAttr * $100 + 196;
  For LV := ULX to LRX Do Begin
    DirectWrite (LV,ULY,AC);
    DirectWrite (LV,LRY,AC);
  End;
  AC := TextAttr * $100 + 179;
  For LV := ULY to LRY Do Begin
    DirectWrite (ULX,LV,AC);
    DirectWrite (LRX,LV,AC);
  End;
  AC := TextAttr * $100;
  DirectWrite (ULX,ULY,AC+218);  DirectWrite (ULX,LRY,AC+192);
  DirectWrite (LRX,ULY,AC+191);  DirectWrite (LRX,LRY,AC+217);
  Window (1,1,80,25);
  If LRX - ULX > Length (Titel) + 4 Then Begin
    GotoXY (ULX+(LRX-ULX-Length(Titel)) Div 2,ULY);
    Write (Titel);
  End;
  Window (ULX+1,ULY+1,LRX-1,LRY-1);
  ClrScr;
End;

Procedure WindowStore;
Begin
  StoreScreen (ULX,ULY,LRX,LRY,Store);
  WindowPaint (ULX,ULY,LRX,LRY,Titel);
End;

Function SelectDirRec;
Var
  Zeile, Spalte,
  XPos,YPos,
  TextAttrAlt,
  AusSchnitt,MaxAusSchnitt : Byte;
  WO,WU                    : Word;
  Anzahl                   : Integer;
  Ende                     : Boolean;
  Ch1,Ch2                  : Char;
  St                       : String [14];
  StoreScr                 : Pointer;
  P                        : DirPointer;
  PointerList              : Array [0..3,1..8] Of DirPointer;

  Procedure BildAufbau;
  Var
    LV,Z,S : Byte;
    Test   : Boolean;

  Begin
    For S:=0 to 3 Do Begin
      For Z:=1 to 8 Do Begin
        PointerList [S,Z] := Nil;
      End;
    End;
    TextAttr := 112;
    P:= Start; S:=0; Z:=1;
    ClrScr;
    For LV:=1 to AusSchnitt * 4 Do P:= P^.Next;
    Repeat
      GotoXY (3+S*16,z);
      PointerList [S,Z]:=P;
      If (P^.Attr And Directory) = Directory Then Write ('[',P^.Name,'\]')
      Else Write (Expand (P^.Name));
      Test := (P^.Next = Nil) Or ((Z=8) And (S=3));
      If Not Test Then Begin
        P:=P^.Next;
        Inc (s);
        If S=4 Then Begin
          S:=0;
          Inc (Z);
        End;
      End;
    Until Test;
  End;

Begin
  SelectDirRec := Nil;
  If Start = Nil Then Exit;
  TextAttrAlt := TextAttr;
  TextAttr := 112;
  WO := WindMin; WU := WindMax;
  XPos := WhereX; YPos := WhereY;
  If Sichern Then WindowStore (8,9,73,18,' ' + Titel + ' ',StoreScr)
             Else WindowPaint (8,9,73,18,' ' + Titel + ' ');
  Zeile := 1; Spalte := 0; Ausschnitt := 0;
  P := Start; Anzahl :=1;
  While P^.Next <> Nil Do Begin
    Inc (Anzahl);
    P:= P^.Next;
  End;
  Anzahl := Anzahl - 32;
  If Anzahl < 1 Then MaxAusschnitt :=0
                Else Begin
                  MaxAusschnitt := Anzahl Div 4;
                  If Anzahl Mod 4 >0 Then Inc (MaxAusschnitt);
                End;
  BildAufbau;
  Ende:=False;
  Repeat
    GotoXY (2+Spalte*16,Zeile);
    TextAttr:=15;
    With PointerList [Spalte,Zeile]^ Do
    If (Attr And Directory) = Directory Then St := ' ['+Name+'\]'
                                        Else St := ' '+Expand(Name);
    Write (St,'':14-Length (St));
    Ch1 := ReadKey;
    Case Ch1 of
      {ESC}  #27 : Begin
                     SelectDirRec :=Nil;
                     Ende := True;
                   End;
      {RET}  #13 : Begin
                     SelectDirRec:= PointerList [Spalte,Zeile];
                     Ende := True;
                   End;
      {SCAN} #0  : Begin
                     Ch2 := ReadKey;
                     If (Ch2 <> #73) And (Ch2 <> #81) Then Begin
                       GotoXY (2+Spalte*16,Zeile); TextAttr := 112;
                       With PointerList [Spalte,Zeile]^ Do
                         If (Attr And Directory) = Directory Then
                           St := ' ['+Name+'\]'
                         Else St := ' '+Expand(Name);
                         Write (St,'':14-Length (St));
                     End;
                     Case Ch2 of
                       {UP}   #72 : If Zeile > 1 Then Dec (Zeile)
                                                 Else If Ausschnitt > 0 Then Begin
                                                   Dec (Ausschnitt);
                                                   BildAufbau;
                                                 End;
                       {DOWN} #80 : If Zeile < 8 Then Begin
                                      If PointerList [Spalte,Zeile+1] <> Nil Then
                                        Inc (Zeile);
                                    End
                                    Else If Ausschnitt < MaxAusschnitt Then Begin
                                      Inc (Ausschnitt);
                                      BildAufbau;
                                      While PointerList [Spalte,Zeile] = Nil Do
                                        Dec (spalte);
                                    End;

                       {Left} #75 : If Spalte > 0 Then Dec (Spalte);
                       {Right}#77 : If Spalte < 3 Then
                                      If PointerList[Spalte+1,Zeile] <> Nil Then
                                        Inc (Spalte);

                       {PUp}  #73 : If Ausschnitt > 0 Then Begin
                                      Dec (Ausschnitt);
                                      BildAufbau;
                                    End;
                       {PDown}#81 : If Ausschnitt < MaxAusschnitt Then Begin
                                      Inc (Ausschnitt);
                                      BildAufbau;
                                      While PointerList [Spalte,Zeile] = Nil Do
                                        Dec (Spalte);
                                    End;
                     End; (* Case Ch2 *)
                   End; (* SCAN = #0 *)
    End; (* Case Ch1 *)
  Until Ende;
  If Sichern Then RestoreScreen (StoreScr);
  Window (Lo(WO)+1,Hi (WO)+1,Lo(WU)+1,Hi(WU)+1);
  GotoXY (XPos,Ypos);
  TextAttr := TextAttrAlt;
End;

Function SelectFile;
Label
  Ende;

Var
  Test             : Boolean;
  LV,Fehler        : Byte;
  Anzahl1,Anzahl2  : Word;
  AltDir,Suchweg,
  WildCard         : Str80;
  StoreScr         : Pointer;
  DP1,DP2          : DirPointer;

Begin
  SelectFile := '';
  GetDir (0,AltDir);
  DP1 := Nil;
  StoreScreen(8,9,73,18,StoreScr);
  LV := Length (path);
  While (Path[LV] <> '\') And (Path[LV] <> ':') And (LV>0) Do Dec (LV);
  If LV = Length (Path) Then Begin
    SuchWeg := Path;
    WildCard := '*.*';
  End
  Else Begin
    SuchWeg := Copy (Path,1,LV);
    WildCard:= Copy (Path,LV+1,Length(Path)-LV);
  End;
  LV := Length (SuchWeg);
  If (SuchWeg [LV-1] <> ':') And (SuchWeg [LV] = '\') Then
    SuchWeg := Copy (SuchWeg,1,LV-1);
  If SuchWeg <> '' Then Begin
    (*$I-*) ChDir (SuchWeg); (*$I+*)
    If IoResult <> 0 Then Goto Ende;
  End;
  Repeat
    ReadDir ('*.*',Directory,NoAttr,Fehler,Anzahl1,DP1);
    If Fehler <> 18 Then Goto Ende;
    If DP1 <> Nil Then Begin
      DP2 := DP1;
      While DP2^.Next <> Nil Do Dp2 := DP2^.Next;
      ReadDir (WildCard,NoAttr,Directory+VolumeID,Fehler,Anzahl2,DP2^.Next);
    End
    Else ReadDir (WildCard,NoAttr,Directory+VolumeID,Fehler,Anzahl2,DP1);
    If (Fehler <> 18) Or (Anzahl1 + Anzahl2 =0) Then Goto Ende;
    GetDir (0,SuchWeg);
    If Length(SuchWeg) > 3 Then SuchWeg := SuchWeg + '\';
    DP2 := SelectDirRec (SuchWeg + WildCard,DP1,False);
    Test := True;
    If DP2 <> Nil Then
      If (DP2^.Attr And Directory) = Directory Then Begin
        ChDir (DP2^.Name);
        Test := False;
      End
      Else SelectFile := SuchWeg + DP2^.Name;
    FreeDir (DP1);
    DP1 := Nil;
  Until Test;
  Ende:
  ChDir (AltDir);
  If DP1 <> Nil Then FreeDir (DP1);
  RestoreScreen (StoreScr);
End;

Procedure WindowClose;
Begin
  TextAttr := Attr_Alt;
  Window (1,1,80,25);
  ClrScr;
End;

Procedure CloseWindow;
Begin
  WindowClose;
End;

Begin
  Regs.ah := 15;
  Intr ($10,Regs);
  Mono := (Regs.al=7);
  Attr_alt := TextAttr;
End.

