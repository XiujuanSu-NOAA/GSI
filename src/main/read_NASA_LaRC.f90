subroutine read_NASA_LaRC(nread,ndata,infile,obstype,lunout,twind,sis)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:  read_NASA_LaRC          Reading in NASA LaRC cloud   
!
!   PRGMMR: Ming Hu          ORG: GSD/AMB        DATE: 2009-09-21
!
! ABSTRACT: 
!     This routine reads in NASA LaRC cloud data. The data has already  
!          been interpolated into analysis grid and in form of BUFR.
!
! PROGRAM HISTORY LOG:
!    2009-09-21  Hu  initial
!    2010-04-09  Hu  make changes based on current trunk style
!
!
!   input argument list:
!     infile   - unit from which to read NASA LaRC file
!     obstype  - observation type to process
!     lunout   - unit to which to write data for further processing
!     twind    - input group time window (hours)
!     sis      - observation variable name
!
!   output argument list:
!     nread    - number of type "obstype" observations read
!     ndata    - number of type "obstype" observations retained for further processing
!
! USAGE:
!   INPUT FILES:  NASALaRCCloudInGSI.bufr
!
!   OUTPUT FILES:
!
! REMARKS:
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90 
!   MACHINE:  Linux cluster (WJET)
!
!$$$
!
!_____________________________________________________________________
!
  use kinds, only: r_kind,r_double,i_kind
  use constants, only: zero,one,izero,ione
  use convinfo, only: nconvtype,ctwind,cgross,cermax,cermin,cvar_b,cvar_pg, &
        ncmiter,ncgroup,ncnumgrp,icuse,ictype,icsubtype,ioctype
  use gsi_4dvar, only: l4dvar,winlen

  implicit none
!
  
  character(10),    intent(in)   :: infile,obstype
  integer(i_kind),  intent(in)   :: lunout
  integer(i_kind),  intent(inout):: nread,ndata
  real(r_kind),     intent(in   ):: twind
  character(20),    intent(in)   :: sis
!
!  For LaRC
!
  integer(i_kind) nreal,nchanl,ilat,ilon

  integer(i_kind) ifn,i,j
 
  logical :: LaRCobs

!
!  for read in bufr
!
    real(r_kind) :: hdr(5),obs(1,5)
    character(80):: hdrstr='SID XOB YOB DHR TYP'
    character(80):: obsstr='POB'

    INTEGER(i_kind),PARAMETER ::  MXBF = 160000_i_kind
    INTEGER(i_kind) :: ibfmsg = MXBF/4_i_kind

    character(8) subset,sid
    integer(i_kind) :: lunin,idate
    integer(i_kind)  :: ireadmg,ireadsb

    INTEGER(i_kind)  ::  maxlvl,nlon,nlat
    INTEGER(i_kind)  ::  numlvl,numLaRC
    INTEGER(i_kind)  ::  n,k,iret
    INTEGER(i_kind),PARAMETER  ::  nmsgmax=100000_i_kind
    INTEGER(i_kind)  ::  nmsg,ntb
    INTEGER(i_kind)  ::  nrep(nmsgmax)
    INTEGER(i_kind),PARAMETER  ::  maxobs=450000_i_kind 

    REAL(r_kind),allocatable :: LaRCcld_in(:,:)   ! 3D reflectivity in column

    integer(i_kind)  :: ikx
    real(r_kind)     :: timeo,t4dv

    REAL(r_double)  :: rid
    EQUIVALENCE (sid,rid)

!**********************************************************************
!
!            END OF DECLARATIONS....start of program
!
   LaRCobs = .false.
   ikx=izero
   do i=1,nconvtype
       if(trim(obstype) == trim(ioctype(i)) .and. abs(icuse(i))== ione) then
           LaRCobs =.true.
           ikx=i
       endif
   end do

   nchanl= izero
   nread = izero
   ndata = izero
   ifn = 15_i_kind
!
   if(LaRCobs) then
      lunin = 10_i_kind            
      maxlvl= 5_i_kind
      allocate(LaRCcld_in(maxlvl+2_i_kind,maxobs))

      OPEN  ( UNIT = lunin, FILE = trim(infile),form='unformatted',err=200)
      CALL OPENBF  ( lunin, 'IN', lunin )
      CALL DATELEN  ( 10_i_kind )

      nmsg=izero
      nrep=izero
      ntb = izero
      msg_report: do while (ireadmg(lunin,subset,idate) == izero)
         nmsg=nmsg+ione
         if (nmsg>nmsgmax) then
            write(6,*)'read_NASA_LaRC: messages exceed maximum ',nmsgmax
            call stop2(50)
         endif
         loop_report: do while (ireadsb(lunin) == izero)
            ntb = ntb+ione
            nrep(nmsg)=nrep(nmsg)+ione
            if (ntb>maxobs) then
                write(6,*)'read_NASA_LaRC: reports exceed maximum ',maxobs
                call stop2(50)
            endif

!    Extract type, date, and location information
            call ufbint(lunin,hdr,5_i_kind,ione,iret,hdrstr)
! check time window in subset
            if (l4dvar) then
               t4dv=hdr(4)
               if (t4dv<zero .OR. t4dv>winlen) then
                  write(6,*)'read_NASALaRC:      time outside window ',&
                       t4dv,' skip this report'
                  cycle loop_report
               endif
            else
               timeo=hdr(4)
               if (abs(timeo)>ctwind(ikx) .or. abs(timeo) > twind) then
                  write(6,*)'read_NASALaRC:  time outside window ',&
                       timeo,' skip this report'
                  cycle loop_report
               endif
            endif

! read in observations
            call ufbint(lunin,obs,ione,maxlvl,iret,obsstr)
            numlvl=iret

            LaRCcld_in(1,ntb)=hdr(2)*10.0_r_kind       ! observation location, grid index i
            LaRCcld_in(2,ntb)=hdr(3)*10.0_r_kind       ! observation location, grid index j

            do k=1,numlvl
              LaRCcld_in(2+k,ntb)=obs(1,k)             ! NASA LaRC cloud products: k=1 cloud top pressure
            enddo                                      ! k=2 cloud top temperature, k=3 cloud fraction     
                                                       ! k=4 lwp,  k=5, cloud levels
         enddo loop_report
      enddo msg_report

      write(6,*)'read_NASALaRC: messages/reports = ',nmsg,'/',ntb
      numLaRC=ntb
!
      ilon=ione
      ilat=2_i_kind
      nread=numLaRC
      ndata=numLaRC
      nreal=maxlvl+2_i_kind
      if(numLaRC > izero ) then
          write(lunout) obstype,sis,nreal,nchanl,ilat,ilon
          write(lunout) ((LaRCcld_in(k,i),k=1,maxlvl+2),i=1,numLaRC)
          deallocate(LaRCcld_in)
      endif
    endif
!
    call closbf(lunin)
    return
200 continue
    write(6,*) 'read_NASA_LaRC, Warning : cannot find LaRC data file'

end subroutine  read_NASA_LaRC
