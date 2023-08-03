import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const dice = await ethers.getContractAt('Dice', process.env.Dice || '');
  const token = process.env.Token || '';
  const Token = await ethers.getContractAt('Token', token);
  const tx_approve = await Token.approve(
    await dice.getAddress(),
    '10000000000000000000',
  );
  console.log('tx_approve: ', tx_approve.hash);
  await tx_approve.wait();
  const tx = await dice.Dice_Play(
    '10000000000000000000',
    '20000',
    token,
    true,
    1,
    '10000000000000000000',
    '500000000000000000',
  );
  console.log('tx: ', tx.hash);
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
