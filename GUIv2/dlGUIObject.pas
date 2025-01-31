﻿unit dlGUIObject;

interface

uses RTTI, Classes, Graphics, SysUtils, dlOpenGL, dlGUITypes, dlGUITypesRTTI, dlGUIFont, dlGUIVertexController, TypInfo;

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

//Сообщения GUI компонентам
 const MSG_FORM_INSERTOBJ   = 2; //Добавлен компонент на форму
       MSG_CHNG_RADIOBUTTON = 3; //Изменилось состояние RadioButton

 type
   //Компоненты
   TGUITypeDefName = record
     Name: String; //Название компонента по умолчанию
   end;
   TGUITypeComponent = (gtcObject, gtcForm, gtcButton, gtcPopupMenu, gtcCheckBox, gtcLabel, gtcImage, gtcProgressBar,
     gtcEditBox, gtcTrackBar, gtcListBox, gtcRadioButton, gtcBevel, gtcComboBox, gtcPanel, gtcTable);

 //Имена компонентов по умолчанию
 const
   TGUITypeDefNames: array[TGUITypeComponent] of TGUITypeDefName =
     ((Name: 'Object'),
      (Name: 'Form'),
      (Name: 'Button'),
      (Name: 'PopupMenu'),
      (Name: 'CheckBox'),
      (Name: 'Label'),
      (Name: 'Image'),
      (Name: 'ProgressBar'),
      (Name: 'EditBox'),
      (Name: 'TrackBar'),
      (Name: 'ListBox'),
      (Name: 'RadioButton'),
      (Name: 'Bevel'),
      (Name: 'ComboBox'),
      (Name: 'Panel'),
      (Name: 'Table')
     );

type
   TGUIObject = class;
   EGUIObject = class(Exception);

   //Сообщения что то наподобие Windows.TMessage
   TGUIMessage = record
     Msg    : Integer;    //Сообщение GUI_WM_USER например
     Self   : TGUIObject; //Текущий объект
   end;

   TGUIActionSetter = (
                        goaFocused,             //Фокус на объекте
                        goaDown,                //На объект нажали
                        goaTextureNeedRecalc,   //Нужно пересчитать координаты текстуры
                        goaTextureAlwaysRecalc, //Всегда пересчитываем текстуру
                        goaItemSelect,          //Выбрали элемент (у ListBox например)
                        goaWhell,               //Сработала прокрутка
                        goaUpdateSize           //Поменялись размеры
                      );

   TGUIObjectAction = Set of TGUIActionSetter;

   //Прозрачность объекта
   TGUIObjectAlpha = class(TPersistent)
     public
       FValue : TFloat; //Индекс прозрачности
       FSrc   : TUInt; //Blend src (GL_ONE)
       FDst   : TUInt; //Blend dst (GL_DST_COLOR)
     public
       constructor Create(pValue: TFloat; pSrc, pDst: TUInt);
       procedure SetValue(pValue: TFloat; pSrc: TUInt = GL_ONE; pDst: TUInt = GL_ONE_MINUS_SRC_ALPHA);
     published
       property Value: TFloat read FValue write FValue;
       property Src  : TUInt  read FSrc   write FSrc;
       property Dst  : TUInt  read FDst   write FDst;
   end;

   //Размеры текстуры устанавливаются при назначении текстуры объекту
   TGUITextureInfo = record
     public
       Width : Integer;
       Height: Integer;
     public
       procedure SetSize(pWidth, pHeight: Integer);
   end;

   //Всплывающая подсказка (Параметры потом передаются в класс Hint'а на форме)
   //TGUIFormHint
   TGUIHintObject = class(TPersistent)
     private
       FText   : String;  //Текст всплывающей подсказки
       FColor  : TColor;  //Цвет всплывающей подсказки
       FEnable : Boolean; //Включено отображение подсказки или нет
       FBGColor: TColor;  //Фоновый цвет
     private
       constructor Create;
       procedure SetText(pText: String);
       procedure SetColor(pColor: TColor);
       procedure SetEnable(pEnable: Boolean);
       procedure SetBackgroundColor(pColor: TColor);
     published
       property Text  : String          read FText    write SetText;
       property Color : TColor          read FColor   write SetColor;
       property Enable: Boolean         read FEnable  write SetEnable;
       property BackgroundColor: TColor read FBGColor write SetBackgroundColor;
   end;

   //Объект от которого наследуются компоненты
   TGUIObject = class(TPersistent)
     private
       FName       : String; //Название объекта
       FDefName    : String; //Имя данное автоматически (для подставки ID, SetID())
       FType       : TGUITypeComponent; //Тип компонента
     protected
       FUID        : Integer; //Номер объекта в листе
     protected
       FRect       : TGUIObjectRect; //Позиция и размеры
       FTextOffset : TGUIObjectRect; //Положение текста
       FHide       : Boolean; //Видимость
       FEnable     : Boolean; //Активный компонент или нет
       FAction     : TGUIObjectAction; //Действия над объектом
     protected
       FHint       : TGUIHintObject; //Всплывающая подсказка
     protected
       FTextureInfo: TGUITextureInfo; //Информация о размерах текстуры
     private
       FTextureLink: TTextureLink; //Ссылка на текстуру
     protected
       FScale      : TFloat; //Увеличение
       FFont       : TGUIFont; //Шрифт
       FBlend      : TBlendParam; //Смешивание цветов
       FColor      : TGLColor; //Цвет
       FModeDraw   : TUInt; //Режим прорисовки
     protected
       FParent     : TGUIObject; //Родитель объекта
       FPopupMenu  : TGUIObject; //Выпадающий список
       FArea       : TGUITypeArea; //Рамка при наведении
     protected
       FVertexList : TGUIVertexList; //Список вершин
     protected
       //Событие при изменении шрифта
       procedure SetFontEvent; virtual;
       //Установить ссылку на шрифт
       procedure SetFontLink(pFont: TGUIFont); virtual;
       //Установить popupmenu
       procedure SetPopupMenu(pPopupMenu: TGUIObject);

       procedure SetScale(pScale: TFloat); virtual; //Установить размер
       procedure SetWidth(pWidth: Integer); //Установить ширину компонента
       procedure SetHeight(pHeight: Integer); //Установить высоту компонента
       procedure SetResize; virtual; //Вызывается в SetWidth, SetHeight при изменении размера
       procedure SetHide(pHide: Boolean); virtual;
       procedure SetEnable(pEnable: Boolean); virtual;
       procedure SetColor(pColor: TColor); virtual;
       procedure SetAreaResize; virtual;
     private
       function GetColor: TColor;
       function GetTextureLinkName: String;
       function GetAttrFocused: Boolean;
       procedure SetID(pID: Integer);
       function GetPopupMenuName: String;
       procedure ChangeTextureInfo;
     public
       //Управление FAction
       procedure SetAction(pAction: TGUIObjectAction);
       procedure RemoveAction(pAction: TGUIObjectAction);
       function GetAction: TGUIObjectAction;
     public
       //Узнать позицию родителя (нужно для отрисовки компонента на форме)
       function GetParentPos: TCoord2D;
       //Установить ссылку на текстуру
       procedure SetTextureLink(pTextureLink: TTextureLink); virtual;
       //Скопировать текстуру
       procedure SetTextureCopyFrom(pTextureLink: TTextureLink);
       //Получить ссылку на текущую текстуру
       function GetTextureLink: TTextureLink;
       //Установить размеры компонента
       procedure SetRect(pX, pY, pW, pH: Integer);
       //Получить какой то другой активный popup например у ListBox
       function GetChildItemPopup: TGUIObject; virtual;
       //Вызвать SetResize
       procedure OnResize;
     public
       {RTTI}
       //Получить список публичных свойств
       procedure RTTIGetObjectPropList(pObj: TObject; var pList: TStringList; pIgnoreList: TStringList = nil);
       function RTTIGetPublishedList(pIgnoreList: TStringList = nil): String; virtual;
       //Получить список процедур и значения
       function RTTIGetProcList: String;
       function RTTIGetProcName(pProc: TGUIProc): String;

       {RTTI Import}
       procedure RTTISetFromList(pObj: TObject; pList: TStringList);
     public
       OnClick               : TGUIProc; //Нажатие на компонент мышью
     public
       property VertexList   : TGUIVertexList    read FVertexList;
       property ID           : Integer           read FUID                write SetID;
       property Rect         : TGUIObjectRect    read FRect;
       property TextRect     : TGUIObjectRect    read FTextOffset         write FTextOffset;
       property Focused      : Boolean           read GetAttrFocused;

       property Name         : String            read FName;
       property ObjectName   : String            read FDefName;
       property ObjectType   : TGUITypeComponent read FType;

       property X            : Integer           read FRect.X             write FRect.X;
       property Y            : Integer           read FRect.Y             write FRect.Y;
       property Width        : Integer           read FRect.Width         write SetWidth;
       property Height       : Integer           read FRect.Height        write SetHeight;
       property Color        : TColor            read GetColor            write SetColor;

       property Hide         : Boolean           read FHide               write SetHide;
       property Enable       : Boolean           read FEnable             write SetEnable;

       property TextureName  : String            read GetTextureLinkName;
       property Font         : TGUIFont          read FFont               write SetFontLink;
       property PopupMenu    : TGUIObject        read FPopupMenu          write SetPopupMenu;
       property Parent       : TGUIObject        read FParent             write FParent;
       property Scale        : TFloat            read FScale              write SetScale;
       property Hint         : TGUIHintObject    read FHint               write FHint;

       property Blend        : TBlendParam       read FBlend              write FBlend;
       property PopupMenuName: String            read GetPopupMenuName;
       property Area         : TGUITypeArea      read FArea               write FArea;
     public
       constructor Create(pName: String = ''; pType: TGUITypeComponent = gtcObject);
       destructor Destroy; override;

       //Событие нажатия на кнопку клавиатуры
       procedure OnKeyDown(var Key: Word; Shift: TShiftState); virtual;
       //Событие отпускания кнопки клавиатуры
       procedure OnKeyUp(var Key: Word; Shift: TShiftState); virtual;
       //Событие получения символа при нажатии на клавиатуру
       procedure OnKeyPress(Key: Char); virtual;
       //Событие перед нажатием на OnMouseDown например для того чтобы динамически сменить имя PopupMenu
       procedure BeforeOnMouseDown(pX, pY: Integer; Button: TGUIMouseButton); virtual;
       //Событие нажатие на кнопку мыши после BeforeOnMouseDown
       procedure OnMouseDown(pX, pY: Integer; Button: TGUIMouseButton); virtual;
       //Событие отпускание кнопки мыши
       procedure OnMouseUp(pX, pY: Integer; Button: TGUIMouseButton); virtual;
       //Событие перемещение кнопки мыши
       procedure OnMouseMove(pX, pY: Integer); virtual;
       //Событие двойное нажатие мыши (даблклик)
       procedure OnMouseDoubleClick(pX, pY: Integer; Button: TGUIMouseButton); virtual;
       //Прокрутка колесика мыши вверх
       procedure OnMouseWheelUp(Shift: TShiftState; MPosX, MPosY: Integer); virtual;
       //Прокрутка колесика мыши вниз
       procedure OnMouseWheelDown(Shift: TShiftState; MPosX, MPosY: Integer); virtual;
       //Проверка входит ли координата pX, pY в область компонента
       function OnHit(pX, pY: Integer): Boolean; virtual;
       //Если не попали в OnHit тогда срабатывает это событие
       procedure OutHit(pX, pY: Integer); virtual;
       //При перемещении мыши у родителя не тестируется OnHit
       procedure OnMouseOver(pX, pY: Integer); virtual;
       //При деактивации "формы"
       procedure OnDeactivate(Sender: TGUIObject); virtual;
     public
       //Прорисовка до Render
       procedure BeforeObjRender; virtual;
       //Прорисовка объекта
       procedure Render; virtual;
       //Прорисовка после Render например при выделении пункта меню
       procedure AfterObjRender; virtual;
       //Прорисовка текста
       procedure RenderText; virtual;
     public
       procedure SendGUIMessage(pMessage: TGUIMessage); virtual;
   end;

implementation

{ TGUIObject }

procedure TGUIObject.ChangeTextureInfo;
begin
  if Assigned(FTextureLink) then
    FTextureInfo.SetSize(FTextureLink.Width, FTextureLink.Height)
  else
    FTextureInfo.SetSize(1, 1);

  //Текстура поменялась или изменился размер, нужно пересчитать
  SetAction([goaTextureNeedRecalc]);
end;

constructor TGUIObject.Create(pName: String = ''; pType: TGUITypeComponent = gtcObject);
begin
  FDefName      := TGUITypeDefNames[pType].Name;

  if Trim(pName) <> '' then
    FName:= pName
  else
    FName:= FDefName;

  FType         := pType;
  FUID          := -1;
  FRect.SetRect(0, 0, 0, 0);
  FTextOffset.SetRect(0, 0, 0, 0);
  FHide         := False;
  FEnable       := True;
  FAction       := [];
  FTextureInfo.SetSize(1, 1);
  FVertexList   := TGUIVertexList.Create;
  FTextureLink  := TTextureLink.Create;
  FFont         := TGUIFont.Create(nil);
  FBlend        := TBlendParam.Create();
  FColor        := TGLColor.Create(clWhite);
  FModeDraw     := GL_QUADS;
  FParent       := nil;
  FPopupMenu    := nil;
  OnClick       := nil;
  FScale        := 1.0;
  FHint         := TGUIHintObject.Create;
  FArea         := TGUITypeArea.Create;
end;

destructor TGUIObject.Destroy;
begin
  FreeAndNil(FVertexList);
//  FreeAndNil(FTextureLink); не нужно
  FreeAndNil(FFont);
  FreeAndNil(FBlend);
  FreeAndNil(FColor);
  FreeAndNil(FHint);
  FreeAndNil(FArea);
end;

procedure TGUIObject.SendGUIMessage(pMessage: TGUIMessage);
begin

end;

function TGUIObject.GetAction: TGUIObjectAction;
begin
  Result:= FAction;
end;

function TGUIObject.GetAttrFocused: Boolean;
begin
  Result:= goaFocused in FAction;
end;

function TGUIObject.GetChildItemPopup: TGUIObject;
begin
  Result:= nil;
end;

function TGUIObject.GetColor: TColor;
begin
  Result:= FColor.GetColor;
end;

function TGUIObject.GetParentPos: TCoord2D;
begin
  Result.X:= 0.0;
  Result.Y:= 0.0;

  if not Assigned(FParent) then
    Exit;

  Result.X:= FParent.FRect.X;
  Result.Y:= FParent.FRect.Y;
end;

function TGUIObject.GetPopupMenuName: String;
begin
  Result:= '';

  if not Assigned(PopupMenu) then
    Exit;

  Result:= PopupMenu.Name;
end;

function TGUIObject.RTTIGetProcName(pProc: TGUIProc): String;
var Context: TRttiContext;
    Typ    : TRttiType;
    Method : TRttiMethod;
begin
  Result:= '';

  Context:= TRttiContext.Create;

  try
    Typ := Context.GetType(TObject(TMethod(pProc).Data).ClassType);

    for Method in Typ.GetMethods do
      if Method.CodeAddress = TMethod(pProc).Code then
      begin
        Result:= Method.Name;
        Break;
      end;

  finally
    Context.Free;
  end;
end;

function TGUIObject.RTTIGetProcList: String;
var Context: TRttiContext;
    Typ    : TRttiType;
    Field  : TRttiField;
    rtValue: TValue;
    Buf    : TStringList;

    ProcContext: TRttiContext;
    ProcType   : TRttiType;
    Method     : TRttiMethod;
    Proc       : TGUIProc;

    ProcName : String;
    ProcValue: String;
begin
  Buf:= TStringList.Create;
  Buf.Add(objRTTI.RawFormat(rawProc, Self));

  Context:= TRttiContext.Create;
  Typ := Context.GetType(TGUIObject(Self).ClassType);

  if not Assigned(Typ) then
    Exit;

  for Field in Typ.GetFields do begin

    if Field.FieldType = nil then Continue;
    if not Assigned(Field.FieldType.Handle)            then Continue;
    if not (Field.FieldType.Handle^.Kind = tkMethod)   then Continue;
    if not (Field.FieldType.Handle^.Name = 'TGUIProc') then Continue;

    rtValue:= context.GetType(Self.ClassType).GetField(Field.Name).GetValue(Self);

    if rtValue.Kind <> tkMethod then
      Continue;

    //Название "метода" процедуры
    ProcName:= Field.Name;

    //Название процедуры
    if rtValue.IsEmpty then
    begin
      ProcValue:= '';
      Buf.Add(ProcName + '=' + ProcValue);
      Continue;
    end;

    //Получаем ссылку на метод
    Proc:= TGUIProc(PMethod(rtValue.GetReferenceToRawData())^);

    //Создаем новый контекст
    ProcContext:= TRttiContext.Create;

    try
      //Из основного контекста узнаем тип
      ProcType:= Context.GetType(TObject(TMethod(Proc).Data).ClassType);

      for Method in ProcType.GetMethods do
        if Method.CodeAddress = TMethod(Proc).Code then
        begin
          ProcValue:= Method.Name;
          Break;
        end;

    finally
      ProcContext.Free;
    end;

    Buf.Add(objRTTI.RawValue(ProcName, ProcValue));
  end;

  Buf.Add(objRTTI.RawFormat(rawEndProc, Self));

  Result:= Buf.Text;
  Buf.Free;
end;

procedure TGUIObject.RTTIGetObjectPropList(pObj: TObject; var pList: TStringList; pIgnoreList: TStringList = nil);
var PropCount : Integer;
    PropList  : PPropList;
    PropInfo  : PPropInfo;
    i         : integer;
    PropName  : String;
    PropValue : String;
    PropType  : TTypeInfo;

    PropObject: TObject;
begin
  if not Assigned(pList) then
    Exit;

  //Получаем список published property
  PropCount:= GetPropList(pObj, PropList);
  if (not Assigned(PropList)) or (PropCount < 1) then
    Exit;

  //Перебираем все свойства и записываем
  try
    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      PropType := PropInfo.PropType^^;
      PropName := String(PropList^[i].Name);
      PropValue:= StringReplace(GetPropValue(pObj, PropInfo), #13, 'n\', [rfReplaceAll]);

      //Ищем в списке игнорируемых свойств
      if pIgnoreList <> nil then
        if pIgnoreList.IndexOf(PropName) > -1 then
          Continue;

      if (PropType.Kind = tkClass) then
      begin
        PropObject:= GetObjectProp(pObj, PropInfo);
        if not Assigned(PropObject) then Continue;

        if SameText(PropObject.ClassName, 'TGUIPopupMenu') then
        begin
          pList.Add(objRTTI.RawFormat(rawClass, PropObject));
          pList.Add(TGUIObject(PropObject).RTTIGetPublishedList(pList));
          pList.Add(objRTTI.RawFormat(rawEndClass, PropObject));
          Continue;
        end;

        if SameText(String(PropType.Name), Self.ClassParent.ClassName) then Continue;

        pList.Add(objRTTI.RawFormat(rawClass, PropObject));
        RTTIGetObjectPropList(PropObject, pList);
        pList.Add(objRTTI.RawFormat(rawEndClass, PropObject));
      end
      else
        pList.Add(objRTTI.RawValue(PropName, PropValue));

    end;

  except

  end;
end;

function TGUIObject.RTTIGetPublishedList(pIgnoreList: TStringList = nil): String;
var Buf : TStringList;
begin
  Result:= '';
  Buf:= TStringList.Create;

  try
    Buf.Add(objRTTI.RawFormat(rawObject, Self));
      RTTIGetObjectPropList(Self, Buf, pIgnoreList);
    Buf.Add(objRTTI.RawFormat(rawEndObject, Self));

    Result:= Buf.Text;

    Buf.SaveToFile('.\Published\' + Self.ClassName + '_' + TGUITypeDefNames[Self.FType].Name + '.txt');
  finally
    Buf.Free;
  end;

end;

procedure TGUIObject.RTTISetFromList(pObj: TObject; pList: TStringList);
var PropCount : Integer;
    PropList  : PPropList;
    PropInfo  : PPropInfo;
    i, j      : integer;
    PropName  : String;
    PropValue : String;
    PropType  : TTypeInfo;

    PropObject: TObject;
    Str: String;
    Value     : Variant;
begin
  if not Assigned(pList) then
    Exit;

  //Получаем список published property
  PropCount:= GetPropList(Self, PropList);
   if (not Assigned(PropList)) or (PropCount < 1) then
     Exit;

  //Перебираем все свойства и записываем
  try
    for I := 0 to PropCount - 1 do
    begin
      PropInfo := PropList^[I];
      PropType := PropInfo.PropType^^;
      PropName := String(PropList^[i].Name);
      PropValue:= GetPropValue(Self, PropInfo);
      PropObject:= GetObjectProp(Self, PropInfo);

      Str:= '';
      for j := 0 to pList.Count - 1 do
        if Copy(pList[j], 1, Length(PropName)) = PropName then
        begin
          str:= pList[j];

          Value:= Copy(str, pos('=', str) + 1, Length(str));
          Break;
        end;

      if Str = '' then Continue;

      SetPropValue(PropObject, PropInfo, Value);

    end;
  except

  end;
end;

function TGUIObject.GetTextureLink: TTextureLink;
begin
  Result:= FTextureLink;
end;

function TGUIObject.GetTextureLinkName: String;
begin
  Result:= '';
  if Assigned(FTextureLink) then
    Result:= FTextureLink.Name;
end;

procedure TGUIObject.OnDeactivate(Sender: TGUIObject);
begin
  if Assigned(FArea) then
    FArea.Visible:= False;
end;

function TGUIObject.OnHit(pX, pY: Integer): Boolean;
begin
  Result:= False;

  if Hide then
    Exit;

  if (pX >= FRect.X) and (pY >= FRect.Y) and
     (pX <= FRect.X + FRect.Width) and (pY <= FRect.Y + FRect.Height) then
     Result:= True;
end;

procedure TGUIObject.AfterObjRender;
begin
  if Hide then
    Exit;

  if Assigned(FArea) then
  begin
    SetAreaResize;
    FArea.Render;
  end;
end;

procedure TGUIObject.BeforeObjRender;
begin
  if Hide then Exit;
end;

procedure TGUIObject.BeforeOnMouseDown(pX, pY: Integer; Button: TGUIMouseButton);
begin
  if Hide then Exit;
end;

procedure TGUIObject.OnKeyDown(var Key: Word; Shift: TShiftState);
begin
  if Hide then Exit;
end;

procedure TGUIObject.OnKeyPress(Key: Char);
begin
  if Hide then Exit;
end;

procedure TGUIObject.OnKeyUp(var Key: Word; Shift: TShiftState);
begin
  if Hide then Exit;
end;

procedure TGUIObject.OnMouseDoubleClick(pX, pY: Integer; Button: TGUIMouseButton);
begin
  if Hide then Exit;
end;

procedure TGUIObject.OnMouseDown(pX, pY: Integer; Button: TGUIMouseButton);
begin
  if Hide then
    Exit;

  if not OnHit(pX, pY) then
    Exit;

  SetAction([goaDown]);
end;

procedure TGUIObject.OnMouseMove(pX, pY: Integer);
begin
  if Hide then
    Exit;

  if Assigned(FArea) then
    if FArea.Show then
      FArea.Visible:= OnHit(pX, pY);
end;

procedure TGUIObject.OnMouseOver(pX, pY: Integer);
begin
  if Hide then
    Exit;

  if Assigned(FArea) then
    FArea.Visible:= False;
end;

procedure TGUIObject.OnMouseUp(pX, pY: Integer; Button: TGUIMouseButton);
begin
  try
    if goaDown in FAction then
      if Assigned(OnClick) then
        if OnHit(pX, pY) and FEnable then OnClick(Self);
  finally
    RemoveAction([goaDown]);
  end;
end;

procedure TGUIObject.OnMouseWheelDown(Shift: TShiftState; MPosX, MPosY: Integer);
begin
  if Hide then
    Exit;
end;

procedure TGUIObject.OnMouseWheelUp(Shift: TShiftState; MPosX, MPosY: Integer);
begin
  if Hide then
    Exit;
end;

procedure TGUIObject.OnResize;
begin
  SetResize;
end;

procedure TGUIObject.OutHit(pX, pY: Integer);
begin
  RemoveAction([goaDown, goaFocused]);
end;

procedure TGUIObject.Render;

  procedure GapOccur(Item: TVertexClass);
  begin
    if not Item.GapOccur then
      Exit;

    glEnd;
    glBegin(FModeDraw);
  end;

var FID : Integer;
    Item: TVertexClass;
begin
  if (not Assigned(FVertexList)) or FHide then
    Exit;

  //Текстура
  if (Assigned(FTextureLink))   and
     (FTextureLink.Enable)      and
     (not FTextureLink.IsEmpty) then
  begin
    glEnable(GL_TEXTURE_2D);
    FTextureLink.Bind;
  end
  else
    glDisable(GL_TEXTURE_2D);

  //Смешивание цветов
  Blend.Bind;

  glPushMatrix;
    glTranslatef(FRect.X, FRect.Y, 0);
    glScalef(FScale, FScale, FScale);

    BeforeObjRender;

    glBegin(FModeDraw);

      for FID := 0 to FVertexList.Count - 1 do
      begin
        Item:= FVertexList.Vertex[FID];

        //Пересчитать координаты, даже у скрытых элементов
        if (goaTextureNeedRecalc in FAction)   or
           (goaTextureAlwaysRecalc in FAction) then
        begin
          Item.TexCoord.SetCalculatedUV(
                Item.TexCoord.U / (FTextureInfo.Width),
              -(Item.TexCoord.V / (FTextureInfo.Height))
            );
        end;

        if Item.Hide then
        begin
          GapOccur(Item);
          Continue;
        end;

        //Если цвет не меняется ОТКЛЮЧИ текстуру !!!
        glColor4f   (Item.Color.R, Item.Color.G, Item.Color.B, Blend.Alpha);
        glTexCoord2f(Item.TexCoord.UCalc, Item.TexCoord.VCalc);
        glVertex2f  (Item.Vertex.X, Item.Vertex.Y);

        //Если эта вершина разрывающая начнем рисовать новый элемент
        GapOccur(Item);
      end;

    glEnd;

    //Удалим флаг что нужно пересчитывать текстурные координаты
    RemoveAction([goaTextureNeedRecalc]);

    AfterObjRender;

    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
  glPopMatrix;

  RenderText;
end;

procedure TGUIObject.RenderText;
begin
  if Hide then
    Exit;

  if FFont._State <> gfsNone then
    SetFontEvent;
end;

procedure TGUIObject.RemoveAction(pAction: TGUIObjectAction);
begin
  FAction:= FAction - pAction;
end;

procedure TGUIObject.SetAction(pAction: TGUIObjectAction);
begin
  FAction:= FAction + pAction;
end;

procedure TGUIObject.SetAreaResize;
begin
  if Assigned(FArea) then
    FArea.Rect.SetRect(0, 0, Width, Height);
end;

procedure TGUIObject.SetColor(pColor: TColor);
var FID: Integer;
begin
  FColor.SetColor(pColor);
  for FID := 0 to FVertexList.Count - 1 do
    FVertexList.Vertex[FID].Color.SetColor(pColor);
end;

procedure TGUIObject.SetEnable(pEnable: Boolean);
begin
  FEnable:= pEnable;
end;

procedure TGUIObject.SetFontEvent;
begin
  if FHide then
    Exit;

  if FFont = nil then
    Exit;

  FFont._State:= gfsNone;
end;

procedure TGUIObject.SetFontLink(pFont: TGUIFont);
begin
  FFont:= pFont;
  FFont._State:= gfsUpdate;
end;

procedure TGUIObject.SetPopupMenu(pPopupMenu: TGUIObject);
begin
  FPopupMenu:= pPopupMenu;
  if FPopupMenu = nil then
    Exit;

  try
    FPopupMenu.Parent:= Self;
  finally
  end;
end;

procedure TGUIObject.SetTextureCopyFrom(pTextureLink: TTextureLink);
begin
  FTextureLink.CopyFrom(pTextureLink);
  ChangeTextureInfo;
end;

procedure TGUIObject.SetTextureLink(pTextureLink: TTextureLink);
begin
  FTextureLink:= pTextureLink;
  ChangeTextureInfo;
end;

procedure TGUIObject.SetRect(pX, pY, pW, pH: Integer);
begin
  FRect.SetRect(pX, pY, pW, pH);
  SetResize;
end;

procedure TGUIObject.SetResize;
begin
end;

procedure TGUIObject.SetScale(pScale: TFloat);
begin
  FScale:= pScale;
end;

procedure TGUIObject.SetWidth(pWidth: Integer);
begin
  if FRect.Width = pWidth then
    Exit;

  FRect.Width:= pWidth;
  SetResize;
end;

procedure TGUIObject.SetHeight(pHeight: Integer);
begin
  if FRect.Height = pHeight then
    Exit;

  FRect.Height:= pHeight;
  SetResize;
end;

procedure TGUIObject.SetHide(pHide: Boolean);
begin
  FHide:= pHide;
end;

procedure TGUIObject.SetID(pID: Integer);
begin
  if FUID <> -1 then
    FUID:= pID;
end;

{ TGUIObjectAlpha }

constructor TGUIObjectAlpha.Create(pValue: TFloat; pSrc, pDst: TUInt);
begin
  SetValue(pValue, pSrc, pDst);
end;

procedure TGUIObjectAlpha.SetValue(pValue: TFloat; pSrc: TUInt = GL_ONE; pDst: TUInt = GL_ONE_MINUS_SRC_ALPHA);
begin
  Value:= pValue;
  Src  := pSrc;
  Dst  := pDst;
end;

{ TGUITextureInfo }

procedure TGUITextureInfo.SetSize(pWidth, pHeight: Integer);
begin
  Width := pWidth;
  Height:= pHeight;
end;

{ TGUIHintObject }

constructor TGUIHintObject.Create;
begin
  FText   := '';
  FColor  := clWhite;
  FEnable := False;
  FBGColor:= $002C1A16;
end;

procedure TGUIHintObject.SetBackgroundColor(pColor: TColor);
begin
  FBGColor:= pColor;
end;

procedure TGUIHintObject.SetColor(pColor: TColor);
begin
  FColor:= pColor;
end;

procedure TGUIHintObject.SetEnable(pEnable: Boolean);
begin
  FEnable:= pEnable;
end;

procedure TGUIHintObject.SetText(pText: String);
begin
  FText:= pText;
end;

end.
