import anesthetic
import numpy as np
import matplotlib.pyplot as plt

chains = anesthetic.read_chains("chains/my_likelihood")

cutoff = 0.2
betas = np.linspace(0.08, cutoff, 100)[::-1]
# ave_mags=[alpha0.set_beta(i)[mag_col_name].mean() for i in betas]
lattice_dim=3**4
mags= [chains.set_beta(i)[np.arange(lattice_dim)].mean(axis=1).mean() for i in betas]
# Zs = [chains.set_beta(i).logZ(100) for i in betas]
# Zs_mean = np.asarray([x.mean() for x in Zs])
# Zs_std = np.asarray([x.std() for x in Zs])
f, a = plt.subplots(nrows=1, ncols=1, figsize=[3, 2])
# a.plot(betas, Zs_mean, label="$D=4, n_{\mathrm{live}}=100$")
a.plot(betas, mags, label="$D=4, n_{\mathrm{live}}=100$")
# a.fill_between(betas, Zs_mean - Zs_std, Zs_mean + Zs_std, alpha=0.5)
f.suptitle("$w=3,\lambda=1.5$")
# a.legend()
a.set_ylabel(r"$|m|$")
a.set_xlabel(r"$\kappa$")
a.set_xlim(0, cutoff)
f.tight_layout(pad=0.15)
f.savefig("phase.pdf")
