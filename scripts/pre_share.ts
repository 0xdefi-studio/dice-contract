import { ethers } from 'hardhat';
import { resolve } from 'path';
import { config as dotenvConfig } from 'dotenv';

dotenvConfig({ path: resolve(__dirname, './.env') });

async function main() {
  const house = await ethers.getContractAt(
    'Bankroll',
    process.env.Bankroll || '',
  );
  const totalSupply = await house.totalSupply();
  console.log('total supply: ', totalSupply);

  const totalAsset = await house.totalAssets();
  console.log('total asset: ', totalAsset);

  const d = ethers.parseEther('50');
  console.log('d: ', d);
  const shares = await house.convertToShares(d);
  console.log('shares: ', shares);
}

// 100000000000000000000
// 50000000000000000000

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
