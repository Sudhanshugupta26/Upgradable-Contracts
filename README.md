# Upgradable Box (UUPS) with Foundry

A compact Foundry project that demonstrates the UUPS proxy upgrade pattern using OpenZeppelin v5 contracts.

## What This Project Shows

- Deploying `BoxV1` behind an `ERC1967Proxy`
- Upgrading the proxy implementation to `BoxV2`
- Preserving proxy storage across upgrades
- Testing upgrade behavior with Forge

## Architecture

- `src/BoxV1.sol`
  - UUPS upgradeable implementation (version `1`)
  - Uses `Initializable` + `OwnableUpgradeable`
- `src/BoxV2.sol`
  - Upgraded implementation (version `2`)
  - Adds `setNumber(uint256)`
- `script/DeployBox.s.sol`
  - Deploys `BoxV1` and an `ERC1967Proxy`
- `script/UpgradeBox.s.sol`
  - Deploys `BoxV2` and upgrades proxy via `upgradeToAndCall`
- `test/DeployAndUpgradeTest.t.sol`
  - End-to-end and edge-case tests for deploy + upgrade behavior

## Tech Stack

- Foundry (`forge`, `anvil`, `cast`)
- Solidity `^0.8.30`
- OpenZeppelin Contracts + Contracts Upgradeable
- `foundry-devops` for resolving latest deployment artifacts in scripts

## Setup

### 1. Clone and enter project

```bash
git clone https://github.com/Sudhanshugupta26/Upgradable-Contracts
cd Upgradable-Contracts
```

### 2. Install dependencies (submodules)

```bash
git submodule update --init --recursive
```

### 3. Build

```bash
forge build
```

## Run Tests

```bash
forge test -vvv
```

## Coverage

```bash
forge coverage
```

Current test suite covers upgrade lifecycle and key UUPS constraints (`proxiableUUID`, proxy-context checks, invalid implementation reverts, initializer behavior).

## Scripts

### Deploy proxy with BoxV1

```bash
forge script script/DeployBox.s.sol:DeployBox --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Upgrade proxy to BoxV2

```bash
forge script script/UpgradeBox.s.sol:UpgradeBox --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Upgrade Flow

1. Deploy `BoxV1` implementation.
2. Deploy `ERC1967Proxy` pointing to `BoxV1`.
3. Call `initialize()` through proxy.
4. Deploy `BoxV2` implementation.
5. Call `upgradeToAndCall(newImplementation, "")` through proxy.
6. Interact with proxy using `BoxV2` ABI.

## Security Notes

This repo is educational/demo oriented.

- `_authorizeUpgrade(...)` is currently open in both versions.
- For production, restrict upgrades with `onlyOwner` (or stronger governance controls).
- Ensure initializer calls are performed as part of deployment flow.

## Project Structure

```text
Upgradable/
├── src/
│   ├── BoxV1.sol
│   └── BoxV2.sol
├── script/
│   ├── DeployBox.s.sol
│   └── UpgradeBox.s.sol
├── test/
│   └── DeployAndUpgradeTest.t.sol
├── foundry.toml
└── lib/
```
