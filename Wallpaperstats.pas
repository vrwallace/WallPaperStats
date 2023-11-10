program Wallpaperstats;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}

  Classes,
  Windows,
  INTERFACES,
  SysUtils,
  Forms,
  CustApp,
  utilwmi,
  Graphics,
  BGRABitmap,
  BGRABitmapTypes,
  contnrs,
  BGRATextFX,
  registry,
  lclintf,
  shlobj,strutils,LazUTF8;





{ you can add units after this }

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure DumpExceptionCallStack(E: Exception);
   procedure setdesktop(sWallpaperBMPPath: string);
    function getsetpath(): string;
    function readfileintostring(filename: string): string;
    function  IsNumericString(const inStr: string): boolean;
    function windowsFolder: string;
    procedure setlockscreen(slockscreenPath: string);
  end;

  { TMyApplication }

  procedure TMyApplication.DoRun;
  var
    ErrorMsg: string;
    WMIResult: TFPObjectList;
    i: integer;
    PropNamesIndex: integer;
    PropNamesnetwork: array[0..2] of
    string = ('Name', 'MACAddress', 'NetConnectionId');



    PropNameswindowsnew: array[0..5] of string = ('Caption', 'Version','ServicePackMajorVersion','ServicePackMinorVersion','OSArchitecture','LastBootUpTime');
    PropNameswindowsold: array[0..4] of string = ('Caption', 'Version','ServicePackMajorVersion','ServicePackMinorVersion','LastBootUpTime');

    PropNamescomputersystem: array[0..0] of string = ('TotalPhysicalMemory');
    PropNamesprocessor: array[0..0] of string = ('Description');
    PropNameslogicaldisk: array[0..2] of string = ('DeviceID','FreeSpace', 'Size');
    PropNamesNetworkAdapterConfiguration: array[0..1] of
    string = ('Description', 'IPAddress');
    propComputerSystem: array[0..1] of string = ('Name','UserName');
    propversiononly:array[0..0] of string = ('Version');
    REPORT: string;
    bmp, wallimage,lockimage: TBGRABitmap;
    renderer: TBGRATextEffectFontRenderer;
    c: TBGRAPixel;
    reportmessage, filepath: string;
    versionwindows:integer;
  begin
    // quick check parameters
    ErrorMsg := CheckOptions('h', 'help');
    if ErrorMsg <> '' then
    begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    // parse parameters
    if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    try
      if fileexists('c:\skipw.txt') then
      begin
        writeln('Skip file found');
        Terminate;
        Exit;
      end;

      REPORT := '';

      WMIResult := GetWMIInfo('Win32_OperatingSystem', propversiononly);
      versionwindows:= strtoint(ExtractDelimited(1,TStringList(WMIResult[0]).ValueFromIndex[0],[#46]));


      //propComputerSystem


      try
      WMIResult := GetWMIInfo('Win32_ComputerSystem', propComputerSystem);
      REPORT := report + #13#10+'[ComputerSystem]'+ #13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin

        for PropNamesIndex := Low(propComputerSystem) to High(propComputerSystem) do
        begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10;
        end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;



      if (versionwindows>5) then
      begin
      try

      WMIResult := GetWMIInfo('Win32_OperatingSystem', PropNameswindowsnew);
      REPORT := report + #13#10+'[OperatingSystem]'+#13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNameswindowsnew) to High(PropNameswindowsnew) do
        begin

        if (TStringList(WMIResult[i]).Names[PropNamesIndex]<>'LastBootUpTime') then
        REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10
        else
        REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' +  ExtractDelimited(1,TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex],[#46]) + #13#10;

        end;
      end;
      // Clean up
      WMIResult.Free;
      except
       on E: Exception do
      end;
      end
      else
      begin
        try

        WMIResult := GetWMIInfo('Win32_OperatingSystem', PropNameswindowsold);
        REPORT := report +#13#10+'[OperatingSystem]'+ #13#10;

        for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNameswindowsold) to High(PropNameswindowsold) do
        begin


        if (TStringList(WMIResult[i]).Names[PropNamesIndex]<>'LastBootUpTime') then
        REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10
        else
        REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + ExtractDelimited(1,TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex],[#46]) + #13#10;
        end;
      end;
      // Clean up
      WMIResult.Free;
      except
       on E: Exception do
      end;



      end;

      try

      WMIResult := GetWMIInfo('Win32_ComputerSystem', PropNamescomputersystem);
      REPORT := report +#13#10+'[ComputerSystem]' +#13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNamescomputersystem)
          to High(PropNamescomputersystem) do
        begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + floattostr(trunc(strtofloat(TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex]) / 1024 / 1024 + 1)) + ' MB' + #13#10;
        end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;

      try

      WMIResult := GetWMIInfo('Win32_Processor', PropNamesprocessor);
      REPORT := report +#13#10+'[Processor]'+ #13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNamesprocessor) to High(PropNamesprocessor) do
        begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10;
        end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;


        try
        WMIResult := GetWMIInfo('Win32_LogicalDisk', PropNameslogicaldisk,'where DriveType = ''3''');
        REPORT := report +#13#10+'[LogicalDisk]'+ #13#10;


      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNameslogicaldisk) to High(PropNameslogicaldisk) do
        begin
          if (IsNumericString(TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex])) then
          begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + floattostr(trunc(strtofloat(TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex]) / 1024 / 1024 + 1)) + ' MB' + #13#10;
          end
          else
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10;

          end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;

      if (versionwindows>5) then
    begin
      try
      WMIResult := GetWMIInfo('Win32_NetworkAdapter', PropNamesnetwork,
        'WHERE NETENABLED = TRUE');
      REPORT := report +#13#10+'[NetworkAdapter]'+ #13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNamesnetwork) to High(PropNamesnetwork) do
        begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10;
        end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;
      end;

      try
      WMIResult := GetWMIInfo('Win32_NetworkAdapterConfiguration',
        PropNamesNetworkAdapterConfiguration, 'Where IPEnabled = True');
        REPORT := report +#13#10+'[NetworkAdapterConfiguration]' +#13#10;

      for i := 0 to Pred(WMIResult.Count) do
      begin
        for PropNamesIndex := Low(PropNamesNetworkAdapterConfiguration)
          to High(PropNamesNetworkAdapterConfiguration) do
        begin
          REPORT := report + TStringList(WMIResult[i]).Names[PropNamesIndex] +
            ' : ' + TStringList(WMIResult[i]).ValueFromIndex[PropNamesIndex] + #13#10;
        end;
      end;
       WMIResult.Free;
      except
       on E: Exception do
      end;

      REPORT := report +#13#10+'[Misc]' +#13#10;
      REPORT := report +'Snapshot Time : '+FormatDateTime('YYYYMMDDhhnnss',now)+#13#10;

      try
        bmp := TBGRABitmap.Create;
        if fileexists(application.location + 'pace.jpg') then
          bmp.LoadFromfile(application.location + 'pace.jpg');
        lockimage := TBGRABitmap.Create(screen.Width, screen.Height, BGRABlack);
        wallimage:= TBGRABitmap.Create(screen.Width, screen.Height, BGRABlack);
        lockimage.PutImage(0, 0, bmp, dmDrawWithTransparency);
        wallimage.PutImage(0, 0, bmp, dmDrawWithTransparency);

        c := ColorToBGRA(ColorToRGB(clwhite));

        renderer := TBGRATextEffectFontRenderer.Create;
        lockimage.FontRenderer := renderer;
        wallimage.FontRenderer := renderer;

        renderer.ShadowVisible := false;
        renderer.OutlineVisible := true;
        renderer.OutlineColor := CSSblack;
        renderer.OuterOutlineOnly := True;
        lockimage.FontQuality := fqFineAntialiasing;
        wallimage.FontQuality := fqFineAntialiasing;

        lockimage.fontheight:=14;
        wallimage.fontheight:=14;
        //20,560
        //15,400
        //14,355
        lockimage.TextRect(Classes.rect(lockimage.Width - 355, 0,
          lockimage.Width, lockimage.Height), report,
          taleftJustify, tltop, c);

        wallimage.TextRect(Classes.rect(lockimage.Width - 355, 0,
          lockimage.Width, lockimage.Height), report,
          taleftJustify, tltop, c);

       //  lockimage.Rectangle(classes.rect(lockimage.Width - 560,0, lockimage.Width, lockimage.Height),c,dmSet);

        reportmessage := readfileintostring(application.location + 'pace.txt');

        if (trim(reportmessage) <> '') then
        begin

          lockimage.TextRect(Classes.rect(0, 0, lockimage.Width, lockimage.Height),
            reportmessage,
            taleftJustify, tlcenter, c);

          wallimage.TextRect(Classes.rect(0, 0, lockimage.Width, lockimage.Height),
            reportmessage,
            tacenter, tlcenter, c);

        end;



        filepath := getsetpath;
        wallimage.SaveToFile(filepath + 'wallpaper.bmp');
        lockimage.SaveToFile(filepath + 'lockscreen.jpg');

        setdesktop(filepath + 'wallpaper.bmp');
        setlockscreen(filepath + 'lockscreen.jpg');

      finally
        lockimage.Free;
        wallimage.free;
        bmp.Free;

      end;


    except
      on E: Exception do
        DumpExceptionCallStack(E);

    end;



    { add your program here }

    // stop program loop
    Terminate;
  end;

  constructor TMyApplication.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMyApplication.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMyApplication.WriteHelp;
  begin
    { add your help code here }
    writeln('Usage: ', ExeName, ' -h');
  end;

  procedure TMyApplication.DumpExceptionCallStack(E: Exception);
  var

    Report: string;
  begin
    report := '';
    if E <> nil then
    begin
      Report := 'Exception class: ' + E.ClassName + ' | Message: ' + E.Message;


      writeln(trim(FormatDateTime('h:nn:ss AM/PM', now) + ' ' +
        FormatDateTime('MM/DD/YYYY', now)) + ' ERROR: ' + report);

    end;
  end;


  procedure TMyApplication.setdesktop(sWallpaperBMPPath: string);
  var
    reg: TRegistry;
  begin
    try
      try
        reg := TRegistry.Create;
        reg.Lazywrite := false;
        reg.RootKey := hkey_current_user;

        if reg.OpenKey('Control Panel\Desktop', True) then
        begin

          reg.WriteString('WallpaperStyle', IntToStr(0));
        end;


       SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, pchar(sWallpaperBMPPath), SPIF_UPDATEINIFILE);

        //if (version<=5) then
        //begin
        SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),(UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);

        //SysUtils.ExecuteProcess('rundll32',('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"'), []);

        //end;

      finally
        reg.Free;
      end;
    except
      on E: Exception do
        DumpExceptionCallStack(E);

    end;

  end;

  function TMyApplication.getsetpath(): string;
  var
    PersonalPath: array[0..MaxPathLen] of char; //Allocate memory
    filepath: string;

  begin

    try
      PersonalPath := '';
      SHGetSpecialFolderPath(0, PersonalPath, CSIDL_PERSONAL, False);

      filepath := PersonalPath + '\wallpaperstats\';
      if not directoryexists(filepath) then
        createdir(filepath);
      Result := filepath;
    except
      on E: Exception do
        DumpExceptionCallStack(E);

    end;
  end;

  function TMyApplication.readfileintostring(filename: string): string;
  var
    tfIn: TextFile;
    message, s: string;

  begin
    message := '';
    if fileexists(filename) then
    begin
      // Set the name of the file that will be read
      AssignFile(tfIn, filename);

      // Embed the file handling in a try/except block to handle errors gracefully
      try
        // Open the file for reading
        reset(tfIn);

        // Keep reading lines until the end of the file is reached
        while not EOF(tfIn) do
        begin
          readln(tfIn, s);
          message := message + s + #13#10;
        end;

        // Done so close the file
        CloseFile(tfIn);
        Result := message;
      except
        on E: Exception do
          DumpExceptionCallStack(E);
      end;
    end
    else
      Result := '';
  end;
 function  TMyApplication.IsNumericString(const inStr: string): boolean;
var
  i: extended;
begin
  Result := TryStrToFloat(inStr, i);
end;

procedure TMyApplication.setlockscreen(slockscreenPath: string);
  var
    reg: TRegistry;

  begin
    try
      try

        reg := TRegistry.Create( KEY_WRITE or KEY_WOW64_64KEY );
        reg.Lazywrite := false;
        reg.RootKey := hkey_local_machine;
         if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background', true) then
        begin
                   reg.Writeinteger('OEMBackground', strtoint('$00000001'));

        end;


        //if not (directoryexists(windowsfolder+'\SysNative\oobe\info')) then createdir(windowsfolder+'\SysNative\oobe\info');
        if not (directoryexists(windowsfolder+'\SysNative\oobe\info\backgrounds')) then createdir(windowsfolder+'\SysNative\oobe\info\backgrounds');
        if (fileexists(windowsfolder+'\SysNative\oobe\info\backgrounds\backgroundDefault.jpg')) then
        begin
          deletefile(windowsfolder+'\SysNative\oobe\info\backgrounds\backgroundDefault.jpg');
        end;

         copyfile(pchar(slockscreenPath), pchar(windowsfolder+'\SysNative\oobe\info\backgrounds\backgroundDefault.jpg'),false);

        SysUtils.ExecuteProcess(UTF8ToSys('rundll32'),(UTF8ToSys('"USER32.DLL,UpdatePerUserSystemParameters, 1, True"')), []);

      finally
        reg.Free;
      end;
    except
      on E: Exception do
        DumpExceptionCallStack(E);

    end;

  end;

 function TMyApplication.windowsFolder: string;
begin
  //SetLength(Result, Windows.MAX_PATH);
  {SetLength(
    Result, Windows.GetSystemDirectory(PChar(Result), Windows.MAX_PATH)
  );}

   SetLength(
    Result, Windows.getwindowsdirectory(PChar(Result), Windows.MAX_PATH)
  );


end;

var
  Application: TMyApplication;

{$R *.res}

begin
  Application := TMyApplication.Create(nil);
  Application.Title := 'Wallpaper Stats';
  Application.Run;
  Application.Free;
end.
