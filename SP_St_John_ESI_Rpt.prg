drop program sp_out_unaliased_daily_rpt go
create program sp_out_unaliased_daily_rpt
 
/*****************
  Script will check the OEN_TXLOG table for all outbound messages for the prior
  day to check for CD:<num>. If found will keep a running total for the day. At
  the end of the report will send an email to select individuals for the CD: values
  found, what interfaces had the issue, and what code set's the values belonged to.
  Will be broken out by interface
 
  Question - how will report be created. Initial feelings report should be done for each
  outbound interface for the prior day. Will i need to break that down in PROD? Meaning
  will volume be too much on a busy interface to get all tx keys or ...?
 
  At this time query OEN_PROCINFO joining to OEN_PERSONALITY where OPI.service = OUTBOUND and
  OP.PACKESO > 0  this is not the best way, but should do for now
 *****************/

/**************
  TODO - issue with email. being sent for each oen msg and needs to only be sent once
for each interface. 
Made a change to correct, need to confirm.
Need to give total count of messages check
need to give total count of unaliased values by codeset/code value
need to give date/time that report was run against
possible need to break txlog query apart by time frame of every 6 hours
***************/
 
;;;; %i /cerner/d_m22/ccluserdir/sp_out_unaliased_daily_rpt.prg go
;;;; sp_out_unaliased_daily_rpt go
 
Free Record Out_Interfaces
Record Out_Interfaces
 (
   1 OI[*]
     2 Proc_Name = VC
     2 Proc_Desc = VC
     2 InterfaceID = F8
     2 SCP_ID      = F8
     2 PackESO     = F8
 )  ;; End
 
Free Record Msg_Key
Record Msg_Key
 (
   1 MK[*]
     2 TX_Key = VC
 )  ;; End
 
Free Record Query_Date
Record Query_Date
 (
   1 QD[*]
     2 Begin_Key = VC
     2 End_Key   = VC
 ) ;; End
 
Free Record Msg_CD
Record Msg_CD
 (
   1 MC[*]
     2 CD_Value = F8
 )
 
Free Record Not_Aliased
Record Not_Aliased
 (
   1 NA[*]
     2 CodeSet = F8
     2 CodeSetDisplay = VC
     2 CV[*]
       3 CodeValue = F8
       3 CodeValueDisplay = VC
 )  ;; End
 
Free Record Hold_Code
Record Hold_Code
 (
   1 HC[*]
     2 CodeSet   = F8
     2 CodeSetDisplay = VC
     2 CodeValue = F8
 )  ;; End
 
Free Record Email_List
Record Email_List
 (
    1 EL[*]
       2 To_Address = VC
 )
Declare Add_To_Email_List(emailToAdd) = I2
 
;; This is to query the oen_txlog table
Declare BASE_QUERY_DATE = VC With Public,
  Constant(Format((CURDATE - 1), "MM/DD/YYYY;;D"))
Declare BASE_QUERY_START_TIME = VC With Public,
  Constant("00:00:01")
Declare BASE_QUERY_END_TIME = VC With Public,
  Constant("23:59:59")
Declare Populate_Query_Date(procID) = I2
Declare Get_Msg_Keys(junk)      = I2
Declare Get_Txlog_Msg(keyIndex) = VC
 
;;;; Email variables and funcs
Declare LINE_FEED = C2 With Public,
  Constant(ConCat(Char(13), Char(10)))
Declare MyEnv = VC With Public,
  Constant(CnvtLower(Logical("ENVIRONMENT")))
Declare EmailDate = VC With Public,
  Constant(Format(CnvtDateTime(CURDATE, CURTIME3), "MM/DD/YYYY HH:MM:SS;;D"))
Declare DEFAULT_TO_EMAIL_ADDRESS = VC With Public,
  Constant("agagnon@spconinc.com");;;"Bryan.McKay@sjmc.org")
Declare FromEmailAddress = VC With Public,
  Constant(ConCat("daily_rpt_no_alias_", Trim(MyEnv), "@stjohn.org"))
Declare Build_Email_Msg(procID, procName)  = I2
Declare Send_Email_Msg(toEmail, msgToSend) = I2
 
;;;; Misc funcs to run program
Declare Get_Out_Interface(junk) = I2  ;; will get the list of outbound interfaces 4 msgs to check
 
;;;; parsing routines n variables
Declare NOT_ALIASED_VALUE = VC With Public,
  Constant("CD:")
Declare Parse_CD_Values(msg) = I2  ;; will parse the message apart to get to the CD:<num>
Declare Add_MSG_CD(cdValue)  = I2
 
;;;; capturing the data for the report
Declare Load_Not_Aliased(junk)   = I2  ;; load the not aliased rec struc with unique values
Declare Insert_Not_Aliased(junk) = I2 ;; Will find a match or insert at proper location
Declare Insert_Not_Aliased_NA(codeSetCD, 
       codeSetName, insertPos)   = I2  ;; will perform actual insert 
Declare Insert_Not_Aliased_CV(codeValueCD, csIndex,
                      insertPos) = I2  ;; into the struc at the given loc
Declare Clear_Not_Aliased(codeSetCD, 
          codeSetName, codeValue) = I2  ;; purge the not aliased rec struc
Declare Load_Code_Hold(codeValue) = I2  ;; will query the code value and code value set table
 
Declare log_msg(msg1, msg2) = I2
 
;;set stat = log_msg("Get out", "interface") 
Set stat = Get_Out_Interfaces(0)
;;set stat = log_msg("Back from", "out interfaces")
 
;;go to EXIT_SP_OUT_UNALIASED_DAILY_RPT
;; Loop over the outbound interfaces
For (oiCtr = 1 To Size(Out_Interfaces->OI, 5))
  Set stat = Populate_Query_Date(Out_Interfaces->OI[oiCtr]->InterfaceID)
  Set stat = Get_Msg_Keys(0)

  ;;;; loop over the messages for the individual proc id/interface
  For (keyCtr = 1 To Size(Msg_Key->MK, 5))
    Declare TXMsg = VC
    Set TXMsg = Get_Txlog_Msg(keyCtr)    

    If (Parse_CD_Values(TXMsg) > 0)
      Set stat = Load_Not_Aliased(0)      
      ;; send email to interested parties
      ;; do i want to break this out by contributor source or by interface?
    EndIf
    if (keyCtr > 5)
      set keyctr = (Size(Msg_Key->MK, 5) + 1)
    endif
  EndFor  ;; endthe keyCtr FOR
  Set stat = Build_Email_Msg(Out_Interfaces->OI[oiCtr]->InterfaceID,
                  Out_Interfaces->OI[oiCtr]->Proc_Name)
  ;;if (oiCtr > 5)
    ;;set oictr = (size(out_interfaces->oi, 5) + 1)
  ;;endif
EndFor  ;; End the oiCtr FOR
 
#EXIT_SP_OUT_UNALIASED_DAILY_RPT 
;;;; Subs below
 
subroutine log_msg(msg1, msg2)
  call echo(build(msg1, "-and-", msg2, char(0)))
  return (1)
end
 
;;;; ====================
 
Subroutine Load_Not_Aliased(junk)
  Set stat = Clear_Not_Aliased(0)
  For (mcCtr = 1 To Size(Msg_CD->MC, 5))
    If (Load_Code_Hold(Msg_CD->MC[mcCtr]->CD_Value) > 0)
      Set stat = Insert_Not_Aliased(Hold_Code->HC[1]->CodeSet,
           Hold_Code->HC[1]->CodeSetDisplay, Hold_Code->HC[1]->CodeValue)
    EndIf
  EndFor
End ;; ENd
 
;;;; =======

Subroutine Insert_Not_Aliased(codeSetCD, codeSetName, codeValue)
  Declare csPos = I2
  Declare cvPos = I2
  Set cvPos = 0
  Set csPos = 0
  For (naCtr = 1 To Size(Not_Aliased->NA, 5))
    If (Not_Aliased->NA[naCtr]->CodeSet >= codeSetCD)
      Set csPos = naCtr
      Set naCtr = (Size(Not_Aliased->NA, 5) + 1)
    EndIf
  EndFor
  Set csPos = Insert_Not_Aliased_NA(codeSetCD, codeSetName, csPos)
  For (cvCtr = 1 To Size(Not_Aliased->NA[csPos]->CV, 5))
    If (Not_Aliased->NA[csPos]->CV[cvCtr]->CodeValue >= codeValue)
      Set cvPos = cvCtr
      Set cvCtr = (Size(Not_Aliased->NA[csPos]->CV, 5) + 1)
    EndIf
  EndFor
  Set cvPos = Insert_Not_Aliased_CV(codeValue, csPos, cvPos)
  /***
  for (naCtr=1 to size(not_aliased->na,5))
    set stat = log_msg("COde set:", not_aliased->NA[nactr]->CodeSetDisplay)
    for (cvCtr = 1 to size(not_aliased->NA[nactr]->CV, 5))
      set stat = log_msg("Code Value:", 
          uar_get_code_display(not_aliased->NA[nactr]->CV[cvctr]->CodeValue))
    endfor
  endfor
  ****/
  return (Size(Not_Aliased->NA, 5))
End ;; End

;;;; ========

Subroutine Insert_Not_Aliased_NA(codeSetCD, codeSetName, insertPos)
  Declare tmpCSCtr = I2  
  Set tmpCSCtr     = insertPos
  If (insertPos = 0)
    Set tmpCSCtr = (Size(Not_Aliased->NA, 5) + 1)
    Set stat = AlterList(Not_Aliased->NA, tmpCSCtr)
  Else
    Set stat = AlterList(Not_Aliased->NA, 
        (Size(Not_Aliased->NA, 5) + 1), (tmpCSCtr - 1))
  EndIf
  Set Not_Aliased->NA[tmpCSCtr]->CodeSet = codeSetCD
  Set Not_Aliased->NA[tmpCSCtr]->CodeSetDisplay = codeSetName
  return (tmpCSCtr)
End  ;; End

;; =======

Subroutine Insert_Not_Aliased_CV(codeValueCD, csIndex, insertPos)
  Declare tmpCVCtr = i2
  Set tmpCVCtr = insertPos
  If (insertPos = 0)
    Set tmpCVCtr = (Size(Not_Aliased->NA[csIndex]->CV, 5) + 1)
    Set stat = AlterList(Not_Aliased->NA[csIndex]->CV, tmpCVCtr)
  Else
    Set stat = AlterList(Not_Aliased->NA[csIndex]->CV,
         (Size(Not_Aliased->NA[csIndex]->CV, 5) + 1), (tmpCVCtr - 1))
  EndIf
  Set Not_Aliased->NA[csIndex]->CV[tmpCVCtr]->CodeValue = codeValueCD
  Set Not_Aliased->NA[csIndex]->CV[tmpCVCtr]->CodeValueDisplay =
            UAR_Get_Code_Display(codeValueCD)
  return (Size(Not_Aliased->NA[csIndex]->CV, 5))
End  ;; End

;;;; =======
 
Subroutine Load_Code_Hold(codeValue)
  Set stat = AlterList(Hold_Code->HC, 0)
  Select Into "nl:"
    cv.code_set,
    cvs.display
  From code_value cv,
       code_value_set cvs
  Plan cv
    Where cv.code_value = codeValue
   Join cvs
    Where cvs.code_set = cv.code_set
  Detail
    stat = AlterList(Hold_Code->HC, 1)
    Hold_Code->HC[1]->CodeSet = cv.code_set
    Hold_Code->HC[1]->CodeSetDisplay = cvs.display
    Hold_Code->HC[1]->CodeValue      = codeValue
  With MaxRec = 1
  return (Size(Hold_Code->HC, 5))
End   ;; end
 
;;;; =======
 
Subroutine Clear_Not_Aliased(junk)
  For (naCtr = 1 TO Size(Not_Aliased->NA, 5))
    Set stat = AlterList(Not_Aliased->NA[naCtr]->CV, 0)
  EndFor
  Set stat = AlterList(Not_Aliased->NA, 0)
  return (0)
End ;; End
 
;;;; ====================

Subroutine Build_Email_Msg(procID, procName)
  Set stat = Add_To_Email_List(DEFAULT_TO_EMAIL_ADDRESS)
  Declare MyMsg = VC
  Set MyMsg = ConCat(
     "PROC ID:", CnvtString(procID), LINE_FEED,
     "NAME:", procName)
  For (naCtr = 1 To Size(Not_Aliased->NA,5))
    Set MyMsg = ConCat(Trim(MyMsg), LINE_FEED,
        "     ", "CODE SET:",
            Trim(CnvtString(Not_Aliased->NA[naCtr]->CodeSet)), LINE_FEED,
        "     ", "CODE SET DISPLAY:", 
            Trim(Not_Aliased->NA[naCtr]->CodeSetDisplay))
    For (cvCtr = 1 To Size(Not_Aliased->NA[naCtr]->CV, 5))
      Set MyMsg = ConCat(Trim(MyMsg), LINE_FEED,
        "           ", "CODE VALUE:", 
             Trim(CnvtString(Not_Aliased->NA[naCtr]->CV[cvCtr]->CodeValue)), LINE_FEED,
        "           ", "CODE VALUE DISPLAY:",
             Trim(UAR_Get_Code_Display(Not_Aliased->NA[naCtr]->CV[cvCtr]->CodeValue)))
    EndFor
  EndFor
  For (eaCtr = 1 To Size(Email_List->EL, 5))
    Set stat = Send_Email_Msg(Email_List->EL[eaCtr]->To_Address,
                  MyMsg)
  EndFor
  return (1)
End ;; End

;;;; ====================
 
Subroutine Send_Email_Msg(toEmail, msgToSend)
  Set stat = UAR_Send_Mail(
                          NullTerm(toEmail),
                          NullTerm(ConCat(Trim(MyEnv), " - ESI Log daily rpt: ",
                                      Trim(EmailDate))),
                          NullTerm(msgToSend),
                          NullTerm(FromEmailAddress),
                          5,
                          NullTerm("IPM.NOTE"))
  return (1)
End ;; Ed
 
;;;; =========================
 
Subroutine Populate_Query_Date(procID)
  Set stat = AlterList(Query_Date->QD, 0)
  Set stat = AlterList(Query_Date->QD, 1)
  Declare Beg_Date = VC
  Declare End_Date = VC
  Declare Beg_Time = VC
  Declare End_Time = VC
  Declare SDString = VC
  Declare EDString = VC
  Set Beg_Date  = BASE_QUERY_DATE
  Set End_Date  = BASE_QUERY_DATE
  Set Beg_Time  = BASE_QUERY_START_TIME
  Set End_Time  = BASE_QUERY_END_TIME
 
  SET SDSTRING  =  CNVTSTRING(CNVTDATE2(Beg_Date, "MM/DD/YYYY"), 5, 0, R)
  SET EDSTRING  =  CNVTSTRING(CNVTDATE2(End_Date, "MM/DD/YYYY"), 5, 0, R)
  SET TTIME  =  CONCAT(SUBSTRING(1, 2, BEG_TIME), SUBSTRING(4, 2, BEG_TIME))
  SET TITIME = (CNVTMIN(CNVTINT(TTIME)) * 60 +
                   CNVTINT(SUBSTRING(7, 2, BEG_TIME))) * 100
 
  SET STSTRING = CNVTSTRING(TITIME, 7, 0, R)
  SET TTIME    = CONCAT(SUBSTRING(1, 2, END_TIME), SUBSTRING(4, 2, END_TIME))
  SET TITIME   = (CNVTMIN(CNVTINT(TTIME)) * 60 +
                  CNVTINT(SUBSTRING(7, 2,  END_TIME ))) * 100
  SET ETSTRING = CNVTSTRING(TITIME, 7, 0, R)
 
  Set Query_Date->QD[1]->Begin_Key =
            CONCAT(" ", CNVTSTRING(procid, 4, 0, R), SDSTRING, STSTRING, "*")
  Set Query_Date->QD[1]->End_Key =
            CONCAT(" ", CNVTSTRING(procid, 4, 0, R), EDSTRING, ETSTRING, "*")
  return (Size(Query_Date->QD, 5))
End ;; End
 
;;;; =========================
 
Subroutine Get_Out_Interfaces(junk)
  Declare tmpOICtr = I2
  Select Into "nl:"
    opi.proc_name,
    opi.proc_desc,
    opi.service,
    opi.interfaceid,
    opi.scp_eid,
    op.value
  From oen_procinfo opi,
       oen_personality op
  Plan opi
    Where opi.service = "Outbound"
          and opi.interfaceid = 1026
   Join op
    Where op.interfaceid = opi.interfaceid AND
          op.name = "PACKESO" AND
          op.value != "0"
  Detail
    tmpOICtr = (Size(Out_Interfaces->OI, 5) + 1)
    stat     = AlterList(Out_Interfaces->OI, tmpOICtr)
    Out_Interfaces->OI[tmpOICtr]->InterfaceID = opi.interfaceid
    Out_Interfaces->OI[tmpOICtr]->SCP_ID      = opi.scp_eid
    Out_Interfaces->OI[tmpOICtr]->Proc_Name   = opi.proc_name
    Out_Interfaces->OI[tmpOICtr]->Proc_Desc   = opi.proc_desc
    Out_Interfaces->OI[tmpOICtr]->PackESO     = CnvtReal(op.value)
  With NoCounter,Time=90
  return (Size(Out_Interfaces->OI, 5))
End ;; End
 
;;;; ======================
 
Subroutine Get_Msg_Keys(junk)
  Set stat = AlterList(Msg_Key->MK, 0)
  Declare tmpMKCtr = I4
  Select Into "nl:"
    ot.tx_key
  From oen_txlog ot
  Plan ot
    Where ot.tx_key >= Query_Date->QD[1]->Begin_Key AND
          ot.tx_key <= Query_Date->QD[1]->End_Key
  Detail
    tmpMKCtr = (Size(Msg_Key->MK, 5) + 1)
    stat     = AlterList(Msg_Key->MK, tmpMKCtr)
    Msg_Key->MK[tmpMKCtr]->TX_Key = ot.tx_key
  With NoCounter,time=120
  return (Size(Msg_Key->MK, 5))
End  ;; End
 
;;;; ======================
 
Subroutine Get_Txlog_Msg(keyIndex)
  Declare tmpMsg = VC
  Select Into "nl:"
    ot.msg_text
  From oen_txlog ot
  Where ot.tx_key = Msg_Key->MK[keyIndex]->TX_Key
  Detail
    tmpMsg = ConCat(Trim(ot.msg_text))
  With MaxRec = 1
  return (tmpMsg)
End ;; End
 
;;;; ======================
 
Subroutine Parse_CD_Values(msg)
  Set stat = AlterList(Msg_CD->MC, 0)
  declare myctr = i2 with public, noconstant(0)
  Declare startPos  = I2
  Declare startLoop = I2
  Declare endPos    = I2
  Declare sinChar   = C1
  ;;;set stat = log_msg("Msg:", msg)
  Set startPos = FindString(NOT_ALIASED_VALUE, msg)
  While (startPos > 0)
    Set startLoop = (startPos + Size(NOT_ALIASED_VALUE, 1))
    Set endPos    = (Size(msg, 1) - startLoop)
    For (ctr = startLoop To Size(msg, 1))
      Set sinChar = SubString(ctr, 1, msg)
      If (IsNumeric(sinChar) = FALSE)
        ;;;Set ctr    = (ctr - 1)  ;; move it back to the last number
        Set endPos = (ctr - startLoop)
        Set ctr = (Size(msg, 1) + startLoop)
      EndIf
    EndFor
    Set startLoop    = (startPos + Size(NOT_ALIASED_VALUE, 1))
    Declare tmpValue = VC
    Set tmpValue     = SubString(startLoop, endPos, msg)
    Set stat = Add_MSG_CD(tmpValue)
    Set startPos = FindString(NOT_ALIASED_VALUE, msg, startLoop)
    Set myctr = myctr + 1
    
  EndWhile
  return (Size(Msg_CD->MC, 5))
End ;; End
 
;;;; ======================
 
Subroutine Add_MSG_CD(cdValue)
  Declare tmpMCCtr = I2
  Set tmpMCCtr = (Size(Msg_CD->MC, 5) + 1)
  Set stat     = AlterList(Msg_CD->MC, tmpMCCtr)
  Set Msg_CD->MC[tmpMCCtr]->CD_Value = CnvtReal(cdValue)
  return (Size(Msg_CD->MC, 5))
End

;;;; ===================

Subroutine Add_To_Email_List(emailToAdd)
  Declare tmpELCtr = I2
  Set tmpELCtr = (Size(Email_List->EL, 5) + 1)
  Set stat = AlterList(Email_List->EL, tmpELCtr)
  Set Email_List->EL[tmpELCtr]->To_Address = emailToAdd
  return (Size(Email_List->EL, 5))
End ;; End

 
;;;; END  =================
 
end
go
 