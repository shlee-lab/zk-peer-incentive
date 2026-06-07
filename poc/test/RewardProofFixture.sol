// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = 31;
    uint256 internal constant PAYOUT_COUNT = 8;
    uint256 internal constant TOTAL_PAYOUT = 3000000;

    function publicSignals() internal pure returns (uint256[] memory values) {
        values = new uint256[](31);
        values[0] = 3000000;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 0;
        values[5] = 0;
        values[6] = 0;
        values[7] = 0;
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
        values[27] = 78;
        values[28] = 14695795747349035543706149517880938740666020856823802164744237392406265945397;
        values[29] = 9263339189501945826388293463996074031888061588302967159355430724061076023359;
        values[30] = 3000000;
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
            [uint256(20604426191217326589294180227845810801573186034002614015823249194252877887644), uint256(15295631512504575504247670290665399860957024774417821463825779577367741428672)];
        uint256[2][2] memory b = [
            [uint256(20642915248774808400211154628468098865440496125944731549607858109539565514514), uint256(11023133776725907221083576704870229532709550197423923347347170214774883564556)],
            [uint256(9687701868390883697268065612372939437544985188873680022299194842812457132288), uint256(2232796652011268069270939269093207431263905060049549090755675723693857948930)]
        ];
        uint256[2] memory c =
            [uint256(11836217058103824130414268748315420946821132511063991458362372501309650416015), uint256(8536721672936059489536466011542631578823986011167429232222983567212680393832)];
        return abi.encode(a, b, c);
    }
}
