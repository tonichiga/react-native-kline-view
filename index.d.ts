import type {
  HostComponent,
  NativeSyntheticEvent,
  ViewProps,
} from "react-native";

export type RNKLineColorValue = number | string;

export interface RNKLineDrawItemDidTouchPayload {
  shouldReloadDrawItemIndex: number;
  drawColor?: number[];
  drawLineHeight?: number;
  drawDashWidth?: number;
  drawDashSpace?: number;
  drawIsLock?: boolean;
}

export interface RNKLineDrawItemCompletePayload {
  [key: string]: never;
}

export interface RNKLineDrawPointCompletePayload {
  pointCount: number;
}

export interface RNKLineTargetItem {
  title: string;
  selected: boolean;
  index: number;
}

export interface RNKLineModelItem {
  id?: number;
  time?: number;
  open?: number;
  high?: number;
  low?: number;
  close?: number;
  vol?: number;
  volume?: number;
  dateString?: string;
  selectedItemList?: Array<Record<string, unknown>>;
  maList?: RNKLineTargetItem[];
  maVolumeList?: RNKLineTargetItem[];
  openTradePrice?: number;
  closeTradePrice?: number;
  openTradeCount?: number;
  closeTradeCount?: number;
  [key: string]: unknown;
}

export interface RNKLineTargetList {
  maList?: RNKLineTargetItem[];
  maVolumeList?: RNKLineTargetItem[];
  bollN?: string;
  bollP?: string;
  macdS?: string;
  macdL?: string;
  macdM?: string;
  kdjN?: string;
  kdjM1?: string;
  kdjM2?: string;
  rsiList?: RNKLineTargetItem[];
  wrList?: RNKLineTargetItem[];
}

export interface RNKLineConfigColorList {
  increaseColor?: RNKLineColorValue;
  decreaseColor?: RNKLineColorValue;
}

export interface RNKLineConfigList {
  colorList?: RNKLineConfigColorList;
  targetColorList?: RNKLineColorValue[];
  backgroundColor?: RNKLineColorValue;
  textColor?: RNKLineColorValue;
  gridColor?: RNKLineColorValue;
  candleTextColor?: RNKLineColorValue;
  minuteLineColor?: RNKLineColorValue;
  minuteGradientColorList?: RNKLineColorValue[];
  minuteGradientLocationList?: number[];
  panelBackgroundColor?: RNKLineColorValue;
  panelBorderColor?: RNKLineColorValue;
  panelTextColor?: RNKLineColorValue;
  selectedPointContainerColor?: RNKLineColorValue;
  selectedPointContentColor?: RNKLineColorValue;
  closePriceCenterBackgroundColor?: RNKLineColorValue;
  closePriceCenterBorderColor?: RNKLineColorValue;
  closePriceCenterTriangleColor?: RNKLineColorValue;
  closePriceCenterSeparatorColor?: RNKLineColorValue;
  closePriceRightBackgroundColor?: RNKLineColorValue;
  closePriceRightSeparatorColor?: RNKLineColorValue;
  closePriceRightLightLottieFloder?: string;
  closePriceRightLightLottieScale?: number;
  closePriceRightLightLottieSource?: string;
  panelGradientColorList?: RNKLineColorValue[];
  panelGradientLocationList?: number[];
  mainFlex?: number;
  volumeFlex?: number;
  paddingTop?: number;
  paddingBottom?: number;
  paddingRight?: number;
  itemWidth?: number;
  candleWidth?: number;
  minuteVolumeCandleColor?: RNKLineColorValue;
  minuteVolumeCandleWidth?: number;
  macdCandleWidth?: number;
  headerTextFontSize?: number;
  rightTextFontSize?: number;
  candleTextFontSize?: number;
  panelTextFontSize?: number;
  panelMinWidth?: number;
  fontFamily?: string;
  [key: string]: unknown;
}

export interface RNKLineDrawList {
  drawType?: number;
  shouldReloadDrawItemIndex?: number;
  drawShouldContinue?: boolean;
  drawShouldTrash?: boolean;
  shouldFixDraw?: boolean;
  shouldClearDraw?: boolean;
  shotBackgroundColor?: RNKLineColorValue;
  drawColor?: RNKLineColorValue;
  drawLineHeight?: number;
  drawDashWidth?: number;
  drawDashSpace?: number;
  drawIsLock?: boolean;
  [key: string]: unknown;
}

export interface RNKLineOptionList {
  modelArray?: RNKLineModelItem[];
  shouldScrollToEnd?: boolean;
  scrollEnabled?: boolean;
  fitBarsCount?: number;
  targetList?: RNKLineTargetList;
  configList?: RNKLineConfigList;
  drawList?: RNKLineDrawList;
  primary?: number;
  second?: number;
  time?: number;
  price?: number;
  volume?: number;
  [key: string]: unknown;
}

export type RNKLineOptionListSerialized = string;

export interface RNKLineViewProps extends ViewProps {
  optionList?: RNKLineOptionListSerialized | null;
  onDrawItemDidTouch?: (
    event: NativeSyntheticEvent<RNKLineDrawItemDidTouchPayload>,
  ) => void;
  onDrawItemComplete?: (
    event: NativeSyntheticEvent<RNKLineDrawItemCompletePayload>,
  ) => void;
  onDrawPointComplete?: (
    event: NativeSyntheticEvent<RNKLineDrawPointCompletePayload>,
  ) => void;
}

export type RNKLineViewComponent = HostComponent<RNKLineViewProps>;

declare const RNKLineView: RNKLineViewComponent;

export default RNKLineView;
