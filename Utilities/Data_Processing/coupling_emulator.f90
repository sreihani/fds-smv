PROGRAM TWOWAYCOUPLING_EMULATOR

IMPLICIT NONE

INTEGER, PARAMETER :: FB = SELECTED_REAL_KIND(6)
INTEGER :: IERR, NMESHES, NM, I, J
INTEGER :: IFILE, NSAM
!INTEGER :: I1, I2, J1, J2, K1, K2, I3, J3, K3
!INTEGER :: NPATCH, IJBAR, JKBAR,II

TYPE MESH_TYPE
   REAL(FB), POINTER, DIMENSION(:) :: X,Y,Z
   REAL(FB) :: D1,D2,D3,D4
   INTEGER :: IBAR,JBAR,KBAR,IERR
END TYPE MESH_TYPE
 
TYPE (MESH_TYPE), DIMENSION(:), ALLOCATABLE, TARGET :: MESH
TYPE (MESH_TYPE), POINTER :: M
 
!INTEGER, ALLOCATABLE, DIMENSION(:) :: IOR,I1B,I2B,J1B,J2B,K1B,K2B
!REAL(FB), ALLOCATABLE, DIMENSION(:,:,:,:) :: Q
!REAL(FB), ALLOCATABLE, DIMENSION(:,:,:) :: F
!LOGICAL, ALLOCATABLE, DIMENSION(:,:,:) :: ALREADY_USED
CHARACTER(2) :: ANS
CHARACTER(4) :: CHOICE
CHARACTER(256) GRIDFILE,CHID,QFILE,JUNK,EXECUTABLE
CHARACTER(256), DIMENSION(500) :: BNDF_FILE,BNDF_TEXT,BNDF_UNIT
CHARACTER(20), DIMENSION(500) :: BNDF_TYPE
CHARACTER(20) :: BNDF_TYPE_CHOSEN
!REAL(FB), DIMENSION(500) :: X1, X2, Y1, Y2, Z1, Z2
!INTEGER,  DIMENSION(60) :: IB
INTEGER,  DIMENSION(500) :: BNDF_MESH
INTEGER :: RCODE
INTEGER :: NFILES_EXIST
LOGICAL :: EXISTS
INTEGER :: BATCHMODE
!CHARACTER(256) :: BUFFER
!INTEGER :: ERROR_STATUS
!CHARACTER(256) :: ARG

INTEGER COUNTER,VAR
INTEGER SIZE,VARIABLE,IN
REAL TBEG,TEND,TINT
REAL NOMASTER(1,4)
REAL, ALLOCATABLE, DIMENSION(:,:) :: VERTS,TFACES,DISP,NEWVERTS
INTEGER, ALLOCATABLE, DIMENSION(:) :: SURF_IDS,MATL_IDS,NODE
INTEGER, ALLOCATABLE, DIMENSION(:,:) :: FACES,VOLUS
CHARACTER(8) OUTFILE

REAL(FB) TIME,TIMEGEOM
INTEGER N_FACE(4),OWNER_INDEX
INTEGER ONE_INTEGER,VERSION,N_FLOATS,N_INTS,FIRST_FRAME_STATIC,N_FACES,N_VERTS,N_VOLUS,N_STEPS
INTEGER :: ONE=1, ZERO=0

COUNTER=10

!WRITE(6,*) ' Enter Job ID string (CHID):'
!READ(*,'(a)') CHID
CHID='tetra_1'
CALL GETARG(1,EXECUTABLE)
CALL SYSTEMQQ (TRIM(EXECUTABLE)//' '//TRIM(CHID)//'.fds &')


OPEN(10,FILE=TRIM(CHID)//'.gc',ACTION='WRITE',FORM='UNFORMATTED')
OWNER_INDEX=0
WRITE(10) OWNER_INDEX
CLOSE(10)  

! Set a few default values
BATCHMODE=0

! Check to see if the .smv file exists
GRIDFILE = TRIM(CHID)//'.smv'
INQUIRE(FILE=GRIDFILE,EXIST=EXISTS)
IF (.NOT.EXISTS) THEN
   WRITE(6,*)"*** Fatal error: The file: ",TRIM(GRIDFILE)," does not exist"
   STOP
ENDIF

! Open the .smv file

OPEN(11,FILE=GRIDFILE,STATUS='OLD',FORM='FORMATTED')
 
! Determine the number of meshes

REWIND(11)
 
CALL SEARCH('NMESHES',7,11,IERR)
IF (IERR.EQ.1) THEN
   WRITE(6,*) ' WARNING: Assuming 1 mesh'
   NMESHES = 1
ELSE
   READ(11,*) NMESHES
ENDIF

ALLOCATE(MESH(NMESHES))

! Get the coordinates of the meshes

REWIND(11)
 
READ_SMV: DO NM=1,NMESHES
   M=>MESH(NM)
!   CALL SEARCH('GRID',4,11,IERR)
!   READ(11,*) M%IBAR,M%JBAR,M%KBAR
    
!   CALL SEARCH('TRNX',4,11,IERR)
!   READ(11,*) NOC
!   DO I=1,NOC
!      READ(11,*)
!      ENDDO
!      DO I=0,M%IBAR
!      READ(11,*) IDUM,M%X(I)
!   ENDDO
 
!   CALL SEARCH('TRNY',4,11,IERR)
!   READ(11,*) NOC
!   DO I=1,NOC
!      READ(11,*)
!      ENDDO
!      DO J=0,M%JBAR
!      READ(11,*) IDUM,M%Y(J)
!   ENDDO
 
!   CALL SEARCH('TRNZ',4,11,IERR)
!   READ(11,*) NOC
!   DO I=1,NOC
!      READ(11,*)
!      ENDDO
!      DO K=0,M%KBAR
!      READ(11,*) IDUM,M%Z(K)
!   ENDDO
 
ENDDO READ_SMV
 
IFILE=3 
NSAM=1 
ANS='y'
CALL TOUPPER(ANS,ANS)
! **************************************************
! Beggining of the inputs for the new code - SILVA, JC
!   WRITE(6,*) ' Enter XYZ position'
!   READ(LU_IN,*) X,Y,Z
!   WRITE(6,*) ' Enter Cell Size'
!   READ(LU_IN,*) C_SIZE
            
         BNDF_MESH = 1
         REWIND(11)
         NFILES_EXIST=0

         SEARCH_BNDF: DO I=1,500
            CALL SEARCH2('BNDE',4,'BNDC',4,11,IERR,CHOICE)
            IF (IERR.EQ.1) EXIT SEARCH_BNDF
            BACKSPACE(11)
            READ(11,*) JUNK
            READ(11,'(A)') BNDF_FILE(I)
            WRITE(6,*) BNDF_FILE(I)
            READ(11,'(A)') BNDF_FILE(I)
            WRITE(6,*) BNDF_FILE(I)
            READ(11,'(A)') BNDF_TEXT(I)
            WRITE(6,*) BNDF_TEXT(I)
            READ(11,*)
            READ(11,'(A)') BNDF_UNIT(I)
            OPEN(12,FILE=BNDF_FILE(I),FORM='UNFORMATTED',STATUS='OLD', IOSTAT=RCODE)
            CLOSE(12)
            IF (RCODE.NE.0) CYCLE
            NFILES_EXIST=NFILES_EXIST+1
         ENDDO SEARCH_BNDF
    
         IF (NFILES_EXIST.EQ.0)THEN
            IF(BATCHMODE.EQ.0) write(6,*)"There are no boundary files to convert"
            STOP
         ENDIF
         

!VARIABLE_NUMBER: DO VAR=1,VARIABLE
VAR=1
! 500 - Point of the loop in case of the point does not reach a meaning value - SILVA, JC         
500 CONTINUE

!SIZE=((TEND-TBEG)/TINT)+1
!ALLOCATE (V_TIME(SIZE+1))
!ALLOCATE (M_AST(COUNTER,SIZE+1))
!ALLOCATE (TAST(COUNTER))
!V_TIME=0.0
!TAST=0.0
!M_AST=0.0

             
! IN_LOOP is a loop at index file - SILVA, JC
!IN_LOOP: DO IN=VAR,VARIABLE*NMESHES,VARIABLE

!CALL CPU_TIME (tb_nmeshes)
!*********
         !IF (BATCHMODE.EQ.0) write(6,*) ' Enter orientation: (plus or minus 1, 2 or 3)'
         !READ(LU_IN,*) IOR_INPUT

TIME_LOOP: DO TIMEGEOM=2,10,2

!***********************
!            NV=1
!            MV=1
!            IB(MV) = IN
IN=1
QFILE = BNDF_FILE(IN)
OPEN(12+VAR,FILE=QFILE,FORM='UNFORMATTED',STATUS='OLD', IOSTAT=RCODE)
IF (RCODE.NE.0) THEN
  CLOSE(12+VAR)
!CYCLE
ENDIF

! wait for FDS flag
BOUNDARY_CHECK_LOOP: DO I=1,600
   OPEN(10,FILE=TRIM(CHID)//'.gc',ACTION='READ',FORM='UNFORMATTED',SHARED)
   READ(10) OWNER_INDEX
   IF (OWNER_INDEX/=2) THEN
      CLOSE(10)
      IF (I==1) THEN
         WRITE (6,'(4X,A)')  'waiting for FDS results ... '
      ELSE 
         !WRITE(6,'(4X,A,I2,A)')  'waiting ... ', I-1,' min'
      ENDIF
      CALL SLEEP(15)
      IF (I==600) THEN
         WRITE (6,*) 'ERROR: .be FILE WAS NOT UPDATED BY FDS'
         STOP
      ENDIF
   ELSEIF (OWNER_INDEX==2) THEN
      CLOSE(10)
      EXIT BOUNDARY_CHECK_LOOP
   ENDIF
ENDDO BOUNDARY_CHECK_LOOP

BNDF_TYPE_CHOSEN = BNDF_TYPE(IN)
READ(12+VAR) ONE_INTEGER
WRITE(6,*) ONE_INTEGER
READ(12+VAR) VERSION
WRITE(6,*) VERSION

!WRITE(12+VAR) ZERO, ZERO, ONE 

READ(12+VAR) N_FLOATS, N_INTS, FIRST_FRAME_STATIC
WRITE(6,*) N_FLOATS, N_INTS, FIRST_FRAME_STATIC
READ(12+VAR) TIME
WRITE(6,*) TIME 
READ(12+VAR) N_VERTS, N_FACES, N_VOLUS 
WRITE(6,*) N_VERTS, N_FACES, N_VOLUS

!OPEN(16,FILE='verts.dat',FORM='FORMATTED',STATUS='UNKNOWN')

IF (N_VERTS>0) THEN
  ALLOCATE (VERTS(3,N_VERTS))            
  ALLOCATE (NEWVERTS(3,N_VERTS))     
  READ(12+VAR) VERTS
!  WRITE(6,*) VERTS
!  DO I=1,N_VERTS
!    WRITE(16,'(F8.5,F8.5,F8.5)') VERTS(1,I),VERTS(2,I),VERTS(3,I)
!  ENDDO
ENDIF

IF (N_FACES>0) THEN
   ALLOCATE (FACES(N_FACES,3))
   ALLOCATE (SURF_IDS(N_FACES))
   ALLOCATE (TFACES(N_FACES,6))
   READ(12+VAR) FACES
!   WRITE(6,*) FACES
   READ(12+VAR) SURF_IDS
!   WRITE(6,*) SURF_IDS
   READ(12+VAR) TFACES
ENDIF
IF (N_VOLUS>0) THEN
   ALLOCATE (VOLUS(N_VOLUS,4))
   ALLOCATE (MATL_IDS(N_VOLUS))
   READ(12+VAR) VOLUS
!   WRITE(6,*) VOLUS
   READ(12+VAR) MATL_IDS
!   WRITE(6,*) MATL_IDS
ENDIF

CLOSE(12+VAR) 

OPEN(12+VAR,FILE=TRIM(CHID)//'.gc',FORM='UNFORMATTED',STATUS='REPLACE')
WRITE(12+VAR) ONE
WRITE(6,*) ONE
WRITE(12+VAR) VERSION
WRITE(6,*) VERSION
!WRITE(12+VAR) ZERO,ZERO,ZERO
!WRITE(6,*) ZERO,ZERO,ZERO
!WRITE(12+VAR) TIME
!WRITE(6,*) TIME
!WRITE(12+VAR) N_VERTS, N_FACES, N_VOLUS 
!WRITE(6,*) N_VERTS, N_FACES, N_VOLUS 
!IF (N_VERTS>0) WRITE(12+VAR) VERTS
!IF (N_FACES>0) THEN
!  WRITE(12+VAR) FACES
!  WRITE(12+VAR) SURF_IDS
!  WRITE(12+VAR) TFACES
!ENDIF
!IF (N_VOLUS>0) THEN
!  WRITE(12+VAR) VOLUS
!  WRITE(12+VAR) MATL_IDS
!ENDIF

ALLOCATE (DISP(3,N_VERTS))  
ALLOCATE (NODE(N_VERTS))
!OPEN(15,FILE='displacements.dat',FORM='FORMATTED',STATUS='OLD')
!READ(15,'(I8)') N_STEPS


!DO J=1,N_STEPS 
!READ(15,'(F8.3)') TIME
!WRITE(6,*) TIME
!  DO I=1,N_VERTS
!    READ(15,'(I8)', ADVANCE='NO') NODE(I)
!    WRITE(6,*) NODE(I)
!    READ(15,'(F8.5,F8.5,F8.5)') DISP(1,I),DISP(2,I),DISP(3,I)
!    WRITE(6,*) DISP(1,I),DISP(2,I),DISP(3,I)
!  ENDDO

!DO I=1,N_VERTS
!  NEWVERTS(1,I)=VERTS(1,I)+DISP(1,I)
!  NEWVERTS(2,I)=VERTS(2,I)+DISP(2,I)
!  NEWVERTS(3,I)=VERTS(3,I)+DISP(3,I)
!ENDDO   
!WRITE(6,*) NEWVERTS
NEWVERTS=VERTS
NEWVERTS(3,4)=VERTS(3,4)-(0.1*(TIMEGEOM/2))

WRITE(12+VAR) TIMEGEOM
WRITE(12+VAR) N_VERTS, N_FACES, N_VOLUS 
WRITE(6,*) N_VERTS, N_FACES, N_VOLUS 
IF (N_VERTS>0) WRITE(12+VAR) NEWVERTS
IF (N_FACES>0) THEN
  WRITE(12+VAR) FACES
  WRITE(12+VAR) SURF_IDS
  WRITE(12+VAR) TFACES
ENDIF
IF (N_VOLUS>0) THEN
  WRITE(12+VAR) VOLUS
  WRITE(12+VAR) MATL_IDS
ENDIF

!ENDDO

!LOOP_FDS2AST: DO I=1,COUNTER
!    WRITE (OUTFILE,'(g8.0)') INT(NOMASTER(I,1))
!    PRINT *, OUTFILE
!****************

!OPEN(100+VAR,FILE=TRIM(OUTFILE)//'.dat',FORM='FORMATTED',STATUS='UNKNOWN')
!      DO J=1,SIZE+1
!        WRITE (100+VAR,'(E12.5)', ADVANCE='NO') V_TIME(J)
!        WRITE (100+VAR,'(E12.5)', ADVANCE='YES') M_AST(I,J)
!      ENDDO
!    CLOSE (100+VAR)
!100 CONTINUE

!ENDDO LOOP_FDS2AST

!ENDDO IN_LOOP



!ENDDO VARIABLE_NUMBER
CLOSE(12+VAR)
DEALLOCATE (DISP)  
DEALLOCATE (NODE)
DEALLOCATE (VERTS)            
DEALLOCATE (NEWVERTS)
DEALLOCATE (FACES)
DEALLOCATE (SURF_IDS)
DEALLOCATE (TFACES)
DEALLOCATE (VOLUS)
DEALLOCATE (MATL_IDS)
ENDDO TIME_LOOP

END PROGRAM TWOWAYCOUPLING_EMULATOR


! *********************** SEARCH *******************************

SUBROUTINE SEARCH(STRING,LENGTH,LU,IERR)

IMPLICIT NONE
CHARACTER(*), INTENT(IN) :: STRING
INTEGER, INTENT(OUT) :: IERR
INTEGER, INTENT(IN) :: LU, LENGTH
CHARACTER(20) :: JUNK

SEARCH_LOOP: DO 
   READ(LU,'(A)',END=10) JUNK
   IF (JUNK(1:LENGTH).EQ.STRING(1:LENGTH)) EXIT SEARCH_LOOP
ENDDO SEARCH_LOOP

IERR = 0
RETURN

10 IERR = 1
RETURN

END SUBROUTINE SEARCH

! *********************** SEARCH2 *******************************

SUBROUTINE SEARCH2(STRING,LENGTH,STRING2,LENGTH2,LU,IERR,CHOICE)

IMPLICIT NONE
CHARACTER(*), INTENT(IN) :: STRING,STRING2
CHARACTER(*), INTENT(OUT) :: CHOICE
INTEGER, INTENT(OUT) :: IERR
INTEGER, INTENT(IN) :: LU, LENGTH, LENGTH2
CHARACTER(20) :: JUNK

SEARCH_LOOP: DO 
   READ(LU,'(A)',END=10) JUNK
   IF (JUNK(1:LENGTH).EQ.STRING(1:LENGTH).OR.JUNK(1:LENGTH2).EQ.STRING2(1:LENGTH2)) THEN
      IF (JUNK(1:LENGTH) .EQ.STRING(1:LENGTH))   CHOICE = JUNK(1:LENGTH)
      IF (JUNK(1:LENGTH2).EQ.STRING2(1:LENGTH2)) CHOICE = JUNK(1:LENGTH2)
      EXIT SEARCH_LOOP
   ENDIF
ENDDO SEARCH_LOOP

IERR = 0
RETURN

10 IERR = 1
RETURN

END SUBROUTINE SEARCH2

! *********************** TOUPPER *******************************

SUBROUTINE TOUPPER(BUFFERIN, BUFFEROUT)
CHARACTER(LEN=*), INTENT(IN) :: BUFFERIN
CHARACTER(LEN=*), INTENT(OUT) :: BUFFEROUT
CHARACTER(LEN=1) :: C

INTEGER :: LENBUF, I

LENBUF=MIN(LEN(TRIM(BUFFERIN)),LEN(BUFFEROUT))
DO I = 1, LENBUF
   C = BUFFERIN(I:I)
   IF(C.GE.'a'.AND.C.LE.'z')C=CHAR(ICHAR(C)+ICHAR('A')-ICHAR('a'))
    BUFFEROUT(I:I)=C
END DO

END SUBROUTINE TOUPPER
