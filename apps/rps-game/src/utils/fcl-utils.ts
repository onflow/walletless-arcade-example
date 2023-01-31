// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck

export function serviceOfType(services = [], type) {
  return services.find((service) => service.type === type);
}
