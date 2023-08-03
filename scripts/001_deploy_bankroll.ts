import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const Bankroll = await ethers.deployContract('Bankroll', {
    gasLimit: 5000000,
    gasPrice: process.env.GASPRICE || '',
  });

  const tx = await Bankroll.waitForDeployment();
  await tx.waitForDeployment();
  console.log('Bankroll address: ', await Bankroll.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
