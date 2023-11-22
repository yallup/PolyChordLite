import anesthetic
import numpy as np
import matplotlib.pyplot as plt

chains = anesthetic.read_chains("chains/my_likelihood")


betas = np.linspace(0.0, 2.0, 100)[::-1]
# ave_mags=[alpha0.set_beta(i)[mag_col_name].mean() for i in betas]

Zs = [chains.set_beta(i).logZ(100) for i in betas]
Zs_mean = np.asarray([x.mean() for x in Zs])
Zs_std = np.asarray([x.std() for x in Zs])
f, a = plt.subplots(nrows=1, ncols=1, figsize=[3, 2])
a.plot(betas, Zs_mean, label="$4D$")
a.fill_between(betas, Zs_mean - Zs_std, Zs_mean + Zs_std, alpha=0.5)

a.legend()
a.set_ylabel(r"$\ln Z(\beta)$")
a.set_xlabel(r"Inverse temperature $(\beta)$")
a.set_xlim(0, 2)
f.tight_layout(pad=0.15)
f.savefig("phase.pdf")
