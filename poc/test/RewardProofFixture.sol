// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = 31;
    uint256 internal constant PAYOUT_COUNT = 8;
    uint256 internal constant TOTAL_PAYOUT = 3000000;

    function publicSignals() internal pure returns (uint256[] memory values) {
        values = new uint256[](31);
        values[0] = 2993018;
        values[1] = 997;
        values[2] = 997;
        values[3] = 997;
        values[4] = 997;
        values[5] = 997;
        values[6] = 997;
        values[7] = 1000;
        values[8] = 642829559307850963015472508762062935916233390536;
        values[9] = 344073830386746567427978432078835137280280269756;
        values[10] = 827616541489050293873067319834814086332722428166;
        values[11] = 124600769394618761707529974069218112888608942693;
        values[12] = 875734974754274547701265637215306557576585454812;
        values[13] = 864525257947771085510183188952227776536258415273;
        values[14] = 119096571092301921719253721560231391405901977941;
        values[15] = 201990263407130541861732429012178345511141645967;
        values[16] = 10;
        values[17] = 20;
        values[18] = 10;
        values[19] = 15;
        values[20] = 5;
        values[21] = 10;
        values[22] = 15;
        values[23] = 15;
        values[24] = 1;
        values[25] = 100;
        values[26] = 1000;
        values[27] = 3000000;
        values[28] = 78;
        values[29] = 14695795747349035543706149517880938740666020856823802164744237392406265945397;
        values[30] = 3000000;
    }

    function amounts() internal pure returns (uint256[] memory values) {
        values = new uint256[](8);
        values[0] = 2993018;
        values[1] = 997;
        values[2] = 997;
        values[3] = 997;
        values[4] = 997;
        values[5] = 997;
        values[6] = 997;
        values[7] = 1000;
    }

    function recipients() internal pure returns (address[] memory values) {
        values = new address[](8);
        values[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        values[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        values[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        values[3] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        values[4] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
        values[5] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        values[6] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        values[7] = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    }

    function proof() internal pure returns (bytes memory) {
        uint256[2] memory a =
            [uint256(17715873573845208073690912349026001149711897340568360595563670609250541721091), uint256(19334784713226379717839345947191231921273743444872620000083288136802536987484)];
        uint256[2][2] memory b = [
            [uint256(17543569218779784095084308874738450474747257439930022278223189372223918591542), uint256(17489827326010960882142776645300789111092750235410408852742512461048895880119)],
            [uint256(12820320018151513805961682559013238466699541620520847245829333535747974909942), uint256(382767978345440978004981686515734379935843070934578591009096369770527987953)]
        ];
        uint256[2] memory c =
            [uint256(439122413594290122658850265402418620263831836602133819688040741558777230668), uint256(13960507916283972372470558534414441427627384649481387244908701665243098596390)];
        return abi.encode(a, b, c);
    }
}
