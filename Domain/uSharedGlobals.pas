unit uSharedGlobals;

interface

uses
  Windows, Classes, Menus, ActnList, SysUtils, ShellApi, Forms, Registry,
  WinTypes, GraphUtil, Graphics, StrUtils;

var
  foundNewAppVersion: boolean;

const
  VISUALMASM_VERSION = 16;
  VISUALMASM_FILE_VERSION = 2;
  VISUALMASM_VERSION_DISPLAY = '2.00';
  VISUALMASM_VERSION_URL = 'http://s3.amazonaws.com/visualmasm/version.txt';
  VISUALMASM_WHATSNEW_URL = 'http://s3.amazonaws.com/visualmasm/whatsnew.txt';
  VISUALMASM_DOWNLOAD_URL = 'http://s3.amazonaws.com/visualmasm/';
  VISUALMASM_FILENAME = 'visualmasm.exe';
  WIN32_HLP_URL = 'http://s3.amazonaws.com/visualmasm/win32.7z';
  WIN32_HLP_FILENAME = 'Win32.hlp';
  WIN32_HLP_FILENAME_COMPRESSED = 'win32.7z';
  LAST_FILES_USED_MAX = 20;
  COPYRIGHT = 'Copyright (c) 2014 - 2017 by Thomas Jaeger. All Rights Reserved.';
  HIGHLIGHTER_FILENAME = 'AssemblerMASM.json';
  EDITOR_COLORS_FILENAME = 'VisualMASM.json';

  KEY_WOW64_64KEY = $0100;

  CRLF: string = #13#10;
  GROUP_FILE_EXT: string = '.vmg';
  PROJECT_FILE_EXT: string = '.vmp';
  ANY_FILE_EXT: string = '*.*';
  TEMP_FILE_PREFIX: string = '~vm~';
  VISUAL_MASM_FILE = 'visualmasm.json';
  DEFAULT: string = 'default';
  SOURCE_FOLDER: string = 'source\';
  ASSEMBLE_FOLDER: string = 'assemble\';
  TEMPLATES_FOLDER: string = 'templates\';
  DOWNLOAD_FOLDER: string = 'download\';
  DOS_16_BIT_COM_STUB_FILENAME: string = 'MSDOS16COMHelloWorld.asm';
  DOS_16_BIT_EXE_STUB_FILENAME: string = 'MSDOS16EXEHelloWorld.asm';
  WIN_32_BIT_EXE_MASM32_FILENAME: string = 'Masm32HelloWorld.asm';
  WIN_64_BIT_EXE_WINSDK64_FILENAME: string = 'WinSDK64HelloWorld.asm';
  TAB: string = #9;
  DEFAULT_PROJECTGROUP_NAME: string = 'ProjectGroup1';
  DEFAULT_PROJECT_NAME: string = 'Project1';
  DEFAULT_FILE_NAME: string = 'Assembly1.asm';
  VISUAL_MASM_FILTER: string = 'Visual MASM File (*.vmg; *.vmp)|*.vmg; *.vmp';
  GROUP_FILTER: string = 'Visual MASM Project Group (*.vmg)|*.vmg';
  PROJECT_FILTER: string = 'Visual MASM Project (*.vmp)|*.vmp';
  RESOURCE_FILTER: string = 'Resource File (*.rc)|*.rc';
  INI_FILTER: string = 'Ini File (*.ini)|*.ini';
  ANY_FILE_FILTER: string = 'Any File (*.*)|*.*';
  MODIFIED_CHAR: string = '*';
  THEME_CODE_EDITOR_DEFAULT: string = 'Dark';
  THEME_DEFAULT: string = 'TV-b (internal)';

  // New Items
  NEW_ITEM_ASSEMBLY_PROJECTS: string = 'Assembly Projects';
  NEW_ITEM_WINDOWS: string = 'Windows';
  NEW_ITEM_MSDOS: string = 'MS-DOS';
  NEW_ITEM_16_BIT_MSDOS_COM_APP: string = '16-Bit MS-DOS COM Application';
  NEW_ITEM_16_BIT_MSDOS_EXE_APP: string = '16-Bit MS-DOS EXE Application';
  NEW_ITEM_16_BIT_WIN_EXE_APP: string = '16-Bit Windows EXE Application';
  NEW_ITEM_16_BIT_WIN_DLL_APP: string = '16-Bit Windows DLL Application Extension';
  NEW_ITEM_32_BIT_WIN_EXE_APP: string = '32-Bit Windows EXE Application';
  NEW_ITEM_32_BIT_WIN_DLL_APP: string = '32-Bit Windows DLL Application Extension';
  NEW_ITEM_64_BIT_WIN_EXE_APP: string = '64-Bit Windows EXE Application';
  NEW_ITEM_64_BIT_WIN_DLL_APP: string = '64-Bit Windows DLL Application Extension';
  NEW_ITEM_ASSEMBLY_FILE: string = 'Assembly File';
  NEW_ITEM_PROJECT_GROUP: string = 'Project Group';
  NEW_ITEM_BATCH_FILE: string = 'Batch File';
  NEW_ITEM_TEXT_FILE: string = 'Text File';
  NEW_ITEM_OTHER_FILES: string = 'Other Files';

  // Microsoft Windows SDK for Windows 7 and .NET Framework 4 (ISO)
  // http://www.microsoft.com/en-us/download/details.aspx?id=8442
  SDK_URL: string = 'http://download.microsoft.com/download/F/1/0/F10113F5-B750-4969-A255-274341AC6BCE/GRMSDK_EN_DVD.iso';

  // MASM32 SDK Version 11
  // http://www.masm32.com/masmdl.htm
  MASM32_URL: string = 'http://website.assemblercode.com/masm32/masm32v11r.zip';

  // HUTCH - MASM32
  // Microsoft (R) Macro Assembler Version 6.14.8444
  // Copyright (C) Microsoft Corp 1981-1997.  All rights reserved.
  MASM_HUTCH_MD5 = 'B54B173761AC671CEA635672E214A8DE';

type
  TAnoPipe=record
    Input : THandle;
    Output: THandle;
  end;

  TAssemblyError = class
    IntId: string;
    FileName: string;
    LineNumber: integer;
    Description: string;
  end;

  PProjectData = ^TProjectData;
  TProjectData = record
    Name: string;
    FileSize: integer;
    Level: integer;
    ProjectId: string;
    FileId: string;
    FileIntId: integer;   // This id is coming from the TDomainObject.IntId
    ProjectIntId: integer; // This id is coming from the TDomainObject.IntId
//    Group: TGroup;
//    Project: TProject;
//    ProjectFile: TProjectFile;
  end;

  PGenericTreeData = ^TGenericTreeData;
  TGenericTreeData = record
    Name: string;
    Level: integer;
    FileName: string;
  end;

  TPlatformType = (p16BitDOS, p16BitWin, p32BitWin, p64BitWinX86amd64,
    p64BitWinX86ia64);

  TProjectType = (ptWin32, ptWin64, ptWin32DLL, ptWin64DLL, ptDos16COM,
    ptDos16EXE, ptWin16, ptWin16DLL);

  TProjectFileType = (pftASM, pftRC, pftTXT, pftDLG, pftBAT, pftOther, pftINI,
    pftCPP);

  TChange = (fcNone, fcCreate, fcUpdate, fcDelete);

function GetEnvVarValue(const VarName: string): string;
function SetEnvVarValue(const VarName, VarValue: string): Integer;
function FileSize(const aFilename: String): Int64;
function FileSearch(const Name, DirList: string): TStringlist;
function ExecAndCapture(const ACmdLine: string; var AOutput: string): Integer;
function GPGExecute(const CmdLine: String; var Output, Errors: String;
   const Wait: DWORD = 10000; const Hide: Boolean = true): Boolean;
function MD5(const stringToHash : string) : string;
function MD5FileHash(const fileName : string) : string;
function RunAsAdminAndWaitForCompletion(hWnd: HWND; filename: string; Parameters: string): Boolean;
procedure ExecuteAndWait(const aCommando: string);
function ReadRegistryValue(key: string; propertyToRead: string): string;
//function ReadRegEntry(strSubKey,strValueName: string): string;
function BrightenColor(AColor: TColor): TColor;
function DarkenColor(AColor: TColor): TColor;
function Split(input: string; schar: Char; s: Integer): string;
function FormatByteSize(const bytes: Longint): string;

implementation

uses
  IdHashMessageDigest;

function BrightenColor(AColor: TColor): TColor;
var
  H, S, L: Word;
begin
  ColorRGBToHLS(AColor, H, L, S);
  if L+2 <= 225 then
    Result := ColorHLSToRGB(H, L+2, S)
  else
    Result := ColorHLSToRGB(H, 225, S);
end;

function DarkenColor(AColor: TColor): TColor;
var
  H, S, L: Word;
begin
  ColorRGBToHLS(AColor, H, L, S);
  Result := ColorHLSToRGB(H, 0, S);
end;

function GetEnvVarValue(const VarName: string): string;
var
  BufSize: Integer;  // buffer size required for value
begin
  // Get required buffer size (inc. terminal #0)
  BufSize := Windows.GetEnvironmentVariable(PChar(VarName), nil, 0);
  if BufSize > 0 then
  begin
    // Read env var value into result string
    SetLength(Result, BufSize - 1);
    Windows.GetEnvironmentVariable(PChar(VarName),PChar(Result), BufSize);
  end
  else
    // No such environment variable
    Result := '';
end;

function SetEnvVarValue(const VarName, VarValue: string): Integer;
begin
  if SetEnvironmentVariable(PChar(VarName), PChar(VarValue)) then
    Result := 0
  else
    Result := GetLastError;
end;

function FileSize(const aFilename: String): Int64;
var
  info: TWin32FileAttributeData;
begin
  result := -1;

//  if not GetFileAttributesEx(PAnsiChar(aFileName), GetFileExInfoStandard, @info) then
    if not GetFileAttributesEx(PWideChar(aFileName), GetFileExInfoStandard, @info) then
    exit;

  result := Int64(info.nFileSizeLow) or Int64(info.nFileSizeHigh shl 32);
end;

function FileSearch(const Name, DirList: string): TStringlist;
var
  I, P, L: Integer;
  C: Char;
  list: TStringlist;
  matches: TStringList;
  fileName: string;
  folders: string;
begin
  list := TStringlist.Create;
  matches := TStringlist.Create;
  Result := list;
  if Name = '' then // nothing to do
    Exit;
  fileName := Name;

  folders:=StringReplace(DirList,';',#13#10,[rfReplaceAll]);
  list.Text:=folders;

  for i:=0 to list.Count-1 do
  begin
    fileName := IncludeTrailingPathDelimiter(list.Strings[i])+Name;
    if FileExists(fileName) then
      matches.Add(fileName);
  end;

  result := matches;

//  P := 1;
//  L := Length(DirList);
//  while True do
//  begin
//    if FileExists(fileName) then
//    begin
//      list.Add(fileName)
//    end;
//    while (P <= L) and (DirList[P] = PathSep) do Inc(P);
//    if P > L then Break;
//    I := P;
//    while (P <= L) and (DirList[P] <> PathSep) do
//    begin
//      //if IsLeadChar(DirList[P]) then
//      if DirList[P] in LeadBytes then
//        P := NextCharIndex(DirList, P)
//      else
//        Inc(P);
//    end;
//    fileName := Copy(DirList, I, P - I);
//    C := AnsiLastChar(fileName)^;
//    if (C <> DriveDelim) and (C <> PathDelim) then
//      fileName := fileName + PathDelim;
//    fileName := fileName + Name;
//  end;
//  fileName := '';
end;

function ExecAndCapture(const ACmdLine: string; var AOutput: string): Integer;
const
  //cBufferSize = 2048;
  cBufferSize = 4096;
var
  vBuffer: Pointer;
  vStartupInfo: TStartUpInfo;
  vSecurityAttributes: TSecurityAttributes;
  vReadBytes: DWord;
  vProcessInfo: TProcessInformation;
  vStdInPipe : TAnoPipe;
  vStdOutPipe: TAnoPipe;
  lengthOfOutput: integer;
begin
  Result := 0;

  with vSecurityAttributes do
  begin
    nlength := SizeOf(TSecurityAttributes);
    binherithandle := True;
    lpsecuritydescriptor := nil;
  end;

  // Create anonymous pipe for standard input
  if not CreatePipe(vStdInPipe.Output, vStdInPipe.Input, @vSecurityAttributes, 0) then
    raise Exception.Create('Failed to create pipe for standard input. System error message: ' + SysErrorMessage(GetLastError));

  try
    // Create anonymous pipe for standard output (and also for standard error)
    if not CreatePipe(vStdOutPipe.Output, vStdOutPipe.Input, @vSecurityAttributes, 0) then
      raise Exception.Create('Failed to create pipe for standard output. System error message: ' + SysErrorMessage(GetLastError));

    try
      GetMem(vBuffer, cBufferSize);
      try
        // initialize the startup info to match our purpose
        FillChar(vStartupInfo, Sizeof(TStartUpInfo), #0);
        vStartupInfo.cb         := SizeOf(TStartUpInfo);
        vStartupInfo.wShowWindow:= SW_HIDE;  // we don't want to show the process
        // assign our pipe for the process' standard input
        vStartupInfo.hStdInput  := vStdInPipe.Output;
        // assign our pipe for the process' standard output
        vStartupInfo.hStdOutput := vStdOutPipe.Input;
        vStartupInfo.dwFlags    := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;

        if not CreateProcess(nil
                             , PChar(ACmdLine)
                             , @vSecurityAttributes
                             , @vSecurityAttributes
                             , True
                             , NORMAL_PRIORITY_CLASS
                             , nil
                             , nil
                             , vStartupInfo
                             , vProcessInfo) then
          raise Exception.Create('Failed creating the console process. System error msg: ' + SysErrorMessage(GetLastError));

        try
          // wait until the console program terminated
          while WaitForSingleObject(vProcessInfo.hProcess, 50)=WAIT_TIMEOUT do
            Sleep(0);

          // clear the output storage
          AOutput := '';
          // Read text returned by the console program in its StdOut channel
          repeat
            ReadFile(vStdOutPipe.Output, vBuffer^, cBufferSize, vReadBytes, nil);
            if vReadBytes > 0 then
            begin
              {$IF CompilerVersion >= 20.0} //>= Delphi 2009
                  AOutput := AOutput + PAnsiChar(vBuffer);
              {$ELSE} //< Delphi 2009
                  AOutput := AOutput + StrPas(vBuffer);
              {$IFEND}
              Inc(Result, vReadBytes);
            end;
          until (vReadBytes < cBufferSize);
          lengthOfOutput := length(AOutput);
          if lengthOfOutput > Result then
            AOutput := copy(AOutput, 0 , result);
        finally
          CloseHandle(vProcessInfo.hProcess);
          CloseHandle(vProcessInfo.hThread);
        end;
      finally
        FreeMem(vBuffer);
      end;
    finally
      CloseHandle(vStdOutPipe.Input);
      CloseHandle(vStdOutPipe.Output);
    end;
  finally
    CloseHandle(vStdInPipe.Input);
    CloseHandle(vStdInPipe.Output);
  end;
end;

function GPGExecute(const CmdLine: String; var Output, Errors: String;
   const Wait: DWORD = 10000; const Hide: Boolean = true): Boolean;
   function _PipeToString(const Pipe: THandle): String;
   const
     BLOCK_SIZE = 1024;
   var
     iBytesRead, iBytesReadTotal: Cardinal;
     szBuffer: array[0..BLOCK_SIZE-1] of Char;
   begin
     Result := '';
     iBytesReadTotal := 0;
     repeat
       // try to read from pipe
       if ReadFile(Pipe, szBuffer, BLOCK_SIZE, iBytesRead, nil) then
       begin
         Inc(iBytesReadTotal, iBytesRead);
         Result := Result + szBuffer;
         SetLength(Result, iBytesReadTotal);
       end;
     until (iBytesRead = 0);
   end;
var
   myStartupInfo: STARTUPINFO;
   myProcessInfo: PROCESS_INFORMATION;
   mySecurityAttributes: SECURITY_ATTRIBUTES;
   hPipeOutputRead, hPipeOutputWrite,
   hPipeErrorRead, hPipeErrorWrite: THandle;
   iWaitRes: Integer;
begin
   // prepare startupinfo structure
   ZeroMemory(@myStartupInfo, SizeOf(STARTUPINFO));
   myStartupInfo.cb := Sizeof(STARTUPINFO);
   // show/hide application
   myStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
   if Hide then // hide application
     myStartupInfo.wShowWindow := SW_HIDE
   else // show application
     myStartupInfo.wShowWindow := SW_SHOWNORMAL;
   // create pipes to get output
   ZeroMemory(@mySecurityAttributes, SizeOf(SECURITY_ATTRIBUTES));
   mySecurityAttributes.nLength := SizeOf(SECURITY_ATTRIBUTES);
   mySecurityAttributes.lpSecurityDescriptor := NIL;
   mySecurityAttributes.bInheritHandle := TRUE;
   CreatePipe(hPipeOutputRead, hPipeOutputWrite, @mySecurityAttributes, 0);
   CreatePipe(hPipeErrorRead, hPipeErrorWrite, @mySecurityAttributes, 0);
   // assign pipes
   myStartupInfo.dwFlags := myStartupInfo.dwFlags or STARTF_USESTDHANDLES;
   myStartupInfo.hStdInput := 0;
   myStartupInfo.hStdOutput := hPipeOutputWrite;
   myStartupInfo.hStdError := hPipeErrorWrite;
   // start the process
   Result := CreateProcess(nil, PChar(CmdLine), nil, nil, True,
     NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE, nil, nil,
     myStartupInfo, myProcessInfo);
   // close the ends of the pipes used by the process
   CloseHandle(hPipeOutputWrite);
   CloseHandle(hPipeErrorWrite); 
   // could process be started ? 
   if Result then 
   begin 
     // wait until process terminates 
     if (Wait > 0) then 
     begin 
       iWaitRes := WaitForSingleObject(myProcessInfo.hProcess, Wait); 
       Output := _PipeToString(hPipeOutputRead); 
       Errors := _PipeToString(hPipeErrorRead); 
       // timeout reached ? 
       if (iWaitRes = WAIT_TIMEOUT) then 
       begin 
         Result := False; 
         TerminateProcess(myProcessInfo.hProcess, 1); 
       end; 
     end; 
     CloseHandle(myProcessInfo.hProcess); 
   end; 
   // close our ends of the pipes 
   CloseHandle(hPipeOutputRead); 
   CloseHandle(hPipeErrorRead); 
end;

function MD5(const stringToHash : string) : string;
var
  idmd5 : TIdHashMessageDigest5;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  try
    //result := idmd5.HashStringAsHex(stringToHash, TEncoding.UTF8);   // TEncoding not avail in D7
    result := idmd5.HashStringAsHex(stringToHash);
  finally
    idmd5.Free;
  end;
end;

function MD5FileHash(const fileName : string) : string;
var
  idmd5 : TIdHashMessageDigest5;
  fs : TFileStream;
  hash : T4x4LongWordRecord;
begin
  if not fileexists(fileName) then exit;
  idmd5 := TIdHashMessageDigest5.Create;
  //fs := TFileStream.Create(fileName, fmOpenRead OR fmShareDenyWrite) ;
  fs := TFileStream.Create(fileName, fmOpenRead OR fmShareDenyNone) ;
  try
    //result := idmd5.AsHex(idmd5.HashValue(fs)) ;
    result := idmd5.HashStreamAsHex(fs);
  finally
    fs.Free;
    idmd5.Free;
  end;
end;

function RunAsAdminAndWaitForCompletion(hWnd: HWND; filename: string; Parameters: string): Boolean;
var
  sei: TShellExecuteInfo;
  ExitCode: DWORD;
begin
  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(TShellExecuteInfo);
  sei.Wnd := hwnd;
  sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
  sei.lpVerb := PChar('runas');
  sei.lpFile := PChar(Filename); // PAnsiChar;
  if parameters <> '' then
      sei.lpParameters := PChar(parameters); // PAnsiChar;
  sei.nShow := SW_SHOWNORMAL; //Integer;

  if ShellExecuteEx(@sei) then
  begin
    repeat
      Application.ProcessMessages;
      GetExitCodeProcess(sei.hProcess, ExitCode) ;
    until (ExitCode <> STILL_ACTIVE) or  Application.Terminated;
  end;
end;

procedure ExecuteAndWait(const aCommando: string);
var
  tmpStartupInfo: TStartupInfo;
  tmpProcessInformation: TProcessInformation;
  tmpProgram: String;
begin
  tmpProgram := trim(aCommando);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  if CreateProcess(nil, pchar(tmpProgram), nil, nil, true, CREATE_NO_WINDOW,
    nil, nil, tmpStartupInfo, tmpProcessInformation) then
  begin
    // loop every 10 ms
    while WaitForSingleObject(tmpProcessInformation.hProcess, 10) > 0 do
    begin
      Application.ProcessMessages;
    end;
    CloseHandle(tmpProcessInformation.hProcess);
    CloseHandle(tmpProcessInformation.hThread);
  end
  else
  begin
    RaiseLastOSError;
  end;
end;

function ReadRegistryValue(key: string; propertyToRead: string): string;
var
  RegistryEntry: TRegistry;
  RegistryString: string;
begin
  result := '';
  RegistryEntry := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  try
    RegistryEntry.RootKey := HKEY_LOCAL_MACHINE;
    if RegistryEntry.KeyExists(key) then
    begin
      RegistryEntry.Access := KEY_READ or KEY_WOW64_64KEY;
      if RegistryEntry.OpenKey(key, false) then
      begin
        result := RegistryEntry.ReadString(propertyToRead);
      end;
    end;
//    if (not RegistryEntry.KeyExists(key)) then
//    begin
//      RegistryEntry.Access := KEY_WRITE or KEY_WOW64_64KEY;
//      if RegistryEntry.OpenKey(C_KEY, true) then
//        RegistryEntry.WriteString('', 'MyFirstProject');
//    end
//    else
//    begin
//      RegistryEntry.Access := KEY_READ or KEY_WOW64_64KEY;
//      if RegistryEntry.OpenKey(C_KEY, false) then
//      begin
//        Memo01.Lines.Add(RegistryEntry.ReadString(''));
//      end;
//    end;
    RegistryEntry.CloseKey();
  finally
    RegistryEntry.Free;
  end;
end;

{
 VERY fast split function
 this function returns part of a string based on
 constant defineable delimiters, such as ";". So
 SPLIT('this is a test ',' ',3) = 'is' or
 SPLIT('data;another;yet;again;more;',';',4) = 'yet'

 Split function shifts index integer by two to
 be compatible with commonly used PD split function
 gpl 2004 / Juhani Suhonen
}
function Split(input: string; schar: Char; s: Integer): string;
var
  c: array of Integer;
  b, t: Integer;
begin
  Dec(s, 2);  // for compatibility with very old & slow split function
  t := 0;     // variable T needs to be initialized...
  setlength(c, Length(input));
  for b := 0 to pred(High(c)) do
  begin
    c[b + 1] := posex(schar, input, succ(c[b]));
    // BREAK LOOP if posex looped (position before previous)
    // or wanted position reached..
    if (c[b + 1] < c[b]) or (s < t) then break
    else
      Inc(t);
  end;
  Result := Copy(input, succ(c[s]), pred(c[s + 1] - c[s]));
end;

 {Reads a value from the the registry key
  HKEY_LOCAL_MACHINE. It accepts the SubKey you want to open and
  the name of the value you want to know as input paramters. It
  returns the values data or ERROR if there was a problem.}
//function ReadRegEntry(strSubKey,strValueName: string): string;
//var
// Key: HKey;
// Buffer: array[0..255] of char;
// Size: cardinal;
//begin
// Result := 'ERROR';
// Size := SizeOf(Buffer);
// if RegOpenKeyEx(HKEY_LOCAL_MACHINE,
//    PChar(strSubKey), 0, KEY_READ, Key) = ERROR_SUCCESS then
//  if RegQueryValueEx(Key,PChar(strValueName),nil,nil,
//      @Buffer,@Size) = ERROR_SUCCESS then
//    Result := Buffer;
// RegCloseKey(Key);
//end;

function FormatByteSize(const bytes: Longint): string;
const
  B = 1; //byte
  KB = 1024 * B; //kilobyte
  MB = 1024 * KB; //megabyte
  GB = 1024 * MB; //gigabyte
begin
//  if bytes > GB then
//    result := FormatFloat('#.## GB', bytes / GB)
//  else
//    if bytes > MB then
//      result := FormatFloat('#.## MB', bytes / MB)
//    else
//      if bytes > KB then
//        result := FormatFloat('# KB', bytes / KB)
//      else
//        //result := FormatFloat('#.## bytes', bytes);
        result := FormatFloat('#,##0', bytes);
end;


end.
