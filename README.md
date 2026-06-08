# ZK Peer-Prediction Reward PoC

This repository is a research prototype for adding a ZK-verifiable
peer-prediction reward layer to private MACI voting.

MACI is used for what it already does well: voters submit encrypted votes, the
system processes those messages privately, and a tally proof verifies the final
result without exposing each voter's vote. This PoC adds a separate reward
sidecar. The sidecar takes the final hidden voting state, commits the
reward-relevant data into a root, proves that a fixed-budget peer-prediction
payout vector was computed correctly, and lets recipients claim the finalized
rewards on-chain.

```text
encrypted MACI votes
  -> MACI message-processing proof
  -> MACI tally proof
  -> hidden binary reports from final MACI ballots
  -> reward state root
  -> reward proof
  -> on-chain reward finalization
  -> recipient claim
```

The implementation lives under `poc/`. The goal is feasibility for research,
not production security.

## Core Idea

The prototype keeps official MACI unmodified. MACI handles signup, poll join,
encrypted vote publication, message processing, tally proving, and on-chain
tally verification. After MACI finishes, the reward sidecar derives binary
reports from the final MACI ballots and builds a reward state root.

Each reward leaf binds the hidden report to the MACI state index, a voter
identity value, a nonce commitment, a public stake, and the recipient address:

```text
nonceCommitment_i = Poseidon(nonce_i, 0)
leaf_i = Poseidon(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i)
```

The reward proof then shows that the prover knows hidden reports and nonce
openings included in that root, and that the public payout vector follows the
reward rule. The Solidity reward pool checks the proof, checks that the root is
the registered final reward state, records claimable balances, and lets each
recipient withdraw their assigned payout.

The claim supported by the PoC is intentionally narrow:

> A reward layer can be bound to a MACI-derived hidden report state, and a real
> Groth16 proof can verify fixed-budget peer-prediction payouts before an
> on-chain claim flow pays recipients.

## Reward Rule

The current reward rule is fixed-size and intentionally simple: `N = 8`, binary
reports, public stakes, ring peer matching, and smoothed inverse-frequency peer
agreement. The mechanism first computes an unnormalized peer-prediction score
`T_i` for each voter. It then adds a baseline and normalizes all scores into a
fixed reward budget `B`:

```text
score_i = T_i + scale
payout_i ~= B * score_i / sum_j score_j
sum_i payout_i = B
```

The final payout receives the deterministic rounding residue, so the payout
vector always sums exactly to the configured budget. Reports only change how
that fixed pool is divided.

Here, `kappa` is the reward scale. Increasing `kappa` makes peer-agreement
scores larger before the fixed-budget normalization step. It does not create a
larger reward pool; it changes how strongly the nonzero peer-prediction scores
dominate the small baseline.

## Current Result

The latest full local run uses official MACI at commit
`22106c8a2015f18709a32208ad2ad40b6f3fa8a5`, an Anvil chain with chain id
`31337`, eight voters, and a reward budget of `3,000,000`.

```text
MACI tally: option0 = 36, option1 = 36
reports: [1, 0, 1, 1, 0, 0, 1, 0]
payouts: [644, 644, 1498065, 644, 1498065, 644, 644, 650]
MACI proof phase: 97995 ms
reward proof phase: 3034 ms
reward circuit: 17,262 constraints, 30 public inputs, 88 private inputs
Foundry tests: 13 passed
```

Reward-specific gas from the same run was:

```text
registerFinalState   93,334 gas
fundDispute          47,396 gas
finalizeRewards     664,956 gas
claim                30,706 gas
```

`finalizeRewards` is the expensive reward-layer operation because it verifies
the Groth16 proof and records the payout vector. `claim` is cheap because it
only withdraws a balance that was already finalized.

## Evaluation

The evaluation artifacts are under `experiments/reward-evaluation/`. They are
meant to support the basic research questions: whether the full MACI plus reward
flow runs end to end, whether the fixed-budget reward rule behaves sensibly
under representative report profiles, how stake weighting affects payout share,
and what the reward-only on-chain cost looks like.

Reward-rule behavior:

This graph is about the raw reward score, not the final payout. The x-axis
`kappa` is the reward multiplier. Larger `kappa` means matching peer reports get
stronger scores. The flat alternating line means that, under the current
ring-peer rule, nobody agrees with their assigned peer, so the raw score stays
near zero. Stake is fixed across these report profiles, so this chart isolates
the effect of the report pattern.

![Reward-rule behavior](experiments/reward-evaluation/figures/reward_sensitivity.png)

Fixed-budget allocation:

This graph shows how the fixed `3,000,000` budget is divided in the MACI-derived
example. The y-axis is logarithmic so both the large peer-match payouts and the
small baseline payouts remain visible. Voter 2 and voter 4 receive most of the
budget because they are the only voters whose report matches their assigned
peer's report. Since all stakes are fixed to the same value in this chart, those
two voters receive the same large payout.

![Budget allocation](experiments/reward-evaluation/figures/budget_allocation.png)

Stake weighting:

This graph is the only one that changes stake. It changes voter 2's public stake
while keeping the report pattern fixed. It checks that, when a voter has a valid
peer-agreement signal, increasing that voter's stake increases their share of
the fixed reward budget.

![Stake-weighting behavior](experiments/reward-evaluation/figures/stake_concentration.png)

Reward gas:

This graph separates the reward-layer on-chain costs. `Verify + finalize` is
the largest bar because it verifies the reward proof and records the payout
vector. `Claim` is much smaller because it only withdraws an already-finalized
balance.

![Reward on-chain cost](experiments/reward-evaluation/figures/cost_profile.png)

The same figures are also exported as vector PDFs for paper or slide use. More
detail is in [experiments/reward-evaluation/README.md](experiments/reward-evaluation/README.md).

## Running The Prototype

The reward-only Anvil flow checks the generated reward proof and reward
contracts without running full MACI:

```bash
cd poc
forge build
forge test -vvv
npm run e2e:anvil
```

The full MACI plus reward flow expects an official MACI checkout at
`/tmp/maci-official`, Node `v20.20.2`, MACI test zkeys, rapidsnark, Foundry, and
the reward circuit artifacts under `poc/artifacts/v2/`. The exact setup is
documented in [poc/maci_baseline.md](poc/maci_baseline.md).

```bash
cd poc
MACI_REPO=/tmp/maci-official npm run e2e:full-maci-reward:anvil
```

That command starts Anvil, deploys official MACI, signs up and joins eight
voters, publishes encrypted votes, generates and submits MACI proofs, derives
the reward sidecar state, generates the reward proof, finalizes payouts, and
claims one payout.

To regenerate the evaluation data and figures:

```bash
cd poc
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
npm run experiments:reward
```

## Scope

This is a local research prototype with fixed `N = 8`, binary reports, a local
development Groth16 setup, and an experimental reward sidecar around official
MACI. It does not include a production audit, Sybil-resistance policy,
token-economics design, large-scale benchmarking, or proof of real-world human
effort.

MACI remains responsible for private voting and tally correctness. The new
reward proof is responsible only for payout correctness from committed hidden
reports.

For deeper technical details, see [poc/zk_relation.md](poc/zk_relation.md),
[poc/maci_baseline.md](poc/maci_baseline.md), and
[experiments/reward-evaluation/README.md](experiments/reward-evaluation/README.md).
