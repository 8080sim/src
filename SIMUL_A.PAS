unit simul_a;

{$i direct.inc}

interface
uses crt,procs,printer,
     assembla,
     astypdea,
     asprocs,
     mygloerr,
     mywindow,
     myinput,
     int05;


function getbyte(i:word):byte;

function lad_inc(var i:word):byte;

procedure simula;

Const
  EZ80_Typ= 1;
  P5_2K   = 2;
  P5_4K   = 3;
  P5_8K   = 4;
  MFA_Typ = 5;
  Anw_Typ = 6;

implementation

type t_l41=record
				r8:array[1..8] of str2;
        r16:array[1..2] of str4;
			end;

Var
	 TA     : LongInt;
	 Zeit   : LongInt Absolute $0040:$006C;
	 TLoop  : LongInt;

const
	DelayTime : Word    = 1;
	RomTrace  : Boolean = True;

Const
  l4anz = 10;
  l4: ARRAY[1..l4anz] OF RECORD
  xp,yp,xe,le,te :BYTE;

	m :STRING[80] END =
   (
    (xp: 1;yp: 1;xe:3;le: 2;te: 9;m :''),
    (xp: 1;yp: 1;xe:14;le: 2;te: 9;m :''),
    (xp: 1;yp: 3;xe:3;le: 2;te: 9;m :''),
    (xp: 1;yp: 3;xe:14;le: 2;te: 9;m :''),
    (xp: 1;yp: 5;xe:3;le: 2;te: 9;m :''),
    (xp: 1;yp: 5;xe:14;le: 2;te: 9;m :''),
    (xp: 1;yp: 7;xe:3;le: 2;te: 9;m :''),
    (xp: 1;yp: 7;xe:14;le: 2;te: 9;m :''),
		(xp: 1;yp: 9;xe:2;le: 4;te: 9;m :''),
		(xp: 1;yp: 9;xe:13;le: 4;te: 9;m :''));

type
	_command = array[1..4] of str4;

var
		ialt:word;
		l41:t_l41;
		command,LastCommand : _command;
		s:str80;
		disstr:string[25];
		memadr,i,j,k,x,y:word;
		b,b1:byte;
		ascc,esc:boolean;
		step,adresserror:boolean;
		stopadr:word;
		c:str80;

const
		rbn :array[0..8] of char =
		 ('B','C','D','E','H','L','M','A',' ');
	 rwn :array[0..4] of str2 =
		 ('B','D','H','SP','');

{$ifdef madebug}
	maxramsize=$9000;

{$else}
	maxramsize=$ffff;

{$endif}

type
 _vptr =^_vidsave;
 _vidsave=array[1..$4000] of byte;
 reg8080 = record
	case word of
	 0 : (c,b,e,d,l,h,a,m:byte);
	 1 : (bc,de,hl,af,sp,pc:word);
	 2 : (aw:array[0..5] of word);
	 3 : (ab: array[0..7] of byte);
 end;

 var
		vid :_vptr;
		ram:^byte;
		dummy:^byte;
		ramseg:word;
		writerom:boolean;
		hexstr                            :str8;
		port80                            :array[0..4,0..12] of byte;
		inte                              :array[0..2,0..2] of boolean;
		reg,regalt:reg8080;
		flags,flagsalt,
{Original jetzt in INT05 deklariert}
{
		intmask,
}
		o0,o1,o2,ot,by:byte;
		pcport1:word;
		sscr:pointer;
		xpo,ypo:byte;

Procedure ZeigMaske; Forward;
Procedure ShowDis (i:Word); Forward;
Procedure CheckCommand; Forward;

{$i simul1_a.inc}

Var
	 Tastm  : Boolean;
	TempCh      : Char;

Function CheckKey : Boolean;
Const
  TxtBufAnf   : Word = $001E;
Var
  TxtBufStart : Word Absolute $0040:$001A;
  TxtBufEnd   : Word Absolute $0040:$001C;
  Taste       : Word;
	TastCh      : Char;

Begin
  If TxtBufStart = TxtBufEnd Then Begin {keine Taste gedrÅckt}
		CheckKey := False;
		Exit;
  End;
	Taste := Mem [$0040:TxtBufStart];    { Keine Funktionstaste, kein Buchstabe}
  If Lo (Taste) <> 0 Then Begin
    TastCh := UpCase (Chr (Lo(Taste)));
    If TastCh = ' ' Then Begin
      TastCh := UpCase (ReadKey);
      TxtBufStart := TxtBufAnf;
      TxtBufEnd   := TxtBufAnf;
			CheckKey := False;
      Tastm    := True;
      Exit;
    End
  End
  Else Begin
		CheckKey := True;
  End;
End;


procedure sim;
var
addre:word;
bb,byt :byte;

procedure return;
var b1, b2:byte;
begin
 b1:=lad_inc(reg.sp); b2:=lad_inc(reg.sp);
 reg.pc:=b1 + b2 shl 8;
end;

procedure loesch;
begin
  popwin(true);window(1,1,80,24);
end;

procedure tastd;
var ch:char;
		esc:boolean;
		by:byte;
begin
	anzeige;
	Meldung(1);
	repeat
		ch:=readkey;
		esc:=false;
		by:=$ff;
		if (ch=#0) then begin
			ch:=readkey;
			esc:=true
		end
		else ch:=cap(ch);
		if esc then case ch of
				f3:by:=$11;
				f4:by:=$10;
				f5:by:=$16;
				f6:by:=$17;
				f7:by:=$12;
				f8:by:=$14;
				f9:by:=$13;
				f10:by:=$15;
				f2:by:=$18;
				f1:hilfe(49);
		end
		else begin
			if ch in ['0'..'9'] then by:=ord(ch)-ord('0') else
				if ch in ['A'..'F'] then by:=ord(ch)-ord('A')+10 else
					if ch=#$0d then by:=$15;
		end;
	until (ch=#27) or (by in [0..$18]);
	loesch;
	if ch=#27 then begin
		step:=true;
		dec(reg.pc,3)
	end
	else reg.a:=by;
{ neu: Tastaturpuffer aufrÑumen }
	While KeyPressed Do Ch := ReadKey;
end;

procedure call;
var i,x:word;
		m,b,c:byte;
		ch:char;

function daa:word;
begin
	reg.a:=(reg.a shr 4) * 10 + (reg.a and $0f);
	daa:=reg.a;
end;

procedure realcall;
begin
   dec(reg.sp,2);
   putbyte(hi(reg.pc),reg.sp+1);putbyte(lo(reg.pc),reg.sp);
   reg.pc:=addre;
end;

begin
{$ifdef int}
	If EnRST And ei And GotInt And IntEnable Then Begin
		realCall;
    Sound (2000);
    Delay (IntLoop Div 5);
    NoSound;
    GotInt:=False;
		IntMask := IntMask And RSTRIM.AndMask;
		STI;
		exit;
  End
	Else inc(reg.pc,2);
{$else}
	inc(reg.pc,2);
{$endif}
  case simtyp of
	 1..4:begin
         if addre=$216 then tastd else
         if addre=$223 then begin
					 window(1,1,80,24);
					 gotoxy(2,24);Write('TastM mit Leertaste aktiveren');
           While KeyPressed Do TempCh := ReadKey;
           if Tastm then Begin
             Tastm := False;
             tastd;
             mem[ramseg:$83f3]:= $FF;
           End
           else Begin
						 reg.a:=$ff;
             mem[ramseg:$83f3]:= $00;
           End
         end else
         if addre=$e9b then else
         if addre=$ea9 then else
         if addre=$6d4 then delay(3*DelayTime) else
         if addre=$2dd then delay(4*DelayTime) else
				 if addre=$2ea then delay(9*DelayTime) else
         if addre=$6d9 then delay(9*DelayTime) else
         if addre=$2ef then delay(27*DelayTime) else
				 if addre=$300 then delay(daa*100) else
				 if addre=$310 then delay(daa*1000) else
				 if addre=$313 then delay(1000*reg.a) else
         if (addre=$3f0) or (addre=$3f4) then delay(100*reg.de) else
         if (addre=$320) or (addre=$32a) then begin
           meldung(2);
           ch:=readkey;
           If Ch = #0 Then Ch := ReadKey;
					 loesch;
         end else
				 if addre=$303 then delay(100*reg.a) else begin
           realcall;
         end;
       end;
{$ifdef mfa2}

	   MFA_Typ: if addre=$860 then begin
						 putbyte(0,$fcc8);
           end
           else if (addre=$89f) or (addre=$fc83) then begin
						 if not userpage then switchscreen(sscr^);
						 gotoxy(xpo,ypo);
						 write(chr(reg.a));
{NÑchste Zeile ist neu}
             edsetcursor(cursortype);
             xpo:=wherex;ypo:=wherey;
						 if not userpage then switchscreen(sscr^);
					 end
					 else if (addre=$82d) or (addre=$fc80) then begin
						 if not userpage then switchscreen(sscr^);
						 gotoxy(xpo,ypo);
						 ch:=readkey;
{ Neu zur Unterbrechung im S - Modus }
						 If ch=#0 Then Begin
							 ch := ReadKey;
							 If ch = f5 Then Begin
								 If UserPage And Not ShowRegs Then Begin
									 switchscreen(sscr^);
									 UserPage := Not UserPage;
									 ShowDis (Reg.PC);
									 ZeigPorts;
									 Repeat  Until KeyPressed;
{
									 ch := ReadKey;
									 If ch = #0 Then ch := ReadKey;
}
									 LastCommand := Command;
									 CheckCommand;
									 If Command [1][1] = 'S' Then Begin
										 userpage:=Not UserPage;
										 ShowRegs:=Not ShowRegs;
									 End
									 Else Command := LastCommand;
									 switchscreen(sscr^);
									 UserPage := Not UserPage;
								 End;
							 End;
						 End;
{ Ende Neu }
						 reg.a:=ord(ch);
						 if not userpage then switchscreen(sscr^);
					 end else realcall;
{$endif}
        Anw_Typ :realcall;
			end; {case}
    end;

procedure p_o0;
var carrysave:byte;
begin
	case o2 of
		0:case o1 of
					4:reg.a :=intmask;
					6:begin
							if reg.a and 8=8 then
								intmask:=(intmask and $f8) or (reg.a and 7);
{$ifdef int}
								EnRST := ((IntMask And RSTSim.OrMask)=0);
{$endif}
							if reg.a and $10=$10 then intmask:=intmask and $bf;
							if reg.a and $40=$40 then begin
								intmask:=intmask and $7f or (reg.a and $80);
								if intmask and $80=$80 then
								wia(45,3,eaattr,'1') else wia(45,3,eaattr,'0');
							end;
             end;
          end;
		1:begin
        if odd(o1) then
        BEGIN
          carrysave:=flags and $fe;
					inline
						($8A/$26/FLAGS/              {  MOV AH,FLAGS }
						$9E/                        {  SAHF }
						$A1/REG+4/                 {  MOV AX,[REG+4] }
						$32/$FF/                    {  XOR BH,BH }
            $8A/$1E/O1/                 {  MOV BL,O1 }
            $FE/$CB/                    {  DEC BL }
            $80/$FB/$06/                {  CMP BL,6 }
						$72/$02/                    {  JC C1 }
            $B3/$08/                    {  MOV BL,8 }
            $03/$87/REG/               {  C1: ADD AX,[BX+REG]  }
            $A3/REG+4/                 {  MOV [REG+4],AX }
						$9F/                        {  LAHF }
						$88/$26/FLAGS);              {  MOV [FLAGS],AH  }
          flags  :=flags and 1 or carrysave;
        END else begin
					 o1:=o1 shr 1;
						if o1 in [0..2] then reg.aw[o1]:=addre else reg.sp:=addre;
            reg.pc:=reg.pc+2;
        end;
			end;
 2:case o1 of
		 0:putbyte(reg.a,reg.bc);
		 1:reg.a:=getbyte(reg.bc);
		 2:putbyte(reg.a,reg.de);
		 3:reg.a:=getbyte(reg.de);
     4:begin putbyte(reg.h,addre+1);putbyte(reg.l,addre);reg.pc:=reg.pc+2 end;
     5:begin reg.h:=getbyte(addre+1);reg.l:=getbyte(addre);reg.pc:=reg.pc+2 end;
		 6:begin putbyte(reg.a,addre);reg.pc:=reg.pc+2 end;
		 7:begin reg.a:=getbyte(addre);reg.pc:=reg.pc+2 end;
  end;

 3: if odd(o1) then begin
      o1:=o1 shr 1;
      if o1 in [0..2] then dec(reg.aw[o1]) else
      dec(reg.sp);
		end else begin
      o1:=o1 shr 1;
			if o1 in [0..2] then inc(reg.aw[o1]) else
			 inc(reg.sp);
		end;
4:BEGIN
		o1:=o1 xor 1;
    carrysave:=flags and 1;
    Inline
			($8A/$26/FLAGS/              {  MOV AH,FLAGS }
      $9E/                        {  SAHF }
      $32/$FF/                    {  XOR BH,BH }
      $8A/$1E/O1/                 {  MOV BL,O1 }
			$FE/$87/REG/               {  C1: INC [BX+REG]  }
      $9F/                        {  LAHF }
      $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
      if o1= 7 then putbyte(reg.m,reg.hl);
      flags:=flags and $fe or carrysave;
  END;
5:BEGIN
		o1:=o1 xor 1;
    carrysave:=flags and 1;
    Inline
     ($8A/$26/FLAGS/              {  MOV AH,FLAGS }
		 $9E/                        {  SAHF }
		 $32/$FF/                    {  XOR BH,BH }
     $8A/$1E/O1/                 {  MOV BL,O1 }
     $FE/$8F/REG/               {  C1: DEC [BX+REG]  }
     $9F/                        {  LAHF }
		 $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
    if o1= 7 then putbyte(reg.m,reg.hl);
    flags:=flags and $fe or carrysave;
  END;
6:begin
    o1:=o1 xor 1;reg.ab[o1]:=byt;reg.pc:=reg.pc+1;
    if o1= 7 then putbyte(reg.m,reg.hl);
  end;
7:case o1 of
    0:BEGIN
       Inline
				($8A/$26/FLAGS/              {  MOV AH,FLAGS }
        $9E/                        {  SAHF }
        $D0/$06/REG+6/             {  C1: ROL [REG+6],1  }
        $9F/                        {  LAHF }
				$88/$26/FLAGS);              {  MOV [FLAGS],AH  }
      END;
     1:BEGIN
        Inline
        ($8A/$26/FLAGS/              {  MOV AH,FLAGS }
        $9E/                        {  SAHF }
        $D0/$0E/REG+6/             {  C1: ROR [REG+6],1  }
        $9F/                        {  LAHF }
        $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
       END;
     2:BEGIN
        Inline
        ($8A/$26/FLAGS/              {  MOV AH,FLAGS }
        $9E/                        {  SAHF }
        $D0/$16/REG+6/             {  C1: RCL [REG+6],1  }
        $9F/                        {  LAHF }
				$88/$26/FLAGS);              {  MOV [FLAGS],AH  }
       END;
     3:BEGIN
				Inline
				($8A/$26/FLAGS/              {  MOV AH,FLAGS }
        $9E/                        {  SAHF }
        $D0/$1E/REG+6/             {  C1: RCR [REG+6],1  }
        $9F/                        {  LAHF }
        $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
       END;
     4:BEGIN
         Inline
         ($8A/$26/FLAGS/              {  MOV AH,FLAGS }
         $9E/                        {  SAHF }
         $A0/REG+6/                 {  C1: MOV AL,[REG+6] }
         $27/                        {  DAA }
         $A2/REG+6/                 {  MOV [REG+6],AL  }
         $9F/                        {  LAHF }
         $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
       END;
		 5: reg.a:=reg.a xor $ff;
     6: flags:=flags or $1;
		 7: flags:=flags xor $1;
    end;
	end;
end;

procedure p_o2(op,byt:byte);
begin

{ Variable         Segment
FLAGS               DSEG
REG                 DSEG }

BEGIN
Inline
	($8A/$26/FLAGS/              {  MOV AH,FLAGS }
	$9E/                        {  SAHF }
	$A0/REG+6/                  {  MOV AL,[REG+6]}
	$FE/$4E/$08/                {  DEC OP }
	$79/$06/                    {  JNS O1  }
	$02/$46/$06/                {  ADD AL,BYT }
	$EB/$43/$90/                {  JMP SV }
	$75/$06/                    {  O1: JNZ O2 }
	$12/$46/$06/                {  ADC AL,BYT }
	$EB/$3B/$90/                {  JMP SV }
  $FE/$4E/$08/                {  O2: DEC OP }
	$75/$06/                    {  JNZ O3 }
  $2A/$46/$06/                {  SUB AL,BYT }
	$EB/$30/$90/                {  JMP SV }
  $FE/$4E/$08/                {  O3: DEC OP }
	$75/$06/                    {  JNZ O4 }
  $1A/$46/$06/                {  SBB AL,BYT }
  $EB/$25/$90/                {  JMP SV }
  $FE/$4E/$08/                {  O4: DEC OP }
  $75/$06/                    {  JNZ O5 }
  $22/$46/$06/                {  AND AL,BYT }
  $EB/$1A/$90/                {  JMP SV }
  $FE/$4E/$08/                {  O5: DEC OP }
  $75/$06/                    {  JNZ O6 }
	$32/$46/$06/                {  XOR AL,BYT }
  $EB/$0F/$90/                {  JMP SV }
  $FE/$4E/$08/                {  O6: DEC OP }
  $75/$06/                    {  JNZ O7 }
	$0A/$46/$06/                {  OR AL,BYT }
  $EB/$04/$90/                {  JMP SV }
  $3A/$46/$06/                {  O7: CMP AL,BYT }
  $A2/REG+6/                  {  SV: MOV [REG+6],AL  }
  $9F/                        {  LAHF }
  $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
END;
end;

procedure p_o3;
var k:byte;
begin
  case o2 of
     0:begin
       case o1 of
				 0:if flags and $40 = 0 then return;
				 1:if flags and $40 = $40 then return;
         2:if flags and $1 = 0 then return;
         3:if flags and $1 = 1 then return;
         4:if flags and $4 = 0 then return;
				 5:if flags and $4 = 4 then return;
         6:if flags and $80 = 0 then return;
         7:if flags and $80 = $80 then return;
        END;
        end;
      1:IF NOT ODD(o1) then begin
         o1:=o1 shr 1;
				 if o1 in [0..2] then begin reg.aw[o1]:=lad_inc(reg.sp);
					reg.aw[o1]:=reg.aw[o1]+(lad_inc(reg.sp) shl 8);
				 end else begin flags:=lad_inc(reg.sp);reg.a:=lad_inc(reg.sp) end;
       end else begin
        case o1 of
         1:return;
         5:reg.pc:=reg.hl;
				 7:reg.sp:=reg.hl;
        end;
			 end;
			2:begin inc(reg.pc,2) ;
        case o1 of
         0:if flags and $40 = 0 then reg.pc:=addre;
				 1:if flags and $40 = $40 then reg.pc:=addre;
         2:if flags and $1 = 0 then reg.pc:=addre;
         3:if flags and $1 = 1 then reg.pc:=addre;
         4:if flags and $4 = 0 then reg.pc:=addre;
         5:if flags and $4 = 4 then reg.pc:=addre;
         6:if flags and $80 = 0 then reg.pc:=addre;
				 7:if flags and $80 = $80 then reg.pc:=addre;
	 END;end;
			 3:case o1 of
				 0:reg.pc:=addre;
				 2:begin
						 if nibbles(k,byt) then begin
							 processOutport(k,byt,reg.a);
						 end;
						 inc(reg.pc);
					 end;
				 3:begin
						 inc(reg.pc);
						 if nibbles(k,byt) then Begin
							 cpureadport(k,byt)
						 End
						 else reg.a:=$ff;
					 end;
				 4:begin  addre:=reg.hl;reg.hl:=(getbyte(reg.sp+1) shl 8) + getbyte(reg.sp);
            putbyte(lo(addre),reg.sp);putbyte(hi(addre),reg.sp+1);
           end;
				 5:begin
            addre:=reg.hl;reg.hl:=reg.de;reg.de:=addre;
           end;
         6: Begin
							intmask:=intmask and $f7;
{$Ifdef int}
              ei := False;
{$endif}
            End;
         7: Begin
							Intmask:=intmask or 8;
{$Ifdef int}
              ei := True;
{$endif}
						End;
         end;
      4: case o1 of
				 0:if flags and $40 = 0 then call else inc(reg.pc,2);
				 1:if flags and $40 = $40 then call else inc(reg.pc,2);
				 2:if flags and $1 = 0 then call else inc(reg.pc,2);
				 3:if flags and $1 = 1 then call else inc(reg.pc,2);
				 4:if flags and $4 = 0 then call else inc(reg.pc,2);
				 5:if flags and $4 = 4 then call else inc(reg.pc,2);
				 6:if flags and $80 = 0 then call else inc(reg.pc,2);
				 7:if flags and $80 = $80 then call else inc(reg.pc,2);
         end;
      5:IF NOT ODD(o1) then begin
          dec(reg.sp,2);
          o1:=o1 shr 1;
          if o1 in [0..2] then begin putbyte(lo(reg.aw[o1]),reg.sp);putbyte(hi(reg.aw[o1]),reg.sp+1);end
          else begin
          putbyte(flags,reg.sp);putbyte(reg.a,reg.sp+1) end;
        end else
        case o1 of
				 1:call;
				end;
			6:begin inc(reg.pc);p_o2(o1,byt);end;
      7: begin
					dec(reg.sp,2);
          putbyte(hi(reg.pc),reg.sp+1);putbyte(lo(reg.pc),reg.sp);
					reg.pc:=8*o1;
         end;
    end;
end;

begin {SIM!!}
	adresserror:=false;
	bb:=lad_inc(reg.pc);
	o0:=(bb and $c0) shr 6;
	o1:=(bb and $38) shr 3;
	o2:=(bb and $7) ;
	case o0 of
		0: ot:=opt0[o2,o1];
		1: ot:=1;
		2: ot:=5;
		3: ot:=opt3[o2,o1];
	end;
	if ot and $30<>0 then byt:=getbyte(reg.pc);
	if ot and $20<>0 then addre:=byt + getbyte(reg.pc+1) shl 8;
	reg.m:=mem[ramseg:reg.hl];
	case o0 of
		0:p_o0;
		1:begin
			 if getbyte(reg.pc-1) = $76 then begin
				 dec(reg.pc);
				 stopadr:=reg.pc
			 end
			 else begin
				 o1:=o1 xor 1;
				 o2:=o2 xor 1;
				 reg.ab[o1]:=reg.ab[o2];
				 if o1= 7 then putbyte(reg.m,reg.hl);
			 end;
			end;
		2:p_o2(o1,reg.ab[o2 xor 1]);
		3:p_o3;
	end;
{$ifdef int}
	If EnRST And ei And GotInt And IntEnable Then Begin
		CLI;
		addre := IntAdr;
		Call;
	End;
{$endif}
end;


procedure schreibregister;
var err:word;
begin
	with reg do begin
		with l41 do begin
		 a:=hexdez(r8[1],err);
		 flags:=hexdez(r8[2],err);
		 b:=hexdez(r8[3],err);
		 c:=hexdez(r8[4],err);
		 d:=hexdez(r8[5],err);
		 e:=hexdez(r8[6],err);
		 h:=hexdez(r8[7],err);
		 h:=hexdez(r8[8],err);
		 pc:=hexdez(r16[1],err);
		 sp:=hexdez(r16[2],err);
		end;
	end;
end;

procedure zeigmaske;
var fl:string[50];
		k:word;
begin
	If Not Romtrace And (Reg.PC < RamLow) Then Exit;

{$ifdef mfa2}
	 if userpage then switchscreen(sscr^);
{$endif}
	with reg do begin
		with l41 do begin
		 l41.r8[1]:=hex(a);
		 r8[2]:=hex(flags);
		 r8[3]:=hex(b);
		 r8[4]:=hex(c);
		 r8[5]:=hex(d);
		 r8[6]:=hex(e);
		 r8[7]:=hex(h);
		 r8[8]:=hex(l);
		 r16[1]:=hex(hi(pc))+hex(lo(pc));
		 r16[2]:=hex(hi(sp))+hex(lo(sp));
		end;
		pushwin(11);schreibrecord(l41,l4,l4anz);popwin(false);
		if flagsalt<>flags then begin
			if flags and $80=$80 then fl:='MI ' else fl:='PL ';
			if flags and $40=$40 then fl:=fl+'ZR ' else fl:=fl +'NZ ';
			if flags and $10=$10 then fl:=fl+'AC ' else fl:=fl+ '   ';
			if flags and $4=$4 then fl:=fl+ 'PE ' else fl:=fl+'PO ';
			if flags and $1=$1 then fl:=fl+'CY' else fl:=fl+'NC';
			wia(27,3,eaattr,fl);
		end;
		if simtyp<>EZ80_Typ then begin
			if intmask and $80=$80 then
			wia(45,3,eaattr,'1') else wia(45,3,eaattr,'0');
			wia(50,3,eaattr,dezbin(intmask));
		end
		else if intmask and $8=$8 then
			Begin
				wia(45,3,eaattr,'1');
			End
			else Begin
				wia(45,3,eaattr,'0');
			End;
		if memadr<>0 then begin
			wia(24,5,schattenattr,'∞∞');
			wia(28,5,eaattr,hex(hi(memadr))+hex(lo(memadr)));
			for k:=0 to 12 do wia(37+k*3,5,eaattr,hex(mem[ramseg:memadr+k]));
		end else begin
			if (reg.bc<=ramhigh) and (reg.bc>=ramlow) then begin
				wia(24,5,tattr,'=>');
				wia(28,5,eaattr,hex(b)+hex(c));for k:=0 to 12 do wia(37+k*3,5,eaattr,hex(mem[ramseg:bc+k]));
			end;
		end;
		if (reg.de<=ramhigh) and (reg.de>=ramlow) then begin
			 wia(24,7,tattr,'=>');
			 wia(28,7,eaattr,hex(d)+hex(e));for k:=0 to 12 do wia(37+k*3,7,eaattr,hex(mem[ramseg:de+k]));
		end else begin
					wia(24,7,schattenattr,'∞∞');
		 end;
			if (reg.hl<=ramhigh) and (reg.hl>=ramlow) then begin
				 wia(24,9,tattr,'=>');
				 wia(28,9,eaattr,hex(h)+hex(l));for k:=0 to 12 do wia(37+k*3,9,eaattr,hex(mem[ramseg:hl+k]));
		 end else begin
			wia(24,9,schattenattr,'∞∞');
		 end;
		wia(28,11,eaattr,hex(hi(sp))+hex(lo(sp)));
		for k:=0 to 12 do wia(37+k*3,11,eaattr,hex(mem[ramseg:sp+k]));
	end;
	regalt:=reg;flagsalt:=flags;
{$ifdef mfa2}
	if userpage then switchscreen(sscr^);
{$endif}
end;


procedure baumaske;
var i:word;
begin
 tafel(0); pushwin(11);
 schatten(11);
 with wd[11] do begin
  wia(x+4,y+1,rahmattr, 'µ A ∆ÕÕ—ÕÕµ F ∆');wia(x+11,y+2,rahmattr, '≥');
  wia(x+1,y+3,rahmattr, '«ƒƒ¥ B √ƒƒ≈ƒƒ¥ C √ƒƒ∂');wia(x+11,y+4,rahmattr, '≥');
  wia(x+1,y+5,rahmattr, '«ƒƒ¥ D √ƒƒ≈ƒƒ¥ E √ƒƒ∂');wia(x+11,y+6,rahmattr, '≥');
  wia(x+1,y+7,rahmattr, '«ƒƒ¥ H √ƒƒ≈ƒƒ¥ L √ƒƒ∂');wia(x+11,y+8,rahmattr, '≥');
  wia(x+1,y+9,rahmattr, '«ƒƒ¥PC √ƒƒ≈ƒƒ¥SP √ƒƒ∂');wia(x+11,y+10,rahmattr, '≥');
	wia(x+11,y+11,rahmattr, 'œ');
 end;
 popwin(false);
 pushwin(12);
 schatten(12);
 with wd[12] do begin
	 wia(x+2,y+1,rahmattr,'µFlags∆ÕÕÕÕÕÕÕÕ—µSOD∆—µIntMask∆Õ—µDisplay∆');
   if simtyp=1 then begin
		 wia(x+19,y+1,rahmattr,'IFF');wia(x+24,y+1,rahmattr,'ÕÕÕÕÕÕÕÕÕ');
   end;
   if simtyp=Anw_Typ then wia(x+35,y+1,rahmattr,'ÕÕÕÕÕÕÕÕÕ');
   wia(x+17,y+2,rahmattr,'≥     ≥          ≥');
   wia(x+1,y+3,rahmattr,'«¥ Adr √¬¥Inh.√ƒ¡ƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ∂');wia(x+9,y+4,rahmattr,'≥');
   wia(x+1,y+5,rahmattr,'«ƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ∂');wia(x+9,y+6,rahmattr,'≥');
	 wia(x+1,y+7,rahmattr,'«ƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ∂');wia(x+9,y+8,rahmattr,'≥');
	wia(x+1,y+9,rahmattr,'«¥Stack√≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ∂');
  wia(x+9,y+10,rahmattr,'≥');wia(x+9,y+11,rahmattr,'œ');
 end;popwin(false);
 pushwin(13);schatten(13);
 with wd[13] do begin
  wia(x+6,y+1,rahmattr,'—ÕµBytes∆—ÕµMnemonic∆');
  for i:=2 to 8 do wia(x+6,y+i,rahmattr,'≥        ≥');
	wia(x+6,y+9,rahmattr,'œÕÕÕÕÕÕÕÕœ');
 end;popwin(false);
	if MaxPort=2 then begin
		wd[14].dx:=31
	End
  else wd[14].dx:=14;
 pushwin(14);schatten(14);
 with wd[14] do begin
  wia(x+5,y+1,rahmattr,'—');
	if MaxPort=2 then begin
		wia(x+14,y+1,rahmattr,'—ÕÕÕÕÕÕÕÕ—');
	End;
	for i:=1 to 3 do begin
		wia(x+5,y+2*i,rahmattr,'≥');
    wia(x+1,y+2*i+1,rahmattr,'«ƒƒƒ≈ƒƒƒƒƒƒƒƒ');
		if MaxPort=2 then begin
      wia(x+14,y+2*i,rahmattr,'≥        ≥');
      wia(x+14,y+2*i+1,rahmattr,'≈ƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒ∂');
    end;
  end;
	wia(x+5,y+8,rahmattr,'≥');
  wia(x+5,y+9,rahmattr,'œÕ8255/1');
	if MaxPort=2 then begin
		 wia(x+14,y+8,rahmattr,'≥        ≥');
     wia(x+14,y+9,rahmattr,'œÕÕ8255/2œÕÕ8255/3');
  end;
	for i:=0 to 2 do  wia(x+12,y+2*i+1,tattr,'IN');
  wia(x+6,y+7,tattr,'IIIIIIII');
	if MaxPort=2 then begin
		for i:=0 to 2 do begin
			 wia(x+21,y+2*i+1,tattr,'IN');
			 wia(x+30,y+2*i+1,tattr,'IN');
		end;
	 wia(x+15,y+7,tattr,'IIIIIIII');
	 wia(x+24,y+7,tattr,'IIIIIIII');
	end;
	wia(x+2,y+2,rahmattr,'KaA');
	wia(x+2,y+4,rahmattr,'KaB');
	wia(x+2,y+6,rahmattr,'KaC');
	wia(x+2,y+8,rahmattr,'Stw');
 end;
 popwin(false);
 zeigmaske;
 zeigports;
end;

procedure checkcommand;
var
 ch:char;
 ss:str80;

procedure remleer;
begin
	while (ss[1]=' ') and (ss>'') do delete(ss,1,1);
end;

procedure testgleich;
begin
	if ss[1]='=' then begin
		delete(ss,1,1);remleer;
		command[2]:=copy(ss,1,pos(' ',ss)-1);
		delete(ss,1,pos(' ',ss));remleer;
	end;
end;

procedure delcommand;
begin
	delete(ss,1,pos(' ',ss));remleer;
end;

procedure getcommand(x:integer);
begin
	command[x]:=copy(ss,1,pos(' ',ss)-1);
	delcommand;
end;

begin
  window(1,1,80,24);
  gotoxy(2,24);Write('Befehl : ');
	If Not CheckKey Then Exit;
	fillchar(command,sizeof(command),0);
	repeat
		input(11,24,69,1,s,ch);
	until ch in [#13,#27,f5,f8,f9,f10];
	case ch of
	 #27:s:='Q';
	 f5 :if simtyp=MFA_Typ
				then s:=f5;
	 f8 :s:='G';
	 f9 :s:='T';
	 f10:s:='P';
	end;
	gotoxy(2,24);Write('Befehl : ',s);
	ss:=caps(s);
	ss:=ss+' ';
	remleer;
	command[1]:=ss[1];delete(ss,1,1);remleer;

	case char(command[1][1]) of
		'G':begin
				 testgleich;
				 if ss>''then getcommand(3);
				end;
		'T':testgleich;
	 'M','D','U': getcommand(2);
	 'I','R','O':begin
								getcommand(2);
								getcommand(3);
							 end;
			'F':begin
						 getcommand(2);
						 getcommand(3);
						 getcommand(4);
					end;
		 end;
end;

function address(t:str4;var e:word):boolean;
var err:word;
begin
 if t='' then address:=false else begin
	 e:=hexdez(t,err);
	 address:=err=0; if err<>0 then e:=0;
 end;
end;

procedure vor;
begin
 if x<60 then begin
	 if x mod 3=1 then inc(x,2) else inc(x);
	 if x>56 then x:=60;
 end else if x<75 then inc(x);
end;
procedure zeigdump(i:word);
begin
  clrscr;
  write('Adresse 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F     123456789ABCDEF');
	for y:=3 to 18 do begin
    x:=9;
		gotoxy(2,y);write(hex(hi(i+((y-3) shl 4) )),hex(lo(i+((y-3) shl 4))));
		for k:=1 to 16 do begin
     gotoxy(x,y);b:=mem[ramseg:(i+((y-3) shl 4)+((x-9) div 3))];write(hex(b));gotoxy((x-9) div 3+60,y);
     if b in [32..127] then write(char(b)) else write('.');
     x:=x+3;
   end;
 end;
 x:=9;y:=3;
end;
var ch:char;

var nextdisadr,lastpadr:word;
		ss:str80;
		kh:byte;

procedure showdis(i:word);
var
		j    :integer;
		aktpc:boolean;

begin
If Not Romtrace And (Reg.PC < RamLow) Then Exit;
{$ifdef mfa2}
		if userpage then switchscreen(sscr^);
{$endif}
	 for j:=0 to 6 do begin
		 aktpc:=i=reg.pc;
		 ss:=hex(hi(i))+Hex(lo(i));
		 disass(i);
		 if aktpc then wia(4,15+j,llinattr,ss) else wia(4,15+j,eaattr,ss) ;
		 ss:=hexstr+cstr(' ',8-length(hexstr));
		 if aktpc then wia(9,15+j,llinattr,ss) else wia(9,15+j,eaattr,ss) ;
		 if aktpc then wia(18,15+j,llinattr,disstr) else wia(18,15+j,eaattr,disstr) ;
	 end;
	 nextdisadr:=i;
{$ifdef mfa2}
		if userpage then switchscreen(sscr^);
{$endif}
end;


procedure simula;
Var
	j : Word;

procedure initdebug;
var f:file;
	 err:word;
	 romload:boolean;

begin
{$ifdef int}
	ei      := False;
	EnRST   := False;
	GotInt  := False;
{$endif}
	s:=''; memadr:=0;
	for i:=0 to 5 do regalt.aw[i]:=not reg.aw[i];
Inline(  $9F/                        {  LAHF }
				 $88/$26/FLAGS);              {  MOV [FLAGS],AH  }
	flagsalt:=not flags;
	vid:=ptr(screenadr,0);akthelpnr:=50;
	fillchar(reg,sizeof(reg),0);
	fillchar(port80,sizeof(port80),0);
	fillchar(inte,sizeof(inte),0);
{$ifdef Int}
	intmask:=0;
{$else if}
	intmask:=0;
{$endif}
	getmem(ram,maxramsize);
	getmem(dummy,$20);
	ramseg:=seg(ram^);
	if ofs(ram^)<>0 then inc(ramseg);
	romload:=true;
	case simtyp of
	 EZ80_Typ : begin
			 romhigh:=$3ff;ramlow:=$8000;ramhigh:=$83ff;maxport:=0;
		 end;
	 P5_2K:begin
			 romhigh:=$3ff;ramlow:=$8000;ramhigh:=$83ff;maxport:=2;
		 end;
	 P5_4K:Begin
			 romhigh:=$0fff;ramlow:=$7800;ramhigh:=$83ff;maxport:=2;
		 end;
	 P5_8K:begin
			 romhigh:=$3fff;ramlow:=$7000;ramhigh:=$87ff;maxport:=2;
		 end;
	 MFA_Typ:begin
			 romhigh:=$5fff;ramlow:=$6000;ramhigh:=$ffff;maxport:=2;
		 end;
	 Anw_Typ: begin
					romlow:=hexdez(caps(l11.srom),err);
					romhigh:=hexdez(caps(l11.erom),err);
					ramlow:=hexdez(caps(l11.sram),err);
					ramhigh:=hexdez(caps(l11.eram),err);
					romload:=l11.romname<>'';
				maxport:=2;
		end;
	end;
	TempStr := '';
	TempStr := RomDir + l11.RomName + '.rom';
	FileMode := 0;
	assign(f,TempStr);
	fillchar(mem[ramseg:romhigh+1],ramlow-romhigh,$ff);
	fillchar(mem[ramseg:ramlow],ramhigh-ramlow+1,0);
	fillchar(mem[ramseg:ramhigh+1],maxramsize-ramhigh,$ff);
	if romload then begin
	 {$i-}RESET(F,1);{$i+}
	 if ioresult=0 then begin
			BLOCKREAD(F,mem[ramseg:romlow],romhigh-romlow+1,err);
			close(f);
			FileMode := 2;
		end else Begin
			FileMode := 2;
			error(156);
		End;
	end;
	showregs:=true;
	pcport1:=memw[$40:8];
	stopadr:=$ffff; reg.pc:=ramlow;
	readhex_cmd;
	p_s:=nil;
	Case simtyp of
		EZ80_Typ : l11.RomName := 'EZ80';
		P5_2K    : l11.RomName := 'PROFI_2K';
		P5_4K    : l11.RomName := 'PROFI_4K';
		P5_8K    : l11.RomName := 'PROFI_5E';
		MFA_Typ  : l11.RomName := 'MFA';
	End; {Case}
	FileMode := 0;
	TempStr := RomDir + l11.RomName + '.SYM';
	readsym (TempStr);
	FileMode := 2;
	writerom:=false;
{
	reg.sp:=ramhigh- $3e;
}
	reg.sp:=$FFFF;
	pushwin(0);
	baumaske;
	step:=true;
	showdis(reg.pc);
	llin(5);
	RomTrace  := True;
end;

Label Stop;

begin
{$ifdef mfa2}
	 getmem(sscr,4000);
{$endif}
	 initdebug;
{$ifdef mfa2}
	if simtyp=MFA_Typ then begin
		 windmin:=0;windmax:=$184f;
		 switchscreen(sscr^);
		 clrscr;xpo:=wherex;ypo:=wherey;
		 switchscreen(sscr^);
	end;
 {$endif}
	userpage:=false;
	Step := True;
	repeat
		i:=reg.pc;
		if i=stopadr then begin
			step := True;
			showregs := True;
			if command[1][1]='P'  then i:=lastpadr;
			Zeigmaske;
			ZeigPorts;
			showdis (i);
		end; { If i=stopadr }
		While Step And Not KeyPressed Do Begin
			For i:=0 to 6 Do Port80 [3,i] := Port [ioadr+i];
			if pc8255 then begin
				port80 [pradr,0] := port[pcadr];
				port80 [pradr,1] := port[pcadr+1];
				port80 [pradr,2] := port[pcadr+2];
				If (MaxPort = 2) And DoLPT then Begin
					port80 [2,0] := port[lptadr];
					port80 [2,1] := port[lptadr+1];
					port80 [2,2] := port[lptadr+2];
				{ Busy invertieren PC - spezifisch!}
					If (port80 [2,1] And $80) > 0
						Then port80 [2,1] := port80 [2,1] And $7F
						Else port80 [2,1] := port80 [2,1] Or  $80;
				End;
				If ShowRegs Then ZeigPorts;
			End; { If PC8255 }
			if showregs then Begin
				showdis(reg.pc);
				Zeigmaske;
        If Not PC8255 Then ZeigPorts;

				if simtyp < MFA_Typ then anzeige;
			End; { If ShowRegs }
		End; { While }
		if showregs or step then Begin
			showdis(reg.pc);
			Zeigmaske;
			ZeigPorts;
		End { If ShowRegs Or Step }
		else
			if simtyp <> MFA_Typ then with reg do wia(6,11,eaattr,hex(hi(pc))+hex(lo(pc)));
		if simtyp < MFA_Typ then anzeige;
		If Step Or KeyPressed Then Begin
{$ifdef mfa2}
			if userpage then switchscreen(sscr^);
{$endif}
			checkcommand;
			step:=true;
{$ifdef mfa2}
			if userpage then switchscreen(sscr^);
{$endif}
				case command[1][1] of
					'G':begin
								if address(command[2],i) then reg.pc:=i;
								if address(command[3],i) then stopadr:=i else stopadr:=$ffff;
								step:= False;
							end;
					'T':Begin
								{$ifdef mfa2}
								if userpage then Begin
									switchscreen(sscr^);
									UserPage := False;
									ShowRegs := True;
								End;
								{$endif}
								if address(command[2],i) then reg.pc:=i;
								if getbyte(reg.pc) = $76 then Begin
									Inc (Reg.PC);
									Inc (i);
								End
								Else ROMTrace := True;
							End;
					'P':begin
								{$ifdef mfa2}
								if userpage then Begin
									switchscreen(sscr^);
									UserPage := False;
									ShowRegs := True;
								End;
								{$endif}
								i:=reg.pc;
								lastpadr:=i;
								disass(i);
								if (o0=3) and ((o2=4) or ((o2=5) and(o1=1))) then begin
									stopadr:=i;
									step:=False;
									showregs:=false;
								end
{NÑchste Zeile ist neu, da sonst keine Portaktualisierung}
								Else Begin
									ShowRegs := True;
								End;
								if getbyte(reg.pc) = $76 then Begin
									Inc (Reg.PC);
									Inc (i);
								End
								Else ROMTrace := True;
							end; {'P'}
{$ifdef mfa2}
					f5: begin
								If SimTyp = MFA_Typ Then Begin
									switchscreen(sscr^);
{
									If Not UserPage Then ShowDis (Reg.Pc);
									For i:= 1 to 4 Do Command [i] := '';
}
									Repeat until KeyPressed;
									LastCommand := Command;
									CheckCommand;
									If Command [1][1] = 'S' Then Begin
										userpage:=Not UserPage;
										ShowRegs:=Not ShowRegs;
									End
									Else Begin
										switchscreen(sscr^);
										Command := LastCommand;
									End;
								End;
							end;
{$endif}
					'V':Begin
								listvars;
							End;
					'E':Begin
								RomTrace := Not RomTrace;
							End;
					'M':if address(command[2],i) then memadr:=i else memadr:=0;

					'I',
					'O':if address(command[2],i) then Begin
								if nibbles(kh,byte(i)) then
									if address(command[3],j) then begin
										if command[1][1]='O' then ProcessOutPort(kh,i,lo(j))
																					else processinput(kh,i,lo(j));
									End;
								If ShowRegs Then ZeigPorts;
							end;
					'S':begin
								showregs:=not showregs;
{$ifdef mfa2}
								If SimTyp = MFA_Typ Then Begin
									switchscreen(sscr^);
									userpage:=not userpage;
								End;
{$endif}
							end; {'S'}
					'R':if command[2]='' then begin
								llin(6);pushwin(11);
								liesrecord(l41,l4,l4anz,ch,[f8],f6);
								if ch=f8 then schreibregister;popwin(false);llin(5);
							end
							else begin
								b:=pos(command[2],'CBEDLHAFSPPC');
								if b in [1..7] then begin
									if address(command[3],i) then reg.ab[b-1]:=lo(i);
								end
								else if b=9 then begin
									if address(command[3],i) then reg.sp:=i;
								end
								else if b=11 then begin
									if address(command[3],i) then begin
										reg.pc:=i ;showdis(i);
									end;
								end
								else if b=8 then begin
									if command[3]='NC'then flags:=flags and $fe;
									if command[3]='PO'then flags:=flags and $fb;
									if command[3]='NZ'then flags:=flags and $bf;
									if command[3]='PL'then flags:=flags and $7f;
									if command[3]='CY'then flags:=flags or $1;
									if command[3]='PE'then flags:=flags or $4;
									if command[3]='ZR'then flags:=flags or $40;
									if command[3]='MI'then flags:=flags or $80;
								end;
								Step := True;
								ZeigMaske;
							end; {'R'}
					'U':begin
								if not address(command[2],i) then i:=nextdisadr;
								showdis(i);
								Step := True;
							end;
					'F':if address(command[2],i) and address(command[3],j)
								and address(command[4],k) then
								for i:= i to j do mem[ramseg:i]:=lo(k);
					'D':begin
								IF not address(command[2],i) then i:=reg.pc;i:=i and $fff0;
								with wd[6] do begin
									x:=0;y:=0;dx:=79;dy:=24;xp:=1;yp:=1;
									s:='π Hex-Dump Ã';BP:=nil;
								end;
								pushwin(6);llin(4);
								zeigdump(i);edsetcursor(cursortype);
								repeat
									gotoxy(x,y);esc:=false;
									ascc:=x>59;
									ch:=readkey;
									If Ch = #27 Then Goto Stop;
									esc:=(ch=#0) and keypressed;
									if esc then begin
										ch:=readkey;
										case ch of
											'K':begin
														if x>60 then begin
															dec(x);
															if x=60 then x:=55
														end
														else if x>9 then
															if (x mod 3)=1 then dec(x) else dec(x,2);
													end;
											'H':if y>3 then dec(y);
											'P':if y<18 then inc(y);
											'M':vor;
											'I':begin i:=i-256;zeigdump(i);end;
											'Q':begin i:=i+256;zeigdump(i);end;
										end; { Case Ch of (Cursorsteuerung im Dump - Modus }
									end {if esc}
									else begin
										if ascc then begin
											write(ch);gotoxy((x-60)*3+9,y);b:=ord(ch);
											mem[ramseg:i+((y-3) shl 4)+(x-60)]:=b;
											write(hex(b));vor;
										end
										else if cap(ch) in ['0'..'9','A'..'F'] then begin
											write(cap(ch));
											b:=vid^[y*160+(x div 3)*6+3]-ord('0');
											if b>$a then b:=b-7;b:=b shl 4;
											b1:=vid^[y*160+ x div 3 *6+5]-ord('0');
											if b1>$a then b1:=b1-7;b:=b+b1;
											gotoxy((x-9) div 3+60,y);
											if b in [32..127] then write(char(b)) else write('.');
											mem[ramseg:i+((y-3) shl 4)+((x-9) div 3)]:=b;vor;
										end;
									end;
								until ch=#27;
Stop:
								Popwin(true);
								window(1,1,80,24);
							end; { 'D' = Dump }
					end; { Case Command [1][1] }
			End; { If Step or KeyPressed }
			j:=reg.pc;
			if pos(command[1],'GPT')>0 then begin
				sim;
				if showregs or step  then begin
					if (reg.pc<j) or (reg.pc>=nextdisadr) then j:=reg.pc;
					showdis(j);
				end;
			end;
	until command[1]='Q';
	If SimTyp = MFA_Typ Then UserPage := False;
	popwin(true);
	freemem(ram,maxramsize);
	freemem(dummy,$20);
	wd[11].bp:=nil;
	wd[12].bp:=nil;
	wd[13].bp:=nil;
	wd[14].bp:=nil;
	Tastm := False;
end;

Begin
	Tastm := False;
	CheckBreak := False;
	TA := Abs (Zeit);
  TLoop := 0;
  Delaytime := 1;
  Repeat
    Inc (TLoop);
  Until (Zeit Mod TA) >= 5;
  DelayTime := (TLoop Div 2200) + 1;
end.
