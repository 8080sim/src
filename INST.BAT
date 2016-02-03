copy 8080sim.exe %1\
copy 8080sim.hlp %1\
copy com.dat %1\
md %1\rom
md %1\prg
xcopy d:\sim\8080\rom\. %1\rom
xcopy d:\sim\8080\prg\noname.asm %1\PRG
xcopy d:\sim\8080\prg\iotest.asm %1\PRG
copy f:\tools\ted.exe %1\
%1\
ted com.dat



