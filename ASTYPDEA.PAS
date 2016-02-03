unit astypdea;

interface
type
		 str2   = string[2];
		 str3   = string[3];
     str4   = string[4];
     str5   = string[5];
     str6   = string[6];
     str8   = string[8];
		 str10  = string[10];
		 str12  = string[12];
		 str15  = string[15];
		 str20  = string[20];
		 str25  = string[25];
		 str30  = string[30];
		 str35  = string[35];
     str40  = string[40];
     str80  = string[80];
		 str255 = string[255];
		 LongStr  = String [255];

	_mptr  =^_macro;
  _vptr  =^_var;
  _var   = record
     name:str80;
     repl:str80;
     next:_vptr;
  end;
  _lptr=^_line;
  _line=record
     s:string;
     next:_lptr;
  end;
  _macro = record
     next:_mptr;
     name :str80;
     vars:_vptr;
    locals:_vptr;
    lines:_lptr;
  end;

 t_sp = ^t_as;
  t_as= record
    opc :str8;
    links,rechts:t_sp;
    bal:-1..+1;
     o0,o1,o2,t:byte;
  end;

 t_var = ^t_typ;
  t_typ= record
    name :str30;
    adresse:word;
    typ:byte;
    links,rechts:t_var;
    bal:-1..+1;
  end;

 _zeile=record
      case byte of
      0:(ausd:str255);
      1:(l:byte;
         adr:array[1..4] of byte;
         d1:byte;
         opcode:array[1..11] of byte;
         d2:byte;
         info:array[1..3] of char;
         label1:array[1..120] of byte);
end;

_buffer = record
  case byte of
   0:(schreib:array[1..36] of byte);
   1:(anzahl:byte;
     adresse:word;
     null:byte;
     daten:array[0..31] of byte);
end;

  _pseudo = (flist,fnolist,fconds,fnoconds,fincl,fnoincl,fmacs,fnomacs,
             fctls,fnoctls,fnewpage,feject,fpage,ftitel,fsyms,fnosyms,
	     fdb,fdw,fdd,fend,fdef,fequ,finclude,frept,firp,firpc,
             fif,fife,fifb,fifnb,fifdif,fifidn,fifdef, fifndef,fendif,felse,felseif,
             forg,fmacro,fexitm,ferr,fendm,fsymbol,fmnemo,fmac);
  pseudolist = ARRAY[_pseudo] OF STRING[8];

const
  varbez:array[0..6] of str6=('Byte  ','Word  ','DWord ','Label ','EQU   ','=     ','Macro ');
  ptext: pseudolist =
  ('%LIST','%NOLIST','%CONDS','%NOCONDS','%INCL','%NOINCL','%MACS','%NOMACS',
   '%CTLS','%NOCTLS','%NEWPAGE','%EJECT','%PAGE','%TITEL','%SYMS','%NOSYMS',
   'DB','DW','DD','END','=','EQU','INCLUDE','REPT','IRP','IRPC',
   'IF','IFE','IFB','IFNB','IFDIF','IFIDN','IFDEF','IFNDEF','ENDIF','ELSE','ELSEIF',
   'ORG','MACRO','EXITM','ERR','ENDM','','','');

  opc0: array[0..7,0..7] of str4 =
  (('NOP','???','???','???','RIM','???','SIM','???'),
   ('LXI','DAD','LXI','DAD','LXI','DAD','LXI','DAD'),
   ('STAX','LDAX','STAX','LDAX','SHLD','LHLD','STA','LDA'),
   ('INX','DCX','INX','DCX','INX','DCX','INX','DCX'),
   ('INR','INR','INR','INR','INR','INR','INR','INR'),
   ('DCR','DCR','DCR','DCR','DCR','DCR','DCR','DCR'),
   ('MVI','MVI','MVI','MVI','MVI','MVI','MVI','MVI'),
   ('RLC','RRC','RAL','RAR','DAA','CMA','STC','CMC'));

  opc2: array[0..7] of str4 =
   ('ADD','ADC','SUB','SBB','ANA','XRA','ORA','CMP');

  opc3: array[0..7,0..7] of str4 =
  (('RNZ','RZ','RNC','RC','RPO','RPE','RP','RM'),
   ('POP','RET','POP','???','POP','PCHL','POP','SPHL'),
   ('JNZ','JZ','JNC','JC','JPO','JPE','JP','JM'),
   ('JMP','???','OUT','IN','XTHL','XCHG','DI','EI'),
   ('CNZ','CZ','CNC','CC','CPO','CPE','CP','CM'),
   ('PUSH','CALL','PUSH','???','PUSH','???','PUSH','???'),
   ('ADI','ACI','SUI','SBI','ANI','XRI','ORI','CPI'),
   ('RST','RST','RST','RST','RST','RST','RST','RST'));

(* Operationstypen :
   Bit 0=1 GÅltiger Opcode
   Bit 1=1 1.Operand ist Register
   Bit 2=1 2.Operand ist Register
   Bit 3=1 Operand ist Registerpaar
   Bit 4=1 Operand ist Byte
   Bit 5=1 Operand ist Adresse oder Word
   Bit 6=1 Rst-Operation
   Bit 7=1 Pseudoopcode *)

  OPT0: ARRAY[0..7,0..7] of byte =
  ((1,0,0,0,1,0,1,0),
    (41,9,41,9,41,9,41,9),
    (9,9,9,9,33,33,33,33),
    (9,9,9,9,9,9,9,9),
    (3,3,3,3,3,3,3,3),
    (3,3,3,3,3,3,3,3),
    (19,19,19,19,19,19,19,19),
    (1,1,1,1,1,1,1,1));

  OPT3: ARRAY[0..7,0..7] of byte =
  ((1,1,1,1,1,1,1,1),
    (9,1,9,0,9,1,9,1),
    (33,33,33,33,33,33,33,33),
    (33,0,17,17,1,1,1,1),
    (33,33,33,33,33,33,33,33),
    (9,33,9,0,9,0,9,0),
    (17,17,17,17,17,17,17,17),
    (65,65,65,65,65,65,65,65));
     l1anz= 5;
      l1: ARRAY[1..l1anz] OF RECORD
      xp,yp,xe,le,te :BYTE;
      m :STRING[80]
END =
   ((xp: 1;yp: 1;xe:20;le: 4;te: 4;m :'Startadresse ROM: '),
    (xp: 1;yp: 2;xe:20;le: 4;te: 4;m :'Endadresse ROM  :'),
    (xp: 1;yp: 3;xe:20;le: 4;te: 4;m :'Startadresse RAM: '),
    (xp: 1;yp: 4;xe:20;le: 4;te: 4;m :'Endadresse RAM  :'),
    (xp: 1;yp: 5;xe:20;le:20;te: 1;m :'Name Rom-File   :'));

     l2anz= 3;
      l2: ARRAY[1..l2anz] OF RECORD
      xp,yp,xe,le,te :BYTE;
      m :STRING[80]
END =
   ((xp: 1;yp: 1;xe:23;le: 1;te: 5;m :'8255-Karte im PC    :'),
    (xp: 1;yp: 2;xe:23;le: 2;te: 4;m :'Profi -Adresse 8255 :   H'),
    (xp: 1;yp: 3;xe:23;le: 3;te: 4;m :'PC-Adresse     8255 :    H'));

   pc8255:boolean = False;

   l21:record
		 has8255:string[1];
     pradr:str2;
     pcadr:string[3];
   end=(has8255:'N';pradr:'10';pcadr:'100');

	 ffname:array[0..2] of str35= ('*.hex','*.asm','*.*');

	 fname:array[0..20] of str35=('','','','','','','','','','','',
																'','','','','','','','','','');

	 l11:record
			srom,erom,sram,eram:str4;
			romname:string[20];
	 end=(srom:'0';erom:'1FFF';sram:'7800';eram:'83ff';romname:'PROFI_4K');
	 simtyp:byte=3;
	 maxport:byte=2;
	 romlow:word=0;romhigh:word=$1fff;ramlow:word=$7000;ramhigh:word=$87ff;
	 listrept:boolean=true;
	 portinfo='PCport.msk';
	 porttab:array[0..4] of byte =(0,$10,$20,$30,$34);

var
	sp,sp_start  : t_sp;
	i1,i2,i3,Astitel       : str80;
	 obj,er,lfi  : TEXT;
	 pradr,pcadr:word;
implementation
end.