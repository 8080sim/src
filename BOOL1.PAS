Uses Dos,Crt;

Var
	a,b,y : Boolean;

Begin
	Clrscr;
	a:= True;
	b:= True;
	y := a And b;
	Write (y);
	Repeat Until KeyPressed;
End.
