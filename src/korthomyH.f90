!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
! Copyright 2010.  Los Alamos National Security, LLC. This material was    !    
! produced under U.S. Government contract DE-AC52-06NA25396 for Los Alamos !    
! National Laboratory (LANL), which is operated by Los Alamos National     !    
! Security, LLC for the U.S. Department of Energy. The U.S. Government has !    
! rights to use, reproduce, and distribute this software.  NEITHER THE     !    
! GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY, LLC MAKES ANY WARRANTY,     !    
! EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY FOR THE USE OF THIS         !    
! SOFTWARE.  If software is modified to produce derivative works, such     !    
! modified software should be clearly marked, so as not to confuse it      !    
! with the version available from LANL.                                    !    
!                                                                          !    
! Additionally, this program is free software; you can redistribute it     !    
! and/or modify it under the terms of the GNU General Public License as    !    
! published by the Free Software Foundation; version 2.0 of the License.   !    
! Accordingly, this program is distributed in the hope that it will be     !    
! useful, but WITHOUT ANY WARRANTY; without even the implied warranty of   !    
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General !    
! Public License for more details.                                         !    
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    

SUBROUTINE KORTHOMYH

  USE CONSTANTS_MOD
  USE SETUPARRAY
  USE NONOARRAY
  USE KSPACEARRAY
  USE MYPRECISION

  IMPLICIT NONE

  INTEGER I, J, II
  COMPLEX(LATTEPREC), PARAMETER :: ALPHA = CMPLX(ONE, ZERO), BETA=CMPLX(ZERO, ZERO)
  COMPLEX(LATTEPREC), ALLOCATABLE :: KTMP(:,:)
  IF (EXISTERROR) RETURN

  ALLOCATE(KTMP(HDIM, HDIM))

  !
  ! ORTHOH = X^dag H X
  !

  IF (SPINON .EQ. 0) THEN
     
     DO II = 1, NKTOT

        CALL ZGEMM('C', 'N', HDIM, HDIM, HDIM, ALPHA, KXMAT(:,:,II), &
             HDIM, HK(:,:,II), HDIM, BETA, KTMP, HDIM)
        CALL ZGEMM('N', 'N', HDIM, HDIM, HDIM, ALPHA, KTMP, HDIM, &
             KXMAT(:,:,II), HDIM, BETA, KORTHOH(:,:,II), HDIM)

     ENDDO

  ELSE

     DO II = 1, NKTOT

        CALL ZGEMM('C', 'N', HDIM, HDIM, HDIM, ALPHA, KXMAT(:,:,II), &
             HDIM, KHUP(:,:,II), HDIM, BETA, KTMP, HDIM)
        CALL ZGEMM('N', 'N', HDIM, HDIM, HDIM, ALPHA, KTMP, HDIM, &
             KXMAT(:,:,II), HDIM, BETA, KORTHOHUP(:,:,II), HDIM)

        CALL ZGEMM('C', 'N', HDIM, HDIM, HDIM, ALPHA, KXMAT(:,:,II), &
             HDIM, KHDOWN(:,:,II), HDIM, BETA, KTMP, HDIM)
        CALL ZGEMM('N', 'N', HDIM, HDIM, HDIM, ALPHA, KTMP, HDIM, &
             KXMAT(:,:,II), HDIM, BETA, KORTHOHDOWN(:,:,II), HDIM)

     ENDDO

  ENDIF

  DEALLOCATE(KTMP)

  RETURN

END SUBROUTINE KORTHOMYH

