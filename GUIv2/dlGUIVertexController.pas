﻿unit dlGUIVertexController;

interface

uses dlGUITypes, Graphics, Classes, SysUtils;

{
  ====================================================
  = Delphi OpenGL GUIv2                              =
  =                                                  =
  = Author: Ansperi L.L., 2021                       =
  = Email : gui_proj@mail.ru                         =
  = Site  : lemgl.ru                                 =
  =                                                  =
  = Собрано на Delphi 10.3 community                 =
  ====================================================
}

type
  TGUIVertexList = class
    private
      FVertexList: TList;
    private
      function GetCount: Integer;
      function GetVertex(pIndex: Integer): TVertexClass;
    public
      constructor Create;

      //Добавить 4 вершины
      procedure MakeSquare(pX, pY, pWidth, pHeight: TFloat; pVColor: TColor; pTextureLink: TTextureLink; pGroup: Byte = 0; pHide: Boolean = false); overload;
      procedure MakeSquare(pX, pY, pWidth, pHeight: TFloat; pVColor1, pVColor2, pVColor3, pVColor4: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte = 0; pHide: Boolean = false); overload;
      procedure MakeSquare(pX, pY, pWidth, pHeight: TFloat; pVColor: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte = 0; pHide: Boolean = false); overload;
      procedure MakeSquareOffset(pLink: Integer; pOffset: integer; pColor: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte = 0; pHide: Boolean = false); overload;
      procedure MakeSquareOffset(pLink: Integer; pOffset: integer; pVColor1, pVColor2, pVColor3, pVColor4: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte = 0; pHide: Boolean = false); overload;
      //Добавить вершину в список
      procedure Make(pX, pY: TFloat; pColor: TColor; pTU, pTV: TFloat; pGroup: Byte = 0; pHide: Boolean = false);
      //Проверить есть ли вершина по индексу
      function IsExists(pIndex: Integer): Boolean;
      //Установить цвет вершине по индексу
      procedure SetColor(pIndex: Integer; pColor: TColor);
      //Установить цвет группе вершин
      procedure SetGroupColor(pGroup: Byte; pColor: TColor);
      procedure SetGroupColorSquare(pGroup: Byte; const ColorArr: array of TColor);
      //Узнать цвет вершины в группе
      function GetGroupColor(pGroup: Byte; pVertexIndex: Integer): TColor;
      //Скрыть группу вершин
      procedure SetGroupHide(pGroup: Byte; pHide: Boolean);
      //Скрыть вершину по индексу
      procedure SetVertexHide(pIndex: Integer; pHide: Boolean);
      //Указать вершине новые координаты
      procedure SetVertexPos(pIndex: Integer; pX, pY: TFloat);
      procedure SetVertexPosSquare(pIndexStart: Integer; pX, pY, pWidth, pHeight: TFloat);
      //Установить текстурные координаты
      procedure SetVertexTextureUV(pIndex: Integer; pU, pV: TFloat);
      //Установить текстурные координаты группе вершин
      procedure SetVertexTextureMap(pIndexStart: Integer; pTextureCoord: TTextureLinkSquadArr);
      //Установить все координаты текстуры объекта в 1, 1
      procedure SetVertexTextureOne(pIndexOne: Integer = 0; pIndexStart: Integer = 0);
      //Установить видимость (показать/скрыть) только тем которые в списке (-1 - всем)
      procedure SetVertexHideList(pHide: Boolean; pVertexIndexList: array of Integer);
      //Уничтожить класс
      destructor Destroy; override;
    public
      property Vertex[index: Integer]: TVertexClass read GetVertex;
      property Count: Integer read GetCount;

  end;

implementation

{ TGUIVertexController }

procedure TGUIVertexList.SetColor(pIndex: Integer; pColor: TColor);
begin
  if not IsExists(pIndex) then
    Exit;

  TVertexClass(FVertexList[pIndex]).Color.SetColor(pColor);
end;

procedure TGUIVertexList.SetGroupColor(pGroup: Byte; pColor: TColor);
var FID: Integer;
begin
  if not Assigned(FVertexList) then
    Exit;

  for FID := 0 to FVertexList.Count - 1 do
    if TVertexClass(FVertexList.Items[FID]).Group = pGroup then
      TVertexClass(FVertexList.Items[FID]).Color.SetColor(pColor);
end;

procedure TGUIVertexList.SetGroupColorSquare(pGroup: Byte; const ColorArr: array of TColor);
var FID  : Integer;
    Index: Integer;
begin
  if not Assigned(FVertexList) then
    Exit;

  if Length(ColorArr) < 1 then
    Exit;

  Index:= -1;

  for FID := 0 to FVertexList.Count - 1 do
    with TVertexClass(FVertexList.Items[FID]) do
      if Group = pGroup then
      begin
        Inc(Index);

        if Index > High(ColorArr) then
          Break;

        TVertexClass(FVertexList.Items[FID]).Color.SetColor(ColorArr[Index]);
      end;
end;

procedure TGUIVertexList.SetGroupHide(pGroup: Byte; pHide: Boolean);
var FID: Integer;
begin
  if not Assigned(FVertexList) then
    Exit;

  for FID := 0 to FVertexList.Count - 1 do
   with TVertexClass(FVertexList.Items[FID]) do
     if Group = pGroup then
        Hide:= pHide;
end;

procedure TGUIVertexList.SetVertexHide(pIndex: Integer; pHide: Boolean);
begin
  if not IsExists(pIndex) then
    Exit;

  TVertexClass(FVertexList.Items[pIndex]).Hide:= pHide;
end;

procedure TGUIVertexList.SetVertexHideList(pHide: Boolean; pVertexIndexList: array of Integer);

  //Проверим вхождение в список значения
  function ExistInList(pIndex: Integer): Boolean;
  var i: integer;
  begin
    Result:= False;

    for i := 0 to High(pVertexIndexList) do
      if pIndex = pVertexIndexList[i] then
      begin
        Result:= True;
        Break;
      end;

  end;

var i: integer;
begin
  if not Assigned(FVertexList) then
    Exit;

  for i := 0 to FVertexList.Count - 1 do
    if ExistInList(i) then
      TVertexClass(FVertexList.Items[i]).Hide:= pHide
    else
      TVertexClass(FVertexList.Items[i]).Hide:= not pHide;
end;

procedure TGUIVertexList.SetVertexPos(pIndex: Integer; pX, pY: TFloat);
begin
  if not IsExists(pIndex) then
    Exit;

  TVertexClass(FVertexList.Items[pIndex]).SetCoord(pX, pY);
end;

procedure TGUIVertexList.SetVertexPosSquare(pIndexStart: Integer; pX, pY, pWidth, pHeight: TFloat);
begin
  SetVertexPos( pIndexStart    , pX         , pY);
  SetVertexPos( pIndexStart + 1, pX + pWidth, pY);
  SetVertexPos( pIndexStart + 2, pX + pWidth, pY + pHeight);
  SetVertexPos( pIndexStart + 3, pX         , pY + pHeight);
end;

procedure TGUIVertexList.SetVertexTextureMap(pIndexStart: Integer; pTextureCoord: TTextureLinkSquadArr);
var i: integer;
begin
  for i := Low(pTextureCoord.Index) to High(pTextureCoord.Index) do
    if not IsExists(pIndexStart + i) then
      Continue
    else
      TVertexClass(FVertexList.Items[pIndexStart + i]).TexCoord.SetValue(
        pTextureCoord.Index[i].U,
        pTextureCoord.Index[i].V);
end;

procedure TGUIVertexList.SetVertexTextureOne(pIndexOne: Integer = 0; pIndexStart: Integer = 0);
var i: integer;
    Buf: TTextureCoord;
begin
  if not Assigned(FVertexList) or
     (FVertexList.Count < 1)   then
     Exit;

  if (not IsExists(pIndexOne))   or
     (not IsExists(pIndexStart)) then
      Exit;

  Buf:= TVertexClass(FVertexList.Items[pIndexOne]).TexCoord;

  for i := pIndexStart to FVertexList.Count - 1 do
    TVertexClass(FVertexList.Items[i]).TexCoord.SetValue(Buf.U + 1, Buf.V + 1);
end;

procedure TGUIVertexList.SetVertexTextureUV(pIndex: Integer; pU, pV: TFloat);
begin
  if not IsExists(pIndex) then
    Exit;

  TVertexClass(FVertexList.Items[pIndex]).SetTexCoord(pU, pV);
end;

procedure TGUIVertexList.Make(pX, pY: TFloat; pColor: TColor; pTU, pTV: TFloat; pGroup: Byte = 0; pHide: Boolean = false);
begin
  FVertexList.Add(TVertexClass.Create(pX, pY, pColor, pTU, pTV, pGroup, pHide))
end;

procedure TGUIVertexList.MakeSquare(pX, pY, pWidth, pHeight: TFloat; pVColor: TColor; pTextureLinkArr: TTextureLinkSquadArr;
  pGroup: Byte = 0; pHide: Boolean = false);
begin
  MakeSquare(pX, pY, pWidth, pHeight, pVColor, pVColor, pVColor, pVColor, pTextureLinkArr, pGroup, pHide);
end;

procedure TGUIVertexList.MakeSquareOffset(pLink, pOffset: integer; pVColor1,
  pVColor2, pVColor3, pVColor4: TColor; pTextureLinkArr: TTextureLinkSquadArr;
  pGroup: Byte; pHide: Boolean);
var X, Y: TFloat;
begin
  if not IsExists(pLink + 3) then
    Exit;

  X:= Vertex[pLink].Vertex.X;
  Y:= Vertex[pLink].Vertex.Y;
  Make(X + pOffset, Y + pOffset, pVColor1, pTextureLinkArr.Index[0].U, pTextureLinkArr.Index[0].V, pGroup, pHide);

  X:= Vertex[pLink + 1].Vertex.X;
  Y:= Vertex[pLink + 1].Vertex.Y;
  Make(X - pOffset, Y + pOffset, pVColor2, pTextureLinkArr.Index[1].U, pTextureLinkArr.Index[1].V, pGroup, pHide);

  X:= Vertex[pLink + 2].Vertex.X;
  Y:= Vertex[pLink + 2].Vertex.Y;
  Make(X - pOffset, Y - pOffset, pVColor3, pTextureLinkArr.Index[2].U, pTextureLinkArr.Index[2].V, pGroup, pHide);

  X:= Vertex[pLink + 3].Vertex.X;
  Y:= Vertex[pLink + 3].Vertex.Y;
  Make(X + pOffset, Y - pOffset, pVColor4, pTextureLinkArr.Index[3].U, pTextureLinkArr.Index[3].V, pGroup, pHide);
end;

procedure TGUIVertexList.MakeSquareOffset(pLink, pOffset: integer;
  pColor: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte;
  pHide: Boolean);
begin
  MakeSquareOffset(pLink, pOffset, pColor, pColor, pColor, pColor, pTextureLinkArr, pGroup, pHide);
end;

procedure TGUIVertexList.MakeSquare(pX, pY, pWidth, pHeight: TFloat; pVColor: TColor; pTextureLink: TTextureLink; pGroup: Byte = 0; pHide: Boolean = false);
var TextureLinkSquadArr: TTextureLinkSquadArr;
begin
  if pTextureLink <> nil then
    TextureLinkSquadArr.SetSize(pTextureLink.Width, pTextureLink.Height)
  else
    TextureLinkSquadArr.SetSize(1, 1);

  MakeSquare(pX, pY, pWidth, pHeight, pVColor, TextureLinkSquadArr, pGroup, pHide);
end;

procedure TGUIVertexList.MakeSquare(pX, pY, pWidth, pHeight: TFloat;
  pVColor1, pVColor2, pVColor3, pVColor4: TColor; pTextureLinkArr: TTextureLinkSquadArr; pGroup: Byte = 0; pHide: Boolean = false);
begin
  Make(pX         , pY          , pVColor1, pTextureLinkArr.Index[0].U, pTextureLinkArr.Index[0].V, pGroup, pHide);
  Make(pX + pWidth, pY          , pVColor2, pTextureLinkArr.Index[1].U, pTextureLinkArr.Index[1].V, pGroup, pHide);
  Make(pX + pWidth, pY + pHeight, pVColor3, pTextureLinkArr.Index[2].U, pTextureLinkArr.Index[2].V, pGroup, pHide);
  Make(pX         , pY + pHeight, pVColor4, pTextureLinkArr.Index[3].U, pTextureLinkArr.Index[3].V, pGroup, pHide);
end;

function TGUIVertexList.IsExists(pIndex: Integer): Boolean;
begin
  Result:= (Assigned(FVertexList) and (pIndex > -1) and (pIndex < FVertexList.Count));
end;

constructor TGUIVertexList.Create;
begin
  FVertexList:= TList.Create;
end;

destructor TGUIVertexList.Destroy;
var FID   : Integer;
    Vertex: TVertexClass;
begin
  for FID := 0 to FVertexList.Count - 1 do
  begin
    Vertex:= TVertexClass(FVertexList.Items[FID]);
     if Assigned(Vertex) then
       Vertex.Destroy;
  end;

  FVertexList.Clear;
  FreeAndNil(FVertexList);
  inherited;
end;

function TGUIVertexList.GetCount: Integer;
begin
  Result:= 0;

  if not Assigned(FVertexList) then
    Exit;

  Result:= FVertexList.Count;
end;

function TGUIVertexList.GetGroupColor(pGroup: Byte; pVertexIndex: Integer): TColor;
var FID  : Integer;
    Index: Integer;
begin
  Result:= 0;
  Index := -1;

  for FID := 0 to FVertexList.Count - 1 do
    with TVertexClass(FVertexList.Items[FID]) do
      if Group = pGroup then
      begin
        Inc(Index);
        if Index = pVertexIndex then begin
          Result:= TVertexClass(FVertexList.Items[FID]).Color.GetColor;
          Break;
        end;
      end;
end;

function TGUIVertexList.GetVertex(pIndex: Integer): TVertexClass;
begin
  Result:= nil;

  if not IsExists(pIndex) then
    Exit;

  Result:= TVertexClass(FVertexList.Items[pIndex]);
end;

end.
