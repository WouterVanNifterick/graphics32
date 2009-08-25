unit MainUnit;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Polygons Example
 *
 * The Initial Developer of the Original Code is
 * Alex A. Denisov
 *
 * Portions created by the Initial Developer are Copyright (C) 2000-2005
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$MODE Delphi}

uses
  LCLIntf, LResources, Buttons,
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs, GR32, GR32_Image,
  GR32_Layers, GR32_Polygons, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Image: TImage32;
    BitmapList: TBitmap32List;
    Panel1: TPanel;
    Antialiase: TCheckBox;
    Label1: TLabel;
    LineAlpha: TScrollBar;
    Label2: TLabel;
    FillAlpha: TScrollBar;
    FillMode: TRadioGroup;
    Button1: TButton;
    LineThickness: TScrollBar;
    Label3: TLabel;
    ThickOutline: TCheckBox;
    Label4: TLabel;
    AntialiasMode: TRadioGroup;
    Memo1: TMemo;
    Memo2: TMemo;
    Pattern: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImageResize(Sender: TObject);
    procedure ParamsChanged(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ThicknessChanged(Sender: TObject);
  private
    Polygon: TPolygon32;
    Outline: TPolygon32;
    UseOutlinePoly: Boolean;
    LineSize: Single;
    procedure Build;
    procedure Draw;
  end;

var
  Form1: TForm1;

implementation

uses
{$IFDEF Darwin}
  FPCMacOSAll,
{$ENDIF}
  LazJPG;

procedure TForm1.Draw;
var
  MyFiller: TBitmapPolygonFiller;
begin
  with Image do
  begin
    Bitmap.BeginUpdate;
    Bitmap.Clear(clWhite32);
    Bitmap.Draw(50, 50, BitmapList.Bitmap[0]);

    Polygon.Antialiased := Antialiase.Checked;
    Polygon.AntialiasMode := TAntialiasMode(AntialiasMode.ItemIndex);

    if UseOutlinePoly then
    begin
      Outline.Antialiased := Antialiase.Checked;
      Outline.AntialiasMode := TAntialiasMode(AntialiasMode.ItemIndex);
    end;

    if FillMode.ItemIndex = 0 then
      Polygon.FillMode := pfAlternate
    else
      Polygon.FillMode := pfWinding;

    if Pattern.Checked then
    begin
      BitmapList.Bitmap[1].MasterAlpha := FillAlpha.Position;
      BitmapList.Bitmap[1].DrawMode := dmBlend;
      MyFiller := TBitmapPolygonFiller.Create;
      try
        MyFiller.Pattern := BitmapList.Bitmap[1];
        Polygon.DrawFill(Bitmap, MyFiller);
      finally
        MyFiller.Free;
      end;
    end
    else
      Polygon.DrawFill(Bitmap, SetAlpha(clGreen32, FillAlpha.Position));

    if UseOutlinePoly then
      Outline.DrawFill(Bitmap, SetAlpha(clBlack32, LineAlpha.Position))
    else
      Polygon.DrawEdge(Bitmap, SetAlpha(clBlack32, LineAlpha.Position));

    Bitmap.EndUpdate;
    Bitmap.Changed;
    Refresh; // force repaint
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
{$IFDEF Darwin}
  pathRef: CFURLRef;
  pathCFStr: CFStringRef;
  pathStr: shortstring;
{$ENDIF}
  pathMedia: string;
  Item: TBitmap32Item;
begin
  // Under Mac OS X we need to get the location of the bundle
{$IFDEF Darwin}
  pathRef := CFBundleCopyBundleURL(CFBundleGetMainBundle());
  pathCFStr := CFURLCopyFileSystemPath(pathRef, kCFURLPOSIXPathStyle);
  CFStringGetPascalString(pathCFStr, @pathStr, 255, CFStringGetSystemEncoding());
  CFRelease(pathRef);
  CFRelease(pathCFStr);
{$ENDIF}

  // On Lazarus we don't use design-time packages because they consume time to be installed
  Image := TImage32.Create(Self);
  with Image do
  begin
    Parent := Self;
    Height := 528;
    Width := 504;
    Align := alClient;
    Bitmap.ResamplerClassName := 'TKernelResampler';
//    Bitmap.Resampler.KernelClassName := 'TCubicKernel';
//    Bitmap.Resampler.Kernel.Coeff := -0.5;
//    Bitmap.Resampler.KernelMode := kmTableLinear;
//    Bitmap.Resampler.TableSize := 32;
    Scale := 1;
    ScaleMode := smStretch;
    TabOrder := 1;
    OnMouseDown := ImageMouseDown;
    OnResize := ImageResize;
  end;

  BitmapList := TBitmap32List.Create(Self);
  Item := BitmapList.Bitmaps.Add;
  Item.Bitmap.ResamplerClassName := 'TNearestResampler';
  Item := BitmapList.Bitmaps.Add;
  Item.Bitmap.ResamplerClassName := 'TNearestResampler';

  // Different platforms store resource files on different locations
{$IFDEF Windows}
  pathMedia := '..\..\..\Media\';
{$ENDIF}

{$IFDEF UNIX}
  {$IFDEF Darwin}
    pathMedia := pathStr + '/Contents/Resources/Media/';
  {$ELSE}
    pathMedia := '../../../Media/';
  {$ENDIF}
{$ENDIF}

  BitmapList.Bitmap[0].LoadFromFile(pathMedia + 'delphi.jpg');
  BitmapList.Bitmap[1].LoadFromFile(pathMedia + 'texture_b.jpg');
  Image.SetupBitmap;
  Polygon := TPolygon32.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Outline.Free;
  Polygon.Free;
end;

procedure TForm1.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Button = mbLeft then Polygon.Add(GR32.FixedPoint(X, Y))
  else Polygon.Clear;
  Build;
  Draw;
end;

procedure TForm1.ImageResize(Sender: TObject);
begin
  Image.SetupBitmap;
  Build;
  Draw;
end;

procedure TForm1.ParamsChanged(Sender: TObject);
begin
  AntialiasMode.Enabled := Antialiase.Checked;
  Draw;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Polygon.NewLine;
end;

procedure TForm1.Build;
var
  TmpPoly: TPolygon32;
begin
  Outline.Free;
  Outline := nil;

  if UseOutlinePoly then
  begin
    TmpPoly := Polygon.Outline;
    Outline := TmpPoly.Grow(Fixed(LineSize / 2), 0.5);
    Outline.FillMode := pfWinding;
    TmpPoly.Free;
  end;

  if UseOutlinePoly then
    Label4.Caption := Format('(%.1f)', [LineSize])
  else
    Label4.Caption := '(1)';
end;

procedure TForm1.ThicknessChanged(Sender: TObject);
begin
  AntialiasMode.Enabled := Antialiase.Checked;
  UseOutlinePoly := ThickOutline.Checked;
  LineSize := LineThickness.Position * 0.1;
  Build;
  Draw;
end;

initialization
  {$I MainUnit.lrs}

end.