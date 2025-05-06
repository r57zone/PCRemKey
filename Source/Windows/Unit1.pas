unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, IdCustomHTTPServer,
  IdHTTPServer, StdCtrls, ShellAPI, Menus, IniFiles, XPMan;

type
  TMain = class(TForm)
    IdHTTPServer: TIdHTTPServer;
    CommandKeyEdt: TEdit;
    CommandLbl: TLabel;
    PopupMenu: TPopupMenu;
    CloseBtn: TMenuItem;
    AboutBtn: TMenuItem;
    LineBtn: TMenuItem;
    KeyCodeEdt: TEdit;
    KeyCodeLbl: TLabel;
    AllowedIPLbl: TLabel;
    AllowedIPsMemo: TMemo;
    AllowAnyIPsCB: TCheckBox;
    BlockReqNewDevsCB: TCheckBox;
    PortLbl: TLabel;
    PortEdt: TEdit;
    OkBtn: TButton;
    CancelBtn: TButton;
    XPManifest1: TXPManifest;
    procedure IdHTTPServerCommandGet(AThread: TIdPeerThread;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CloseBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure KeyCodeEdtKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OkBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure AllowAnyIPsCBClick(Sender: TObject);
    procedure AllowedIPsMemoChange(Sender: TObject);
  private
    procedure DefaultHandler(var Message); override;
    { Private declarations }
  protected
    procedure IconMouse(var Msg: TMessage); message WM_USER + 1;
    procedure WMActivate(var Msg: TMessage); message WM_ACTIVATE;
  public
    procedure AppShow;
    procedure AppHide;
    { Public declarations }
  end;

var
  Main: TMain;
  RunOnce, DebugMode: boolean;
  WM_TASKBARCREATED: Cardinal;
  AllowClose: boolean = false;
  AllowedIPs: TStringList;
  AllowAnyIPs, BlockReqNewDevs: boolean;
  IPSMemoChanged: boolean = false;

  IDS_DEV_SYNC_CONFIRM, IDS_ABOUT, IDS_LAST_UPDATE: string;

const
  AllowedIPsFile = 'AllowedIPs.txt';

implementation

{$R *.dfm}

procedure EmulateKeyPress(Key: string);
const
  VK_OEM_1      = $BA; // ';:' для US раскладки
  VK_OEM_PLUS   = $BB; // '+' на основной клавиатуре
  VK_OEM_COMMA  = $BC; // ','
  VK_OEM_MINUS  = $BD; // '-'
  VK_OEM_PERIOD = $BE; // '.'
  VK_OEM_2      = $BF; // '/?' (обычно)
  VK_OEM_3      = $C0; // '`~' (тильда)
  VK_OEM_4      = $DB; // '[{' (левая квадратная скобка)
  VK_OEM_5      = $DC; // '\|' (обратный слэш)
  VK_OEM_6      = $DD; // ']}' (правая квадратная скобка)
  VK_OEM_7      = $DE; // '''"' (апостроф и кавычка)
var
  KeyCode: Word;
  CtrlPressed, AltPressed, ShiftPressed: boolean;
begin
  CtrlPressed:=Pos('CTRL|', Key) > 0;
  AltPressed:=Pos('ALT|', Key) > 0;
  ShiftPressed:=Pos('SHIFT|', Key) > 0;
  Key:=StringReplace(Key, 'CTRL|', '', []);
  Key:=StringReplace(Key, 'ALT|', '', []);
  Key:=StringReplace(Key, 'SHIFT|', '', []);

  if Key = 'ESC' then KeyCode:=VK_ESCAPE else
  if Key = 'OEM_3' then KeyCode:=VK_OEM_3 else // ~
  if Key = 'OEM_MINUS' then KeyCode:=VK_OEM_MINUS else // -
  if Key = 'OEM_PLUS' then KeyCode:=VK_OEM_PLUS else // =
  if Key = 'BACKSPACE' then KeyCode:=VK_BACK else

  if Key = 'TAB' then KeyCode:=VK_TAB else
  if Key = 'OEM_4' then KeyCode:=VK_OEM_4 else // [
  if Key = 'OEM_6' then KeyCode:=VK_OEM_6 else // ]
  if Key = 'OEM_5' then KeyCode:=VK_OEM_5 else // \

  if Key = 'CAPSLOCK' then KeyCode:=VK_CAPITAL else
  if Key = 'OEM_1' then KeyCode:=VK_OEM_1 else // ;
  if Key = 'OEM_7' then KeyCode:=VK_OEM_7 else // '
  if Key = 'ENTER' then KeyCode:=VK_RETURN else

  if Key = 'SHIFT' then KeyCode:=VK_SHIFT else
  if Key = 'OEM_COMMA' then KeyCode:=VK_OEM_COMMA else // < ,
  if Key = 'OEM_PERIOD' then KeyCode:=VK_OEM_PERIOD else // > .
  if Key = 'OEM_2' then KeyCode:=VK_OEM_2 else // ? /

  if Key = 'CTRL' then KeyCode:=VK_CONTROL else
  if Key = 'WIN' then KeyCode:=VK_LWIN else
  if Key = 'ALT' then KeyCode:=VK_MENU else
  if Key = 'SPACE' then KeyCode:=VK_SPACE else
  if Key = 'LANG' then begin keybd_event(VK_SHIFT, 0, 0, 0); keybd_event(VK_MENU, 0, 0, 0); keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0); keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0); end else
  if Key = 'LEFT' then KeyCode:=VK_LEFT else
  if Key = 'UP' then KeyCode:=VK_UP else
  if Key = 'DOWN' then KeyCode:=VK_DOWN else
  if Key = 'RIGHT' then KeyCode:=VK_RIGHT else
  if Key = 'DEL' then KeyCode:=VK_DELETE else

  if (Length(Key) = 1) and ((Key[1] in ['A'..'Z']) or (Key[1] in ['0'..'9'])) then
    KeyCode:=Ord(Key[1])
  else
    exit;

  // Модификаторы
  if CtrlPressed then keybd_event(VK_CONTROL, 0, 0, 0);   // Нажатие клавиши
  if AltPressed then keybd_event(VK_MENU, 0, 0, 0);   // Нажатие клавиши
  if ShiftPressed then keybd_event(VK_SHIFT, 0, 0, 0);   // Нажатие клавиши

  // Основная клавиша
  keybd_event(KeyCode, 0, 0, 0);   // Нажатие клавиши
  keybd_event(KeyCode, 0, KEYEVENTF_KEYUP, 0); // Отпускание клавиши

  // Отпускание модификатора
  if CtrlPressed then keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
  if AltPressed then keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
  if ShiftPressed then keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
end;

procedure TMain.IdHTTPServerCommandGet(AThread: TIdPeerThread;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
const
  AuthorizationSuccessfulStatus = 'auth:ok';
  AuthorizationDeniedStatus = 'auth:denied';
  SuccessStatus = 'ok';
  ErrorStatus = 'error';
var
  i: integer;
  RequestDocument: string;

  KeyValue: string;
begin
  //CoInitialize(nil);
  if (AllowAnyIPs = false) and (Pos(AThread.Connection.Socket.Binding.PeerIP, AllowedIPs.Text) = 0) then Exit; //CoUninitialize;

  AResponseInfo.CustomHeaders.Add('Access-Control-Allow-Origin: *'); // Политика безопасности браузеров

  if (BlockReqNewDevs = false) and (Pos(AThread.Connection.Socket.Binding.PeerIP, AllowedIPs.Text) = 0) then begin

    case MessageBox(Handle, PChar(Format(IDS_DEV_SYNC_CONFIRM, [AThread.Connection.Socket.Binding.PeerIP])), PChar(Caption), 35) of
      6: begin
          AllowedIPs.Add(AThread.Connection.Socket.Binding.PeerIP);
          AllowedIPs.SaveToFile(ExtractFilePath(ParamStr(0)) + AllowedIPsFile);
          AResponseInfo.ContentText:=AuthorizationSuccessfulStatus;
         end;
      7: AResponseInfo.ContentText:=AuthorizationDeniedStatus;
      else
        AResponseInfo.ContentText:=AuthorizationDeniedStatus;
    end;

    RequestDocument:='none';
  end;

  for i:=0 to ARequestInfo.Params.Count - 1 do
    if AnsiLowerCase(ARequestInfo.Params.Names[i]) = 'key' then begin
      KeyValue:=ARequestInfo.Params.ValueFromIndex[i];
      if DebugMode then CommandKeyEdt.Text:=KeyValue;
      EmulateKeyPress(KeyValue);
    end;

  if (RequestDocument <> 'none') then begin
    RequestDocument:=ExtractFilePath(ParamStr(0)) + '\webapp' + StringReplace(ARequestInfo.Document, '/', '\', [rfReplaceAll]);
    RequestDocument:=StringReplace(RequestDocument, '\\', '\', [rfReplaceAll]);

    if ARequestInfo.Document = '/webapp' then // по webapp отдаем главный файл
      RequestDocument:=ExtractFilePath(ParamStr(0)) + 'webapp\index.html';

    if FileExists(RequestDocument) then begin

      if (AnsiLowerCase(ExtractFileExt(ARequestInfo.Document)) = '.js') then
        AResponseInfo.ContentType:='application/javascript'
      else if (AnsiLowerCase(ExtractFileExt(ARequestInfo.Document)) = '.ico') then
        AResponseInfo.ContentType:='image/x-icon'
      else if (AnsiLowerCase(ExtractFileExt(ARequestInfo.Document)) = '.png') then
        AResponseInfo.ContentType:='image/png'
      else
        AResponseInfo.ContentType:=IdHTTPServer.MIMETable.GetDefaultFileExt(RequestDocument);

      IdHTTPServer.ServeFile(AThread, AResponseinfo, RequestDocument);
    end else
      AResponseInfo.ContentText:=ErrorStatus;
  end;

  //CoUninitialize;
end;

procedure Tray(ActInd: integer); // 1 - добавить, 2 - изменить, 3 - удалить
var
  NIM: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(NIM);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
    hIcon:=SendMessage(Application.Handle, WM_GETICON, ICON_SMALL2, 0);
    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case ActInd of
    1: Shell_NotifyIcon(NIM_ADD, @NIM);
    2: Shell_NotifyIcon(NIM_MODIFY, @NIM);
    3: Shell_NotifyIcon(NIM_DELETE, @NIM);
  end;
end;

function GetLocaleInformation(Flag: Integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  Application.Title:=Caption;
  AppHide;
  WM_TASKBARCREATED:=RegisterWindowMessage('TaskbarCreated');
  Tray(1);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);

  if GetLocaleInformation(LOCALE_SENGLANGUAGE) = 'Russian' then begin
    IDS_ABOUT:='О программе...';
    IDS_LAST_UPDATE:='Последнее обновление:';
    IDS_DEV_SYNC_CONFIRM:='Устройство "%s" запрашивает разрешение на синхронизацию. Разрешить?'
  end else begin
    PortLbl.Caption:='Port:';
    AllowAnyIPsCB.Caption:='Allow access from any IP';
    AllowedIPLbl.Caption:='Allowed IP addresses:';
    BlockReqNewDevsCB.Caption:='Block requests for new devices';
    CancelBtn.Caption:='Cancel';
    IDS_ABOUT:='About...';
    AboutBtn.Caption:=IDS_ABOUT;
    IDS_LAST_UPDATE:='Last update:';
    CloseBtn.Caption:='Close';
    IDS_DEV_SYNC_CONFIRM:='The "%s" device requests permission to sync. Allow it?'
  end;

  // Ограничение IP адресов для управления
  AllowedIPs:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + AllowedIPsFile) then begin
    AllowedIPs.LoadFromFile(ExtractFilePath(ParamStr(0)) + AllowedIPsFile);
    AllowedIPsMemo.Text:=AllowedIPs.Text;
  end;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  IdHTTPServer.DefaultPort:=Ini.ReadInteger('Main', 'Port', 7533);
  PortEdt.Text:=IntToStr(IdHTTPServer.DefaultPort);
  AllowAnyIPs:=Ini.ReadBool('Main', 'AllowAnyIPs', false);
  BlockReqNewDevs:=Ini.ReadBool('Main', 'BlockRequestNewDevs', false);
  DebugMode:=Ini.ReadBool('Main', 'DebugMode', false);
  Ini.Free;
  BlockReqNewDevsCB.Checked:=BlockReqNewDevs;
  AllowAnyIPsCB.Checked:=AllowAnyIPs;
  AllowedIPsMemo.Lines.SaveToFile(ExtractFilePath(ParamStr(0)) + AllowedIPsFile); // В Ini ограничение на кол-во символов в строке
  SetWindowLong(PortEdt.Handle, GWL_STYLE, GetWindowLong(PortEdt.Handle, GWL_STYLE) or ES_NUMBER);

  CommandLbl.Visible:=DebugMode;
  CommandKeyEdt.Visible:=DebugMode;
  KeyCodeLbl.Visible:=DebugMode;
  KeyCodeEdt.Visible:=DebugMode;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LBUTTONDOWN:
      begin
        if IsWindowVisible(Main.Handle) then
          AppHide
        else
          AppShow;
      end;

    WM_RBUTTONDOWN:
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.WMActivate(var Msg: TMessage);
begin
  if (Msg.WParam = WA_INACTIVE) then
    AppHide;
  inherited;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  AllowClose:=true;
  AllowedIPs.Free;
  Tray(3);
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(1);
  inherited;
end;

procedure TMain.AppHide;
begin
  AllowClose:=true;
  ShowWindow(Handle, SW_HIDE);
end;

procedure TMain.AppShow;
begin
  if Main.AlphaBlend then begin
    Main.AlphaBlendValue:=255;
    Main.AlphaBlend:=false;
  end;
  ShowWindow(Handle, SW_SHOW);
  SetForegroundWindow(Handle);
  AllowClose:=false;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if AllowClose = false then CanClose:=false;
  AppHide;
end;

procedure TMain.CloseBtnClick(Sender: TObject);
begin
  AllowClose:=true;
  Close;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Caption + ' 1.0' + #13#10 +
  IDS_LAST_UPDATE + ' 06.05.25' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(IDS_ABOUT), MB_ICONINFORMATION);
end;

procedure TMain.KeyCodeEdtKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  KeyCodeEdt.Text:=IntToStr(Key);
end;

procedure TMain.OkBtnClick(Sender: TObject);
var
  Ini: TIniFile;
begin
  BlockReqNewDevs:=BlockReqNewDevsCB.Checked;
  AllowAnyIPs:=AllowAnyIPsCB.Checked;
  IdHTTPServer.DefaultPort:=StrToInt(PortEdt.Text);

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Ini.WriteInteger('Main', 'Port', IdHTTPServer.DefaultPort);
  Ini.WriteBool('Main', 'AllowAnyIPs', AllowAnyIPs);
  Ini.WriteBool('Main', 'BlockRequestNewDevs', BlockReqNewDevs);
  Ini.Free;

  if IPSMemoChanged then
    AllowedIPsMemo.Lines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'AllowedIPs.txt');

  //AppHide;
  IdHTTPServer.Active:=false;
  WinExec(PChar(ParamStr(0)), SW_SHOW);
  AllowClose:=true;
  Close;
end;

procedure TMain.CancelBtnClick(Sender: TObject);
begin
  AppHide;
end;

procedure TMain.AllowAnyIPsCBClick(Sender: TObject);
begin
  AllowedIPsMemo.Enabled:=not AllowAnyIPsCB.Checked;
end;

procedure TMain.AllowedIPsMemoChange(Sender: TObject);
begin
  IPSMemoChanged:=true;
end;

end.
