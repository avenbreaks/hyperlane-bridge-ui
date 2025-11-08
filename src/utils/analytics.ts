declare global {
  interface Window {
    umami?: {
      track: (eventName: string, eventData?: Record<string, any>) => void;
    };
  }
}

export const trackEvent = (eventName: string, eventData?: Record<string, any>) => {
  if (typeof window !== 'undefined' && window.umami) {
    window.umami.track(eventName, eventData);
  }
};

// Helper functions for bridge events
export const analytics = {
  trackBridgeInitiated: (data: {
    fromChain: string;
    toChain: string;
    token: string;
    amount: string;
  }) => {
    trackEvent('bridge_initiated', data);
  },

  trackBridgeCompleted: (data: {
    fromChain: string;
    toChain: string;
    token: string;
    amount: string;
    txHash: string;
  }) => {
    trackEvent('bridge_completed', data);
  },

  trackBridgeFailed: (data: {
    fromChain: string;
    toChain: string;
    token: string;
    errorMessage: string;
  }) => {
    trackEvent('bridge_failed', data);
  },

  trackWalletConnected: (data: { walletType: string; chain: string }) => {
    trackEvent('wallet_connected', data);
  },

  trackTokenSelected: (data: { token: string; chain: string }) => {
    trackEvent('token_selected', data);
  },

  trackChainSelected: (data: { chain: string; direction: 'origin' | 'destination' }) => {
    trackEvent('chain_selected', data);
  },
};
