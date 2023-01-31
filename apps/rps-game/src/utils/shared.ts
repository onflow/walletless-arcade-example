export const delay = (ms = 0) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

export const yup = (tag: string) => (d: unknown) => (
  console.log(`${tag}`, d), d
);
export const nope = (tag: string) => (d: unknown) => (
  console.error(`Oh No!! [${tag}]`, d), d
);
