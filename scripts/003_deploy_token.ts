import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const token = await ethers.deployContract(
    'Token',
    ['10000000000000000000000'],
    {
      gasLimit: 5000000,
      gasPrice: process.env.GASPRICE || '',
    },
  );

  await token.waitForDeployment();
  console.log('Token address: ', await token.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
