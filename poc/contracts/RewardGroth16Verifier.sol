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
    uint256 constant deltax1 = 15683059922831506164872473699110619864936867240814222799500164333091103672923;
    uint256 constant deltax2 = 11134892339272906578508408668036537987529015690305804684506677788736680331079;
    uint256 constant deltay1 = 19124225103186827575000286268455179151398886676446500991436229972636506640619;
    uint256 constant deltay2 = 11619612023365539818292424091781333985053365490839243141476169277310919884196;


    uint256 constant IC0x = 20372011163479891494969227777708178955710912461089448897724401331106457630597;
    uint256 constant IC0y = 8129685079221918164041304246618877729630109846487010390739879585444481913882;

    uint256 constant IC1x = 15715878842223790988880747515305058503886531955065128876512846533353998604842;
    uint256 constant IC1y = 760678406232336025305983818297118641639855533833453173222190338840170227149;

    uint256 constant IC2x = 14463020063474664455607452850951518367728758444385616747667188525937396109435;
    uint256 constant IC2y = 15979259542208647232070992255207976645450286390888727871286193316079605096787;

    uint256 constant IC3x = 6777646398663656638842629676453643190531423529798749268930582042553616041936;
    uint256 constant IC3y = 2259180713591565842846880950857589594607350243880193468722207571539751985375;

    uint256 constant IC4x = 19413984002159988896876119013601599653181438582853524834864160673928824155772;
    uint256 constant IC4y = 7058188811195701066971166448502429079148802581362996486787057577579617886123;

    uint256 constant IC5x = 8248473601722327473153409821096688604494644083506147194669066858184941429273;
    uint256 constant IC5y = 1002659895713915094562498104180391740972579526317333380715304757422567338954;

    uint256 constant IC6x = 15103800323967870634909539913785554357359438883237555088256172120323600609471;
    uint256 constant IC6y = 14354177814692250277011755184718130728250886590463252368537272550637079784311;

    uint256 constant IC7x = 8639635920535554734018602770053880821718775279405177847652974915959861724186;
    uint256 constant IC7y = 19630430432260896975323122472703025946967620564684322184241598387978307371430;

    uint256 constant IC8x = 21108885165839422938294007829488772840413424508861888237523449418001003765294;
    uint256 constant IC8y = 7883156605370527972301147059396829300359383643063762107349048062307304250584;

    uint256 constant IC9x = 1911243558838891535377563485734596877334110499633199843001756133780024279808;
    uint256 constant IC9y = 12092898397526842715342414516001106980760682405886791403607202017791593598205;

    uint256 constant IC10x = 10432364218436842514533993690705650823527205623722653155730133399691798149945;
    uint256 constant IC10y = 1748210257357737694095239564027157980726923347320460901857116075512578858172;

    uint256 constant IC11x = 6725363487351790980105856178645658278142284494339235954209858913257422640972;
    uint256 constant IC11y = 4388572250079492414158526721330079577364689574347255301072458589007932338305;

    uint256 constant IC12x = 15670795595840661608843887743768214698512191910454848754429940866943208914543;
    uint256 constant IC12y = 16076921906789343643834953128956121555593307673909224298727043475845702663777;

    uint256 constant IC13x = 16976490932922432117599595074652024173013205187609980529747426376015706842984;
    uint256 constant IC13y = 8890475594809008875221200178417165916115205662509311785367435227985048487911;

    uint256 constant IC14x = 18862189612363884927559553906730541582035740348899162470982553526197819096334;
    uint256 constant IC14y = 6951012005297155090194179043151600227526648995957529133674760862423051860585;

    uint256 constant IC15x = 14551645382572283840074578431226635407587307335254573967204244352092927595814;
    uint256 constant IC15y = 3485898461274487846873963131005114399225100705639452182026729093808893714529;

    uint256 constant IC16x = 5291067650343295957403787105431545187628007747610079689559713254909874612739;
    uint256 constant IC16y = 2588231141390043410771707068977334522877183418898106625541097064101049383131;

    uint256 constant IC17x = 2873421289086308886024731862863938552087340408442008400563742919039009673280;
    uint256 constant IC17y = 9642456179223991752786566584176961658490737787846074164614501622840685010828;

    uint256 constant IC18x = 10448809430320053009940612693943923941738240479031153393864828906528499672567;
    uint256 constant IC18y = 11302851967675206619832118792122386822782407930767177880038585116280729398850;

    uint256 constant IC19x = 3445305925964129566256122122392259351067258603881322558110508873386088022813;
    uint256 constant IC19y = 11692190241254977058042696841920801807416573005850507569430567672871139880858;

    uint256 constant IC20x = 13736337116466779226217459555137849185372083825228383692136130814650738014628;
    uint256 constant IC20y = 19127614943501443469250337997827525888720261848037901443304955490800894163555;

    uint256 constant IC21x = 20726752709770738437761062823254902118784550859947659325384140906056506806265;
    uint256 constant IC21y = 20839416133358048123377401943753873533210803030783506865944572315118884760756;

    uint256 constant IC22x = 19246927212753153832943483705722218273763716007114177250210811642683288907605;
    uint256 constant IC22y = 13516798398914185451420594236169099314467402618825154108336024475769356799397;

    uint256 constant IC23x = 3489385650677967204428500158629725670735772725219507800566027435384669523080;
    uint256 constant IC23y = 14171955951553931288745152404451359590985291783681155434909107135370428620253;

    uint256 constant IC24x = 11169317960144271868144478101721904933832266209481786126259547332422763813446;
    uint256 constant IC24y = 17864255486362180083011407109337756538938505973737493381377516563370136710390;

    uint256 constant IC25x = 3163175750006691810658739101252434128150786144415128900155562585820401703242;
    uint256 constant IC25y = 14567780193288979630212537359659232352453050627205174634369077531326066799730;

    uint256 constant IC26x = 19991971417942635130382600584437474770039449191308534657859203099736597346901;
    uint256 constant IC26y = 8515721072370042607584204266375188274165986620497835299583271997827119570051;

    uint256 constant IC27x = 15779877097005599626082920659764456734905427705081386882635361329867665009369;
    uint256 constant IC27y = 18232097702990773636244037095230088239353885908827846867581428513761254451072;

    uint256 constant IC28x = 20177567302147741018547362499600937408099038157436394397689551971730284344003;
    uint256 constant IC28y = 10798132543702402962626444955888015329798297581915636298518077402687406576132;

    uint256 constant IC29x = 4552468526350184437311837797850720975982604711321167301848175536784531194563;
    uint256 constant IC29y = 5628142608187391601407271896964197562285093112924842386084294587626389870902;

    uint256 constant IC30x = 1536003079772159720538759812954179522861777652642129853844517593715408047716;
    uint256 constant IC30y = 17681142714272155310429840547722963176219694845421959329882818382091702430100;

    uint256 constant IC31x = 14750836037639878932200054741520322278448933861589567932101623170638201694603;
    uint256 constant IC31y = 16902532670250557516346194032067683693151943206676475454641814463077407855363;

    uint256 constant IC32x = 11009354334859927499614107008878542465033096839795429368331293653766657829045;
    uint256 constant IC32y = 9665837789853496564049027373976106583201551292839807503797370146768925357373;

    uint256 constant IC33x = 6264765188368591268936161505043870495223289602535113482340723282084121862924;
    uint256 constant IC33y = 17191558277411883187579871085302764316799558585054122838690782811295340521647;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[33] calldata _pubSignals) public view returns (bool) {
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

                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))

                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))


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

            checkField(calldataload(add(_pubSignals, 992)))

            checkField(calldataload(add(_pubSignals, 1024)))


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
