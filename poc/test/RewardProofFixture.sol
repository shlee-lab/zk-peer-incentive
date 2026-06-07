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
        values[19] = 78;
        values[20] = 7747586990438478377040476295415066244160110975964786170833313685388274660466;
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
            [uint256(16306281293807304711560260380368026606516097907044194757559586036862798920713), uint256(10897683697362080674774717376254058286997119981080240522134294810183766713864)];
        uint256[2][2] memory b = [
            [uint256(6324116774584361158172701818016148453099490553930673615154811267752696635453), uint256(398021519138162482726991252738055400203094779486267384750125719060786502782)],
            [uint256(11842097999965129186898132314012972721186924901144912282408542656987527919734), uint256(3876065198947116448767368629275145656539037154695246646306004521182458377857)]
        ];
        uint256[2] memory c =
            [uint256(11789916663739931357199328846807257739861025116643556490411725543350107276125), uint256(13657146527052470555099292818469447810667929837995041020317742013487512353846)];
        return abi.encode(a, b, c);
    }
}
