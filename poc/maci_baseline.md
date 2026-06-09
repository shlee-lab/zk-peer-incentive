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

## Integration Path

Use unmodified official MACI plus a reward sidecar adapter, with MACI
`VoteCommand.salt` values reused as the private reward nonces.

This is Path A for MACI itself: contracts, circuits, zkeys, SDK helpers, and
proof generation remain unmodified. It is also a limited Path-B-style nonce
bridge: the reward nonce is not a new MACI command field, but it is sourced from
an existing encrypted MACI command salt rather than from a separate external
randomness input.

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
- A deeper Path B would add a dedicated reward nonce to MACI's vote command
  domain and circuits. That would require changing MACI circuits, verifying
  keys, and proof generation flow, so it is out of scope for this experimental
  integration.

## Current Reward Sidecar Binding

The sidecar derives binary reports from final MACI ballots and builds:

```text
leaf_i = H(maciStateIndex_i, voterId_i, report_i, nonceCommitment_i, stake_i, recipient_i)
finalRewardStateRoot = MerkleRoot(leaf_1, ..., leaf_N)
```

The reward circuit privately opens `nonce_i` to `nonceCommitment_i`, verifies
Merkle inclusion against `finalRewardStateRoot`, computes fixed-budget lottery
peer-prediction rewards, and exposes payouts plus `pollId` and
`finalRewardStateRoot` as public signals. The current full MACI experiment uses
each encrypted `VoteCommand.salt` as the private reward nonce, and the circuit
also exposes recipient addresses so the payout contract can bind claims to the
proof.

This remains experimental. The MACI baseline is real; the reward sidecar binding
is a PoC adapter and is not a production security claim.

## Full MACI Plus Reward Sidecar Command

After the reward v2 circuit artifacts and Foundry artifacts exist in this repo,
the combined local flow can be run from `poc/`:

```sh
MACI_REPO=/tmp/maci-official npm run e2e:full-maci-reward
MACI_REPO=/tmp/maci-official npm run e2e:full-maci-reward:anvil
```

The script writes a generated ts-mocha test into the official MACI checkout and
runs it with Node `v20.20.2`. It uses official MACI contracts, SDK helpers,
circuits, test zkeys, and rapidsnark to:

- deploy MACI on the official local Hardhat network or an external Anvil RPC;
- sign up 8 voters and join all 8 to a poll;
- publish 8 encrypted binary votes;
- generate and submit message-processing and tally Groth16 proofs;
- verify and submit the MACI tally;
- derive binary reward reports from final MACI ballots;
- generate a reward sidecar proof from those reports;
- deploy this repo's reward contracts to the same local chain;
- finalize rewards and claim one payout.

Observed Hardhat-harness smoke run:

- Result: `1 passing (4m)`.
- MACI tally: option 0 = `36`, option 1 = `36`.
- Total spent voice credits: `648`.
- Derived reports: `[1, 0, 1, 1, 0, 0, 1, 0]`.
- This harness is useful for checking official MACI compatibility, but the
  latest gas and reward timing numbers below come from the Anvil E2E run.

Latest observed Anvil run:

- Result: `1 passing (5m)`.
- Execution chain ID: `31337`.
- Anvil RPC: `http://127.0.0.1:8556`.
- MACI tally: option 0 = `36`, option 1 = `36`.
- Total spent voice credits: `648`.
- Derived reports: `[1, 0, 1, 1, 0, 0, 1, 0]`.
- Final reward sidecar root:
  `9085344411136641853726403055769717154468974807716947437918939447230816557425`.
- Reward nonce source: `MACI VoteCommand.salt`.
- Reward budget: `3000000`.
- Reward mode: fixed-budget lottery with `rhoTau = 3000000`.
- Stake design: uniform public stake `10` for all eight voters.
- Lottery wins: `[0, 0, 1, 0, 1, 0, 0, 0]`.
- Fixed-budget lottery payouts: `[499, 499, 1498501, 499, 1498501, 499, 499, 503]`.
- Sample claim index: `0`.
- MACI proof phase: `101229 ms`.
- Reward proof phase: `2970 ms`.
- Reward root registration gas: `93334`.
- Reward pool funding gas: `47396`.
- Reward finalization gas: `671978`.
- Reward claim gas: `30684`.

Generated reward artifacts are under `poc/artifacts/full_maci_reward/` for the
Hardhat harness and `poc/artifacts/full_maci_reward_anvil/` for Anvil. They are
not committed.

## Anvil Details

The Anvil command starts a dedicated Anvil instance with MACI's testing mnemonic:

```sh
anvil --host 127.0.0.1 --port 8556 --chain-id 31337 \
  --mnemonic "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" \
  --accounts 101 --balance 10000 --gas-limit 30000000 --code-size-limit 1000000
```

The runner temporarily patches `/tmp/maci-official/packages/testing/hardhat.config.ts`
so the official MACI testing package uses the `localhost` network pointed at
that Anvil RPC, then restores the file after the run. This keeps the official
MACI contracts and circuits unmodified while using Anvil as the execution chain.

The older reward-only Anvil E2E remains available:

```sh
npm run e2e:anvil
```
