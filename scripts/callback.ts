import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const dice = await ethers.getContractAt('Dice', process.env.Dice || '');
  const tx = await dice.randomizerCallback(5, ethers.randomBytes(32), {
    gasLimit: 5000000,
    gasPrice: process.env.GASPRICE || '',
  });
  await tx.wait();
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
