!-----------------------------------------
!
SUBROUTINE PREPARE_WALL_MATERIALS

  USE ParallelOperationValues
  USE CurrentProblemValues

  IMPLICIT NONE

  INTEGER n

  CHARACTER(24) initmaterial_filename     ! init_material_AAAAAA.dat
                                          ! ----x----I----x----I----
  LOGICAl exists
  
  CHARACTER(1) buf 

  CHARACTER(54) bosee_filename    ! _bo_NN_electron_induced_SEE_coefficients_vs_energy.dat
                                  ! ----x----I----x----I----x----I----x----I----x----I----
  INTEGER j
  REAL(8) energy, coef1, coef2, coef3
  
! functions
  REAL(8) Coeff_SEE_Elastic
  REAL(8) Coeff_SEE_Inelastic
  REAL(8) Coeff_SEE_True

  INTERFACE
     FUNCTION convert_int_to_txt_string(int_number, length_of_string)
       CHARACTER*(length_of_string) convert_int_to_txt_string
       INTEGER int_number
       INTEGER length_of_string
     END FUNCTION convert_int_to_txt_string
  END INTERFACE

  DO n = 1, N_of_boundary_objects
     whole_object(n)%eps_diel = 1.0_8
     whole_object(n)%SEE_enabled = .FALSE.
     whole_object(n)%ion_induced_EE_enabled = .FALSE.
     whole_object(n)%Emitted_model = 0  ! sets to zero all electron-induced SEE coefficients

     IF (whole_object(n)%object_type.EQ.VACUUM_GAP) THEN
        IF (Rank_of_process.EQ.0) PRINT '("### PREPARE_WALL_MATERIALS :: no material properties data file for VACUUM_GAP boundary object ",i2)', n
        CYCLE
     END IF

     IF (whole_object(n)%object_type.EQ.PERIODIC_PIPELINE_X) THEN
        IF (Rank_of_process.EQ.0) PRINT '("### PREPARE_WALL_MATERIALS :: no material properties data file for PERIODIC_PIPELINE_X boundary object ",i2)', n
        CYCLE
     END IF

     IF (whole_object(n)%object_type.EQ.PERIODIC_PIPELINE_Y) THEN
        IF (Rank_of_process.EQ.0) PRINT '("### PREPARE_WALL_MATERIALS :: no material properties data file for PERIODIC_PIPELINE_Y boundary object ",i2)', n
        CYCLE
     END IF

     initmaterial_filename = 'init_material_AAAAAA.dat'
     initmaterial_filename(15:20) = whole_object(n)%material

     INQUIRE (FILE = initmaterial_filename, EXIST = exists)
     IF (.NOT.exists) THEN
        IF (Rank_of_process.EQ.0) PRINT '("### PREPARE_WALL_MATERIALS :: file ",A24," not found, use default material properties for boundary object ",i2)', initmaterial_filename, n
        CYCLE
     END IF

! since we are here, file initmaterial_filename exists
! read the file
     IF (Rank_of_process.EQ.0) PRINT '("### PREPARE_WALL_MATERIALS :: file ",A24," found, reading material properties for boundary object ",i2,"...")', initmaterial_filename, n

     OPEN (9, FILE = initmaterial_filename)

     READ (9, '(A77)') buf ! -------d----- ELASTIC ELECTRON REFLECTION MODEL (0/1/2 = turned off/model 1/model 2)
     READ (9, '(7x,i1)') whole_object(n)%Emitted_model(1)
     READ (9, '(A77)') buf ! -------d----- ELASTIC ELECTRON REFLECTION TYPE (0/1 = specular/random)
     READ (9, '(7x,i1)') whole_object(n)%Elast_refl_type

     READ (9, '(A77)') buf ! ============= ELASTIC ELECTRON REFLECTION, MODEL 1, PARAMETERS:
     READ (9, '(A77)') buf ! -------d.ddd- emission coefficient (from 0 to 1), constant for energies between E_min and E_max
     READ (9, '(7x,f5.3)') whole_object(n)%setD_see_elastic
     READ (9, '(A77)') buf ! --dddddd.ddd- lower energy boundary E_min, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%minE_see_elastic
     READ (9, '(A77)') buf ! --dddddd.ddd- upper energy boundary E_max, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%maxE_see_elastic

     READ (9, '(A77)') buf ! ============= ELASTIC ELECTRON REFLECTION, MODEL 2, PARAMETERS:
     READ (9, '(A77)') buf ! --dddddd.ddd- threshold energy, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%E_elast_0
     READ (9, '(A77)') buf ! --dddddd.ddd- energy of maximum of the emission coefficient [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%E_elast_max
     READ (9, '(A77)') buf ! -------d.ddd- maximum of the emission coefficient (from 0 to 1)
     READ (9, '(7x,f5.3)') whole_object(n)%maxD_elast
     READ (9, '(A77)') buf ! --dddddd.ddd- energy scale of decaying part for energy above the coefficient maximum energy, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%dE_elast
     READ (9, '(A77)') buf ! -------d.ddd- additional fraction of the classic emission coefficient, (>=0, <<1)
     READ (9, '(7x,f5.3)') whole_object(n)%Frac_elast_highenergy

     IF (whole_object(n)%Emitted_model(1).EQ.0) whole_object(n)%Frac_elast_highenergy = 0.0_8

     READ (9, '(A77)') buf ! -------d----- INELASTIC ELECTRON REFLECTION MODEL (0/1/2 = turned off/model 1/model 2)
     READ (9, '(7x,i1)') whole_object(n)%Emitted_model(2)

     READ (9, '(A77)') buf ! ============= INELASTIC ELECTRON REFLECTION, MODEL 1, PARAMETERS:
     READ (9, '(A77)') buf ! -------d.ddd- emission coefficient (from 0 to 1), constant for energies between E_min and E_max
     READ (9, '(7x,f5.3)') whole_object(n)%setD_see_inelastic
     READ (9, '(A77)') buf ! --dddddd.ddd- lower energy boundary E_min, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%minE_see_inelastic
     READ (9, '(A77)') buf ! --dddddd.ddd- upper energy boundary E_max, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%maxE_see_inelastic

     READ (9, '(A77)') buf ! ============= INELASTIC ELECTRON REFLECTION, MODEL 2, PARAMETERS:
     READ (9, '(A77)') buf ! -------d.ddd- fraction of the classic emission coefficient (>=0, <<1)
     READ (9, '(7x,f5.3)') whole_object(n)%Frac_inelastic
     
     IF (whole_object(n)%Emitted_model(2).EQ.0) whole_object(n)%Frac_inelastic = 0.0_8

     READ (9, '(A77)') buf ! -------d----- TRUE SECONDARY EMISSION MODEL (0/1/2 = turned off/model 1/model 2)
     READ (9, '(7x,i1)') whole_object(n)%Emitted_model(3)
     READ (9, '(A77)') buf ! --dddddd.ddd- temperature of true secondary electrons, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%T_see_true_eV 

     READ (9, '(A77)') buf ! ============= TRUE SECONDARY EMISSION, MODEL 1, PARAMETERS:
     READ (9, '(A77)') buf ! -------d.ddd- emission coefficient (>=0), constant for energies between E_min and E_max
     READ (9, '(7x,f5.3)') whole_object(n)%setD_see_true
     READ (9, '(A77)') buf ! --dddddd.ddd- lower energy boundary E_min, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%minE_see_true
     READ (9, '(A77)') buf ! --dddddd.ddd- upper energy boundary E_max, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%maxE_see_true

     READ (9, '(A77)') buf ! ============= TRUE SECONDARY EMISSION, MODEL 2 (AND CLASSIC), PARAMETERS
     READ (9, '(A77)') buf ! --dddddd.ddd- threshold energy, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%E_see_0
     READ (9, '(A77)') buf ! --dddddd.ddd- energy of maximum of the emission coefficient, [eV]
     READ (9, '(2x,f10.3)') whole_object(n)%E_see_max
     READ (9, '(A77)') buf ! ------dd.ddd- maximum of the emission coefficient (>0)
     READ (9, '(6x,f6.3)') whole_object(n)%maxD_see_classic
     READ (9, '(A77)') buf ! -------d.ddd- Smoothness factor (0 = very rough, 2 = polished)
     READ (9, '(7x,f5.3)') whole_object(n)%k_smooth

     CLOSE (9, STATUS = 'KEEP')

! make energy values dimensionless
! elastic reflection, model 1
     whole_object(n)%minE_see_elastic = whole_object(n)%minE_see_elastic / energy_factor_eV
     whole_object(n)%maxE_see_elastic = whole_object(n)%maxE_see_elastic / energy_factor_eV

! elastic reflection, model 2
     whole_object(n)%E_elast_0   = whole_object(n)%E_elast_0 / energy_factor_eV
     whole_object(n)%E_elast_max = whole_object(n)%E_elast_max / energy_factor_eV
     whole_object(n)%dE_elast    = whole_object(n)%dE_elast / energy_factor_eV

! inelastic, model 1
     whole_object(n)%minE_see_inelastic = whole_object(n)%minE_see_inelastic / energy_factor_eV
     whole_object(n)%maxE_see_inelastic = whole_object(n)%maxE_see_inelastic / energy_factor_eV

! true secondary emission, model 1
     whole_object(n)%minE_see_true = whole_object(n)%minE_see_true / energy_factor_eV
     whole_object(n)%maxE_see_true = whole_object(n)%maxE_see_true / energy_factor_eV

! true secondary emission, model 2, and the classic coefficient
     whole_object(n)%E_see_0   = whole_object(n)%E_see_0 / energy_factor_eV
     whole_object(n)%E_see_max = whole_object(n)%E_see_max / energy_factor_eV

     whole_object(n)%factor_convert_seetrue_vinj = SQRT(whole_object(n)%T_see_true_eV / T_e_eV) / N_max_vel

! find the energy threshold for any kind of electron induced emissions

     whole_object(n)%lowest_energy_for_see = 1.0d6 / energy_factor_eV   ! start with a ridiculously high value (1 MeV)

     SELECT CASE (whole_object(n)%Emitted_model(1))
        CASE (1)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%minE_see_elastic)
        CASE (2)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%E_elast_0)
     END SELECT

     SELECT CASE (whole_object(n)%Emitted_model(2))
        CASE (1)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%minE_see_inelastic)
        CASE (2)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%E_see_0)
     END SELECT

     SELECT CASE (whole_object(n)%Emitted_model(3))
        CASE (1)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%minE_see_true)
        CASE (2)
           whole_object(n)%lowest_energy_for_see = MIN(whole_object(n)%lowest_energy_for_see, whole_object(n)%E_see_0)
     END SELECT

     IF ((whole_object(n)%Emitted_model(1) + whole_object(n)%Emitted_model(2) + whole_object(n)%Emitted_model(3)).GT.0) whole_object(n)%SEE_enabled = .TRUE.

  END DO

  IF (Rank_of_process.EQ.0) THEN
       DO n = 1, N_of_boundary_objects
          IF (.NOT.whole_object(n)%SEE_enabled) CYCLE

!print '("============= ",4(2x,i2)," ============")', n, whole_object(n)%Emitted_model(1:3)

! save data file with emission coefficients
          bosee_filename = '_bo_NN_electron_induced_SEE_coefficients_vs_energy.dat'
          bosee_filename(5:6) = convert_int_to_txt_string(n, 2)
          OPEN (20, FILE = bosee_filename)
          WRITE (20, '("# col 1 is the primary electron energy [eV]")')
          WRITE (20, '("# col 2 is the total electron-induced secondary electron emission coefficient")')
          WRITE (20, '("# col 3 is the emission coefficient for elastically reflected electrons")')
          WRITE (20, '("# col 4 is the emission coefficient for inelastically reflected electrons")')
          WRITE (20, '("# col 5 is the emission coefficient for true secondary electrons")')
          DO j = 0, 2000
             energy = 0.2_8 * DBLE(j) / energy_factor_eV
             coef1 = Coeff_SEE_Elastic(energy, 0.0_8, n)
             coef2 = Coeff_SEE_Inelastic(energy, 0.0_8, n)
             coef3 = Coeff_SEE_True(energy, 0.0_8, n)
!print '(2(2x,i5),4(2x,e10.3))', n, j, energy, coef1, coef2, coef3
             WRITE (20, '(5(2x,f10.4))') energy * energy_factor_eV, coef1 + coef2 + coef3, coef1, coef2, coef3
          END DO
          CLOSE (20, STATUS = 'KEEP')
          PRINT '("### file ",A54," is ready ###")', bosee_filename
!stop
       END DO
  END IF

END SUBROUTINE PREPARE_WALL_MATERIALS
