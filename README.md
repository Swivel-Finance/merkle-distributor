# @uniswap/merkle-distributor

[![Tests](https://github.com/Uniswap/merkle-distributor/workflows/Tests/badge.svg)](https://github.com/Uniswap/merkle-distributor/actions?query=workflow%3ATests)
[![Lint](https://github.com/Uniswap/merkle-distributor/workflows/Lint/badge.svg)](https://github.com/Uniswap/merkle-distributor/actions?query=workflow%3ALint)

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`


## Generating Tree

```npm install typescript```

```npm install ts-node```

```ts-node scripts/generate-merkle-root.ts --input <INPUT_JSON_DIRECTORY>```

e.g.

```ts-node scripts/generate-merkle-root.ts --input scripts/airdrop_list.json```

