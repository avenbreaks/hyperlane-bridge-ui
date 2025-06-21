import { ChainMap, ChainMetadata, ExplorerFamily } from '@hyperlane-xyz/sdk';
import { Address, ProtocolType } from '@hyperlane-xyz/utils';

// A map of chain names to ChainMetadata
// Chains can be defined here, in chains.json, or in chains.yaml
// Chains already in the SDK need not be included here unless you want to override some fields
// Schema here: https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/typescript/sdk/src/metadata/chainMetadataTypes.ts
export const chains: ChainMap<ChainMetadata & { mailbox?: Address }> = {
  davinci: {
   protocol: ProtocolType.Ethereum,
   chainId: 293,
   domainId: 293,
   name: 'davinci',
   displayName: 'DaVinci Chain',
   nativeToken: { name: 'DaVinci', symbol: 'DCOIN', decimals: 18 },
   rpcUrls: [{ http: 'https://rpc.davinci.bz' }],
   blockExplorers: [
     {
       name: 'DaVinci Explorer',
       url: 'https://mainnet-explorer.davinci.bz',
       apiUrl: 'https://mainnet-explorer.davinci.bz/api',
       family: ExplorerFamily.Blockscout,
     },
   ],
   logoURI: 'https://raw.githubusercontent.com/davinchi-protocol/branding-kit/refs/heads/main/logo-network/davinci-logo.svg',
 },
   optimism: {
    protocol: ProtocolType.Ethereum,
    chainId: 10,
    domainId: 10,
    name: 'optimism',
    displayName: 'Optimism',
    nativeToken: {
      name: 'Ether',
      symbol: 'ETH',
      decimals: 18,
    },
    rpcUrls: [
      { http: 'https://mainnet.optimism.io' },
      { http: 'https://optimism.drpc.org' },
      { http: 'https://optimism-rpc.publicnode.com' },
      { http: 'https://op-pokt.nodies.app' },
      { http: 'https://optimism-mainnet.g.allthatnode.com/full/evm/eabc4ca8f01f4a148f43a8623dc7687d' },
      { http: 'https://1rpc.io/op' },
      { http: 'https://opt-mainnet.nodereal.io/v1/6e0e7ff6084c444ab8bc499ad6c83116' },
      { http: 'https://opt-mainnet.g.alchemy.com/v2/s96wHNp66Hu7iqIwFiPb6Cgjj27d9kkG' },
    ],
    blockExplorers: [
      {
        name: 'Etherscan',
        url: 'https://optimistic.etherscan.io',
        apiUrl: 'https://api-optimistic.etherscan.io/api',
        family: ExplorerFamily.Etherscan,
        apiKey: 'JMYR3W6HHVPQ1HH8T6W8HSZVG88IH3MHRU',
      },
    ],
    gasCurrencyCoinGeckoId: 'ethereum',
    gnosisSafeTransactionServiceUrl: 'https://safe-transaction-optimism.safe.global/',
    deployer: {
      name: 'Abacus Works',
      url: 'https://www.hyperlane.xyz',
    },
    blocks: {
      confirmations: 1,
      estimateBlockTime: 3,
      reorgPeriod: 10,
    },
  },
};

// rent account payment for (mostly for) SVM chains added on top of IGP,
// not exact but should be pretty close to actual payment
export const chainsRentEstimate: ChainMap<bigint> = {
  eclipsemainnet: BigInt(Math.round(0.00004019 * 10 ** 9)),
  solanamainnet: BigInt(Math.round(0.00411336 * 10 ** 9)),
  sonicsvm: BigInt(Math.round(0.00411336 * 10 ** 9)),
  soon: BigInt(Math.round(0.00000355 * 10 ** 9)),
};
