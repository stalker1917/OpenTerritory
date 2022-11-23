object Form1: TForm1
  Left = 173
  Top = 124
  Caption = 'Open Territory Beta'
  ClientHeight = 768
  ClientWidth = 968
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OnCreate = FormCreate
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 887
    Top = 194
    Width = 48
    Height = 20
    Caption = 'Label1'
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Transparent = False
  end
  object Button1: TButton
    Left = 885
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Standart'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button7: TButton
    Left = 885
    Top = 132
    Width = 75
    Height = 25
    Caption = 'Resume'
    TabOrder = 1
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 885
    Top = 163
    Width = 75
    Height = 25
    Caption = 'Quit'
    TabOrder = 2
    OnClick = Button8Click
  end
  object Button12: TButton
    Left = 887
    Top = 101
    Width = 73
    Height = 25
    Caption = 'Pause'
    TabOrder = 3
    OnClick = Button12Click
  end
  object Button2: TButton
    Left = 885
    Top = 39
    Width = 75
    Height = 25
    Caption = 'UK'
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 885
    Top = 70
    Width = 75
    Height = 25
    Caption = 'Australia'
    TabOrder = 5
    OnClick = Button3Click
  end
  object OpenDialog1: TOpenDialog
  end
  object SaveDialog1: TSaveDialog
    Left = 32
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 88
    Top = 104
  end
  object Timer2: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer2Timer
    Left = 80
    Top = 184
  end
end
