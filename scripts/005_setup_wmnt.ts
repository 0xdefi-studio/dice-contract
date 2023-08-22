import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const bankroll = await ethers.getContractAt(
    'Bankroll',
    process.env.Bankroll || '',
  );

  // set token address
  const tx_set_token = await bankroll.setTokenAddress(
    process.env.Token || '',
    true,
    {
      gasLimit: 5000000,
      gasPrice: process.env.GASPRICE || '',
    },
  );
  console.log('tx token address: ', tx_set_token.hash);
  await tx_set_token.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
