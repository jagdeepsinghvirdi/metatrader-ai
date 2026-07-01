//+------------------------------------------------------------------+
//|                                                      compile.mq5 |
//|                                      Copyright 2026,JBlanked LLC |
//|                                         https://www.jblanked.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked LLC"
#property link      "https://www.jblanked.com"
#property version   "1.00"
#property strict

#import "shell32.dll"
int ShellExecuteW(int hWnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

#ifndef COMMON_FOLDER
#define COMMON_FOLDER TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\" + "Files" + "\\"
#endif

#ifndef META_EDITOR
#define META_EDITOR TerminalInfoString(TERMINAL_PATH) + "\\metaeditor64.exe"
#endif

#ifndef COMPILE
#define COMPILE(params) (ShellExecuteW(0, "open", META_EDITOR, params, "", 1))
#endif

#ifndef FCOPY
#define FCOPY(src, dest) (ShellExecuteW(0, "open", "cmd.exe", ("/C copy /Y \"" + src + "\" \"" + dest + "\""), NULL, 0) > 32)
#endif

//+------------------------------------------------------------------+
//| Compile an .mq5 expert advisor; provide path, returns log output |
//+------------------------------------------------------------------+
string compileMql5(string mq5_path)
{
   const int fileExtensionPosition = StringFind(mq5_path, ".mq5");
   if(fileExtensionPosition < 0) return "[Build Error]: Invalid file type. Expected `.mq5`";

   if(!FolderCreate(".compile", FILE_COMMON)) return "[Build Error]: Failed to create log folder";

   const int result = COMPILE("/compile:\"" + mq5_path + "\" /log");

   if(result < 32) return StringFormat("[Build Error]: ShellExecute failed, code (%d)", result);

   int slash = -1;
   for(int i = fileExtensionPosition; i >= 0; i--)
   {
      if(mq5_path[i] == 92)
      {
         slash = i;
         break;
      }
   }

   const string mq5FileName = StringSubstr(mq5_path, slash + 1);
   const string mq5RootPath = StringSubstr(mq5_path, 0, slash + 1);
   const string fileName = StringSubstr(mq5FileName, 0, StringFind(mq5FileName, ".mq5"));
   const string fileLogName = fileName + ".log";
   const string loggerPath = mq5RootPath + fileLogName;
   const string commonPath = COMMON_FOLDER + ".compile\\" + fileLogName;

   if(!FCOPY(loggerPath, commonPath))
   {
      return StringFormat("[Build Error]: Failed to copy log file to common folder: %s", commonPath);
   }

   bool logCopied = false;
   for(int i = 0; i < 50; i++)
   {
      Sleep(100);
      if(::FileIsExist(".compile\\" + fileLogName, FILE_COMMON))
      {
         logCopied = true;
         break;
      }
   }

   if(!logCopied) return StringFormat("[Build Error]: Log file not found: %s", commonPath);

   int handle = ::FileOpen(".compile\\" + fileLogName, FILE_READ | FILE_COMMON | FILE_TXT | FILE_ANSI);
   if (handle == INVALID_HANDLE) return StringFormat("[Build Error]: Error '%d', could not open file: %s", GetLastError(), commonPath);

   string content = "";
   while (!::FileIsEnding(handle))
      content += ::FileReadString(handle) + "\n";
   ::FileClose(handle);
   return StringLen(content) > 0 ? content : "[Build Error]: Log file is empty";
}