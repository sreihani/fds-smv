! VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
! FDS modules used by tetrahedron box volume routine

!  ------------------ PRECISION_PARAMETERS ------------------------ 

MODULE PRECISION_PARAMETERS
IMPLICIT NONE

! Precision of "Four Byte" and "Eight Byte" reals

INTEGER, PARAMETER :: FB = SELECTED_REAL_KIND(6)
INTEGER, PARAMETER :: EB = SELECTED_REAL_KIND(12)
INTEGER :: LU_OUTPUT=6
END MODULE PRECISION_PARAMETERS

MODULE COMP_FUNCTIONS

USE PRECISION_PARAMETERS 
IMPLICIT NONE 

CONTAINS

REAL(EB) FUNCTION SECOND()  ! Returns the CPU time in seconds.
!$ USE OMP_LIB
REAL(FB) CPUTIME
CALL CPU_TIME(CPUTIME)
SECOND = CPUTIME
!$ SECOND = OMP_GET_WTIME()
END FUNCTION SECOND

END MODULE COMP_FUNCTIONS

MODULE MATH_FUNCTIONS

USE PRECISION_PARAMETERS
IMPLICIT NONE 
 
CONTAINS

SUBROUTINE CROSS_PRODUCT(C,A,B)

REAL(EB), INTENT(IN) :: A(3),B(3)
REAL(EB), INTENT(OUT) :: C(3)
! C = A x B
C(1) = A(2)*B(3)-A(3)*B(2)
C(2) = A(3)*B(1)-A(1)*B(3)
C(3) = A(1)*B(2)-A(2)*B(1)
END SUBROUTINE CROSS_PRODUCT

END MODULE MATH_FUNCTIONS

