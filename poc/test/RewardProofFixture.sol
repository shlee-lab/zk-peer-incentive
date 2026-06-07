// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = 22;
    uint256 internal constant PAYOUT_COUNT = 8;
    uint256 internal constant TOTAL_PAYOUT = 3000000;

    function publicSignals() internal pure returns (uint256[] memory values) {
        values = new uint256[](22);
        values[0] = 3000000;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 0;
        values[5] = 0;
        values[6] = 0;
        values[7] = 0;
        values[8] = 10;
        values[9] = 20;
        values[10] = 10;
        values[11] = 15;
        values[12] = 5;
        values[13] = 10;
        values[14] = 15;
        values[15] = 15;
        values[16] = 1;
        values[17] = 100;
        values[18] = 1000;
        values[19] = 78;
        values[20] = 3980522443044212361570141811884742959701655548695247981250487931585868214931;
        values[21] = 3000000;
    }

    function amounts() internal pure returns (uint256[] memory values) {
        values = new uint256[](8);
        values[0] = 3000000;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 0;
        values[5] = 0;
        values[6] = 0;
        values[7] = 0;
    }

    function recipients() internal pure returns (address[] memory values) {
        values = new address[](8);
        values[0] = address(uint160(4096));
        values[1] = address(uint160(4097));
        values[2] = address(uint160(4098));
        values[3] = address(uint160(4099));
        values[4] = address(uint160(4100));
        values[5] = address(uint160(4101));
        values[6] = address(uint160(4102));
        values[7] = address(uint160(4103));
    }

    function proof() internal pure returns (bytes memory) {
        uint256[2] memory a =
            [uint256(3922544968279693678397116953195683114201954596813292378212081585664601150402), uint256(10074219871595291109370770384251922101005673710923834162863796877625585090512)];
        uint256[2][2] memory b = [
            [uint256(1139523943332172757598721011267483642230884205041613278837106444538875661999), uint256(15456693716190501128005913423908143064328471449209202660829918501658654800568)],
            [uint256(21555971874606654788100435505321017479401161518019431262315533916989708050853), uint256(21654515940728811017704278403002096508529297475721811853330427792792008147875)]
        ];
        uint256[2] memory c =
            [uint256(1887949484987492934992660482450367688953896130085733568869859857535973983715), uint256(15118111851215392614312505610471243554227025729393161424812654380289959877825)];
        return abi.encode(a, b, c);
    }
}
