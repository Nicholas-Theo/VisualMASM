unit uGroup;

interface

uses
  SysUtils, Classes, uVisualMASMFile, uSharedGlobals, uProject, System.Generics.Collections,
  uProjectFile, uTFile, uVisualMASMOptions;

type
  PGroup = ^TGroup;
  TGroup = class(TVisualMASMFile)
    private
      FProjects: TDictionary<string,TPRoject>;
      FActiveProject: TProject;
      FLastFileOpenId: string;
      procedure Initialize;
      function GetProjectById(Index: string): TProject;
      procedure SetProjectById(Index: string; const Value: TProject);
      function GetProjectCount: integer;
      procedure SetActiveProject(project: TProject);
      function CreateProject(name: string; projectType: TProjectType = ptWin32): TProject;
    public
      constructor Create; overload;
      constructor Create (Name: string); overload;
      property ProjectById[Index: string]: TProject read GetProjectById write SetProjectById; default;
      property ProjectCount: integer read GetProjectCount;
      property ActiveProject: TProject read FActiveProject write SetActiveProject;
      procedure DeleteProject(id: string);
      property LastFileOpenId: string read FLastFileOpenId write FLastFileOpenId;
      property Projects: TDictionary<string,TPRoject> read FProjects;
    published
      procedure AddProject(project: TProject);
      procedure CreateNewProject(projectType: TProjectType; options: TVisualMASMOptions);
  end;

implementation

procedure TGroup.Initialize;
begin
  FProjects := TDictionary<string,TPRoject>.Create;
end;

constructor TGroup.Create;
begin
  inherited Create;
  Initialize;
end;

constructor TGroup.Create(name: string);
begin
  inherited Create(name);
  Initialize;
end;

function TGroup.GetProjectById(Index: string): TProject;
begin
  if Index = '' then exit;
  result := FProjects[Index];
end;

procedure TGroup.SetProjectById(Index: string; const Value: TProject);
begin
  FProjects[Index] := Value;
  self.Modified := true;
end;

function TGroup.GetProjectCount: integer;
begin
  result:=FProjects.Count;
end;

procedure TGroup.AddProject(project: TProject);
begin
  if project = nil then exit;
  if FProjects.ContainsKey(project.Id) then
    SetProjectById(project.Id, project)
  else
    FProjects.Add(project.Id, project);
  self.Modified := true;
end;

procedure TGroup.DeleteProject(id: string);
begin
  FProjects.Remove(id);
  self.Modified := true;
end;

procedure TGroup.SetActiveProject(project: TProject);
begin
  FActiveProject := project;
  self.Modified := true;
end;

procedure TGroup.CreateNewProject(projectType: TProjectType; options: TVisualMASMOptions);
var
  project: TProject;
  projectFile: TProjectFile;
begin
  case projectType of
    ptWin32:
      begin
        project := CreateProject('Win32App.exe',projectType);
        projectFile := project.CreateProjectFile(DEFAULT_FILE_NAME, options);
      end;
    ptWin64:
      begin
        project := CreateProject('Win64App.exe',projectType);
        projectFile := project.CreateProjectFile(DEFAULT_FILE_NAME, options);
      end;
    ptDos16COM:
      begin
        project := CreateProject('Program.com',projectType);
        projectFile := project.CreateProjectFile(DEFAULT_FILE_NAME, options);
      end;
    ptDos16EXE:
      begin
        project := CreateProject('Program.exe',projectType);
        projectFile := project.CreateProjectFile(DEFAULT_FILE_NAME, options);
      end;
  end;

  AddProject(project);
  SetActiveProject(project);

//  CreateMemo(projectFile);
//  UpdateProjectExplorer(true);
//  HighlightNodeBasedOnActiveTab;
end;

function TGroup.CreateProject(name: string; projectType: TProjectType = ptWin32): TProject;
var
  project: TProject;
begin
  project := TProject.Create;
  project.Name := name;
  project.ProjectType := projectType;
  project.Modified := true;

  // Do not give it a filename because we want the user to enter a new
  // filename via Save As... prompt.
  //project.FileName := AppFolder+project.Name;

  result := project;
end;


end.
