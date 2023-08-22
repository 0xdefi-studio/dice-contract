import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const house = await ethers.getContractAt(
    'Bankroll',
    process.env.Bankroll || '',
  );
  const [owner] = await ethers.getSigners();
  console.log('owner: ', owner.address);
  const tx = await house.deposit(ethers.parseEther('1'), '', {
    gasLimit: 5000000,
    gasPrice: process.env.GASPRICE || '',
  });
  await tx.wait();
  const previewWithdraw = await house.maxWithdraw('');
  console.log('max withdraw: ', previewWithdraw);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
