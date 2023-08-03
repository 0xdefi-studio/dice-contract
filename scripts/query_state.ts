import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const [owner] = await ethers.getSigners();
  const dice = await ethers.getContractAt('Dice', process.env.Dice || '');
  const state = await dice.Dice_GetState(owner.address);
  console.log('state: ', state);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
