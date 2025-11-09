import { ChainMap, ChainMetadata, ExplorerFamily } from '@hyperlane-xyz/sdk';
import { Address, ProtocolType } from '@hyperlane-xyz/utils';

export const chains: ChainMap<ChainMetadata & { mailbox?: Address }> = {
  davinci: {
    protocol: ProtocolType.Ethereum,
    chainId: 293,
    domainId: 293,
    name: 'davinci',
    displayName: 'DaVinci Chain',
    nativeToken: { name: 'DaVinci', symbol: 'DCOIN', decimals: 18 },
    rpcUrls: [
      { http: 'https://rpc.davinci.bz' },
      { http: 'https://rpc-explorer.davinci.bz' },
      { http: 'https://rpc-bridge.davinci.bz' },
    ],
    blockExplorers: [
      {
        name: 'DaVinci Explorer',
        url: 'https://mainnet-explorer.davinci.bz',
        apiUrl: 'https://mainnet-explorer.davinci.bz/api',
        family: ExplorerFamily.Blockscout,
      },
    ],
    logoURI:
      'https://raw.githubusercontent.com/davinchi-protocol/branding-kit/refs/heads/main/logo-network/davinci-logo.svg',
  },

  optimism: {
    protocol: ProtocolType.Ethereum,
    chainId: 10,
    domainId: 10,
    name: 'optimism',
    displayName: 'Optimism',
    nativeToken: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: [
      { http: 'https://mainnet.optimism.io' },
      { http: 'https://optimism.drpc.org' },
      { http: 'https://optimism-rpc.publicnode.com' },
      { http: 'https://op-pokt.nodies.app' },
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
    logoURI: 'https://raw.githubusercontent.com/hyperlane-xyz/hyperlane-registry/refs/heads/main/chains/optimism/logo.svg',
    gnosisSafeTransactionServiceUrl: 'https://safe-transaction-optimism.safe.global/',
    blocks: {
      confirmations: 1,
      estimateBlockTime: 3,
      reorgPeriod: 10,
    },
  },
};

export const chainsRentEstimate: ChainMap<bigint> = {
  eclipsemainnet: BigInt(Math.round(0.00004019 * 10 ** 9)),
  solanamainnet: BigInt(Math.round(0.00411336 * 10 ** 9)),
  sonicsvm: BigInt(Math.round(0.00411336 * 10 ** 9)),
  soon: BigInt(Math.round(0.00000355 * 10 ** 9)),
};
