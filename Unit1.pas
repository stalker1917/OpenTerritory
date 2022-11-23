{$A-}

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, SyncObjs,Vcl.Imaging.pngimage;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button7: TButton;
    Button8: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button12: TButton;
    Timer1: TTimer;
    Label1: TLabel;
    Timer2: TTimer;
    Button2: TButton;
    Button3: TButton;
    procedure Button12Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    //procedure Button5Click(Sender: TObject);

    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
   // procedure Button11Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
  TField = record
  clr:TColor; // "Цвет"
  plm:int16;//- принадлежность к племени
  hod:boolean; // Можно ли ходить?
 // plhod:boolean// Можно ли присоеденять других к своему племени ?
  end;
  Tcivil = object
  protected
  chislenost:Uint32; //Удерживаемая территория
  sushestvovan:boolean;
  CS:TCriticalSection;
  public
  Army:Uint32;   //Число рот
  cvet:TColor;
  //Preemnik : int16;
  Enemy : int16;
  Senior : int16;
  MinNation : int16;
  MaxNation : int16;
  X_avg : single;
  Y_avg : single;
  procedure Create(var buffl:TField);
  procedure SetChislenost(ch : Word);
  function  GetChislenost : Word;
  procedure IncChislenost;  inline;
  procedure DecChislenost; inline;
  procedure ReduceArmy(N:Uint32); inline;
  procedure Destroy;
 // procedure Check(N:Integer);
  end;

  TCanvasLabel = object
    X,Y:Integer;
    Color : Tcolor;
    FontColor : Tcolor;
    Text : String;
  procedure OutText(const N :TCivil;AlwaysOut:Boolean=False);
  procedure Init(_Color:TColor);
  end;
  TTurnThread=class(TThread)
  protected
    procedure Execute; override;
  end;
  TSectionThread=class(TThread)
    Number : Integer;
    SuspendFlag:Boolean;
  protected
    procedure Execute; override;
  end;
  TPtr = Array[0..1] of TColor;
  PPtr = ^TPtr;

const

  MaxNations = 512;
  CurrNations = 512;
var
  Form1: TForm1;
  //strt:boolean; // Был ли старт?
  null:TField;
  YesTurns : Boolean = False;
  arealength : Word =  1088;//768*2;//6;
  area:array of array of TField;
  Nations:array[0..MaxNations] of Tcivil;
  //buf:array[1..MaxNations] of word; //Для загрузки
  Labels : array[1..CurrNations] of TLabel;
  CanvasLabels : array[1..CurrNations] of TCanvasLabel;
  pl:array[1..8] of byte;
  chislo:word;
  //bufch:word;
  //knt:integer;
  //naci:byte;
  //civ1:word;
  //clik:boolean;
  BufBmp : Tbitmap;
 // Vcicl :Boolean = False;
  f:Text;
  ChHodov : Integer;
  PercentRate : Double =7;
  FormProcess : Boolean = False;
  BitMapReady : Boolean = True;
  TurnThread : TTurnThread;
  Scale : Double = 1;
  PositionX : Integer ;
  PositionY : Integer ;
  OldPositionX,OldPositionY : Integer;
  CursorX,CursorY : Integer;
  CursorDown : Boolean = False;
  FullScale : Double = 2;  //Зависит от загруженной карты
  SectionArray : Array[1..7] of TSectionThread;

procedure PointWork(i,j:Word);
procedure SomeTurns;
procedure SectionWork(Number:Integer);


implementation

{$R *.dfm}
procedure TTurnThread.Execute;
begin
  while True do
    begin
      while (not YesTurns) do Sleep(1);
      SomeTurns;
      YesTurns := False;
    end;
end;


procedure TSectionThread.Execute;
begin
  while True do
    begin
      SectionWork(Number);
      SuspendFlag := True;
      Suspend;
      SuspendFlag := False;
    end;
end;

function GetWindow:Double;
begin
   result:=arealength/(2*Scale);//Form1.ClientHeight/(Scale);
end;

function TakeGray(Color:TColor):Integer;
begin
   result := (Color mod 256) + (Color mod 65536) div 256 + (Color mod 16777216) div 65536;
end;

function Invert(Color:TColor):TColor;
begin
  result := GetRValue(Color)*65536+GetGValue(Color)*256+GetBValue(Color);
end;

procedure TCanvasLabel.Init;
begin
  X:=0;
  Y:=0;
  Color := Invert(_Color);
  if TakeGray(Color)>128*3 then  FontColor := ClBlack
                           else  FontColor := clWhite;
end;

procedure TCanvasLabel.OutText;
var Symbols,i:Integer;
S{,S1}:String;
//A:Uint32;
begin
  if (N.chislenost<10) and (not AlwaysOut) then exit;
  S:= IntToStr(N.Army);
  i:=0;
  while Length(S)>=(i+1)*4 do
    begin
      Symbols:=Length(S)-i*4-3;
      S := Copy(S,1,Symbols)+' '+Copy(S,Symbols+1,i*4+3);
      //S := S1+Copy(S,i*4+2,Length(S)-i*4-1);
      inc(i);
    end;
  Symbols:=Length(S);
  Y := Round(N.Y_avg)-Round(20*FullScale);
  X := Round(N.X_avg)-Symbols*Round(6*FullScale);
  Text := S;
  BufBmp.Canvas.Font.Size := Round(20*FullScale);
  BufBmp.Canvas.Font.Color := FontColor;
  BufBmp.Canvas.Brush.Color := Color;
  BufBmp.Canvas.TextOut(X,Y,Text)
end;

procedure  Tcivil.Create;
 begin
  //if (sushestvovan) then exit;
  sushestvovan:=true;
  chislenost:=1;
  Army:=500;
  Enemy := -1;
  Senior := -1;
  cvet:=buffl.clr;
  Cs := TCriticalSection.Create;
 end;
procedure Tcivil.Destroy;
 begin
  if (not sushestvovan ) then exit;
  sushestvovan:=false;
 end;
procedure  TCivil.IncChislenost;
begin
  if sushestvovan then Inc(chislenost);
end;

procedure  TCivil.DecChislenost;
begin
  if sushestvovan then
    begin
      Dec(chislenost);
      if chislenost<=0 then Destroy;
    end;
end;

procedure  TCivil.ReduceArmy;
begin
 if sushestvovan then
   if Army>N then Army := Army - N
             else Army := 0;

end;

procedure  TCivil.SetChislenost;
begin
  if sushestvovan then Chislenost:=Ch;
end;

function TCivil.GetChislenost;
begin
  Result := Chislenost;
end;


procedure Agression(x,y:integer; var buffl:TField);
var i,j:Integer;
begin
       //Второй вариант - сколько наций, столько критических секций.
       //Крит секция 1
       buffl.Hod := false;
       try
       if (area[x,y].plm=0)  then
         begin
           Nations[buffl.plm].CS.Enter;
           Nations[buffl.plm].ReduceArmy(5);
           Nations[buffl.plm].IncChislenost;
           Nations[buffl.plm].CS.Leave;
         end
       else
       begin
         i := area[x,y].plm;
         j := buffl.plm;
         Nations[i].CS.Enter;
         Nations[j].CS.Enter;
         Nations[i].Decchislenost; //Может одновременно выбивать в разных потоках.
         Nations[j].IncChislenost; //Тоже сделать потокобезопасным

        if (Nations[i].Army=0) then Nations[j].ReduceArmy(5)
        else
          begin
            Nations[j].ReduceArmy(20);
            Nations[i].ReduceArmy(10);
          end;
         Nations[i].CS.Leave;
         Nations[j].CS.Leave;
        end;
        except
        i:=0; //Отладочное
        end;
      // finally
       area[x,y]:=buffl;
//end;
end;





procedure NewNation(var field_prm : TField);
//Var A : Integer;
begin
if {bufch=0}chislo<=59998 then
  begin
    repeat
    inc(chislo);
    until not (Nations[chislo].sushestvovan) or (chislo>59998);


    field_prm.plm:=chislo;
    Nations[chislo].Create(field_prm);
  end

end;

Procedure TestPosition(var Pos:Integer);
var Window : Double;
begin
  Window := GetWindow;//arealength/(2*Scale);
  if Pos-Window<0 then Pos := Round(Window);
  if Pos+Window>arealength then Pos := Round(arealength-Window);
end;

procedure ScaleDown;
begin
  if Scale<1 then  Scale := 1;
  FullScale :=arealength/(Form1.ClientHeight*Scale);
  TestPosition(PositionX);
  TestPosition(PositionY);
end;

Procedure CommonStart;
var
i,j,k:integer;
col:Tcolor;
begin
  for i:=1 to {7}CurrNations do
   begin
    repeat
      j:=random(arealength)+1;
      k:=random(arealength)+1;
      col:=random($ffffff);
    until area[j,k].plm=0;
    area[j,k].clr:=col;
   // area[j,k].kubics:=2;
    area[j,k].plm := i;
    Nations[i].Create(area[j,k]);
    CanvasLabels[i].Init(col);
    if i=1 then
      begin
        Scale:=4;
        PositionX:=j;
        PositionY:=k;
        ScaleDown;
      end;
   end;

  chhodov := 0;
  Form1.Button7.Click;
end;


procedure TForm1.Button1Click(Sender: TObject);
var
i,j:integer;
begin
 //strt:=true;
 Button12Click(Sender);
 Sleep(500);
 arealength := 1088;
 BufBmp.Width := arealength;
 BufBmp.Height := arealength;
 null.clr:=$ffffff;
 null.plm:=0;

 //bufch:=0;
 chislo :=0;
 Nations[0].Army := 0;
 SetLength(area,arealength+1);
  for i:=1 to arealength do
    begin
      SetLength(area[i],arealength+1);
      for j:=1 to arealength do
        area[i,j]:=null;
    end;
 CommonStart;

end;

procedure CommonFile(FileName:String);
var
i,j:integer;
png : TPNGImage;
ptr : PPtr;
begin
 Form1.Button12Click(nil);
 Sleep(300);
 png := TPNGImage.Create;
 png.LoadFromFile(FileName);
 //png.CreateAlpha;
 arealength := (png.Height div 8)*8;
 if arealength<png.Height then arealength := arealength+8;
 BufBmp.Height := arealength;
 BufBmp.Width := arealength;
 BufBmp.Canvas.Draw(0, 0, png);

 //bufch:=0;
 chislo :=0;
 Nations[0].Army := 0;
 {$R-}
 SetLength(area,arealength+1);
 for i:=1 to arealength do SetLength(area[i],arealength+1);
 for j:=1 to arealength do
    begin
      ptr := BufBmp.ScanLine[j-1];
      for i:=1 to arealength do
        begin
          if (ptr^[i-1] mod $1000000=0) or (i>png.Height) or (j>png.Height) then area[i,j].plm:=-1
                                                                            else area[i,j].plm:=0;
          if (i<=png.Height) then area[i,j].clr := ptr^[i-1]//BufBmp.Canvas.Pixels[i,j];
                             else area[i,j].clr := 0;
        end;
    end;
 CommonStart;
 {$R+}
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  CommonFile('uk.png');
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 CommonFile('australia.png');
end;

procedure TForm1.FormCreate(Sender: TObject);
var i:Integer;
begin
 randomize;
// strt:=false;
 Nations[0].chislenost:=0;
 Nations[0].Army:=0;
 //clik:=false;
 //bufch := 0;
 BufBmp:= TBitmap.Create;
 BufBmp.Height:=arealength;
 BufBmp.Width:=arealength;
 BufBmp.PixelFormat :=  pf32bit;
 TurnThread := TTurnThread.Create(False);
 for I := 1 to 7 do
    begin
      SectionArray[i] := TSectionThread.Create(True);
      SectionArray[i].Number := i;
    end;
end;

procedure RenewBmp;   //4,7 ms for 768x768
var i,j{,k,m,razm}:integer;
T1,T2:Double;
Buf{,Buf2} : array  of TColor;
begin

 T1:=GetTickCount;
 SetLength(Buf,arealength);
// razm:=trunc(512/arealength);
 for i:=1 to arealength do       //Линия от 0 до arealength-1
   begin
    for j:=1 to arealength do
      Buf[j-1] :=area[j,i].clr;   //Быстрая операция, закоментирована
    Move(Buf[0],BufBmp.ScanLine[i-1]^{Buf2},arealength*SizeOf(TColor))
    //Тормозит, если не задать Bitmap.PixelFormat :=  pf32bit;
  end;
 T2:=GetTickCount-T1;
end;





Procedure Spy(N,i,j:Word);
begin
  if area[i,j].plm<0 then exit;
  if (Nations[N].MinNation=-1) or (Nations[area[i,j].plm].Army<Nations[Nations[N].MinNation].Army)  then
    Nations[N].MinNation := area[i,j].plm;
  if (Nations[N].MaxNation=-1) or (Nations[area[i,j].plm].Army>Nations[Nations[N].MaxNation].Army)  then
    Nations[N].MaxNation := area[i,j].plm;
end;



procedure PointWork(i,j:Word);
var i1,j1:integer;
//flag:boolean;
kolr,kolr2:Byte;
Rnd : Array[0..8,0..1] of Word;
bufvr:TField;
begin

    //if (area[i,j].plm>0) and (not compare(area[i,j].plm,i,j)) then NewNation(area[i,j]);//bufvr.plm:=0;
    bufvr:=area[i,j];
    if (bufvr.clr>=$ffffff) or (bufvr.clr<=0) or (bufvr.plm<0) then exit;
    if (Nations[bufvr.plm].Senior>0) and (bufvr.plm>1)  then
      if Nations[bufvr.plm].Army<Nations[Nations[bufvr.plm].Senior].Army div 2 then exit;

    if  not bufvr.hod then exit;

   // if (bufvr.hod=false) then  bufvr.hod:=true
     //else
     begin
     //ch:=0;
     kolr := 0;
     for i1:=i-1 to i+1 do
      for j1:=j-1 to j+1 do
        begin
          if (i1<1) or (i1>arealength) then continue;
          if (j1<1) or (j1>arealength) then continue;
          Spy(bufvr.plm,i1,j1);
            //Области, которые можно захватить, захватывать можно только врага.
          if {(area[i1,j1].plm=0) or} ((bufvr.plm<>area[i1,j1].plm) and (area[i1,j1].plm=Nations[bufvr.plm].Enemy) and (area[i1,j1].plm>=0)) then
             begin
               Rnd[kolr,0]:=i1;
               Rnd[kolr,1]:=j1;
               inc(kolr);
             end;
        end;
     if (kolr>0) and (Nations[bufvr.plm].Army>0) and (Nations[bufvr.plm].Army>Nations[Nations[bufvr.plm].Enemy].Army) then
       begin
        kolr2:=Random(kolr);
        if kolr2=kolr then kolr2:=kolr-1;
        Agression(Rnd[kolr2,0],Rnd[kolr2,1],bufvr);
       end;

     //if (bufvr.hod=false) then  bufvr.hod:=true;

   area[i,j]:=bufvr;
   end
end;

procedure SetXYAverage(i,j : Integer);
var ch:Integer;
begin
   if area[i,j].plm<=0 then exit;
   ch := Nations[area[i,j].plm].chislenost;
   if ch=0 then exit;
   Nations[area[i,j].plm].X_avg := Nations[area[i,j].plm].X_avg + i/ch;
   Nations[area[i,j].plm].Y_avg := Nations[area[i,j].plm].Y_avg + j/ch;
end;

procedure OutLabel (var L:TLabel;const N :TCivil);
var Symbols,i:Integer;
S{,S1}:String;
//A:Uint32;
begin
  S:= IntToStr(N.Army);
  i:=0;
  while Length(S)>=(i+1)*4 do
    begin
      Symbols:=Length(S)-i*4-3;
      S := Copy(S,1,Symbols)+' '+Copy(S,Symbols+1,i*4+3);
      //S := S1+Copy(S,i*4+2,Length(S)-i*4-1);
      inc(i);
    end;
  Symbols:=Length(S);
  L.Top := Round(N.Y_avg)-10;
  L.Left :=  Round(N.X_avg)-Symbols*3;
  L.Caption := S;
end;

procedure SectionWork;
var i,j,StartWork,EndWork:Integer;
begin
 StartWork := (arealength div 8) * Number+2;
 EndWork := (arealength div 8) * (Number+1)-1;
 if Number=0 then dec(StartWork);
 if Number=7 then inc(EndWork);
 for i:= StartWork to EndWork do
  for j:=1 to arealength do
   if (ChHodov mod 2) = 0 then PointWork(StartWork+EndWork-i,arealength-j+1)
   else PointWork(i,j);
end;

procedure EdgeWork;
var i,j,k:Integer;
begin
   for I := 1 to 7 do
     for k := 0 to 1 do
       for j:=1 to arealength do
         PointWork(i*(arealength div 8)+k,j);
end;


//procedure TForm1.Button2Click(Sender: TObject);
procedure SomeTurns;  //47 ms for operation
var i,j{,i1,j1,ch},hod:integer;
//bufvr:TField;
T1,T2:Double;
b:Boolean;
begin
//knt:=1;
T1 := GetTickCount;
for hod:=1 to {50}3 do
BEGIN
if ChHodov<1000 then PercentRate := (7-6*ChHodov/1000);
if ChHodov>20000 then PercentRate := (0.5+ChHodov/40000);

 for i := 1 to MaxNations do
   begin
     Nations[i].MinNation :=-1;
     Nations[i].MaxNation :=-1;
     Nations[i].X_avg := 0;
     Nations[i].Y_avg := 0;
   end;
   for i := 1 to 7 do SectionArray[i].Resume;
   SectionWork(0);

   EdgeWork;
   b:=False;
   while not b  do
     begin
       b:=True;
       for I := 1 to 7 do
         b:=b and SectionArray[i].SuspendFlag;//Suspended;  //Конфликт?
     end;

 for i := 2 to MaxNations do  Nations[i].Enemy := Nations[i].MinNation;   //У нации 1 свои порядки
 for i := 2 to MaxNations do  Nations[i].Senior := Nations[i].MaxNation;   //У нации 1 свои порядки

 for i:=1 to arealength do
  for j:=1 to arealength do
    begin
      SetXYAverage(i,j);
      area[i,j].hod:=true;
    end;

  for i := 1 to CurrNations do
   begin
     if Nations[i].Army<Nations[i].chislenost*100 then Nations[i].Army := Round(Nations[i].Army*(1+0.002*PercentRate));
   end;
 inc(ChHodov);

 if ChHodov mod 50 =0 then
   begin
     for i := 1 to MaxNations do
       if Nations[i].Army<Nations[i].chislenost*100  then Nations[i].Army := Nations[i].Army +  Nations[i].chislenost;
   end;

  if ChHodov mod 5 =0 then
    begin
      //for i := 1 to CurrNations do CanvasLabels[i].OutText(Nations[i]);//OutLabel(Labels[i],Nations[i]);
       while FormProcess do Sleep(1);
       BitmapReady := False;
       BufBmp.Canvas.Lock;
       RenewBmp;//Form1.Button3.Click;
       for i := CurrNations downto 1 do CanvasLabels[i].OutText(Nations[i],i=1); //После отображения остального!
       BufBmp.Canvas.UnLock;
       BitmapReady := True;
    end;






end;
T2 := GetTickCount-T1;  //768 мс. для карты 1536*1536      После многопоточности понижено до 219  В худшем случае 266.


end;

{
procedure TForm1.Button5Click(Sender: TObject);
var i,j,k,m,razm:integer;
begin
  naci:=3;
  razm:=trunc(512/arealength);
 for i:=1 to arealength do
  for j:=1 to arealength do
  for k:=0 to razm-1 do
    for m:=0 to razm-1 do
      form1.Canvas.Pixels[(i-1)*razm+k,(j-1)*razm+m]

end;
}



procedure TForm1.Button7Click(Sender: TObject);
//var i:integer;
begin
Timer1.Enabled := True;
Timer2.Enabled := True;

end;

procedure TForm1.Button8Click(Sender: TObject);
begin
Button12Click(Sender);
Close;
end;

  {
procedure TForm1.Button11Click(Sender: TObject);
var i,j,k,kk,m,razm:integer; cr:Tcolor;
begin
 naci:=5;
  razm:=trunc(512/arealength);
 for i:=1 to arealength do
  for j:=1 to arealength do
  begin
   kk:=area[i,j].plm;
   cr:=Nations[kk].cvet;
  for k:=0 to razm-1 do
    for m:=0 to razm-1 do
      form1.Canvas.Pixels[(i-1)*razm+k+1,(j-1)*razm+m+1]:=cr;
  end;


end;
}

procedure TForm1.Button12Click(Sender: TObject);
begin
 // Vcicl:=True;
 Timer1.Enabled := False;
 Timer2.Enabled := False;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  var
  Window : Double;
begin
//Переводить экранный координты в племенные
case Button of
  mbLeft:
    begin
      CursorDown := True;
      CursorX:=X;
      CursorY:=Y;
      OldPositionX := PositionX;
      OldPositionY := PositionY;
    end;
  mbRight:
    begin
      Window := GetWindow;
      Nations[1].Enemy := area[Round(PositionX-Window+x*FullScale),Round(PositionY-Window+y*FullScale)].plm;
    end;
end;



end;



procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
//var
//FScale : Double;
begin
  if CursorDown then
    begin
      PositionX := OldPositionX + Round((CursorX-X)*FullScale);
      PositionY := OldPositionY + Round((CursorY-Y)*FullScale);
      TestPosition(PositionX);
      TestPosition(PositionY);
    end;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  CursorDown := False;
end;



procedure TForm1.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Scale := Scale/1.41;
  ScaleDown;
end;

procedure TForm1.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  Scale := Scale*1.41;
  FullScale :=arealength/(ClientHeight*Scale);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  FullScale :=arealength/(ClientHeight*Scale);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  YesTurns := True;
  //Button2Click(Sender);
end;

procedure TForm1.Timer2Timer(Sender: TObject);
var DestRect, SrcRect  : TRect;
//i:Integer;
T1,T2 : Double;
Window : Integer;
begin
 // exit; //Отладка
  T1 := GetTickCount;
  FormProcess := True;
  while not BitMapReady do Sleep(1);
  BufBmp.Canvas.Lock;
  Window := Round(GetWindow);//Round(arealength/(2*Scale));
  DestRect := Rect(1, 1, ClientHeight,ClientHeight);
  SrcRect := Rect(PositionX-Window, PositionY-Window, PositionX+Window, PositionY+Window);
  Label1.Caption:=FloatToStrF(PercentRate,ffGeneral,1,2)+'%';
  Form1.Canvas.CopyRect(DestRect,BufBmp.Canvas,SrcRect);
  T2:= GetTickCount-T1;
  BufBmp.Canvas.UnLock;
  FormProcess := False;

end;

end.
