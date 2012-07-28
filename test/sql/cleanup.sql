-- cleanup.sql: Clean up the regression test environment, in particular roles 
--              (all components inside the regression database will be deleted with the regression database)

-----------------------------
-- drop emaj_regression_tests_adm_user role
-----------------------------
revoke emaj_adm from emaj_regression_tests_adm_user;
revoke all on schema mySchema1, mySchema2, "phil's schema3" from emaj_regression_tests_adm_user;
revoke all on mySchema1.myTbl1, mySchema1.myTbl2, mySchema1."myTbl3", mySchema1.myTbl4, mySchema1.myTbl2b from emaj_regression_tests_adm_user;
revoke all on mySchema2.myTbl1, mySchema2.myTbl2, mySchema2."myTbl3", mySchema2.myTbl4, mySchema2.myTbl5, mySchema2.myTbl6 from emaj_regression_tests_adm_user;
revoke all on "phil's schema3"."phil's tbl1", "phil's schema3"."myTbl2\", "phil's schema3".myTbl4 from emaj_regression_tests_adm_user;
revoke all on sequence mySchema1."myTbl3_col31_seq" from emaj_regression_tests_adm_user;
revoke all on sequence mySchema2."myTbl3_col31_seq" from emaj_regression_tests_adm_user;
revoke all on sequence myschema2.myseq1 from emaj_regression_tests_adm_user;
revoke all on sequence "phil's schema3"."phil's seq\1" from emaj_regression_tests_adm_user;
--
drop role emaj_regression_tests_adm_user;

-----------------------------
-- drop emaj_regression_tests_viewer_user role
-----------------------------
revoke  all on schema mySchema1, mySchema2, "phil's schema3" from emaj_regression_tests_viewer_user;
revoke  all on mySchema1.myTbl1, mySchema1.myTbl2, mySchema1."myTbl3", mySchema1.myTbl4, mySchema1.myTbl2b from emaj_regression_tests_viewer_user;
revoke  all on mySchema2.myTbl1, mySchema2.myTbl2, mySchema2."myTbl3", mySchema2.myTbl4, mySchema2.myTbl5, mySchema2.myTbl6 from emaj_regression_tests_viewer_user;
revoke  all on "phil's schema3"."phil's tbl1", "phil's schema3"."myTbl2\" from emaj_regression_tests_viewer_user;
revoke  all on sequence mySchema1."myTbl3_col31_seq" from emaj_regression_tests_viewer_user;
revoke  all on sequence mySchema2."myTbl3_col31_seq" from emaj_regression_tests_viewer_user;
revoke  all on sequence mySchema2.mySeq1 from emaj_regression_tests_viewer_user;
revoke  all on sequence "phil's schema3"."phil's seq\1" from emaj_regression_tests_viewer_user;
--
drop role emaj_regression_tests_viewer_user;

-----------------------------
-- drop emaj_regression_tests_anonym_user role
-----------------------------
drop role emaj_regression_tests_anonym_user;

-----------------------------
-- reset tspemaj tablespace to its right name if it has been changed by installation script  
-----------------------------
alter tablespace tspemaj_renamed rename to tspemaj;

