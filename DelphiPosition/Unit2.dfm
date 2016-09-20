object Form2: TForm2
  Left = 0
  Top = 15
  Width = 1024
  Height = 370
  Caption = 'Form2'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 50
    OnTimer = Timer1Timer
    Left = 40
    Top = 16
  end
end
