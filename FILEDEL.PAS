Unit FileDel;

Interface


Uses astypdea,Procs,Dos,CRT;

(* ================================================================== *)
(* Prozedurbeschreibung:                                              *)
(* GetEntries = Prozedur zum Suchen von Dateien nach bestimmten       *)
(*              Kriterien in einem Unterverzeichnis.                  *)
(*              Das Ergebnis der Suche                                *)
(*              wird in der Datei abgelegt die durch DOCNAME (s.u.)   *)
(*              festgelegt ist.                                       *)
(*              Die Datei DOCFILE (s.u.) mu· vorher angelegt und      *)
(*              geîffnet worden sein                                  *)
(*                                                                    *)
(* DoFiles    = Rekursiver Aufruf von GetEntries fuer alle Verzeich-  *)
(*              nisse und Unterverzeichnisse ab STARTDIR (s.u.)       *)
(* ================================================================== *)
(* Die folgende typisierten Konstanten legen die Anfangsbedingungen   *)
(* fÅr die AusfÅhrung von DOFILES, GETFILES und GETENTRIES fest       *)
(* Bei Bedarf kînnen sie durch eigene Parameter Åberschrieben werden  *)
(* Hier nun eine kurze Zusammenfassung der Funktionen:                *)
(* DocName = Name von Datei/Verzeichnis in dem DOCFILE abgelegt wird  *)
(* FData.Name      = Name der von GetFiles zu suchenden Dateien       *)
(* FData.FAttrIncl = Attribut      "               "                  *)
(* FData.FAttrExcl = Attribute die nicht gesucht werden sollen        *)
(* StartDir = Verzeichnis ab dem die Suche erfolgen soll              *)
(* BatchLead = Optionale Kommandos die den im DOCFILE gespeicherten   *)
(*             Dateinamen vorangestellt werden sollen                 *)
(* BatchTail = Optionale Kommandos die den im DOCFILE gespeicherten   *)
(*             Dateinamen nachgestellt werden sollen                  *)
(* Date      = Speicherdatum der Dateien nach denen gesucht wird      *)
(* DateComp  = Vergleich ob Date grî·er (greater), kleiner (less) oder*)
(*             gleich dem Speicherdatum sein soll                     *)
(* ------------------------------------------------------------------ *)

Procedure DelFiles (DateiName : Str12);

Implementation

Type
  FileData = Record
               Name      : Str12;
               FattrIncl : Byte;
               FattrExcl : Byte;
             End;


Const
  FData     : FileData = (
                Name      : '*.BAK';
                FAttrIncl : $3F;
                FattrExcl : $0A
              );
  StartDir  : String = 'C:\';
  Date      : DateTime = (Year : 1991; Month : 6; Day : 5;
                          Hour : 0;    Min   : 0; Sec : 0);
  DateComp  : Byte     = 1;
  greater   = 1;
  less      = 2;
  equal     = 3;

Type
  Verzeichnis = ^Eintrag;

  Eintrag   = Record
                Name : String [12];
                Done : Boolean;
                Next : Verzeichnis;
              End;

Var
  Verz     : String;
  Rec      : SearchRec;
  HeapTop  : ^LongInt;
  Dummy    : Boolean;

Procedure GetFiles;
Var
  Verz     : String;
  Rec      : SearchRec;
  f        : File;
  DT       : DateTime;
  T1,T2    : LongInt;

Procedure DelData;
Begin
  GetDir (0,AktDir);
  If AktDir + '\' = ROMDir Then Exit;
  Assign (f,Rec.Name);
{
  WriteLn (Rec.Name);
}
  If (Rec.Name = 'ROM.SYM')
  Or (Rec.Name = 'EZ80.SYM')
  Or (Rec.Name = 'PROFI_2K.SYM')
  Or (Rec.Name = 'PROFI_4K.SYM')
	Or (Rec.Name = 'PROFI_5E.SYM')
	Or (Rec.Name = 'MFA.SYM')
	Then Exit;
  If Exist (Rec.Name) Then Erase (f);
End;

Begin
  FindFirst (FData.Name,FData.FattrIncl,Rec);
  While (DosError <> 18) Do Begin
    If (
        (Rec.Attr <> Directory) And
        ((Rec.Attr And FData.FAttrExcl) = 0)
       )
    Then Begin
      Assign (f,Rec.Name);
      (*$I-*)
      reset (f);
      Dummy := IOResult = 0;
      (*$I+*)
{Neu}
      DelData;
{Original}
{
      GetFTime (f,T1);
      UnPackTime (T1,DT);
      PackTime (Date,T2);
      Case DateComp of
        Greater : If T1 > T2 Then DelData;
        Less    : If T1 < T2 Then DelData;
        Equal   : If T1 = T2 Then DelData;
      End;
}
      (*$I-*)
      close (f);
      Dummy := IOResult = 0;
      (*$I+*)
    End;
    FindNext (Rec);
  End;
End;

Procedure GetEntries;

Var
  AktVerz,FirstVerz,LastVerz,NewVerz   : Verzeichnis;
  AktDir,
  Verz   : String;

Procedure FindDirs;
Begin
  FindFirst ('*.*',Directory,Rec);
  While (DosError <> 18) Do Begin
    If (Rec.Name <> '.')
      And (Rec.Name <> '..')
      And (Rec.Attr = Directory) Then Begin
        New (NewVerz);
        NewVerz^.Name := Rec.Name;
        NewVerz^.Done := False;
        If FirstVerz = Nil Then FirstVerz := NewVerz
          Else LastVerz^.Next := NewVerz;
        LastVerz := NewVerz;
        LastVerz^.Next := Nil;
    End;
    FindNext (Rec);
  End;
End;

Begin
  FirstVerz := Nil;
  Repeat
    FindDirs;
    AktVerz := FirstVerz;
    While AktVerz <> Nil Do Begin
      With AktVerz^ Do Begin
        If Not Done Then Begin
          ChDir (Name);
          GetFiles;
          GetEntries;
          Done := True;
        End; { If not Done }
        AktVerz := Next;
      End; { With AktVerz^ }
    End;
  Until (AktVerz = Nil);
  GetDir (0,Verz);
  (*$I-*)
  If Verz <> StartDir Then ChDir ('..');
  (*$I+*)
  Dummy := IoResult = 0;
End;

Procedure GetFileInit;
Begin
  Mark (HeapTop);
  GetDir (0,StartDir);
End;

Procedure GetFileExit;
Begin
  GetEntries;
  Release (HeapTop);
End;

Procedure DelFiles (DateiName : Str12);
Begin
  FData.Name :=  DateiName;
  GetFileInit;
  GetFiles;
  GetFileExit;
End;

End.
