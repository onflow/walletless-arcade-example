import React from "react";
import type { FlippyCardProps } from "./FlippyCard";
import FlippyCard from "./FlippyCard";

interface FrontSideProps extends FlippyCardProps {
  style?: object;
}

const FrontSide: React.FC<FrontSideProps> = ({ style, ...props }) => (
  <FlippyCard
    {...props}
    style={{
      ...(style || {}),
    }}
    cardType="front"
  />
);

export default FrontSide;
