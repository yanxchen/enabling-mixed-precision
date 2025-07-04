module comm
  use mpi_f08
  use utils, only : neko_error
  use neko_config
  !$ use omp_lib
  implicit none
  
  interface
     subroutine neko_comm_wrapper_init(fcomm) &
          bind(c, name='neko_comm_wrapper_init')
       integer, value :: fcomm
     end subroutine neko_comm_wrapper_init
  end interface
  
  !> MPI communicator
  type(MPI_Comm) :: NEKO_COMM

  !> MPI type for working precision of REAL types
#ifdef HAVE_MPI_PARAM_DTYPE
  type(MPI_Datatype), parameter :: MPI_REAL_PRECISION = MPI_DOUBLE_PRECISION
  type(MPI_Datatype), parameter :: MPI_EXTRA_PRECISION = MPI_DOUBLE_PRECISION
#else
  type(MPI_Datatype) :: MPI_REAL_PRECISION
  type(MPI_Datatype) :: MPI_EXTRA_PRECISION
#endif
  
  !> MPI rank
  integer :: pe_rank

  !> MPI size of communicator
  integer :: pe_size

  !> I/O node
  logical :: nio

contains
  subroutine comm_init
    integer :: ierr
    logical :: initialized
    integer :: provided, nthrds

    pe_rank = -1
    pe_size = 0
    nio = .false.

    call MPI_Initialized(initialized, ierr)

    nthrds = 1
    !$omp parallel
    !$omp master
    !$ nthrds = omp_get_num_threads()
    !$omp end master
    !$omp end parallel
    
    if (.not.initialized) then       
       if (nthrds .gt. 1) then
          call MPI_Init_thread(MPI_THREAD_MULTIPLE, provided, ierr)
          if (provided .ne. MPI_THREAD_MULTIPLE) then
             ! MPI_THREAD_MULTIPLE is required for mt. device backends
             if (NEKO_BCKND_DEVICE .eq. 1) then 
                call neko_error('Invalid thread support provided by MPI')
             else
                call MPI_Init_thread(MPI_THREAD_SERIALIZED, provided, ierr)
                if (provided .ne. MPI_THREAD_SERIALIZED) then
                   call neko_error('Invalid thread support provided by MPI')
                end if
             end if
          end if
       else
          call MPI_Init(ierr)
       end if
    end if

#ifndef HAVE_MPI_PARAM_DTYPE
    MPI_REAL_PRECISION = MPI_DOUBLE_PRECISION
    MPI_EXTRA_PRECISION = MPI_DOUBLE_PRECISION
#endif
    

#ifdef HAVE_ADIOS2
    ! We split the communicator it to work asynchronously (MPMD)
    call MPI_Comm_rank(MPI_COMM_WORLD, pe_rank, ierr)
    call MPI_Comm_split(MPI_COMM_WORLD, 0, pe_rank, NEKO_COMM, ierr)
#else    
    ! Original version duplicates the communicator:
    call MPI_Comm_dup(MPI_COMM_WORLD, NEKO_COMM, ierr)
#endif

    call MPI_Comm_rank(NEKO_COMM, pe_rank, ierr)
    call MPI_Comm_size(NEKO_COMM, pe_size, ierr)

    ! Setup C/C++ wrapper
    call neko_comm_wrapper_init(NEKO_COMM%mpi_val)

  end subroutine comm_init

  subroutine comm_free
    integer :: ierr

    call MPI_Barrier(NEKO_COMM, ierr)
    call MPI_Comm_free(NEKO_COMM, ierr)
    call MPI_Finalize(ierr)

  end subroutine comm_free

end module comm
