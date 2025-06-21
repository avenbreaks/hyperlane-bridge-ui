import { Space_Grotesk as SpaceGrotesk } from 'next/font/google';
import { Color } from '../styles/Color';

export const MAIN_FONT = SpaceGrotesk({
  subsets: ['latin'],
  variable: '--font-main',
  preload: true,
  fallback: ['sans-serif'],
});
export const APP_NAME = 'DaVinci Warp UI Template';
export const APP_DESCRIPTION = 'A DApp for DaVinci Warp Route transfers';
export const APP_URL = 'davinci-bridge.vercel.app';
export const BRAND_COLOR = Color.primary['800'];
export const BACKGROUND_COLOR = Color.primary['800'];
export const BACKGROUND_IMAGE = 'url(/backgrounds/main.svg)';
