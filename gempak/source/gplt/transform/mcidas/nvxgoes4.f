*********************************************************************
*  This file contains Navigation routines for Himawari netcdf4 data,
*   written according section 4.4.3.2 - Normalized Geostationary
*   Projection
*   (http://2014.cgms-info.org/documents/cgms-lrit-hrit-global-specification-%28v2-8-of-30-oct-2013%29.pdf)
*
*   S Guan/NCEP   10/15      created
*
*				NVXINI --> GOSINI4
*				NVXSAE --> GOSSAE4
*				NVXEAS --> GOSEAS4
*
*********************************************************************
*                  NAVIGATION SUBROUTINE PACKAGE
*********************************************************************
*     FOLLOWING ARE LISTINGS OF FORTRAN/77 SUBROUTINES AND FUNCTIONS
* THAT PERFORM THE VARIOUS STEPS REQUIRED TO 'NAVIGATE' A SATELLITE
* AREA. IF THESE ROUTINES ARE USED THEY SHOULD BE INSTALLED ON THE
* COMPUTER AS A PACKAGE SINCE THEY SHARE SOME DATA THROUGH COMMON BLOCKS.
* EACH ROUTINE CONTAINS A BRIEF DESCRIPTION OF ITS FUNCTION AND WHAT
* INPUTS ARE REQUIRED.
*     TO NAVIGATE A SATELLITE IMAGE OR AREA, THE PARAMETERS CONTAINED IN
* THE 'NAV ' BLOCK ON THE TAPE MUST BE MOVED TO AN ARRAY CALLED 'IARR'.
* IARR(1) SHOULD CONTAIN 'GOE4'for Himawari netcdf4 datq. IN EBCDIC.
*     THE CALL ISTAT= NVXINI(1,IARR) WILL INITIALIZE THE NAVIGATION
* PACKAGE. IF ISTAT IS RETURNED AS 0, THE INITIALIZATION WAS SUCCESSFUL.
* THIS MUST BE DONE PRIOR TO USING THE ROUTINES IN THE PACKAGE.
*     TO TRANSFORM LINE AND ELEMENT FROM THE SATELLITE AREA TO EARTH
* COORDINATES, USE THE CALL ISTAT= GOSSAE(XLIN,XELE,0.,XLAT,XLON,XDUMMY).
* INPUTS ARE REAL*4 XLIN= SATELLITE LINE NUMBER
*                   XELE= SATELLITE ELEMENT NUMBER
* BOTH INPUTS ARE BASED ON FULL RESOLUTION.
* OUTPUTS ARE REAL*4 XLAT= LATITUDE OF PIXEL
*                    XLON= LONGITUDE OF PIXEL
* NORTH AND WEST ARE POSITIVE.
* THE PARAMETERS, 0. AND XDUMMY, ARE USED IN 3-DIMENSIONAL NAVIGATION.
* IF ISTAT= 0 THE TRANSFORMATION WAS SUCCESSFUL. IF ISTAT= -1 THE
* TRANSFORMATION WAS NOT POSSIBLE (E.G. ARGUMENTS OUT OF RANGE).
*     TO TRANSFORM EARTH COORDINATES (LATITUDE, LONGITUDE) TO SATELLITE
* COORDINATES, CALL ISTAT= GOSEAS(XLAT,XLON,0.,XLIN,XELE,XDUMMY).
* THE ARGUMENTS AND RETURN VALUE ARE THE SAME AS THE ABOVE CALL.
*     NORMALLY, TRANSFORMATIONS ARE MADE TO AND FROM LATITUDE AND
* LONGITUDE. IF THIS IS NOT DESIRED, SUCH AS WITH POINTS NEAR THE POLE,
* EARTH BASED COORDINATES MAY BE CHANGED TO RECTANGULAR COORDINATES
* (X,Y,Z). THESE COORDINATES HAVE THE ORIGIN AT THE EARTH'S CENTER WITH
* THE X-AXIS PASSING THROUGH THE EQUATOR AT 0 DEGREES, THE Y-AXIS PASSING
* THROUGH THE EQUATOR AT 90 DEGREES EAST (-90 DEG.) AND THE Z-AXIS
* PASSING THROUGH THE NORTH POLE.
*     THE CALL ISTAT= NVXINI(2,'XYZ') WILL CAUSE THE ROUTINES GOSSAE AND
* GOSEAS TO PERFORM THE FOLLOWING FUNCTIONS:
* ISTAT= GOSSAE(XLIN,XELE,0.,X,Y,Z)
* WHERE XLIN= SATELLITE LINE NUMBER
*       XELE= SATELLITE ELEMENT NUMBER
*      X,Y,Z ARE THE RECTANGLUAR COORDINATES DESCRIBED ABOVE.
* ISTAT= GOSEAS(X,Y,Z,XLIN,XELE,XDUMMY) ARGUMENTS AS DESCRIBED ABOVE.
* IT IS POSSIBLE TO RETURN TO LATITUDE LONGITUDE COORDINATES WITH THE
* CALL ISTAT= NVXINI(2,'LL').
* 
C***********************************************************************

      INTEGER FUNCTION GOSINI4(IFUNC,IARR)
C
C THIS ROUTINE SETS UP COMMON BLOCKS NAVCOM AND NAVINI FOR USE BY THE
C NAVIGATION TRANSFORMATION ROUTINES GOSSAE AND GOSEAS.
C NVXINI SHOULD BE RECALLED EVERY TIME A TRANSFORMATION IS DESIRED
C FOR A PICTURE WITH A DIFFERENT TIME THAN THE PREVIOUS CALL.
C IFUNC IS 1 (INITIALIZE; SET UP COMMON BLOCKS)
C          2 (ACCEPT/PRODUCE ALL EARTH COORDINATES IN LAT/LON
C            FORM IF IARR IS 'LL  ' OR IN THE X,Y,Z COORDINATE FRAME
C            IF IARR IS 'XYZ '.
C            THIS AFFECTS ALL SUBSEQUENT GOSEAS OR GOSSAE CALLS.)
C IARR IS AN INTEGER ARRAY (DIM 128) IF IFUNC=1, CONTAINING NAV
C        PARAMETERS
C
      INTEGER IARR(*)
      CHARACTER*2 CLLSW
      COMMON/NAVCOM/NAVDAY,LINTOT,DEGLIN,IELTOT,DEGELE,SPINRA,IETIMY,IET
     1IMH,SEMIMA,OECCEN,ORBINC,PERHEL,ASNODE,NOPCLN,DECLIN,RASCEN,PICLIN
     2,PRERAT,PREDIR,PITCH,YAW,ROLL,SKEW
      COMMON /BETCOM/IAJUST,IBTCON,NEGBET,ISEANG
      COMMON /VASCOM/SCAN1,TIME1,SCAN2,TIME2
      COMMON /NAVINI/
     1  EMEGA,AB,ASQ,BSQ,R,RSQ,
     2  RDPDG,
     3  NUMSEN,TOTLIN,RADLIN,
     4  TOTELE,RADELE,PICELE,
     5  CPITCH,CYAW,CROLL,
     6  PSKEW,
     7  RFACT,ROASIN,TMPSCL,
     8  B11,B12,B13,B21,B22,B23,B31,B32,B33,
     9  GAMMA,GAMDOT,
     A  ROTM11,ROTM13,ROTM21,ROTM23,ROTM31,ROTM33,
     B  PICTIM,XREF
      COMMON /NVUNIT/ LLSW
      COMMON /NVH8/x_scale, x_offset, y_scale, y_offset, sat_lon
      DATA JINIT/0/

*** NPS MOD *************************************************
*   added these EQUIV's for replacing calls to MOVWC
*
      CHARACTER*2     CI2CV
      INTEGER*2       I2CV
      EQUIVALENCE  ( CI2CV, I2CV )
      CHARACTER*4     CI4CV
      INTEGER*4       I4CV
      EQUIVALENCE     ( CI4CV, I4CV )
**** END NPS MOD *********************************************
      y_scale =  IARR(40)
      y_offset = IARR(41) 
      x_scale =  IARR(42)
      x_offset = IARR(43)
      sat_lon = IARR(44)/1000.0
C      
      IF (JINIT.EQ.0) THEN
         JINIT=1
         LLSW=0
         JDAYSV=-1
         JTIMSV=-1
      ENDIF
      IF (IFUNC.EQ.2) THEN

**** NPS MOD *******************************************************
*    replaced call to MOVWC using EQUIVed variables

*         CALL MOVWC(IARR,CLLSW)
         I2CV = IARR(1)
         CLLSW = CI2CV
**** END NPS MOD ***************************************************

         IF (CLLSW.EQ.'LL') LLSW=0
         IF (CLLSW.EQ.'XY') LLSW=1
         GOSINI4=0
         RETURN
      ENDIF

**** END NPS MOD ************************************************

      JDAY=IARR(2)
      JTIME=IARR(3)
      IF(JDAY.EQ.JDAYSV.AND.JTIME.EQ.JTIMSV) GO TO 10
      GO TO 10
C
C-----INITIALIZE NAVCOM
      NAVDAY=MOD(JDAY,100000)
      DO 20 N=7,12
      IF(IARR(N).GT.0) GO TO 25
   20 CONTINUE
      GO TO 90
   25 IETIMY=ICON1(IARR(5))
      IETIMH=100*(IARR(6)/100)+IROUND(.6*MOD(IARR(6),100))
      SEMIMA=FLOAT(IARR(7))/100.0
      OECCEN=FLOAT(IARR(8))/1000000.0
      ORBINC=FLOAT(IARR(9))/1000.0
      XMEANA=FLOAT(IARR(10))/1000.0
      PERHEL=FLOAT(IARR(11))/1000.0
      ASNODE=FLOAT(IARR(12))/1000.0
      CALL EPOCH(IETIMY,IETIMH,SEMIMA,OECCEN,XMEANA)
      IF (IARR(5).EQ.0.OR.IARR(9).EQ.0) GOTO 90
      DECLIN=FLALO(IARR(13))
      RASCEN=FLALO(IARR(14))
      PICLIN=IARR(15)
      IF (IARR(15).GE.1000000) PICLIN=PICLIN/10000.
      IF (IARR(13).EQ.0.AND.IARR(14).EQ.0.AND.IARR(15).EQ.0)
     *   GOTO 90
      SPINRA=IARR(16)/1000.0
      IF(IARR(16).NE.0.AND.SPINRA.LT.300.0) SPINRA=60000.0/SPINRA
      IF (IARR(16).EQ.0) GOTO 90
      DEGLIN=FLALO(IARR(17))
      LINTOT=IARR(18)
      DEGELE=FLALO(IARR(19))
      IELTOT=IARR(20)
      PITCH=FLALO(IARR(21))
      YAW=FLALO(IARR(22))
      ROLL=FLALO(IARR(23))
      SKEW=IARR(29)/100000.0
      IF (IARR(29).EQ.MISVAL) SKEW=0.
C
C-----INITIALIZE BETCOM
      IAJUST=IARR(25)
      ISEANG=IARR(28)
      IBTCON=6289920
      NEGBET=3144960
C
C-----INITIALIZE NAVINI COMMON BLOCK
      EMEGA=.26251617
      AB=40546851.22
      ASQ=40683833.48
      BSQ=40410330.18
      R=6371.221
      RSQ=R*R
      RDPDG=1.745329252E-02
      NUMSEN=MOD(LINTOT/100000,100)
      IF(NUMSEN.LT.1)NUMSEN=1
      TOTLIN=NUMSEN*MOD(LINTOT,100000)
      RADLIN=RDPDG*DEGLIN/(TOTLIN-1.0)
      TOTELE=IELTOT
      RADELE=RDPDG*DEGELE/(TOTELE-1.0)
      PICELE=(1.0+TOTELE)/2.0
      CPITCH=RDPDG*PITCH
      CYAW=RDPDG*YAW
      CROLL=RDPDG*ROLL
      PSKEW=ATAN2(SKEW,RADLIN/RADELE)
      STP=SIN(CPITCH)
      CTP=COS(CPITCH)
      STY=SIN(CYAW-PSKEW)
      CTY =COS(CYAW-PSKEW)
      STR=SIN(CROLL)
      CTR=COS(CROLL)
      ROTM11=CTR*CTP
      ROTM13=STY*STR*CTP+CTY*STP
      ROTM21=-STR
      ROTM23=STY*CTR
      ROTM31=(-CTR)*STP
      ROTM33=CTY*CTP-STY*STR*STP
      RFACT=ROTM31**2+ROTM33**2
      ROASIN=ATAN2(ROTM31,ROTM33)
      TMPSCL=SPINRA/3600000.0
      DEC=DECLIN*RDPDG
      SINDEC=SIN(DEC)
      COSDEC=COS(DEC)
      RAS=RASCEN*RDPDG
      SINRAS=SIN(RAS)
      COSRAS=COS(RAS)
      B11=-SINRAS
      B12=COSRAS
      B13=0.0
      B21=(-SINDEC)*COSRAS
      B22=(-SINDEC)*SINRAS
      B23=COSDEC
      B31=COSDEC*COSRAS
      B32=COSDEC*SINRAS
      B33=SINDEC
      XREF=RAERAC(NAVDAY,0,0.0)*RDPDG
C
C-----TIME-SPECIFIC PARAMETERS (INCL GAMMA)
      PICTIM=FLALO(JTIME)
      GAMMA=FLOAT(IARR(39))/100.
      GAMDOT=FLOAT(IARR(40))/100.
C
C-----INITIALIZE VASCOM
      IF (JDAY/100000.GT.25.AND.IARR(31).GT.0) THEN
C        THIS SECTION DOES VAS BIRDS
C        IT USES TIMES AND SCAN LINE FROM BETA RECORDS
         SCAN1=FLOAT(IARR(31))
         TIME1=FLALO(IARR(32))
         SCAN2=FLOAT(IARR(35))
         TIME2=FLALO(IARR(36))
      ELSE
C        THIS SECTION DOES THE OLD GOES BIRDS
         SCAN1=1.
         TIME1=FLALO(JTIME)
         SCAN2=FLOAT(MOD(LINTOT,100000))
         TIME2=TIME1+SCAN2*TMPSCL
      ENDIF
C
C-----ALL DONE. EVERYTHING OK
 10   CONTINUE
      JDAYSV=JDAY
      JTIMSV=JTIME
      GOSINI4=0
      RETURN
 90   GOSINI4=-1
      RETURN
      END
C ********************************************************************
C
      INTEGER FUNCTION GOSSAE4(XLIN1,XELE1,XDUM,XPAR,YPAR,ZPAR)
C TRANSFORMS SAT COOR TO EARTH COOR.
C ALL PARAMETERS REAL*4
C INPUTS:
C XLIN,XELE ARE SATELLITE LINE AND ELEMENT (IMAGE COORDS.)
C XDUM IS DUMMY (IGNORE)
C OUTPUTS:
C XPAR,YPAR,ZPAR REPRESENT EITHER LAT,LON,(DUMMY) OR X,Y,Z DEPENDING
C ON THE OPTION SET IN PRIOR NVXINI CALL WITH IFUNC=2.
C FUNC VAL IS 0 (OK) OR -1 (CAN'T; E.G. OFF OF EARTH)
C
      COMMON/NAVCOM/NAVDAY,LINTOT,DEGLIN,IELTOT,DEGELE,SPINRA,IETIMY,IET
     1IMH,SEMIMA,OECCEN,ORBINC,PERHEL,ASNODE,NOPCLN,DECLIN,RASCEN,PICLIN
     2,PRERAT,PREDIR,PITCH,YAW,ROLL,SKEW
      COMMON/NAVINI/
     1  EMEGA,AB,ASQ,BSQ,R,RSQ,
     2  RDPDG,
     3  NUMSEN,TOTLIN,RADLIN,
     4  TOTELE,RADELE,PICELE,
     5  CPITCH,CYAW,CROLL,
     6  PSKEW,
     7  RFACT,ROASIN,TMPSCL,
     8  B11,B12,B13,B21,B22,B23,B31,B32,B33,
     9  GAMMA,GAMDOT,
     A  ROTM11,ROTM13,ROTM21,ROTM23,ROTM31,ROTM33,
     B  PICTIM,XREF
      COMMON /NVUNIT/ LLSW
      COMMON /NVH8/x_scale, x_offset, y_scale, y_offset, sat_lon 
      DATA PI/3.14159265/
C
      HT = 42164.0
      R_EQ = 6378137.0
C     RATIO = (R_eq/R_pol)**2
      RATIO = 1.006739501
C      HTPM = HT * HT - R_EQ * R_EQ
      HTPM = 1737122264.0
      XELE = ( (XELE1 +0.5) * x_scale + x_offset)/1000000.0
      XLIN = ( (XLIN1 +0.5) * y_scale + y_offset)/1000000.0
      COSX=COS(XELE )
      COSY=COS(XLIN )
      SINX=SIN(XELE)
      SINY=SIN(XLIN)
      TEM = COSY*COSY + RATIO*SINY*SINY
      STM = HT*COSX*COSY
      SD = STM *STM - HTPM * TEM
      IF  (SD.LT. 0.0) THEN
         GOSSAE4 = -3
         RETURN
      END IF 
      SD = SQRT( STM *STM - HTPM * TEM)
      SN = ( STM - SD )/TEM
      S1 = HT - SN * COSX*COSY
      S2 = SN * SINX*COSY
      S3 = (-1.0)* SN * SINY
      XPAR = ATAN(RATIO *S3/SQRT(S1*S1 + S2*S2))*180/PI
      XPAR = -XPAR 
      YPAR = ATAN(S2/S1)*180/PI + sat_lon
      if ( YPAR .GT. 180 ) YPAR = YPAR -360.0
      if ( YPAR .LT. -180 ) YPAR = YPAR +360.0
      GOSSAE4 = 0
      RETURN
      END
C ********************************************************************
C
      INTEGER FUNCTION GOSEAS4(XPAR,YPAR,ZPAR,XLIN,XELE,XDUM)
C 5/26/82;  TRANSFORM EARTH TO SATELLITE COORDS
C ALL PARAMETERS REAL*4
C INPUTS:
C XPAR,YPAR,ZPAR REPRESENT EITHER LAT,LON,(DUMMY) OR X,Y,Z DEPENDING
C ON THE OPTION SET IN PRIOR NVXINI CALL WITH IFUNC=2.
C OUTPUTS:
C XLIN,XELE ARE SATELLITE LINE AND ELEMENT (IMAGE COORDS.)
C XDUM IS DUMMY (IGNORE)
C FUNC VAL IS 0 (OK) OR -1 (CAN'T; E.G. BAD LAT/LON)
C
      COMMON /NVH8/x_scale, x_offset, y_scale, y_offset, sat_lon
      DATA PI/3.14159265/
      GOSEAS4=0
      YPAR = -YPAR
      X1 = XPAR
      Y1=YPAR - sat_lon
      if ( Y1 .GT. 180 ) Y1 = Y1 -360.0
      if ( Y1 .LT. -180 ) Y1 = Y1 +360.0
      X1 = X1 *PI/180.0
      X1 = -X1
      Y1= Y1*PI/180.0
      XDUM=0.0
      C_LAT = ATAN(0.993305616 *TAN (X1))
      RR = 6356.7523 /
     1  SQRT( 1.0 - 0.00669438444 * COS (C_LAT)* COS (C_LAT ))
      R1 = 42164.0 - RR * COS (C_LAT) * COS (Y1)
      R2 = (-1.0) * RR *  COS (C_LAT) * SIN (Y1)
      R3 = RR * SIN (C_LAT)
      RN = SQRT( R1*R1 + R2*R2 + R3*R3)
      XELE = ATAN (-R2/R1)
      XLIN = ASIN (-R3/RN)

      XELE = ( XELE*1000000.0 - x_offset )/x_scale -0.5
      XLIN = ( XLIN*1000000.0 - y_offset )/y_scale -0.5
      RETURN
      END
