St John CCL and OE Scripts

1. MOBJ_AP_Fmt_Fix
	Outbound script to format AP ORU messages by removing header and footer rows
2. MOBJ_AP_Fmt_Fix_24
	Same script as MOBJ_AP but for ORU 2.4
3. MOBJ_CA_ORM_ORU_Out_Fix
	Script to change ORM/CA messages to ORU with dta's of the orderable
4. MOBJ_Chk_Out_Not_Aliased2
	Script to check different fields for non aliased values and if found
	send an email of what is missing.
5. MOBJ_Chk_Out_Not_Aliased4
	Updated version of #2. 
6. SP_St_John_ESI_Rpt
	CCL script to create report of ESI Log failures and warnings. Proposed run time
	is every 5 minutes from Ops. Any records found meeting criteria will be emailed
	to persons notifying them of the issues.
7. ReadMe.txt
8. MOBJ_Chk_Out_Req_Field
	Script will check fields for a value and if empty will send a notificaion and
	possible dump the message
9. SP_TIME_TEST.PRG
	testing script for OEN_TXLOG key breakdown and how to format to query
make a change on teh s&p laptop
Making a change
