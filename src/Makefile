FC := mpifort
CC := mpicc
# Get the actual Fortran compiler invoked by mpifort. Need to use double $$ in awk.
BASE_FCOMP := $(shell mpifort -show | awk '{print $$1}' | awk -F/ '{print $$NF}')

# Make sure that the PETSC_DIR environment variable is set. Otherwise exit with error message.
ifeq ($(strip $(PETSC_DIR)),)
   $(error Please set the PETSC_DIR environment variable)
endif

ifeq ($(BASE_FCOMP),ifort)
   $(info "Using Intel compiler" )
   FFLAGS := -O2 -I${PETSC_DIR}/include
   CFLAGS := -O2
else ifeq ($(BASE_FCOMP),gfortran)
   $(info "Using gcc/gfortran compilers" )
   FFLAGS := -O2 -ffree-line-length-none -I${PETSC_DIR}/include
   CFLAGS := -O2
else
   FFLAGS := -O2 -I${PETSC_DIR}/include
   CFLAGS := -O2
endif

# The only external functions explicitly called by EDIPIC2D are from MPI and PETSc.
# However, PETSc will internally call functions from HYPRE, LAPACK, and BLAS. In the
# case of the INTEL compiler, the MKL library can replace LAPACK and BLAS, although
# HYPRE includes its own copy of the LAPACK and BLAS source files.
# These library dependencies can be satisfied via shared libraries by listing them
# in the LD_LIBRARY_PATH environment variable.
# Before linking and running, make sure to set:
#    export LD_LIBRARY_PATH=${PETSC_DIR}/lib:${LD_LIBRARY_PATH}    # for bash
#    setenv LD_LIBRARY_PATH ${PETSC_DIR}/lib:${LD_LIBRARY_PATH}    # for csh

LIBS := -L${PETSC_DIR}/lib -lpetsc -lHYPRE

OBJ := WELL19937a_new.o pic2d_Modules.o pic2d_Snapshots.o pic2d_Prepare_FFTX_SYSY.o \
       pic2d_RandomNumberInterface.o pic2d_TimeDependences.o pic2d_VelocityDistributions.o \
       pic2d_Setup.o pic2d_WallPotentials.o pic2d_ParticleExchange.o pic2d_BlockSetProc.o \
       pic2d_IonMoments.o pic2d_Checkpoints.o pic2d_IonWallCollisions.o pic2d_LoadBalancing.o \
       pic2d_Diagnostics.o pic2d_MainProgram.o pic2d_ElectricFieldCalc_FFT_X.o \
       pic2d_Materials.o pic2d_ElectronDynamics.o pic2d_ElectronExchange.o \
       pic2d_ElectronMoments.o pic2d_ElectronWallCollisions.o pic2d_enCollisionsGeneralProc.o \
       pic2d_enCollisionsSpecificProc.o pic2d_ExternalFields.o pic2d_HTSetup.o \
       pic2d_IonDynamics.o pic2d_PETSc_Solver.o pic2d_ElectricFieldCalc_PETSc.o \
       pic2d_CurProblemValues.o pic2d_SEEmission.o

edipic2d : $(OBJ)
	$(FC) $(FFLAGS) -o $@ $(OBJ) $(LIBS)

%.o : %.f90
	$(FC) $(FFLAGS) -c $< 

%.o : %.F90
	$(FC) $(FFLAGS) -c $< 

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.mod *.o edipic2d

