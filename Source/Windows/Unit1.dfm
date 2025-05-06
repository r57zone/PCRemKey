object Main: TMain
  Left = 192
  Top = 124
  AlphaBlend = True
  AlphaBlendValue = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'PCRemKey'
  ClientHeight = 248
  ClientWidth = 240
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object CommandLbl: TLabel
    Left = 64
    Top = 8
    Width = 48
    Height = 13
    Caption = #1050#1086#1084#1072#1085#1076#1072':'
    Visible = False
  end
  object KeyCodeLbl: TLabel
    Left = 144
    Top = 8
    Width = 69
    Height = 13
    Caption = #1050#1086#1076' '#1082#1083#1072#1074#1080#1096#1080':'
    Visible = False
  end
  object AllowedIPLbl: TLabel
    Left = 8
    Top = 80
    Width = 126
    Height = 13
    Caption = #1056#1072#1079#1088#1077#1096#1105#1085#1085#1099#1077' IP '#1072#1076#1088#1077#1089#1072':'
  end
  object PortLbl: TLabel
    Left = 8
    Top = 8
    Width = 28
    Height = 13
    Caption = #1055#1086#1088#1090':'
  end
  object CommandKeyEdt: TEdit
    Left = 64
    Top = 24
    Width = 73
    Height = 21
    ReadOnly = True
    TabOrder = 6
    Visible = False
  end
  object KeyCodeEdt: TEdit
    Left = 144
    Top = 24
    Width = 73
    Height = 21
    ReadOnly = True
    TabOrder = 7
    Visible = False
    OnKeyDown = KeyCodeEdtKeyDown
  end
  object AllowedIPsMemo: TMemo
    Left = 8
    Top = 96
    Width = 225
    Height = 89
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object AllowAnyIPsCB: TCheckBox
    Left = 8
    Top = 56
    Width = 225
    Height = 17
    Caption = #1056#1072#1079#1088#1077#1096#1080#1090#1100' '#1076#1086#1089#1090#1091#1087' '#1089' '#1083#1102#1073#1099#1093' IP'
    TabOrder = 3
    OnClick = AllowAnyIPsCBClick
  end
  object BlockReqNewDevsCB: TCheckBox
    Left = 8
    Top = 192
    Width = 225
    Height = 17
    Caption = #1041#1083#1086#1082#1080#1088#1086#1074#1072#1090#1100' '#1079#1072#1087#1088#1086#1089#1099' '#1085#1086#1074#1099#1093' '#1091#1089#1090#1088#1086#1081#1089#1090#1074
    TabOrder = 5
  end
  object PortEdt: TEdit
    Left = 8
    Top = 24
    Width = 49
    Height = 21
    TabOrder = 2
  end
  object OkBtn: TButton
    Left = 8
    Top = 216
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 0
    OnClick = OkBtnClick
  end
  object CancelBtn: TButton
    Left = 88
    Top = 216
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 1
    OnClick = CancelBtnClick
  end
  object IdHTTPServer: TIdHTTPServer
    Active = True
    Bindings = <>
    CommandHandlers = <>
    DefaultPort = 7533
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    OnCommandGet = IdHTTPServerCommandGet
    Left = 16
    Top = 104
  end
  object PopupMenu: TPopupMenu
    Left = 48
    Top = 104
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object LineBtn: TMenuItem
      Caption = '-'
    end
    object CloseBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = CloseBtnClick
    end
  end
  object XPManifest1: TXPManifest
    Left = 80
    Top = 104
  end
end
