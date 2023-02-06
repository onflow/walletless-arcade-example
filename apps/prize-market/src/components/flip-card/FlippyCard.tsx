import React from "react";
import type { ReactNode } from "react";

export interface FlippyCardProps {
  className?: string;
  cardType: string;
  style?: object;
  elementType?: keyof JSX.IntrinsicElements;
  animationDuration?: number;
  children?: ReactNode;
}

const FlippyCard: React.FC<FlippyCardProps> = ({
  className,
  cardType,
  style,
  elementType,
  animationDuration = 600,
  children,
}) => {
  return React.createElement(
    elementType || "div",
    {
      className: `flippy-card flippy-${cardType} ${className || ""}`,
      style: {
        ...(style || {}),
        ...{ transitionDuration: `${animationDuration / 1000}s` },
      },
    },
    children
  );
};

export default FlippyCard;
