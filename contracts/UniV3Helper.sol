
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IUniswapV3.sol";

/// @title UniV3Helper
/// @dev Helper contract to interact with Uniswap V3 pool contracts.
contract UniV3Helper {
    int24 private constant _MIN_TICK = -887272;
    int24 private constant _MAX_TICK = -_MIN_TICK;

    /**
     * @notice Fetches tick data for a specified range from a Uniswap V3 pool.
     * @dev The function returns an array of bytes each containing packed data about each tick in the specified range.
     * The returned tick data includes the total liquidity, liquidity delta, outer fee growth for the two tokens, and
     * the tick value itself. The tick range is centered around the current tick of the pool and spans tickRange*2.
     * The tick range is constrained by the global min and max tick values.
     * If there are no initialized ticks in the range, the function returns an empty array.
     * @param pool The Uniswap V3 pool from which to fetch tick data.
     * @return ticks An array of bytes each containing packed data about each tick in the specified range.
     */
    function getTicks(IUniswapV3 pool, int24 fromTick, int24 toTick) external view returns (bytes[] memory ticks) {
        int24 tickSpacing = pool.tickSpacing();
        
        require(fromTick <= toTick, "fromtick > totick");
        require(fromTick >= _MIN_TICK && toTick <= _MAX_TICK, "tick out of range");
        
        

        int24[] memory initTicks = new int24[](uint256(int256((toTick - fromTick + 1) / tickSpacing)));

        uint256 counter = 0;
        int16 pos = int16((fromTick / tickSpacing) >> 8);
        int16 endPos = int16((toTick / tickSpacing) >> 8);
        for (; pos <= endPos; pos++) {
            uint256 bm = pool.tickBitmap(pos);

            while (bm != 0) {
                uint8 bit = BitMath.leastSignificantBit(bm);
                bm ^= 1 << bit;
                int24 extractedTick = ((int24(pos) << 8) | int24(uint24(bit))) * tickSpacing;
                if (extractedTick >= fromTick && extractedTick <= toTick) {
                    initTicks[counter++] = extractedTick;
                }
            }
        }

        ticks = new bytes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            (
                , // uint128 liquidityGross,
                int128 liquidityNet,
                 // uint256 feeGrowthOutside0X128,
                ,// uint256 feeGrowthOutside1X128
                , // int56 tickCumulativeOutside,
                , // secondsPerLiquidityOutsideX128
                , // uint32 secondsOutside
                , // init
            ) = pool.ticks(initTicks[i]);

            ticks[i] = abi.encodePacked(
                // liquidityGross,
                liquidityNet,
                // feeGrowthOutside0X128,
                // feeGrowthOutside1X128,
                // tickCumulativeOutside,
                // secondsPerLiquidityOutsideX128,
                // secondsOutside,
                initTicks[i]
            );
        }
    }
}
