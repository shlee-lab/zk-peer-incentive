// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 4214479445804975612936838715263738492869065514239659874238767555473858797741;
    uint256 constant alphay  = 16425448598480027963938942919583855862599224681327261187137688547542283748707;
    uint256 constant betax1  = 8599676613693470034736635823569791247839384499129936922181268973158456650271;
    uint256 constant betax2  = 13307909728026998544552201791815306782002305306990376761705951637535281190469;
    uint256 constant betay1  = 16703462388693465354451678046054573993694015488012555844413838272037335145806;
    uint256 constant betay2  = 18550169857157266898117932130621559598541353131655831739981209430185900928401;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 19668549797504091066553511055292243266090074808087753879010570056908471646235;
    uint256 constant deltax2 = 17946286627631601853699349247082854681819941955544511324007889380628595587757;
    uint256 constant deltay1 = 18086538988814537889625010137135787417774738295564499404971197831599250693390;
    uint256 constant deltay2 = 17618179962456953332296476471183407644321560309461045968052384597680571677578;


    uint256 constant IC0x = 12290732990247045744686578252335556517432565153059976966335375973024789161806;
    uint256 constant IC0y = 896925765614083169974000922867913617687236938150389999375009681054277936618;

    uint256 constant IC1x = 11863599994417217546703381780448295253469680275134514249533427119193046433945;
    uint256 constant IC1y = 20267417552399444180547024900645540859795656235067230850150733623039480854337;

    uint256 constant IC2x = 12002294618206218667389752579915466984360339480063234005495508537035234431922;
    uint256 constant IC2y = 1468477955887703237429006227180852375897515663535342996056275190729676293009;

    uint256 constant IC3x = 19272053559298253367577456668569627362862313082666083277100286796421770852947;
    uint256 constant IC3y = 12954937584976985222552212180674296636963095927992373000004481189877327077155;

    uint256 constant IC4x = 20511124743129359188814246720324522823273770912601338058512199391792132863673;
    uint256 constant IC4y = 12272548116163361259159029913758530583720835218400662532871326329783136295953;

    uint256 constant IC5x = 7937311771322112617197005218429919892877448130963224055762437791571616721756;
    uint256 constant IC5y = 8062969090189643337278765708913587234841553270792495417915323191518822857107;

    uint256 constant IC6x = 5703081375676566344460091719643940638629736865636524051206687005454665923480;
    uint256 constant IC6y = 17402700698531488026179761578478130173515125659980848237684167390707991687785;

    uint256 constant IC7x = 3585928735060687721253627409233938407195505898366235563844332544648795733395;
    uint256 constant IC7y = 17883633046796394213436184024111579859811361757334263164973104815538314709916;

    uint256 constant IC8x = 1741660667709753970068048415921536432555817118101404941832418135053972251194;
    uint256 constant IC8y = 11157654759645129771657958134486041479804859837314568450765959927320339236878;

    uint256 constant IC9x = 17136655644018036216852821946594600477041872294068807395625908131974512739372;
    uint256 constant IC9y = 2663186291123422539606632299807728021517660015116391942490517386037129051219;

    uint256 constant IC10x = 14117696190048050546980027103025784115798549664295982637573026422066695240142;
    uint256 constant IC10y = 20207302583449268243650060732569773479611606602143409384588960408961584102347;

    uint256 constant IC11x = 18931715956564938495405860376974235766163376269240861975806002618462389069226;
    uint256 constant IC11y = 14412269450331140913155844121995466759775045825055301038616283546007053949648;

    uint256 constant IC12x = 2749795546446890575341497170562572348564191898947560182409184839329430411380;
    uint256 constant IC12y = 15730300265367851148056027396941009942420768033919043303144518118764883106782;

    uint256 constant IC13x = 788085684670866145423186429311542983671523566953650440979105080860121451280;
    uint256 constant IC13y = 957246163447861850197680024306929070790217667166330018613404999633770950871;

    uint256 constant IC14x = 1760091420217694743348465177835876724408682922427766956390733484279879510111;
    uint256 constant IC14y = 13716978835242113651621573941442599880418214931159098937400385626588132999925;

    uint256 constant IC15x = 12301291689368647799811134557893734965302494506718674017911129164874238242716;
    uint256 constant IC15y = 2730794134535558527225367800369731180528364783332994361120644054004841668588;

    uint256 constant IC16x = 14711551605312179765122626516777807882389213968131858308730571781788255941207;
    uint256 constant IC16y = 17742057389222567960497860736243749059836144174170995697262444693903478250879;

    uint256 constant IC17x = 4092067773249070451582669491379207895882483007375579652375191294690738833144;
    uint256 constant IC17y = 3400928726206329465389562327513857399708249329520734768571747670384379551567;

    uint256 constant IC18x = 20239084574094950151382358022237627997484929767401653137713153879863006289936;
    uint256 constant IC18y = 10973744191413611676036129947708663910322262721383839449849697791472006819044;

    uint256 constant IC19x = 271677274013309358668251735451556731117342662185141242912098127046109580986;
    uint256 constant IC19y = 19688924587351724887811467286289308039853917261978682120820562830438309763122;

    uint256 constant IC20x = 6241862984198062445104379208284405535824878792497117646168306907121472626110;
    uint256 constant IC20y = 8443804010626584992355757252784576344072159173087632103716122385593074596303;

    uint256 constant IC21x = 904883021833151638501382630489408887320901069742894437211329638778035435544;
    uint256 constant IC21y = 13187738295200527661800329546086330478315971781721367281989105897533803382318;

    uint256 constant IC22x = 6942435664009237219079444916399836547351771533940199920492637357056374327448;
    uint256 constant IC22y = 19516709419217297321760385434066669977800350328227817124141229350864131214342;

    uint256 constant IC23x = 270842924903540586595602169432787548918288563260781819010403110149203573970;
    uint256 constant IC23y = 12449826119360886947996408129448149886844024882591289130186688844627318830520;

    uint256 constant IC24x = 6314213050996646194950919583596806190949311712223819250745507758210915070896;
    uint256 constant IC24y = 15001767804840148055505871541630906438981668951987260794352166645726694720900;

    uint256 constant IC25x = 4646730761243243282889556898933570363998206091595053599763220502911990270062;
    uint256 constant IC25y = 5006199209367800349994620854781480976500642098577018009709289918457203465447;

    uint256 constant IC26x = 5262896824892239021154690707614555067111717415803688919796821074392549456801;
    uint256 constant IC26y = 4506818920455541837552714290304584317762974492612682512407627064229765806160;

    uint256 constant IC27x = 11712227221506623700828586218369757980198301693764060386156666173545590017465;
    uint256 constant IC27y = 14569923421805006305487842352770242037067576760750015742711884330317772004101;

    uint256 constant IC28x = 11602915456424658272672660734392317456987427300597246781480231100502328341129;
    uint256 constant IC28y = 10317426867747995606376191689927754713437891805331076416456773351499282400848;

    uint256 constant IC29x = 19813728654802775801447678320055683679720127954522824082381242144645871285382;
    uint256 constant IC29y = 18151583240304662876599306650549527121929323786233691135187488484736746557427;

    uint256 constant IC30x = 13948057060020375940850096459928077870813454047145724120579938855505951797253;
    uint256 constant IC30y = 20963738306211300707891075387422853283493727619424136375940750182174211582526;

    uint256 constant IC31x = 18577876102383601889740823098323736508099833132049715522109655771215905232120;
    uint256 constant IC31y = 14042392037195576957932338076548481134526941490973263173811664620528329119991;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[31] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))

                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))

                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))

                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))

                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))

                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))

                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))

                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))

                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))

                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))

                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))

                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))

                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))


                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))

            checkField(calldataload(add(_pubSignals, 448)))

            checkField(calldataload(add(_pubSignals, 480)))

            checkField(calldataload(add(_pubSignals, 512)))

            checkField(calldataload(add(_pubSignals, 544)))

            checkField(calldataload(add(_pubSignals, 576)))

            checkField(calldataload(add(_pubSignals, 608)))

            checkField(calldataload(add(_pubSignals, 640)))

            checkField(calldataload(add(_pubSignals, 672)))

            checkField(calldataload(add(_pubSignals, 704)))

            checkField(calldataload(add(_pubSignals, 736)))

            checkField(calldataload(add(_pubSignals, 768)))

            checkField(calldataload(add(_pubSignals, 800)))

            checkField(calldataload(add(_pubSignals, 832)))

            checkField(calldataload(add(_pubSignals, 864)))

            checkField(calldataload(add(_pubSignals, 896)))

            checkField(calldataload(add(_pubSignals, 928)))

            checkField(calldataload(add(_pubSignals, 960)))


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
