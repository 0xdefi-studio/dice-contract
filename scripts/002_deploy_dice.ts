import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const [owner] = await ethers.getSigners();
  const Dice = await ethers.deployContract(
    'Dice',
    [process.env.Bankroll || '', owner],
    {
      gasLimit: 5000000,
      gasPrice: process.env.GASPRICE || '',
    },
  );

  const tx = await Dice.waitForDeployment();
  await tx.waitForDeployment();
  console.log('Dice address: ', await Dice.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
