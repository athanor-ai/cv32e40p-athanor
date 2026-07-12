# Auxiliary Adapter Miter

This directory packages the CV32E40P `readmask_high_bank_zero` parent-context
proof surface for independent replay.

The load-bearing equivalence receipt is not the adapter miter in this directory.
It is the checked-in `../replay_parent_equiv.sh` flow:

```bash
read gold/gate parent bundles
proc; memory; async2sync; flatten; opt
equiv_make gold gate equiv
equiv_simple
equiv_induct
equiv_status -assert
```

That flow proves `2820/2820` parent `$equiv` cells and the paired mutant leaves
`32` `regfile_data_ra_id` bits unproven.

The adapter files here are included so the package has explicit
gold/gate/mutant source artifacts and a miter-shaped source to inspect. The
K=4 temporal-induction experiment over that adapter is recorded in
`logs/cv32e40p_id_stage_relation_seq_miter_tempinduct_k4.log`; it is an
auxiliary harness result, not the positive proof receipt.
