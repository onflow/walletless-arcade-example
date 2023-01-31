import { type NextApiRequest, type NextApiResponse } from "next";
import { generateKeys } from "../../../utils/crypto";
import { unstable_getServerSession } from "next-auth/next";
import { createAccount as createAccountUtil } from "../../../utils/flow";
import { prisma } from "../../../server/db/client";
import "../../../utils/fcl-setup";

const createAccount = async (req: NextApiRequest, res: NextApiResponse) => {
  if (req.method !== "POST") {
    res.status(405).send({ message: "Only POST requests allowed" });
    return;
  }

  const keys = await generateKeys();
  console.log("privateKey", keys.privateKey);
  console.log("publicKey", keys.publicKey);

  const address = await createAccountUtil(keys.publicKey);

  res.status(200).json({
    publicKey: keys.publicKey,
    privateKey: keys.privateKey,
    address,
  });
};

export default createAccount;
