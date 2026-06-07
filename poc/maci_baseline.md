# MACI Baseline Integration Notes

These notes pin the experimental full-MACI baseline used before touching the
reward sidecar code.

## Pinned MACI Tooling

- Official repository: `https://github.com/privacy-scaling-explorations/maci`
- Commit: `22106c8a2015f18709a32208ad2ad40b6f3fa8a5`
- Reported package version at that commit: `maci@3.0.0`
- Latest release tag observed during inspection: `v2.5.0`
- Node: `v20.20.2`
- pnpm: `10.0.0`
- Test zkeys: `https://maci-develop-fra.s3.eu-central-1.amazonaws.com/v3.0.0/maci_artifacts_v3.0.0_test.tar.gz`
- Rapidsnark binary: `https://maci-devops-zkeys.s3.ap-northeast-2.amazonaws.com/rapidsnark-linux-amd64-1c137`

The official MACI repo was cloned outside this repository at
`/tmp/maci-official` for inspection and baseline runs. The 3.5 GB zkey archive
is intentionally not vendored into this PoC repo.

## Setup Commands

```sh
git clone https://github.com/privacy-scaling-explorations/maci.git /tmp/maci-official
cd /tmp/maci-official
git checkout 22106c8a2015f18709a32208ad2ad40b6f3fa8a5

source ~/.nvm/nvm.sh
nvm install 20.20.2
nvm use 20.20.2
corepack enable
corepack prepare pnpm@10.0.0 --activate

pnpm install --frozen-lockfile
pnpm --filter @maci-protocol/contracts build
pnpm --filter @maci-protocol/circuits --filter @maci-protocol/sdk --filter @maci-protocol/cli --filter @maci-protocol/testing build
pnpm run download-zkeys:test

mkdir -p ~/rapidsnark/build
wget -qO ~/rapidsnark/build/prover https://maci-devops-zkeys.s3.ap-northeast-2.amazonaws.com/rapidsnark-linux-amd64-1c137
chmod +x ~/rapidsnark/build/prover
```

Node 24 did not work for the MACI build in this environment. Hardhat failed
while downloading `solc` with an undici `maxRedirections` error. Using MACI's
declared Node 20 engine fixed the issue.

## Baseline Commands Run

Minimal QV flow:

```sh
cd /tmp/maci-official
source ~/.nvm/nvm.sh
nvm use 20.20.2
mkdir -p packages/testing/proofs
pnpm --filter @maci-protocol/testing exec ts-mocha --exit ./ts/__tests__/e2e.test.ts --grep "2 signups"
```

Result: `4 passing (1m)`.

This flow deployed MACI contracts on Hardhat's local network, signed up a user,
joined the poll, published an encrypted vote, merged state, generated real
message-processing and vote-tally Groth16 proofs, submitted proofs on-chain,
submitted results, and verified the tally.

8-signup QV flow:

```sh
cd /tmp/maci-official
source ~/.nvm/nvm.sh
nvm use 20.20.2
mkdir -p packages/testing/proofs
pnpm --filter @maci-protocol/testing exec ts-mocha --exit ./ts/__tests__/e2e.test.ts --grep "8 signups"
```

Result: `4 passing (2m)`.

This flow signed up eight MACI users, joined one poll user, published and
relayed encrypted messages, generated two message-processing proof batches plus
one vote-tally proof, submitted all proofs on-chain, submitted results, and
verified the tally.

## Path Decision

Use Path A: unmodified MACI plus a reward sidecar adapter.

Reasons:

- The official MACI baseline works with unmodified contracts, circuits, zkeys,
  SDK, and tests.
- MACI's off-chain core state exposes the data needed by the reward sidecar
  after processing: final `Poll.ballots`, `Poll.pollStateLeaves`, `ballotRoot`,
  `stateRoot`, and tally results.
- MACI's on-chain contracts expose final commitments and tally status, but not
  per-voter hidden ballot contents. That is expected for MACI and means reward
  binding should be a sidecar commitment built by the coordinator after MACI
  processing.
- Path B would require changing MACI's vote command domain, circuits,
  verifying keys, and proof generation flow to carry a reward nonce. That is a
  deep MACI circuit rewrite and would destabilize the baseline.

## Reward Sidecar Binding Plan

The sidecar will derive binary reports from final MACI ballots and build:

```text
leaf_i = H(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i)
finalRewardStateRoot = MerkleRoot(leaf_1, ..., leaf_N)
```

The reward circuit will privately open `nonce_i` to `nonceCommitment_i`, verify
Merkle inclusion against `finalRewardStateRoot`, compute the peer-prediction
lottery rewards, and expose payouts plus `pollId` and `finalRewardStateRoot` as
public signals.

This remains experimental. The MACI baseline is real; the reward sidecar binding
is a PoC adapter and is not a production security claim.
