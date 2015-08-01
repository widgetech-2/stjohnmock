drop program sp_st_john_esi_rpt:group1 go
create program sp_st_john_esi_rpt:group1
 
;;;; %i /cerner/d_m22/ccluserdir/sp_st_john_esi_rpt.prg go
;;;; sp_st_john_esi_rpt go
 
If (Validate(reply->status_data->data, "Z") = "Z")
  RECORD  REPLY
  (
    1  STATUS_DATA
     2  STATUS  =  C1
     2  SUBEVENTSTATUS [ 1 ]
       3  OPERATIONNAME     =  C8
       3  OPERATIONSTATUS   =  C1
       3  TARGETOBJECTNAME  =  C15
       3  TARGETOBJECTVALUE =  C100
  )  ;; End
EndIf
 
Set Script_Status = "F"
 
Free Record Last_Run_Rpt
Record Last_Run_Rpt
 (
   1 LRR[*]
     2 Line = VC
     2 Is_Running = C1
     2 Last_ESI_Log_ID = F8
 )  ;; End
 
Free Record ESI_Log
Record ESI_Log
 (
   1 EL[*]
     2 ESI_Log_ID = F8
     2 ESI_Create_Dt_Tm = VC
     2 Person_ID = F8
     2 Encntr_ID = F8
     2 ESI_Error_Stat = VC
     2 ESI_Error_Text = VC
     2 ESI_Msg_Type   = VC
     2 ESI_Order_Ctrl = VC
     2 ESI_Entity_Code = VC
     2 ESI_Tx_Key      = VC
 )  ;; End
 
Free Record Query_Filter
Record Query_Filter
 (
   1 QF[2]
     2 Filter = VC
 )  ;; End
 
;; common errors and the causes/fixes
Free Record Common_Errors
Record Common_Errors
 (
   1 CE[*]
     2 Error_String = VC
     2 Possible_Cause = VC
 )  ;; End
 
Free Record Email_List
Record Email_List
 (
    1 EL[*]
       2 To_Address = VC
 )
Declare Add_To_Email_List(emailToAdd) = I2
 
Declare REPLACE_HOLD_VALUE = VC With Public,
  Constant("##_REPLACE_##")
Declare RUN_FIRST_INDEX = I2 With Public,
  Constant(1)
Declare RUN_AFTER_FIRST_INDEX = I2 With Public,
  Constant(2)
Set Query_Filter->QF[RUN_FIRST_INDEX]->Filter =
  ConCat("esi.create_dt_tm Between",                        ;; 25000 is approx 5 minutes
       " CnvtDateTime((CURDATE), (CURTIME3 - 75000)) AND",  ;; this should be 15 minutes back
       " CnvtDateTime(CURDATE, CURTIME3)"
       )  ;; End
Set Query_Filter->QF[RUN_AFTER_FIRST_INDEX]->Filter =
  ConCat("esi.esi_log_id > ", Trim(REPLACE_HOLD_VALUE))
 
;;;; File information variables
Declare MyEnv = VC With Public,
  Constant(CnvtLower(Logical("ENVIRONMENT")))
Declare LAST_RUN_ESI_LOG_TABLE = VC With Public,
  Constant(ConCat(Trim("sp_log_rpt_"),
                  Trim(MyEnv)
                  ))
Declare TBL_FIELD_SEP = C1 With Public,
  Constant("|")
Declare Set_Dir = VC With Public,
   Constant(ConCat("/cerner/d_",
              Trim(MyEnv), "/ccluserdir/"))
Set Logical N Value(Set_Dir)
 
;;;; Email information
Declare FromDefaultEmail = VC With Public,
  Constant(ConCat("esi_fail_", trim(MyEnv), "@stjohn.org"))
Declare DEFAULT_TO_EMAIL_ADDRESS = VC With Public,
  Constant("agagnon@spconinc.com")
 
;;;; Script query information
Declare SCRIPT_RUN_YES = C1 With Public,
  Constant("Y")
Declare SCRIPT_RUN_NO  = C1 With Public,
  Constant("N")
Declare INITIAL_LAST_ESI_LOG_ID = F8 With Public,
  Constant(-1.0)
Declare Where_Filter_Index = I2 With Public,
  NoConstant(RUN_AFTER_FIRST_INDEX)
 
;;;; Logging
Declare LINE_FEED = C2 With Public,
  Constant(ConCat(Char(13), Char(10)))
Declare TAB = C1 With Public,
  Constant(Char(9))
Declare LogFile = VC With Public,
  Constant("alex_log");
 
/*************
  AG - Process flow
  Script will perform a look up on table/file to determine if a prior instance of
  the script is currently running (RUN = N(o)) and what the end point was for the last run.
  If script is currently running, exit
 
  If table/file not found means first time run of the script and end point is 5 minutes ago
 
  If script is NOT currently running, write table/file script is running (RUN = Y(es))
  Run query on ESI Log looking for failures,warnings looking back where ESI_LOG_ID > File.ESI_LOG_ID
  value found OR if first time run look back 5 minutes
 
 *************/
 
;; Will only be ran once to create and will then be commented out
Declare Create_ESI_Log_Rpt_Table(junk) = I2
 
;; Subroutine that will query the ESI Log table
Declare Run_ESI_Log_Rpt(whenRunIndex) = I2
 
;; Subroutines that will give starting and stopping points
Declare Get_Start_Point(junk) = I2
Declare Write_End_Point(lastESILogID, isRunning) = I2
 
;; Subroutine to send email
Declare Build_Email_Msg(esiIndex, tmpMRN, tmpFIN, tmpCtrl) = VC
Declare Send_Email_Notificaion(emailMsg, toEmailAddress) = I2
 
;;;; Logging
Declare Write_Log_Msg(descrip, msg) = I2
 
;;;; Misc
Declare Get_Parse(Seg, Pos, msg) = VC
Declare Get_In_Msg(txKey) = VC
 
;;;; Loading of common errors
Declare Load_Common_Errors(junk) = I2
Declare Add_Common_Errors(errStr, fixStr) = I2
Declare Find_Common_Error(esiError, defaultFix) = VC
 
/***********
  Get start point for esi query, where last query left off
  if file not found the default in data so query is ran for past 5 minutes
 ***********/
 
;;;Set stat = write_log_msg("get start point:", "begin")
Set stat = Get_Start_Point(0)
;;Set stat = write_log_msg("get start point:", "END")
;;go to EXIT_SP_ST_JOHN_ESI_RPT
 
If ((Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID = INITIAL_LAST_ESI_LOG_ID) AND
    (Last_Run_Rpt->LRR[1]->Is_Running = SCRIPT_RUN_NO))
  Set stat = Write_End_Point(INITIAL_LAST_ESI_LOG_ID, SCRIPT_RUN_YES)
  Set Where_Filter_Index = RUN_FIRST_INDEX
ElseIf (Last_Run_Rpt->LRR[1]->Is_Running = SCRIPT_RUN_YES)
  ;;;Set stat = Write_Log_Msg("Script is currently running", "LEAVE")
  Go To EXIT_SP_ST_JOHN_ESI_RPT
Else
  Set stat = Write_End_Point(Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID,
                  SCRIPT_RUN_YES)
  Set Query_Filter->QF[RUN_AFTER_FIRST_INDEX]->Filter =
         Replace(Query_Filter->QF[RUN_AFTER_FIRST_INDEX]->Filter,
                 REPLACE_HOLD_VALUE,
                 CnvtString(Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID)
                 )  ;; end the replace
EndIf
 
Set stat = Load_Common_Errors(0)
Set stat = Run_ESI_Log_Rpt(Where_Filter_Index)
 
;;;Set stat = Add_To_Email_List(DEFAULT_TO_EMAIL_ADDRESS)
Set stat = Add_To_Email_List("agagnon@spconinc.com")
 
For (esiCtr = 1 To Size(ESI_Log->EL, 5))
  Declare MsgToSend = VC
  Declare OrgMsg    = VC
  Declare MsgMRN    = VC
  Declare MsgFIN    = VC
  Declare MsgCtrl   = VC
  Set OrgMsg    = Get_In_Msg(ESI_Log->EL[esiCtr]->ESI_Tx_Key)
  Set MsgMRN    = Get_Parse("PID|", 2, OrgMsg)
  Set MsgFIN    = Get_Parse("PID|", 18, OrgMsg)
  Set MsgCtrl   = Get_Parse("MSH|", 9, OrgMsg)
  Set MsgToSend = Build_Email_Msg(esiCtr, MsgMRN, MsgFIN, MsgCtrl)
  set stat = write_log_msg("Here:", msgtosend)
  For (elCtr = 1 To Size(Email_List->EL, 5))
    Set stat = Send_Email_Notification(MsgToSend,
                Email_List->EL[elCtr]->To_Address)
  EndFor
EndFor
 
;;;; show the script has stopped and where to pick back up on
Set Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID =
      ESI_Log->EL[Size(ESI_Log->EL, 5)]->ESI_Log_ID
Set stat = Write_End_Point(Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID, SCRIPT_RUN_NO)
 
#EXIT_SP_ST_JOHN_ESI_RPT
Set stat = Write_Log_Msg("===============", "===============")
Set Script_Status = "S"  ;; show script ran successfully
 
;;;; Just in case, mostly for testing
if (Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID = INITIAL_LAST_ESI_LOG_ID)
  Set stat = Write_End_Point(INITIAL_LAST_ESI_LOG_ID, SCRIPT_RUN_NO)
endif
 
#EXIT_SP_ST_JOHN_ESI_RPT_ERROR
 
;;;; Subs below
 
Subroutine Send_Email_Notification(MyMsg, toEmailAddress)
  ;;;;call echo(build("send email: ", toEmailAddress, char(0)))
  Set stat = UAR_Send_Mail(
                          NullTerm(toEmailAddress),
                          NullTerm(ConCat(Trim(MyEnv), " - ESI Failure/Warning: ",
                                      Trim(Format(CnvtDateTime(CURDATE, CURTIME3), "MM/DD/YYYY HH:MM:SS;;D")))),
                          NullTerm(MyMsg),
                          NullTerm(FromDefaultEmail),
                          5,   ;; do not know what this is
                          NullTerm("IPM.NOTE")
                          )  ;; End the function
  return (1)
End ;; End
 
;;;; ================
 
Subroutine Build_Email_Msg(esiIndex, tmpMRN, tmpFIN, tmpCtrl)
  Declare tmpLine = VC
  Declare tmpFixStr = VC
 
  Set tmpFixStr =
     Find_Common_Error(ESI_Log->EL[esiIndex]->ESI_Error_Text, "UNKNOWN")
  Set tmpLine = ConCat(
    "Person ID:",
       Trim(CnvtString(ESI_Log->EL[esiIndex]->Person_ID)), LINE_FEED,
    "Encntr ID:",
       Trim(CnvtString(ESI_Log->EL[esiIndex]->Encntr_ID)), LINE_FEED,
    "ESI Create Dt:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Create_Dt_Tm), LINE_FEED,
    "Msg Ctrl:",
       Trim(tmpCtrl), LINE_FEED,
    "MRN:",
       Trim(tmpMRN), LINE_FEED,
    "FIN:",
       Trim(tmpFIN), LINE_FEED,
    "Msg Type:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Msg_Type), LINE_FEED,
    "Order Ctrl:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Order_Ctrl), LINE_FEED,
    "Order Code:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Entity_Code), LINE_FEED,
    "Error Status:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Error_Stat), LINE_FEED,
    "Error Text:",
       Trim(ESI_Log->EL[esiIndex]->ESI_Error_Text), LINE_FEED,
    TAB, "Possible fix:",
       Trim(tmpFixStr)
  )  ;; End the concat
  return (tmpLine)
End ;; End
 
;;;; ================
 
Subroutine Find_Common_Error(errError, defaultFix)
  Declare tmpFCDIndex = I2 With Public, NoConstant(0)
  Declare possibleFix = VC
  Set errError = CnvtUpper(errError)
 
  For (fcdCtr = 1 To Size(Common_Errors->CE, 5))
    ;;Set stat = Write_Log_Msg("ESI Error:", errError)
    ;;set stat = write_log_msg("Common err:", Common_Errors->CE[fcdCtr]->Error_String)
    If (FindString(Common_Errors->CE[fcdCtr]->Error_String,
           errError) > 0)
      ;;Set stat = write_log_msg("Found the string", "========")
      Set tmpFCDIndex = fcdCtr
      Set fcdCtr = (Size(Common_Errors->CE, 5) + 1)
    EndIf
  EndFor
 
  If (tmpFCDIndex > 0)
    Set possibleFix = Common_Errors->CE[tmpFCDIndex]->Possible_Cause
  Else
    Set possibleFix = defaultFix
  EndIf
 
  return (possibleFix)
End ;; End
 
;;;; ================
 
Subroutine Run_ESI_Log_Rpt(whenRunIndex)
  Declare elCtr = I2
  Declare SQ = VC
  Set SQ = ConCat(
    "Select Distinct Into ", '"', "nl:", '"',
       " esi.esi_log_id,esi.person_id,esi.encntr_id,esi.error_stat,esi.error_text,",
       " esi.msh_msg_type,esi.order_ctrl, esi.hl7_entity_code,esi.tx_key,esi.active_status_dt_tm",
    " From esi_log esi Plan esi ",
    " Where ", Trim(Query_Filter->QF[whenRunIndex]->Filter),
    " and esi.error_stat In(", '"', "ESI_STAT_FAILURE", '"', ",",
      '"', "ESI_STAT_WARNING", '"',
      ;;;",", '"', "ESI_STAT_SUCCESS", '"',
      ")",
    " Detail",
      " elCtr = (Size(ESI_Log->EL, 5) + 1)",
      " stat  = AlterList(ESI_Log->EL, elCtr)",
      " ESI_Log->EL[elCtr]->ESI_Log_ID = esi.esi_log_id",
      " ESI_Log->EL[elCtr]->ESI_Create_Dt_Tm = ",
          " Format(esi.active_status_dt_tm,", '"', "MM/DD/YYYY HH:MM:SS;;D", '"', ")",
      " ESI_Log->EL[elCtr]->Person_ID  = esi.person_id",
      " ESI_Log->EL[elCtr]->Encntr_ID  = esi.encntr_id",
      " ESI_Log->EL[elCtr]->ESI_Error_Stat = esi.error_stat",
      " ESI_Log->EL[elCtr]->ESI_Error_Text = esi.error_text",
      " ESI_Log->EL[elCtr]->ESI_Msg_Type   = esi.msh_msg_type",
      " ESI_Log->EL[elCtr]->ESI_Order_Ctrl = esi.order_ctrl",
      " ESI_Log->EL[elCtr]->ESI_Entity_Code = esi.hl7_entity_code",
      " ESI_Log->EL[elCtr]->ESI_Tx_Key      = esi.tx_key",
    " With MaxRec=5,Time=90 go"
    )  ;; end the contact
  Call Parser(SQ)
  Set stat = Write_Log_Msg("Run ESI Log Rpt: ", SQ)
  ;;Set stat = Write_Log_Msg("Size of ESI Log: ",
    ;;   CnvtString(Size(ESI_Log->EL, 5)))
  return (Size(ESI_Log->EL, 5))
End ;; End
 
;;;; ================
 
Subroutine Get_Start_Point(junk)
  Set stat = AlterList(Last_Run_Rpt->LRR, 0)
  Declare fileName = VC
  Set fileName = ConCat(
     Trim(Set_Dir),
     Trim(LAST_RUN_ESI_LOG_TABLE),
     Trim(".dat"))
  Set stat = Write_Log_msg("Last flie:", fileName)
  If (1=0)  ;;; below piece is not working, skip itFindFile(fileName) = TRUE)
    Set stat = Write_Log_Msg("File does exist:", "---")
    Free define rtl2
    Set Logical cclfilein Value(fileName)
    Select Into "nl:"
      fl.line
    From rtl2t fl
    Detail
      stat = AlterList(Last_Run_Rpt->LRR, 1)
      Last_Run_Rpt->LRR[1]->Line = fl.line
    With MaxRec = 1
  EndIf
  If (Size(Last_Run_Rpt->LRR, 5) = 0)
    Set stat = Write_Log_Msg("Line is empty", "-------")
    Set stat = AlterList(Last_Run_Rpt->LRR, 1)
    Set Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID =
            INITIAL_LAST_ESI_LOG_ID
    Set Last_Run_Rpt->LRR[1]->Is_Running =
            SCRIPT_RUN_NO
  Else
    Declare begPos = I2
    Declare tmpLine = Vc
    Set tmpLine = Last_Run_Rpt->LRR[1]->Line
    Set stat = Write_Log_msg("Line:", tmpLine)
    Set begPos = FindString(TBL_FIELD_SEP, tmpLine)
    If (begPos > 0)
      Set Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID =
         CnvtReal(SubString(1, (begPos - 1), tmpLine))
      Set Last_RUn_Rpt->LRR[1]->Is_Running =
         SubString((begPos + 1), 1, tmpLine)
    EndIf
  EndIf
  ;;Set stat = Write_Log_Msg("Last ID:",
    ;;;   CnvtString(Last_Run_Rpt->LRR[1]->Last_ESI_Log_ID))
  ;;Set stat = Write_Log_Msg("Is Running:",
    ;;;   Last_Run_Rpt->LRR[1]->Is_Running)
  return (Size(Last_Run_Rpt->LRR, 5))
End ;; End
 
;;;; ================
 
Subroutine Write_End_Point(lastESILogID, isRunning)
  Set stat = Write_Log_Msg("Write End Point", isRunning)
  Set stat = Write_Log_Msg("Write last esi", cnvtstring(lastESILogID))
  Select Into Value(ConCat("n:", Trim(LAST_RUN_ESI_LOG_TABLE)))
    ConCat(Trim(CnvtString(lastESILogID)), TBL_FIELD_SEP,
           Trim(isRunning)
          )  ;; End
  With NOFORMFEED,NOHEADING,NOCOUNTER,FORMAT=UNDEFINED
  return (1)
End  ;;; End
 
;;;; ================
 
Subroutine Write_Log_Msg(descrip, msg)
  return (1)
  call echo(build(char(0), char(0),descrip," - ", msg, char(0), char(0)))
  ;;;call echo(build("Write file:", logfile, char(0)))
  Select Into Value(ConCat("n:", Trim(logFile)))
    ConCat(Trim(descrip), ":", Trim(msg), LINE_FEED)
  With NOFORMFEED, NOHEADING, NOCOUNTER, APPEND, FORMAT=UNDEFINED
  return (1)
End ;; ed
 
;;;; ===================
 
Subroutine Get_In_Msg(txKey)
  Declare tmpMsg = VC
  Select Into "nl:"
    oe.msg_text
  From oen_txlog oe
  Where oe.tx_key = txKey
  Detail
    tmpMsg = ConCat(Trim(oe.msg_text))
  With MaxRec = 1
  return (tmpMsg)
End ;; End
 
;;;; ===================
 
Subroutine Get_Parse(Seg, Pos, msg)
  Declare foundSeg = I2
  Declare segCtr   = I2
  Declare FieldDelim = C1
  Declare SubDelim   = C1
  Set FieldDelim     = "|"
  Set SubDelim       "^"
  Free Set Value
  Set foundSeg = FindString(Seg, msg)
  If (foundSeg = 0)
    return (ConCat("No:", Trim(Seg, 3), " was found"))
  EndIf
  Set segCtr = 0
 
  While (segCtr < Pos)
    Set foundSeg = FindString(FieldDelim, msg, foundSeg)
    Set segCtr   = segCtr + 1  ;;;; Sure we found one, but keep moving
    Set foundSeg = foundSeg + 1  ;;;; Move it forward one to get past it
    If (segCtr >= Pos)
       Free Set begPos
       Set begPos   = foundSeg
       Set foundSeg = FindString(FieldDelim, msg, foundSeg)
       Set Value = SubString(begPos, (foundSeg - begPos), msg)
       Free Set foundSub
       Set foundSub = FindString(SubDelim, Value)
       If (foundSub > 0)
         Set Value = SubString(1, (foundSub - 1), Value)
       EndIf
    EndIf
  EndWhile
  Set foundSeg = FindString(Char(13), Value)
  If (foundSeg > 0)
    Set Value = SubString(1, (foundSeg - 1), Value)
  EndIf
  return (Value)
End ;; End
 
;;;; ===================
 
Subroutine Load_Common_Errors(junk)
  Set stat = Add_Common_Errors(
     "Error retrieving order catalog code value for alias:",
     "Value is probably not aliased on cs 200")  ;1
  Set stat = Add_Common_Errors(
     "Unable to retrieve activity_type_flag from order_catalog table for catalog_cd",
     "Value in OBR 4.1 is aliased, but catalog_cd/code_value is not active")  ;;2
  Set stat = Add_Common_Errors(
     "Unable to retrieve order_id from order_alias table for the alias_entity_alias_type_cd",
     "Value in ORC/OBR 2 or 3 was not found on the ORDER_ALIAS table")  ;; 3
  Set stat = Add_Common_Errors(
     "Order_id exists on order_alias table for alias",
     "Value in ORC/OBR 2 or 3 was found, but belongs to a different order")  ;;4
  Set stat = Add_Common_Errors(
     "Unable to retrieve action_type_cd for catalog_cd",
     "OBR 4.1 is not aliased inbound or value in ORC 1 is not aliased")  ;;5
  return (Size(Common_Errors->CE, 5))
End  ;; end
 
;;;; ============
 
Subroutine Add_Common_Errors(errStr, fixStr)
  Declare tmpCECtr = I2
  Set tmpCECtr = (Size(Common_Errors->CE, 5) + 1)
  Set stat     = AlterList(Common_Errors->CE, tmpCECtr)
  Set Common_Errors->CE[tmpCECtr]->Error_String =
       CnvtUpper(errStr)
  Set Common_Errors->CE[tmpCECtr]->Possible_Cause =
       CnvtUpper(fixStr)
  return (Size(Common_Errors->CE, 5))
End ;; End
 
;;;; ===================
 
Subroutine Add_To_Email_List(emailToAdd)
  Declare tmpELCtr = I2
  Set tmpELCtr = (Size(Email_List->EL, 5) + 1)
  Set stat = AlterList(Email_List->EL, tmpELCtr)
  Set Email_List->EL[tmpELCtr]->To_Address = emailToAdd
  return (Size(Email_List->EL, 5))
End ;; End
 
 
;;;; ======= END =======
 
end
go