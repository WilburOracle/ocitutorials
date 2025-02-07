DROP TABLE DEPARTMET CASCADE CONSTRAINTS PURGE;
DROP SEQUENCE DEPT_ID_SEQ;
DROP TRIGGER DEPT_ID_TRIGGER;

CREATE SEQUENCE DEPT_ID_SEQ
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

CREATE OR REPLACE TRIGGER DEPT_ID_TRIGGER
  BEFORE INSERT
  ON DEPARTMENT
  FOR EACH ROW
  WHEN (NEW.DEPT_ID IS NULL)
BEGIN
  SELECT DEPT_ID_SEQ.NEXTVAL INTO :NEW.DEPT_ID FROM DUAL;
END DEPT_ID_TRIGGER;
/

CREATE TABLE DEPARTMENT (
	DEPT_ID NUMBER(10) PRIMARY KEY,
	DEPT_NAME VARCHAR2(60) NOT NULL,
	MGR_ID NUMBER(10) NOT NULL,
);

INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('総務', 1000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('人事', 2000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('法務', 3000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('経理', 4000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('マーケティング', 5000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('開発', 6000);
INSERT INTO DEPARTMENT (DEPT_NAME, MNG_ID) VALUES ('技術', 7000);
COMMIT;



DEPTNO	部門番号または ID。
DEPTNAME	部門の全体的作業を表した名前。
MGRNO