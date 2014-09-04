module chordal_module
    implicit none

    double precision, allocatable, dimension(:,:) ::  nhats_global


    contains

    function ChordalSampling(loglikelihood,settings,seed_point,nhats,M)  result(baby_point)
        use settings_module, only: program_settings
        use random_module, only: random_direction
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit

        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The seed point
        double precision, intent(in), dimension(:)   :: seed_point

        !> The directions of the chords
        double precision, intent(in), dimension(:,:) :: nhats

        ! ------- Outputs -------
        !> The newly generated point, plus the loglikelihood bound that
        !! generated it
        double precision,    dimension(M%nTotal)   :: baby_point


        ! ------- Local Variables -------
        double precision,    dimension(M%nDims)   :: nhat

        double precision  :: max_chord

        double precision :: step_length

        integer :: i_chords

        ! Start the baby point at the seed point
        baby_point = seed_point

        ! Set the number of likelihood evaluations to zero
        baby_point(M%nlike) = 0

        ! Record the step length
        step_length = seed_point(M%last_chord)

        ! Initialise max_chord at 0
        max_chord = 0

        do i_chords=1,settings%num_chords
            ! Give the baby point the step length
            baby_point(M%last_chord) = step_length

            ! Get a new random direction
            nhat = nhats(:,i_chords)

            ! Generate a new random point along the chord defined by baby_point and nhat
            baby_point = random_chordal_point(loglikelihood, nhat, baby_point, M)

            ! keep track of the largest chord
            max_chord = max(max_chord,baby_point(M%last_chord))
        end do

#ifdef MPI
        ! Make sure to hand back any incubator information which has likely been
        ! overwritten
        baby_point(M%daughter) = seed_point(M%daughter)
#endif

        ! Hand back the maximum chord this time to be used as the step length
        ! next time this point is drawn
        baby_point(M%last_chord) = max_chord

    end function ChordalSampling

    function ChordalSamplingBiased(loglikelihood,settings,seed_point, M)  result(baby_point)
        use settings_module, only: program_settings
        use random_module, only: random_direction
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit

        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The seed point
        double precision, intent(in), dimension(M%nTotal)   :: seed_point

        ! ------- Outputs -------
        !> The newly generated point, plus the loglikelihood bound that
        !! generated it
        double precision,    dimension(M%nTotal)   :: baby_point


        ! ------- Local Variables -------
        double precision,    dimension(M%nDims)   :: nhat

        double precision  :: max_chord

        double precision :: step_length

        integer :: i

        ! Start the baby point at the seed point
        baby_point = seed_point

        ! Set the number of likelihood evaluations to zero
        baby_point(M%nlike) = 0

        ! Record the step length
        step_length = seed_point(M%last_chord)

        ! Initialise max_chord at 0
        max_chord = 0

        do i=1,settings%num_chords
            ! Give the baby point the step length
            baby_point(M%last_chord) = step_length

            ! Get a new random direction
            nhat = nhats_global(:,i)

            ! Generate a new random point along the chord defined by baby_point and nhat
            baby_point = random_chordal_point(loglikelihood, nhat, baby_point, M)

            ! keep track of the largest chord
            max_chord = max(max_chord,baby_point(M%last_chord))
        end do

#ifdef MPI
        ! Make sure to hand back any incubator information which has likely been
        ! overwritten
        baby_point(M%daughter) = seed_point(M%daughter)
#endif

        ! Hand back the maximum chord this time to be used as the step length
        ! next time this point is drawn
        baby_point(M%last_chord) = max_chord

    end function ChordalSamplingBiased


    function ChordalSamplingFastSlow(loglikelihood,settings,seed_point, M)  result(baby_point)
        use settings_module, only: program_settings
        use random_module, only: random_gaussian
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit

        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The seed point
        double precision, intent(in), dimension(M%nTotal)   :: seed_point

        ! ------- Outputs -------
        !> The newly generated point, plus the loglikelihood bound that
        !! generated it
        double precision,    dimension(M%nTotal)   :: baby_point


        ! ------- Local Variables -------
        double precision,    dimension(M%nDims,product(settings%nums_chords))   :: nhats

        double precision  :: max_chord

        double precision :: step_length

        integer :: i


        ! Start the baby point at the seed point
        baby_point = seed_point

        ! Set the number of likelihood evaluations to zero
        baby_point(M%nlike) = 0

        ! Record the step length
        step_length = seed_point(M%last_chord)

        ! Initialise max_chord at 0
        max_chord = 0

        ! Generate the set of nhats to use
        nhats=0
        do i=1,M%nDims
            nhats(i,: product(settings%nums_chords) : product(settings%nums_chords)/product(settings%nums_chords(:M%grade(i))) ) &
                = random_gaussian(product(settings%nums_chords(:M%grade(i))))
        end do
        do i=1,product(settings%nums_chords)
            nhats(:,i) = nhats(:,i)/sqrt(dot_product(nhats(:,i),nhats(:,i)))
        end do

        do i=1,product(settings%nums_chords)
            ! Give the baby point the step length
            baby_point(M%last_chord) = step_length

            ! Generate a new random point along the chord defined by baby_point and nhat
            baby_point = random_chordal_point(loglikelihood, nhats(:,i), baby_point, M)

            ! keep track of the largest chord
            max_chord = max(max_chord,baby_point(M%last_chord))
        end do

#ifdef MPI
        ! Make sure to hand back any incubator information which has likely been
        ! overwritten
        baby_point(M%daughter) = seed_point(M%daughter)
#endif

        ! Hand back the maximum chord this time to be used as the step length
        ! next time this point is drawn
        baby_point(M%last_chord) = max_chord

    end function ChordalSamplingFastSlow


    function ChordalSamplingReflective(loglikelihood,settings,seed_point, M)  result(baby_point)
        use settings_module, only: program_settings
        use random_module, only: random_direction,random_subdirection
        use model_module,  only: model, calculate_point,gradloglike
        use utils_module, only: logzero,stdout_unit

        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The seed point
        double precision, intent(in), dimension(M%nTotal)   :: seed_point

        ! ------- Outputs -------
        !> The newly generated point, plus the loglikelihood bound that
        !! generated it
        double precision,    dimension(M%nTotal)   :: baby_point


        ! ------- Local Variables -------
        double precision,    dimension(M%nDims)   :: nhat
        double precision,    dimension(M%nDims)   :: gradL
        double precision                          :: gradL2

        double precision  :: max_chord

        double precision :: step_length

        integer :: i

        ! Start the baby point at the seed point
        baby_point = seed_point

        ! Set the number of likelihood evaluations to zero
        baby_point(M%nlike) = 0


        ! Record the step length
        step_length = seed_point(M%last_chord)

        ! Initialise max_chord at 0
        max_chord = 0

        ! Get a new random direction
        nhat = random_direction(M%nDims) 


        do i=1,settings%num_chords*settings%num_randomisations
            ! Give the baby point the step length
            baby_point(M%last_chord) = step_length

            ! Generate a new nhat by reflecting the old one
            if(mod(i,settings%num_chords)==1) then
                nhat = random_direction(M%nDims)
            else
                ! Get the grad loglikelihood
                gradL = gradloglike(loglikelihood,M,baby_point(M%p0:M%p1),baby_point(M%l0),step_length*1d-3)
                baby_point(M%nlike) = baby_point(M%nlike)+M%nDims

                ! Normalise the grad loglikelihood
                gradL2 = dot_product(gradL,gradL)

                if (gradL2 /= 0d0 ) then
                    !gradLperp = random_subdirection(M%nDims,gradL)
                    !nhat = sqrt(1-(dot_product(gradL,nhat))**2/gradL2 )* gradLperp + dot_product(gradL,nhat)/gradL2 * gradL
                    nhat = nhat - 2d0* dot_product(gradL,nhat)/gradL2 * gradL
                else
                    nhat = random_direction(M%nDims)
                end if

            end if

            ! Generate a new random point along the chord defined by baby_point and nhat
            baby_point = random_chordal_point(loglikelihood, nhat, baby_point, M)

            ! keep track of the largest chord
            max_chord = max(max_chord,baby_point(M%last_chord))
        end do

#ifdef MPI
        ! Make sure to hand back any incubator information which has likely been
        ! overwritten
        baby_point(M%daughter) = seed_point(M%daughter)
#endif

        ! Hand back the maximum chord this time to be used as the step length
        ! next time this point is drawn
        baby_point(M%last_chord) = max_chord

    end function ChordalSamplingReflective






    function random_chordal_point(loglikelihood,nhat,seed_point,M) result(baby_point)
        use model_module,  only: model, calculate_point
        use utils_module,  only: logzero, distance
        use random_module, only: random_real
        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M
        !> The direction to search for the root in
        double precision, intent(in),    dimension(M%nDims)   :: nhat
        !> The start point
        double precision, intent(in),    dimension(M%nTotal)   :: seed_point

        ! The output finish point
        double precision,    dimension(M%nTotal)   :: baby_point

        ! The upper bound
        double precision,    dimension(M%nTotal)   :: u_bound
        ! The lower bound
        double precision,    dimension(M%nTotal)   :: l_bound

        double precision :: trial_chord_length

        ! estimate at an appropriate chord
        trial_chord_length = seed_point(M%last_chord)/2d0

        ! record the number of likelihood calls
        u_bound(M%nlike) = seed_point(M%nlike)
        l_bound(M%nlike) = 0


        ! Select initial start and end points
        l_bound(M%h0:M%h1) = seed_point(M%h0:M%h1) - random_real() * trial_chord_length * nhat 
        u_bound(M%h0:M%h1) = l_bound(M%h0:M%h1) + trial_chord_length * nhat 

        ! Calculate initial likelihoods
        call calculate_point(loglikelihood,M,u_bound)
        call calculate_point(loglikelihood,M,l_bound)

        ! expand u_bound until it's outside the likelihood region
        do while(u_bound(M%l0) > seed_point(M%l1) )
            u_bound(M%h0:M%h1) = u_bound(M%h0:M%h1) + nhat * trial_chord_length
            call calculate_point(loglikelihood,M,u_bound)
        end do

        ! expand l_bound until it's outside the likelihood region
        do while(l_bound(M%l0) > seed_point(M%l1) )
            l_bound(M%h0:M%h1) = l_bound(M%h0:M%h1) - nhat * trial_chord_length
            call calculate_point(loglikelihood,M,l_bound)
        end do

        ! Sample within this bound
        baby_point = find_positive_within(l_bound,u_bound)

        ! Pass on the loglikelihood bound
        baby_point(M%l1) = seed_point(M%l1)

        ! Estimate the next appropriate chord
        baby_point(M%last_chord) = distance( u_bound(M%h0:M%h1),l_bound(M%h0:M%h1) )!distance( baby_point(M%h0:M%h1),seed_point(M%h0:M%h1) )

        contains

        recursive function find_positive_within(l_bound,u_bound) result(finish_point)
            implicit none
            !> The upper bound
            double precision, intent(inout), dimension(M%nTotal)   :: u_bound
            !> The lower bound
            double precision, intent(inout), dimension(M%nTotal)   :: l_bound

            ! The output finish point
            double precision,    dimension(M%nTotal)   :: finish_point

            double precision :: random_temp

            ! Draw a random point within l_bound and u_bound
            random_temp =random_real()
            finish_point(M%h0:M%h1) = l_bound(M%h0:M%h1)*(1d0-random_temp) + random_temp * u_bound(M%h0:M%h1)

            ! Pass on the number of likelihood calls that have been made
            finish_point(M%nlike) = l_bound(M%nlike) + u_bound(M%nlike)
            ! zero the likelihood calls for l_bound and u_bound, as these are
            ! now stored in point
            l_bound(M%nlike) = 0
            u_bound(M%nlike) = 0


            ! calculate the likelihood 
            call calculate_point(loglikelihood,M,finish_point)

            ! If we're not within the likelihood bound then we need to sample further
            if( finish_point(M%l0) <= seed_point(M%l1) ) then

                if ( dot_product(finish_point(M%h0:M%h1)-seed_point(M%h0:M%h1),nhat) > 0d0 ) then
                    ! If finish_point is on the u_bound side of seed_point, then
                    ! contract u_bound
                    u_bound = finish_point
                else
                    ! If finish_point is on the l_bound side of seed_point, then
                    ! contract l_bound
                    l_bound = finish_point
                end if

                ! Call the function again
                finish_point = find_positive_within(l_bound,u_bound)

            end if
            ! otherwise finish_point is returned

        end function find_positive_within


    end function random_chordal_point

    function SphericalSampling(loglikelihood,settings,seed_point,nhats,M)  result(baby_point)
        use settings_module, only: program_settings
        use random_module, only: random_point_in_sphere
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit

        implicit none
        interface
            function loglikelihood(theta,phi,context)
                double precision, intent(in),  dimension(:) :: theta
                double precision, intent(out),  dimension(:) :: phi
                integer,          intent(in)                 :: context
                double precision :: loglikelihood
            end function
        end interface

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The seed point
        double precision, intent(in), dimension(:)   :: seed_point

        !> The directions of the chords
        double precision, intent(in), dimension(:,:) :: nhats

        ! ------- Outputs -------
        !> The newly generated point, plus the loglikelihood bound that
        !! generated it
        double precision,    dimension(M%nTotal)   :: baby_point


        ! ------- Local Variables -------
        double precision :: step_length

        ! Start the baby point at the seed point
        baby_point = seed_point

        ! Set the number of likelihood evaluations to zero
        baby_point(M%nlike) = 0

        ! Record the step length
        step_length = seed_point(M%last_chord)

        ! Generate a new point within a sphere centered on 0.5
        baby_point(M%l0)=seed_point(M%l1)
        do while (baby_point(M%l0) <= seed_point(M%l1) )
            baby_point(M%h0:M%h1) = random_point_in_sphere(M%nDims)*step_length + 0.5d0
            call calculate_point(loglikelihood,M,baby_point)
        end do



    end function SphericalSampling


    ! Direction generators

    !> Generate a set of isotropic nhats
    subroutine isotropic_nhats(settings,M,live_data,nhats)
        use settings_module, only: program_settings
        use random_module, only: random_direction
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit
        implicit none

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The live points
        double precision, intent(in), dimension(:,:) :: live_data

        !> The set of nhats to be generated
        double precision, intent(out), dimension(:,:) :: nhats


        integer i_nhat

        do i_nhat=1,settings%num_chords 
            nhats(:,i_nhat) = random_direction(M%nDims)
        end do

    end subroutine isotropic_nhats

    !> Generate a set of nhats that roughly agree with the longest directions of
    !! a uni-modal distribution
    subroutine unimodal_nhats(settings,M,live_data,nhats)
        use settings_module, only: program_settings
        use random_module, only: random_gaussian
        use model_module,  only: model, calculate_point
        use utils_module, only: logzero,stdout_unit,loginf
        implicit none

        ! ------- Inputs -------
        !> program settings (mostly useful to pass on the number of live points)
        class(program_settings), intent(in) :: settings

        !> The details of the model (e.g. number of dimensions,loglikelihood,etc)
        type(model),            intent(in) :: M

        !> The live points
        double precision, intent(in), dimension(:,:) :: live_data

        !> The set of nhats to be generated
        double precision, intent(out), dimension(:,:) :: nhats

        double precision :: temp_basis(M%nDims,M%nDims)
        double precision :: basis(M%nDims,M%nDims)
        double precision :: temp_lengths(M%nDims)
        double precision :: lengths(M%nDims)
        double precision :: mean(M%nDims)
        integer :: min_pos(1)
        integer :: max_pos(1)
        double precision :: max_val
        double precision :: min_val

        integer :: i,j


        ! Find the mean vector
        mean=sum(live_data(M%h0:M%h1,:),dim=2)/settings%nlive

        ! initialise the smallest likelihood
        min_val=logzero

        ! Find the outward facing vectors
        do i=1,M%nDims

            ! find the smallest position
            min_pos=minloc(live_data(M%l0,:),mask=live_data(M%l0,:)>min_val)
            min_val = live_data(M%l0,min_pos(1))

            ! define the basis vector as extending from the mean to this
            ! position
            basis(:,i) = live_data(M%h0:M%h1,min_pos(1)) - mean

            ! get the length
            lengths(i) = sqrt(dot_product(basis(:,i),basis(:,i)))

            !normalise
            !basis(:,i) = basis(:,i)!/lengths(i)

        end do
!       ! orthogonalise the basis, starting with the largest length
!       temp_basis=basis
!       temp_lengths=lengths
!       basis=0
!       lengths=0
!
!       max_val=loginf
!
!       ! Order the basis by chord length
!       do i=1,M%nDims
!           max_pos = maxloc(temp_lengths,temp_lengths<max_val)
!           max_val = temp_lengths(max_pos(1))
!           basis(:,i) = temp_basis(:,max_pos(1))
!           !lengths(i) = temp_lengths(max_pos(1))
!       end do
!
!       ! Orthogonalise the basis, starting with the longest length
!       do i=1,M%nDims
!           do j= 1,i-1
!               basis(:,i) = basis(:,i)- dot_product(basis(:,i),basis(:,j))/dot_product(basis(:,j),basis(:,j)) * basis(:,j)
!           end do
!           !basis(:,i) = basis(:,i) !/ sqrt(dot_product(basis(:,i),basis(:,i))) 
!       end do

        ! Rescale the basis
        !do i=1,M%nDims
        !    basis(:,i) = basis(:,i) * lengths(new_pos(i))
        !end do

        ! Choose a selection of nhats transformed by the basis
        do i=1,settings%num_chords
            ! generate a random direction
            nhats(:,i) = random_gaussian(M%nDims)
            ! linearly rescale it
            !nhats(:,i) = nhats(:,i)* lengths(:)
            ! transform using the basis
            nhats(:,i) = matmul(basis,nhats(:,i))
            ! normalise
            nhats(:,i) = nhats(:,i)/sqrt(dot_product(nhats(:,i),nhats(:,i)))
            !nhats(:,i) = basis(:,1+mod(i,M%nDims))
            !nhats(:,i) = nhats(:,i)/sqrt(dot_product(nhats(:,i),nhats(:,i))) 
        end do



    end subroutine unimodal_nhats

end module chordal_module

