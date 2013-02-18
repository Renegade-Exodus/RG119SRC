{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

unit fstr;

interface

procedure read_in_fstrings;

implementation

uses
  common;

procedure read_in_fstrings;
var
  lang     : text;
  WhichNum : String;
  WhichStr : Longint;
  InString : String;
begin
  if not exist(general.datapath+'renegade.lng') then
     begin
          sysoplog('Bad or missing language file.  Obtain a new one from the distribution package.');
          writeln ('Bad or missing language file.  Obtain a new one from the distribution package.');
          halt;
     end;

     fillchar(fstring,sizeof(fstring),#0);

     assign(lang,general.datapath+'renegade.lng');
      reset(lang);
      while not eof(Lang) do begin

          readln(lang,InString);

          if InString[1] = '[' then begin


             WhichNum := Copy(InString,Pos('[',InString)+1,Pos(']',InString)-2);
             WhichStr := StrToInt(WhichNum);
             if Pos(']',InString) = Length(InString) then InString := ''
             else InString := Copy(InString,Pos(']',InString)+1,Length(InString));


             with fstring do begin
                  case WhichStr of
                       1: anonymous                               := InString;
                       2: note[1]                                 := InString;
                       3: note[2]                                 := InString;
                       4: lprompt                                 := InString;
                       5: echoc                                := InString[1];
                       6: yourpassword                            := InString;
                       7: yourphonenumber                         := InString;
                       8: engage                                  := InString;
                       9: endchat                                 := InString;
                      10: wait                                    := InString;
                      11: pause                                   := InString;
                      12: entermsg1                               := InString;
                      13: entermsg2                               := InString;
                      14: newscan1                                := InString;
                      15: newscan2                                := InString;
                      16: newuserpassword                         := InString;
                      17: automsgt                                := InString;
                      18: autom                                := InString[1];
                      19: shelldos1                               := InString;
                      20: readingemail                            := InString;
                      21: chatcall1                               := InString;
                      22: chatcall2                               := InString;
                      23: shuttleprompt                           := Instring;
                      24: namenotfound                            := Instring;
                      25: bulletinline                            := Instring;
                      26: protocolp                               := Instring;
                      27: listline                                := Instring;
                      28: newline                                 := Instring;
                      29: searchline                              := Instring;
                      30: findline1                               := Instring;
                      31: findline2                               := Instring;
                      32: downloadline                            := Instring;
                      33: uploadline                              := Instring;
                      34: viewline                                := Instring;
                      35: nofilecredits                           := Instring;
                      36: unbalance                               := Instring;
                      37: ilogon                                  := Instring;
                      38: gfnline1                                := Instring;
                      39: gfnline2                                := Instring;
                      40: batchadd                                := Instring;
                      41: addbatch                                := Instring;
                      42: readq                                   := Instring;
                      43: sysopprompt                             := Instring;
                      44: default                                 := Instring;
                      45: newscanall                              := Instring;
                      46: newscandone                             := Instring;
                      47: chatreason                              := Instring;
                      48: quote_line[1]                           := Instring;
                      49: quote_line[2]                           := Instring;
                      50: userdefques[1]                          := Instring;
                      51: userdefques[2]                          := Instring;
                      52: userdefques[3]                          := Instring;
                      53: userdefed[1]                            := Instring;
                      54: userdefed[2]                            := Instring;
                      55: userdefed[3]                            := Instring;
                      56: continue                                := Instring;
                      57: waitfortelnet                           := Instring;
                      58: stringtwo                               := Instring;
                      59: AskInvisibleLoginStr                    := Instring;
                      60: cantemail                               := Instring;
                      61: sendemail                               := Instring;
                      62: nodenotavail                            := Instring;
                      63: massemail                               := Instring;
                      64: massemailall                            := Instring;
                      65: nonetmail                               := Instring;
                      66: isnetmail                               := Instring;
                      67: nomailwaiting                           := Instring;
                      68: sorryreply                              := Instring;
                      69: FileNewScan                             := Instring;
                      70: ScanCharCheck                           := InString;
                      71: ShowBulletins                           := InString;
                      72: QuickLogon                              := InString;
                      73: LogonAsNew                              := InString;
                      74: MsgHeader                               := InString;
                      75: MsgAreaHeader                           := InString;
                      76: FileAreaHeader                          := InString;
                      77: EmailSenderHeader                       := InString;
                      78: VoteListTopicsHeader                    := InString;
                      79: votetopicresultheader                   := InString;
                      80: FileBoardNameHeader                     := InString;
                      81: syschathelp                             := InString;
                  end;{case}
             end;
          end;{if = [}
      end;{while}
      close(lang);
end;


end.
