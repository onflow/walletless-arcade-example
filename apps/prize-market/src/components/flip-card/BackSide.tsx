import React from "react";
import type { FlippyCardProps } from "./FlippyCard";
import FlippyCard from "./FlippyCard";

interface BackSideProps extends FlippyCardProps {
  style?: object;
}

const BackSide: React.FC<BackSideProps> = ({ style, ...props }) => (
  <FlippyCard
    {...props}
    style={{
      ...(style || {}),
    }}
    cardType="back"
  />
);

export default BackSide;
