PROGRAM convert;

USES DOS,CRT;
VAR          hex_f : FILE OF BYTE;
             asc_f : FILE OF char;
         cdat,bdat : char;
             z,x,y : BYTE;
       zeile,iy,ix : INTEGER;
            laenge : LONGINT;
            ende_1 : BOOLEAN;
   eingabe,ein,aus : string;

BEGIN
  clrscr;
  writeln('Dieses Programm convertiert aus der vom 8080SIM erzeugten');
  writeln('HEX-Datei eine Bin„rdatei.');
  writeln;
  writeln('Bitte geben Sie einen FILE-Namen an !');
  readln(eingabe);
  if eingabe = '' THEN ende_1:=TRUE ELSE ende_1:=FALSE;
  IF length(eingabe)>20 THEN ende_1:=TRUE;
IF NOT ENDE_1 THEN BEGIN
  ein:=eingabe+'.hex';
  aus:=eingabe+'.bin';
  assign(asc_f,ein);
  assign(hex_f,aus);
  reset(asc_f);
  rewrite(hex_f);
  laenge:=0;zeile:=10;
  while (filepos(asc_f)<filesize(asc_f)-1) AND ((zeile+laenge*77)<filesize(asc_f)-17) DO BEGIN
    x:=0;ix:=0;y:=0;iy:=0;
    seek(asc_f,laenge*77+zeile-1);
    read(asc_f,bdat);IF bdat=':' THEN read(asc_f,bdat);
    read(asc_f,cdat);IF cdat=':' THEN read(asc_f,cdat);
    val(bdat,x,ix);
    IF ix>0 THEN
       CASE  bdat OF
          'A': x:=10;
          'B': x:=11;
          'C': x:=12;
          'D': x:=13;
          'E': x:=14;
          'F': x:=15;
          END;{case}
    val(cdat,y,iy);
    IF iy>0 THEN
       CASE cdat OF
          'A': y:=10;
          'B': y:=11;
          'C': y:=12;
          'D': y:=13;
          'E': y:=14;
          'F': y:=15;
          END;{case}
       z:=x;
       z:=z shl 4;
       z:=z+y;
       write(hex_f,z);
       zeile:=zeile+2;
      IF zeile>73 THEN BEGIN
         laenge:=laenge+1;
         zeile:=10;
         END;
  END;{while}
  close(asc_f);
  close(hex_f);
end;{ if not ende_1 }
 END.