export const getString = (value: unknown): string => {
  if (typeof value === "string") return value;
  if (Array.isArray(value) && value.length > 0 && typeof value[0] === "string") {
    return value[0];
  }
  return "";
};

export const getOptionalString = (value: unknown): string | undefined => {
  const normalized = getString(value).trim();
  return normalized.length > 0 ? normalized : undefined;
};
