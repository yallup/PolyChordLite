import anesthetic
import numpy as np
import matplotlib.pyplot as plt

# chains = anesthetic.read_chains("chains/phi4")
chains = anesthetic.read_chains("phi4_samples.csv")
lmda = 0.5
kappa = 1.0
mag_col_index = chains.columns[-4]
betas = np.linspace(0, 1, 50)

mags = np.asarray([np.abs(chains.set_beta(i)[mag_col_index]).mean() for i in betas])
# logZs = np.asarray([chains.set_beta(i).logZ() for i in betas])
f, a = plt.subplots(nrows=1, ncols=1, figsize=[4, 3])
finite_diff = np.diff(mags)

a.plot(betas[:-1], finite_diff)
# a.plot(betas,logZs)
f.suptitle(f"$\kappa={kappa},\lambda={lmda}$")
# a.legend()
a.set_ylabel(r"$\partial |m|/\partial \beta$")
a.set_xlabel(r"$\beta$")
# a.set_xlim(0, cutoff)
f.tight_layout(pad=0.15)
f.savefig("phase.pdf")
