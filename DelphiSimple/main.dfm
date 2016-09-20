object Form1: TForm1
  Left = 307
  Top = 235
  Width = 325
  Height = 189
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 48
    Width = 37
    Height = 13
    Caption = #1041#1072#1083#1083#1086#1085
  end
  object Label2: TLabel
    Left = 16
    Top = 80
    Width = 42
    Height = 13
    Caption = #1042#1077#1088#1093#1085#1103#1103
  end
  object Label3: TLabel
    Left = 16
    Top = 112
    Width = 40
    Height = 13
    Caption = #1053#1080#1078#1085#1103#1103
  end
  object Button2: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = #1057#1090#1086#1087
    TabOrder = 0
    OnClick = Button2Click
  end
  object Button4: TButton
    Left = 136
    Top = 48
    Width = 75
    Height = 25
    Caption = #1042#1083#1077#1074#1086
    TabOrder = 1
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 216
    Top = 48
    Width = 75
    Height = 25
    Caption = #1042#1087#1088#1072#1074#1086
    TabOrder = 2
    OnClick = Button5Click
  end
  object Edit1: TEdit
    Left = 72
    Top = 48
    Width = 49
    Height = 21
    TabOrder = 3
    Text = '6000'
  end
  object Button1: TButton
    Left = 136
    Top = 80
    Width = 75
    Height = 25
    Caption = #1042#1083#1077#1074#1086
    TabOrder = 4
    OnClick = Button1Click
  end
  object Button3: TButton
    Left = 216
    Top = 80
    Width = 75
    Height = 25
    Caption = #1042#1087#1088#1072#1074#1086
    TabOrder = 5
    OnClick = Button3Click
  end
  object Edit2: TEdit
    Left = 72
    Top = 80
    Width = 49
    Height = 21
    TabOrder = 6
    Text = '700'
  end
  object Button7: TButton
    Left = 216
    Top = 112
    Width = 75
    Height = 25
    Caption = #1042#1087#1088#1072#1074#1086
    TabOrder = 7
    OnClick = Button7Click
  end
  object Edit3: TEdit
    Left = 72
    Top = 112
    Width = 49
    Height = 21
    TabOrder = 8
    Text = '1500'
  end
  object Button6: TButton
    Left = 136
    Top = 112
    Width = 75
    Height = 25
    Caption = #1042#1083#1077#1074#1086
    TabOrder = 9
    OnClick = Button6Click
  end
  object ComPort1: TComPort
    BaudRate = br9600
    Port = 'COM2'
    Parity.Bits = prEven
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    StoredProps = [spBasic]
    TriggersOnRxChar = True
    OnRxChar = ComPort1RxChar
    Left = 200
    Top = 8
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 1080
    Top = 8
  end
  object ComPort2: TComPort
    BaudRate = br19200
    Port = 'COM1'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    StoredProps = [spBasic]
    TriggersOnRxChar = True
    OnRxChar = ComPort2RxChar
    Left = 1016
    Top = 8
  end
  object ComPort3: TComPort
    BaudRate = br19200
    Port = 'COM23'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    StoredProps = [spBasic]
    TriggersOnRxChar = True
    OnRxChar = ComPort3RxChar
    Left = 1048
    Top = 8
  end
  object OpenDialog1: TOpenDialog
    Left = 1112
    Top = 8
  end
  object Timer2: TTimer
    Interval = 10
    Left = 168
    Top = 8
  end
end
