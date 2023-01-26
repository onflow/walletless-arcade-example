const SESSION_KEY = "flow-games-retro-session";

export async function getSession() {
  const session = window.localStorage.getItem(SESSION_KEY);
  return session ? JSON.parse(session) : null;
}

export async function setSession({
  gameAccountPrivateKey,
  gameAccountPublicKey,
  gameAccountAddress = null,
  parentAccountAddress = null,
  parentAccountWalletConnected = false,
}: {
  gameAccountPrivateKey: string | null;
  gameAccountPublicKey: string | null;
  gameAccountAddress: string | null;
  parentAccountAddress?: string | null;
  parentAccountWalletConnected?: boolean;
}) {
  window.localStorage.setItem(
    SESSION_KEY,
    JSON.stringify({
      gameAccountPrivateKey,
      gameAccountPublicKey,
      gameAccountAddress,
      parentAccountAddress,
      parentAccountWalletConnected,
    })
  );
}
