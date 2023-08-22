import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  // transfer balance to dice contract
  const Token = await ethers.getContractAt('Token', process.env.Token || '');
  const tx = await Token.transfer('', '100000000000000000000', {
    gasLimit: 5000000,
    gasPrice: process.env.GASPRICE || '',
  });
  console.log('tx fund: ', tx.hash);
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
