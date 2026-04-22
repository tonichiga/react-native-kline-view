import React, { useState, useCallback } from "react";
import { View, StyleSheet, requireNativeComponent } from "react-native";

const RNKLineViewNative = requireNativeComponent("RNKLineView");

function RNKLineView({ tradeComponent, style, ...props }) {
  const [markers, setMarkers] = useState([]);

  const onTradeMarkersLayout = useCallback((event) => {
    setMarkers(event.nativeEvent.markers || []);
  }, []);

  return (
    <View style={style}>
      <RNKLineViewNative
        {...props}
        style={StyleSheet.absoluteFill}
        useCustomTradeMarker={!!tradeComponent}
        onTradeMarkersLayout={tradeComponent ? onTradeMarkersLayout : undefined}
      />
      {tradeComponent &&
        markers.map((marker) => {
          const trade = {
            id: String(marker.timestamp) + "_" + marker.type,
            timestamp: marker.timestamp,
            price: marker.price,
            type: marker.type,
          };
          return (
            <View
              key={trade.id}
              pointerEvents="none"
              style={{
                position: "absolute",
                left: marker.x,
                top: marker.y,
              }}
            >
              {tradeComponent(trade, marker.count)}
            </View>
          );
        })}
    </View>
  );
}

export default RNKLineView;
