// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RewardProofFixture {
    uint256 internal constant PUBLIC_SIGNAL_COUNT = 33;
    uint256 internal constant PAYOUT_COUNT = 8;
    uint256 internal constant TOTAL_PAYOUT = 6000000;
    uint256 internal constant SEED_PREIMAGE = 6369799371949277253245012598200008375444034372419484131652248751882103295441;
    bytes32 internal constant SEED_SALT = 0x37d63a7694b90b7f0ea0fbaa6a94b2611df1180610ab390d9b673b3d20037e27;
    bytes32 internal constant SEED_COMMITMENT = 0x39de86ff1facf4e76d4e64890e319d987c16825df4f926c1d8e149cbe1c3acdb;
    uint256 internal constant RANDOM_SEED = 3572405806052100322862918638837119239699684882178995387621972326006089166157;

    function publicSignals() internal pure returns (uint256[] memory values) {
        values = new uint256[](33);
        values[0] = 3000000;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 3000000;
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
        values[27] = 3000000;
        values[28] = 78;
        values[29] = 14695795747349035543706149517880938740666020856823802164744237392406265945397;
        values[30] = 24000000;
        values[31] = 214748364;
        values[32] = 3572405806052100322862918638837119239699684882178995387621972326006089166157;
    }

    function amounts() internal pure returns (uint256[] memory values) {
        values = new uint256[](8);
        values[0] = 3000000;
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
            [uint256(5217487984967393676058411753109805114147798291135739656792391063527745971595), uint256(21020490592167709738426000610994657525242414124377060535914949061640815121625)];
        uint256[2][2] memory b = [
            [uint256(196134082764367307540717122134045232430661455332025095192470954122607039924), uint256(12774835759147610193188129845236865815992966893818817746840638432336247849684)],
            [uint256(11316390872028775138878568509622626583386354937832296079947931176947143549622), uint256(742487650216226059512447079019014735238189087518516190854184705504190983051)]
        ];
        uint256[2] memory c =
            [uint256(10050947913094599594096676385385266999323965908614694045882743732226322674975), uint256(20693471288844130655179036718523071788866301942593244335996811355813960274775)];
        return abi.encode(a, b, c);
    }
}
