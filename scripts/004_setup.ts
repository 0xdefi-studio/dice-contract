import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const bankroll = await ethers.getContractAt(
    'Bankroll',
    process.env.Bankroll || '',
  );

  // set game
  const tx = await bankroll.setGame(process.env.Dice || '', true, {
    gasLimit: 5000000,
    gasPrice: process.env.GASPRICE || '',
  });
  console.log('tx set game: ', tx.hash);
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
