drop program sp_upload_cs_100010:dba go
create program sp_upload_cs_100010:dba
 
;;;; %i /cerner/w_custom/m22_cust/code/script/sp_upload_cs_100010.prg go
;;;; sp_upload_cs_100010 go
 
Free Record Upload_Values
Record Upload_Values
 (
   1 UV[*]
     2 Code_Value = F8
     2 Alias = VC
 )  ;; End
 
Declare CODE_SET = F8 With Public,
  Constant(100010.0)
Declare UI_SOURCE_CONTRIBUTOR_SOURCE_CD = F8 With Public,
  Constant(3423294.0)
Declare SEND_CA_AS_ORU_CV = F8 With Public,
  Constant(3423294.0)
Declare SEND_CA_AS_ORU_CDF = VC With Public,
  Constant("CA_AS_ORU")
  
Declare Load_Upload_Values(junk) = I2
Declare Insert_Code_Value_Row(org_id) = I2
 
Declare tmpCtr = I2
Set tmpCtr = 0
 
Set stat = Load_Upload_Values(0)
For (ctr = 1 TO Size(Upload_Values->UV, 5))
  Set stat = Insert_Code_Value_Row(Upload_Values->UV[ctr]->Alias)
    Set tmpCtr = tmpCtr + 1
    ;;If (tmpCtr > 3)
      ;;Set ctr = (Size(Upload_Values->UV, 5) + 1)
    ;;EndIf  
EndFor
 
;;;; Subs below
 
Subroutine Insert_Code_Value_Row(tmpAlias)
  Insert Into code_value_alias cvo
  Set CVO.CODE_VALUE     = SEND_CA_AS_ORU_CV,
      CVO.contributor_source_cd = UI_SOURCE_CONTRIBUTOR_SOURCE_CD,
      CVO.CODE_SET       = CODE_SET,
      CVO.alias_type_meaning = SEND_CA_AS_ORU_CDF,
      CVO.alias          = tmpAlias,
      CVO.UPDT_DT_TM     = CNVTDATETIME ( CURDATE ,  CURTIME3 ),
      CVO.UPDT_ID        =  99999999.0,
      CVO.UPDT_APPLCTX   = 1.0,
      CVO.UPDT_CNT       = 0 ,
      CVO.UPDT_TASK      = 1
  WITH  MaxRec = 1
  IF (CURQUAL = 0)
    Call Echo(Build("Unable to insert code value", char(0)))
  else
    Call Echo(Build("Inserted code value: ", tmpAlias, char(0)))
  ENDIF
  return (curqual)
End ;; End
 
;;;; ===============
 
Subroutine Load_Upload_Values(junk)
  Set stat = Add_Upload_Value("5309")
  Set stat = Add_Upload_Value("5313")
  Set stat = Add_Upload_Value("5320")
  Set stat = Add_Upload_Value("5322")
  /***/
  Set stat = Add_Upload_Value("5324")
  Set stat = Add_Upload_Value("5326")
  Set stat = Add_Upload_Value("5342")
  Set stat = Add_Upload_Value("5355")
  Set stat = Add_Upload_Value("5359")
  Set stat = Add_Upload_Value("5394")
  Set stat = Add_Upload_Value("5395")
  Set stat = Add_Upload_Value("5396")
  Set stat = Add_Upload_Value("5401")
  Set stat = Add_Upload_Value("5424")
  Set stat = Add_Upload_Value("5427")
  Set stat = Add_Upload_Value("5439")
  Set stat = Add_Upload_Value("5441")
  Set stat = Add_Upload_Value("5467")
  Set stat = Add_Upload_Value("5490")
  Set stat = Add_Upload_Value("5491")
  Set stat = Add_Upload_Value("5492")
  Set stat = Add_Upload_Value("5493")
  Set stat = Add_Upload_Value("5501")
  Set stat = Add_Upload_Value("5502")
  Set stat = Add_Upload_Value("5515")
  Set stat = Add_Upload_Value("5517")
  Set stat = Add_Upload_Value("5518")
  Set stat = Add_Upload_Value("5519")
  Set stat = Add_Upload_Value("5520")
  Set stat = Add_Upload_Value("5521")
  Set stat = Add_Upload_Value("5538")
  Set stat = Add_Upload_Value("5568")
  Set stat = Add_Upload_Value("5575")
  Set stat = Add_Upload_Value("5589")
  Set stat = Add_Upload_Value("5596")
  Set stat = Add_Upload_Value("5604")
  Set stat = Add_Upload_Value("5617")
  Set stat = Add_Upload_Value("5619")
  Set stat = Add_Upload_Value("5636")
  Set stat = Add_Upload_Value("5641")
  Set stat = Add_Upload_Value("5650")
  Set stat = Add_Upload_Value("5665")
  Set stat = Add_Upload_Value("5744")
  Set stat = Add_Upload_Value("5759")
  Set stat = Add_Upload_Value("5788")
  Set stat = Add_Upload_Value("5808")
  Set stat = Add_Upload_Value("5809")
  Set stat = Add_Upload_Value("5834")
  Set stat = Add_Upload_Value("5841")
  Set stat = Add_Upload_Value("5848")
  Set stat = Add_Upload_Value("5867")
  Set stat = Add_Upload_Value("5876")
  Set stat = Add_Upload_Value("5879")
  Set stat = Add_Upload_Value("5887")
  Set stat = Add_Upload_Value("6003")
  Set stat = Add_Upload_Value("6017")
  Set stat = Add_Upload_Value("6032")
  Set stat = Add_Upload_Value("6094")
  Set stat = Add_Upload_Value("6095")
  Set stat = Add_Upload_Value("6097")
  Set stat = Add_Upload_Value("6106")
  Set stat = Add_Upload_Value("6108")
  Set stat = Add_Upload_Value("6109")
  Set stat = Add_Upload_Value("6165")
  Set stat = Add_Upload_Value("6193")
  Set stat = Add_Upload_Value("6202")
  Set stat = Add_Upload_Value("6208")
  Set stat = Add_Upload_Value("6209")
  Set stat = Add_Upload_Value("6212")
  Set stat = Add_Upload_Value("6240")
  Set stat = Add_Upload_Value("6247")
  Set stat = Add_Upload_Value("6250")
  Set stat = Add_Upload_Value("6259")
  Set stat = Add_Upload_Value("6266")
  Set stat = Add_Upload_Value("6299")
  Set stat = Add_Upload_Value("6300")
  Set stat = Add_Upload_Value("6301")
  Set stat = Add_Upload_Value("6310")
  Set stat = Add_Upload_Value("6322")
  Set stat = Add_Upload_Value("6340")
  Set stat = Add_Upload_Value("6345")
  Set stat = Add_Upload_Value("6375")
  Set stat = Add_Upload_Value("6389")
  Set stat = Add_Upload_Value("6397")
  Set stat = Add_Upload_Value("6400")
  Set stat = Add_Upload_Value("6401")
  Set stat = Add_Upload_Value("6402")
  Set stat = Add_Upload_Value("6403")
  Set stat = Add_Upload_Value("6445")
  Set stat = Add_Upload_Value("6504")
  Set stat = Add_Upload_Value("6512")
  Set stat = Add_Upload_Value("6513")
  Set stat = Add_Upload_Value("6523")
  Set stat = Add_Upload_Value("6544")
  Set stat = Add_Upload_Value("6555")
  Set stat = Add_Upload_Value("6559")
  Set stat = Add_Upload_Value("6560")
  Set stat = Add_Upload_Value("6566")
  Set stat = Add_Upload_Value("6580")
  Set stat = Add_Upload_Value("6585")
  Set stat = Add_Upload_Value("6624")
  Set stat = Add_Upload_Value("6657")
  Set stat = Add_Upload_Value("6662")
  Set stat = Add_Upload_Value("6666")
  Set stat = Add_Upload_Value("6736")
  Set stat = Add_Upload_Value("6763")
  Set stat = Add_Upload_Value("6775")
  Set stat = Add_Upload_Value("6777")
  Set stat = Add_Upload_Value("6780")
  Set stat = Add_Upload_Value("6804")
  Set stat = Add_Upload_Value("6807")
  Set stat = Add_Upload_Value("6808")
  Set stat = Add_Upload_Value("6819")
  Set stat = Add_Upload_Value("6831")
  Set stat = Add_Upload_Value("6832")
  Set stat = Add_Upload_Value("6833")
  Set stat = Add_Upload_Value("6834")
  Set stat = Add_Upload_Value("6835")
  Set stat = Add_Upload_Value("6838")
  Set stat = Add_Upload_Value("6839")
  Set stat = Add_Upload_Value("6840")
  Set stat = Add_Upload_Value("6841")
  Set stat = Add_Upload_Value("6842")
  Set stat = Add_Upload_Value("6843")
  Set stat = Add_Upload_Value("6851")
  Set stat = Add_Upload_Value("6859")
  Set stat = Add_Upload_Value("6873")
  Set stat = Add_Upload_Value("6877")
  Set stat = Add_Upload_Value("6879")
  Set stat = Add_Upload_Value("6881")
  Set stat = Add_Upload_Value("6883")
  Set stat = Add_Upload_Value("6888")
  Set stat = Add_Upload_Value("6892")
  Set stat = Add_Upload_Value("6894")
  Set stat = Add_Upload_Value("6902")
  Set stat = Add_Upload_Value("6931")
  Set stat = Add_Upload_Value("6932")
  Set stat = Add_Upload_Value("6954")
  Set stat = Add_Upload_Value("6962")
  Set stat = Add_Upload_Value("6971")
  Set stat = Add_Upload_Value("6989")
  Set stat = Add_Upload_Value("6994")
  Set stat = Add_Upload_Value("6996")
  Set stat = Add_Upload_Value("6997")
  Set stat = Add_Upload_Value("6998")
  Set stat = Add_Upload_Value("7018")
  Set stat = Add_Upload_Value("7019")
  Set stat = Add_Upload_Value("7037")
  Set stat = Add_Upload_Value("7039")
  Set stat = Add_Upload_Value("7045")
  Set stat = Add_Upload_Value("7054")
  Set stat = Add_Upload_Value("7056")
  Set stat = Add_Upload_Value("7063")
  Set stat = Add_Upload_Value("7074")
  Set stat = Add_Upload_Value("7092")
  Set stat = Add_Upload_Value("7097")
  Set stat = Add_Upload_Value("7130")
  Set stat = Add_Upload_Value("7140")
  Set stat = Add_Upload_Value("7147")
  Set stat = Add_Upload_Value("7156")
  Set stat = Add_Upload_Value("7164")
  Set stat = Add_Upload_Value("7166")
  Set stat = Add_Upload_Value("7167")
  Set stat = Add_Upload_Value("7185")
  Set stat = Add_Upload_Value("7194")
  Set stat = Add_Upload_Value("7195")
  Set stat = Add_Upload_Value("7200")
  Set stat = Add_Upload_Value("7273")
  Set stat = Add_Upload_Value("7275")
  Set stat = Add_Upload_Value("7289")
  Set stat = Add_Upload_Value("7290")
  Set stat = Add_Upload_Value("7291")
  Set stat = Add_Upload_Value("7332")
  Set stat = Add_Upload_Value("7334")
  Set stat = Add_Upload_Value("7341")
  Set stat = Add_Upload_Value("7351")
  Set stat = Add_Upload_Value("7352")
/***/
  return (Size(Upload_Values->UV, 5))
End ;; End
 
Subroutine Add_Upload_Value(tmpAlias)
  Declare uvCtr = I2
  Set uvCtr = (Size(Upload_Values->UV, 5) + 1)
  Set stat = AlterList(Upload_Values->UV, uvCtr)
  Set Upload_Values->UV[uvCtr]->Code_Value = SEND_CA_AS_ORU_CV
  Set Upload_Values->UV[uvCtr]->Alias = tmpAlias
  return (Size(Upload_Values->UV, 5))
End ;; End
 
end
go
 