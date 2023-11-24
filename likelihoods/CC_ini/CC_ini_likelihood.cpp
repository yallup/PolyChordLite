# include "CC_ini_likelihood.hpp"
# include <cmath>

// This module is where your likelihood code should be placed.
//
// * The loglikelihood is called by the subroutine loglikelihood.
// * The likelihood is set up by setup_loglikelihood.
// * You can store any global/saved variables in the module.


//============================================================
// insert likelihood variables here
//
//
//============================================================





// Main loglikelihood function
//
// Either write your likelihood code directly into this function, or call an
// external library from it. This should return the logarithm of the
// likelihood, i.e:
//
// loglikelihood = log_e ( P (data | parameters, model ) )
//
// theta are the values of the input parameters (in the physical space 
// NB: not the hypercube space).
//
// nDims is the size of the theta array, i.e. the dimensionality of the parameter space
//
// phi are any derived parameters that you would like to save with your
// likelihood.
//
// nDerived is the size of the phi array, i.e. the number of derived parameters
//
// The return value should be the loglikelihood
//
// This function is called from likelihoods/fortran_cpp_wrapper.f90
// If you would like to adjust the signature of this call, then you should adjust it there,
// as well as in likelihoods/my_cpp_likelihood.hpp
// 
double potential(double field) 
{
    // double musq = -4.0;
    // double lambda = 1.0;
    double lambda = 1.5;
    double V = lambda * pow(field * field - 1, 2) +  field * field;
    // double V = lambda * field * field * field * field  + 0.5 * musq * field * field;


    return V;
}


double laplacian(double* theta, int n, int i, int j, int k, int l) {
    double kinetic = 0.0;

    int idx = i * n * n * n + j * n * n + k * n + l;

    int idx_i_up = ((i+1) % n) * n * n * n + j * n * n + k * n + l;
    int idx_i_down = ((i-1 + n) % n) * n * n * n + j * n * n + k * n + l;
    int idx_j_up = i * n * n * n + ((j+1) % n) * n * n + k * n + l;
    int idx_j_down = i * n * n * n + ((j-1 + n) % n) * n * n + k * n + l;
    int idx_k_up = i * n * n * n + j * n * n + ((k+1) % n) * n + l;
    int idx_k_down = i * n * n * n + j * n * n + ((k-1 + n) % n) * n + l;
    int idx_l_up = i * n * n * n + j * n * n + k * n + ((l+1) % n);
    int idx_l_down = i * n * n * n + j * n * n + k * n + ((l-1 + n) % n);

    // kinetic += 8 * theta[idx] * theta[idx];
    kinetic -= theta[idx] * theta[idx_i_up];
    kinetic -= theta[idx] * theta[idx_i_down];
    kinetic -= theta[idx] * theta[idx_j_up];
    kinetic -= theta[idx] * theta[idx_j_down];
    kinetic -= theta[idx] * theta[idx_k_up];
    kinetic -= theta[idx] * theta[idx_k_down];
    kinetic -= theta[idx] * theta[idx_l_up];
    kinetic -= theta[idx] * theta[idx_l_down];

    return kinetic;
}


double magnetisation(double* theta, int n) 
{
    double mag = 0.0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            mag += theta[i * n + j];
        }
    }

    return mag / (n*n);
}


double loglikelihood (double theta[], int nDims, double phi[], int nDerived)
{
    // assume n x n = nDims grid for now.
    double fieldAction = 0.0;

    double kappa = 2.0;
    // int n = sqrt(nDims);
    int n = std::round(std::pow(nDims, 0.25));

    // kinetic term
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            for (int k = 0; k < n; k++) {
                for (int l =0; l < n; l++) {
                    fieldAction += kappa * laplacian(theta, n, i, j, k, l);
                }
            }            
        }
    }

    // potential term
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            for (int k = 0; k < n; k++) {
                for (int l = 0; l < n; l++) {
                    fieldAction += potential(theta[i * n * n * n + j * n * n + k * n + l]);
                }
            }
        }
    }

    //lagrangian becomes to T + V after wick rotation

    //lambda=inf gives V(|1|)=0 else inf, so only phi=|1| has non infinite action (non-zero prob)
    //therefore we recover ising model with kappa = 1/T 

    phi[0] = magnetisation(theta, n);

    return -fieldAction;
}

// Prior function
//
// Either write your prior code directly into this function, or call an
// external library from it. This should transform a coordinate in the unit hypercube
// stored in cube (of size nDims) to a coordinate in the physical system stored in theta
//
// This function is called from likelihoods/fortran_cpp_wrapper.f90
// If you would like to adjust the signature of this call, then you should adjust it there,
// as well as in likelihoods/my_cpp_likelihood.hpp
// 
void prior (double cube[], double theta[], int nDims)
{
    //============================================================
    // insert prior code here
    //
    //
    //============================================================
    for(int i=0;i<nDims;i++)
        theta[i] = cube[i];

}

// Dumper function
//
// This function gives you runtime access to variables, every time the live
// points are compressed by a factor settings.compression_factor.
//
// To use the arrays, subscript by following this example:
//
//    for (int i_dead=0;i_dead<ndead;i_dead++)
//    {
//        for (int j_par=0;j_par<npars;j_par++)
//            std::cout << dead[npars*i_dead+j_par] << " ";
//        std::cout << std::endl;
//    }
//
// in the live and dead arrays, the rows contain the physical and derived
// parameters for each point, followed by the birth contour, then the
// loglikelihood contour
//
// logweights are posterior weights
// 
void dumper(int ndead,int nlive,int npars,double* live,double* dead,double* logweights,double logZ, double logZerr)
{
}


// Ini path reading function
//
// If you want the file path to the ini file (for example for pointing to other config files), store ite value in a global variable with this function
void set_ini(std::string ini_str_in)
{
    /**
    Set value for constant holding ini file path.

    @param ini_str_in: ini file path
    **/
}
// Setup of the loglikelihood
// 
// This is called before nested sampling, but after the priors and settings
// have been set up.
// 
// This is the time at which you should load any files that the likelihoods
// need, and do any initial calculations.
// 
// This module can be used to save variables in between calls
// (at the top of the file).
// 
// All MPI threads will call this function simultaneously, but you may need
// to use mpi utilities to synchronise them. This should be done through the
// integer mpi_communicator (which is normally MPI_COMM_WORLD).
//
// This function is called from likelihoods/fortran_cpp_wrapper.f90
// If you would like to adjust the signature of this call, then you should adjust it there,
// as well as in likelihoods/my_cpp_likelihood.hpp
//
void setup_loglikelihood()
{
    //============================================================
    // insert likelihood setup here
    //
    //
    //============================================================
}
