Program SwapCom;

{ Tr„gt COM3 in Sanyo - Tabelle ein und tauscht diese mit COM2 }

Var
  COMData : Array [1..6] Of Word Absolute $0040:$0000;
  Temp    : Word;

Begin
  WriteLn;
  WriteLn ('COM - Swap V1.0 f. Sanyo');
  WriteLn ('Aufruf:');
  WriteLn ('SWAPCOM    -> COM3 installieren');
  WriteLn ('SWAPCOM 1  -> COM3 installieren und COM2 / COM3 tauschen');
  WriteLn;
  If ComData [3] = 0 Then Begin
    ComData [3] := $3E8;
    WriteLn ('COM3 auf 3E8h installiert.');
  End
  Else Write (^G);
  If ParamCount = 0 Then Begin
    Halt;
  End
  Else Begin
    Temp := ComData [3];
    ComData [3] := ComData [2];
    ComData [2] := Temp;
    WriteLn ('COM3 und COM2 getauscht.');
  End;
  WriteLn ('COM1: ',ComData [1],
           ', COM2: ',ComData [2],
           ', COM3: ',ComData [3]);
End.
