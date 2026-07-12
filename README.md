[![Build Status](https://travis-ci.com/pulp-platform/riscv.svg?branch=master)](https://travis-ci.com/pulp-platform/riscv)

# Athanor CV32E40P: Public RISC-V Evidence Packets

CV32E40P is a real open-source 32-bit RISC-V core. This fork preserves the
upstream CORE-V source tree and adds public Athanor evidence packets for bounded
RTL rewrites on CV32E40P blocks.

The public surface is intentionally narrow: input RTL snapshots, candidate RTL
snapshots, selected-toolchain measurements, scoped equivalence evidence,
negative controls, hash manifests, and replay commands. It does not include
agent orchestration, prompts, proposer internals, or private review process.

## Evidence Bar

Every packet states its scope. A bounded parent-context packet is not a
whole-core result. A measured area, timing, or toggle row is measurement
evidence, not formal proof. Yosys SAT/equivalence evidence is named only with
the exact scope it discharged.

Current CV32E40P packets are evidence packets, not accepted whole-core customer
claims. They are useful because they show the falsifiability bar directly:
bounded RTL input, bounded RTL output, replayable measurements, scoped
equivalence checks, and negative controls.

## Results Snapshot

| Packet | Scope | PPA signal | Correctness / activity | Receipt |
| --- | --- | --- | --- | --- |
| `cv32e40p_alu` / `addsub_divvalid_adderneg_prefixes` | ALU parent context | Area `29548.3392 -> 29208.0128` (`-1.151762%`); all five timing groups improve | Source-local SAT equivalence for the rewritten predicates; three negative controls bite; toggle flat | [`athanor_artifacts/alu_addsub_divvalid_adderneg_prefixes/`](athanor_artifacts/alu_addsub_divvalid_adderneg_prefixes/) |
| `cv32e40p_alu` / `shift_divvalid_adderneg_prefixes` | ALU parent context | Area `29548.3392 -> 29353.1520` (`-0.660569%`); all five timing groups improve | Source-local SAT equivalence; three negative controls bite; toggle flat | [`athanor_artifacts/alu_shift_divvalid_adderneg_prefixes/`](athanor_artifacts/alu_shift_divvalid_adderneg_prefixes/) |
| `cv32e40p_alu` / `shift_left_divrem_prefix` | ALU parent context | Area `29548.3392 -> 29433.2288` (`-0.389566%`); all five timing groups improve | Source-local SAT equivalence; wrong-prefix negative control bites; toggle flat | [`athanor_artifacts/alu_shift_left_divrem_prefix/`](athanor_artifacts/alu_shift_left_divrem_prefix/) |
| `cv32e40p_prefetch_controller` / `prefetch_hwlp_plus_next_cnt_arith` | IF-stage parent context, with a named local prefetch-buffer caveat | IF-stage area `18228.7328 -> 18187.4432` (`-0.226508%`); all IF-stage timing groups improve | Source-local SAT equivalence; two negative controls bite; toggle flat; local prefetch-buffer in2out regresses and is called out | [`athanor_artifacts/prefetch_hwlp_plus_next_cnt_arith/`](athanor_artifacts/prefetch_hwlp_plus_next_cnt_arith/) |
| `cv32e40p_register_file_ff` / `readmask_high_bank_zero` | Default ID-stage parent context | Area `111291.7376 -> 110963.9232` (`-0.29455%`); measured timing groups flat or improved | Yosys `equiv_induct` closes `2820/2820` parent `$equiv` cells; RF-grid equivalence closes for the listed FPU/ZFINX tuples; negative control bites; toggle flat | [`athanor_artifacts/register_file_readmask_high_bank_zero/`](athanor_artifacts/register_file_readmask_high_bank_zero/) |

See [`athanor_artifacts/`](athanor_artifacts/) for the full packet index,
including compressed-decoder, prefetch, ALU, and register-file candidates.

## Public Verification

From a fresh clone:

```bash
python3 athanor/verify_public_receipts.py
```

The verifier checks the public toolchain policy, packet manifests, package
hash manifests, and public wording boundaries. Individual packets also include
`COMMANDS.md` files for replaying their local evidence.

## What This Shows

- Athanor can produce auditable RTL candidate packages on a production-grade
  open-source RISC-V core.
- The useful public artifact is not a story about how the candidate was found;
  it is the bounded input/output diff plus replayable evidence for the exact
  claim.
- Scope matters. These CV32E40P packets are parent-context evidence, not
  integrated whole-core claims.
- Rejections and caveats stay visible. A packet with a local timing caveat or
  missing promotion gate is labeled as such instead of being rounded up into a
  win.

## Audit Map

- Toolchain lock: [`tools/TOOLCHAIN.lock`](tools/TOOLCHAIN.lock)
- Receipt verifier: [`athanor/verify_public_receipts.py`](athanor/verify_public_receipts.py)
- Artifact packages: [`athanor_artifacts/`](athanor_artifacts/)
- Packet replay gate: [`.github/workflows/packet-replay-gate.yml`](.github/workflows/packet-replay-gate.yml)

## Upstream CV32E40P

The original OpenHW Group documentation, examples, and source tree are
preserved below.

# OpenHW Group CORE-V CV32E40P RISC-V IP

CV32E40P is a small and efficient, 32-bit, in-order RISC-V core with a 4-stage pipeline that implements
the RV32IM\[F|Zfinx\]C instruction set architecture, and the PULP custom extensions for achieving
higher code density, performance, and energy efficiency \[[1](https://doi.org/10.1109/TVLSI.2017.2654506)\], \[[2](https://doi.org/10.1109/PATMOS.2017.8106976)\].
It started its life as a fork of the OR10N CPU core that is based on the OpenRISC ISA.
Then, under the name of RI5CY, it became a RISC-V core (2016), and it has been maintained
by the [PULP platform](https://www.pulp-platform.org/) team until February 2020,
when it has been contributed to [OpenHW Group](https://www.openhwgroup.org/).

<p align="center"><img src="docs/images/CV32E40P_Block_Diagram.svg" width="750"></p>

## Documentation

The CV32E40P user manual can be found in the _docs_ folder and it is
captured in reStructuredText, rendered to html using [Sphinx](https://docs.readthedocs.io/en/stable/intro/getting-started-with-sphinx.html).
These documents are viewable using readthedocs and can be viewed [here](https://docs.openhwgroup.org/projects/cv32e40p-user-manual/).

## Verification
The verification environment for the CV32E40P is _not_ in this Repository.  There is a small, simple testbench here which is
useful for experimentation only and should not be used to validate any changes to the RTL prior to pushing to the master
branch of this repo.

The verification environment for this core as well as other cores in the OpenHW Group CORE-V family is at the
[core-v-verif](https://github.com/openhwgroup/core-v-verif) repository on GitHub.

The Makefiles supported in the **core-v-verif** project automatically clone the appropriate version of the **cv32e40p**  RTL sources.

## Changelog

A changelog is generated automatically in the documentation from the individual pull requests.
In order to enable automatic changelog generation within the CV32E40P documentation, the committer is required to label each pull request
that touches any file in 'rtl' (or any of its subdirectories) with *Component:RTL* and label each pull request that touches any file in
'docs' (or any of its subdirectories) with *Component:Doc*. Pull requests that are not labeled or labeled with *ignore-for-release* are
ignored for the changelog generation.

Only the person who actually performs the merge can add these labels (you need committer rights). The changelog flow only works if at most
1 label is applied and therefore pull requests that touches both RTL and documentation files in the same pull request are not allowed.

## Constraints
Example synthesis constraints for the CV32E40P are provided.

## Contributing

We highly appreciate community contributions. We are currently using the lowRISC contribution guide.
To ease our work of reviewing your contributions,
please:

* Create your own fork to commit your changes and then open a Pull Request to the **dev** branch.
* Split large contributions into smaller commits addressing individual changes or bug fixes. Do not
  mix unrelated changes into the same commit!
* Do not mix updates within the 'rtl' directory with updates within the 'docs' directory ino the same pull request.
* Write meaningful commit messages. For more information, please check out the [the Ibex contribution
  guide](https://github.com/lowrisc/ibex/blob/master/CONTRIBUTING.md).
* If asked to modify your changes, do fixup your commits and rebase your branch to maintain a
  clean history.
* If the PR gets accepted and merged into the the **dev** branch, an action is triggered automatically to check whether the changes are logically equivalent to the frozen RTL on a given set of parameters. If the changes are logically equivalent, the **dev** branch is automatically merged into the **master** branch. Otherwise, we need to investigate manually. If a bug is found, thus the changes are not logically equivalent, we follow the procedure documented [here](https://docs.openhwgroup.org/projects/cv32e40p-user-manual/core_versions.html). 

For more details on how this is implemented, have a look at this [page](https://github.com/openhwgroup/cv32e40p/blob/master/.github/workflows/aws_cv32e40p.md).

When contributing SystemVerilog source code, please try to be consistent and adhere to [the lowRISC Verilog
coding style guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md).

To get started, please check out the ["Good First Issue"
 list](https://github.com/openhwgroup/cv32e40p/issues?q=is%3Aissue+is%3Aopen+-label%3Astatus%3Aresolved+label%3A%22good+first+issue%22).

The RTL code has been formatted with ["Verible"](https://github.com/google/verible) v0.0-1149-g7eae750.
Run `./util/format-verible` to format all the files.

## Issues and Troubleshooting

If you find any problems or issues with CV32E40P or the documentation, please check out the [issue
 tracker](https://github.com/openhwgroup/cv32e40p/issues) and create a new issue if your problem is
not yet tracked.

## References

1. [Gautschi, Michael, et al. "Near-Threshold RISC-V Core With DSP Extensions for Scalable IoT Endpoint Devices."
 in IEEE Transactions on Very Large Scale Integration (VLSI) Systems, vol. 25, no. 10, pp. 2700-2713, Oct. 2017](https://doi.org/10.1109/TVLSI.2017.2654506)

2. [Schiavone, Pasquale Davide, et al. "Slow and steady wins the race? A comparison of
 ultra-low-power RISC-V cores for Internet-of-Things applications."
 _27th International Symposium on Power and Timing Modeling, Optimization and Simulation
 (PATMOS 2017)_](https://doi.org/10.1109/PATMOS.2017.8106976)

