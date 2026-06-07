// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = 22;
    uint256 internal constant PAYOUT_COUNT = 8;
    uint256 internal constant TOTAL_PAYOUT = 3000000;

    function publicSignals() internal pure returns (uint256[] memory values) {
        values = new uint256[](22);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 3000000;
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
        values[19] = 77;
        values[20] = 17045343719333710368585486555603294077572150615744050755244909649856120229432;
        values[21] = 3000000;
    }

    function amounts() internal pure returns (uint256[] memory values) {
        values = new uint256[](8);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 3000000;
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
            [uint256(10144832009344346148218280704824898254487838343450216420065598688741061415400), uint256(715464978767044300760828040921718010481211683599783965431124143010127646915)];
        uint256[2][2] memory b = [
            [uint256(15454533302774295104039308713985015572269483679552499564202793674109600431419), uint256(6359979686081809670684416145098030558015286946248753972032479262223841869916)],
            [uint256(11994914918706267970328454731872352255933554577474549320561232581495856138376), uint256(11253188054727311877114374418716256067768165037690228196452170259710748459263)]
        ];
        uint256[2] memory c =
            [uint256(16682407199349557743032741508616964936595314289098707370678627740513417054620), uint256(6871968612094629386528620050979028671648806292164371603245060257660373169112)];
        return abi.encode(a, b, c);
    }
}
