import * as shared from "./shared";
import * as fclUtils from "./fcl-utils";

export default function useUtils() {
  return { ...shared, ...fclUtils };
}
