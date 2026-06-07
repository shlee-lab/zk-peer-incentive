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
    uint256 constant deltax1 = 20373920816889607558482283594089590731261636683129487727175435261992816041924;
    uint256 constant deltax2 = 6615756718062814621964580155068131953449417686842087538106614009415563094364;
    uint256 constant deltay1 = 4945376395577578197650864280247137269754546063641811158723087960261785464133;
    uint256 constant deltay2 = 4714896669825542748972170989685802120135168264545447309116774875298152983766;

    
    uint256 constant IC0x = 3600665642995522703916460989552459939934901286329049197432414612963669283781;
    uint256 constant IC0y = 8090406248236314332727791399220675975130305720353772977730121090550570640068;
    
    uint256 constant IC1x = 10880418844970784044163812115784358495052963758014559403988553911198724448463;
    uint256 constant IC1y = 4826005724341358757702138607610496398473414452013611652558750402625198862673;
    
    uint256 constant IC2x = 13472425135564622003156236562120544841251622436508862702713652562759206333496;
    uint256 constant IC2y = 18593068197483988348313960462036654786963338671658977183496524702558612411185;
    
    uint256 constant IC3x = 4108733339810951780806915645742904149978072774697827413615308239763966703231;
    uint256 constant IC3y = 7488952737323927618896275960748799745991141299020162116883223218409861868406;
    
    uint256 constant IC4x = 16377135519618770209317367733498340706659935232883904932434603438580427016811;
    uint256 constant IC4y = 11737501518534385866655873581008771026440993014073108778749805368789341858976;
    
    uint256 constant IC5x = 19347278899934154761667955729275319293159466721562857272035158524973338969998;
    uint256 constant IC5y = 17321345061478845058051913268715168933648250272178082314138584707852040353469;
    
    uint256 constant IC6x = 507650188072588999085435322478088413585561104466164926122068095287508676770;
    uint256 constant IC6y = 20424860703603257756716199350547104912770273707109373411960649470791909327226;
    
    uint256 constant IC7x = 10361616767581934442946847483684661409784744374216658261068473566057036169332;
    uint256 constant IC7y = 14539565125751821247904400777638371428713636296429786898144066252781846366252;
    
    uint256 constant IC8x = 20249760534451305414109538580593270276831475318978855580317005372493296221424;
    uint256 constant IC8y = 17073017970086075071432779166199456427821825851581715090919575794562070753608;
    
    uint256 constant IC9x = 11072567195041549127279355523933599103400995131034690571681958809272898262437;
    uint256 constant IC9y = 6387182755972616163536204858134562548140330999777577509083515650722837160220;
    
    uint256 constant IC10x = 7272347801158438800789749936250383520969427941980327888153010116297015448781;
    uint256 constant IC10y = 3306365429834236034195036865274349498818868209392124463496232365495415461587;
    
    uint256 constant IC11x = 18306005284033760115178339955387752211997935951958499721222496668056956576233;
    uint256 constant IC11y = 21112810290709275855365302856923322677553852032195692263734968356714888473141;
    
    uint256 constant IC12x = 1212423111190940335267743241299003489849153010050203526369078643058497235889;
    uint256 constant IC12y = 12057519994101733637428152935120319256937766402209910326209153355884170208971;
    
    uint256 constant IC13x = 6732727645664145263622446992210779330775954053371118381414113842345253912586;
    uint256 constant IC13y = 9729356655888221469089258741836370076186405575410795326006563029979265409971;
    
    uint256 constant IC14x = 18435216448055490314613955322049202931506743669641819747608963906240553071961;
    uint256 constant IC14y = 10842953254618841601134576753955515156326383180543893935684519816114636920365;
    
    uint256 constant IC15x = 8927839247266250101145040230107283855275151323287887410240454993097829979371;
    uint256 constant IC15y = 9840147182337551352782138509261465433259112637024574235475447346051187186050;
    
    uint256 constant IC16x = 14277683174947959901352454740309380346389056960433573903651061019914340297789;
    uint256 constant IC16y = 4577629837316581331676187090407898321950427577125730895212294032729530751120;
    
    uint256 constant IC17x = 2790845419642555774117385420578215083625483430958173244204457758051592854069;
    uint256 constant IC17y = 15567524129344779239964969639930790130879181170812212025336925497404350144569;
    
    uint256 constant IC18x = 14552920732026432022811138747890035934742717232006465799365133027268912666033;
    uint256 constant IC18y = 4795244196999292470628838784759290899418173880750812598865545639586764690902;
    
    uint256 constant IC19x = 2494936376325886503592029137394343202383898492679714746058899176289156704607;
    uint256 constant IC19y = 342886302785887243985842827476351921438405073722178026122383708536260817009;
    
    uint256 constant IC20x = 11098705397650787655442699759205067283188192282628936352551929871609159716452;
    uint256 constant IC20y = 16467674468920032972296513457556200104793776153024866388829833388034008233938;
    
    uint256 constant IC21x = 2904678532605229143791241728670327166392395730489930577010366347605354477665;
    uint256 constant IC21y = 16938658686428830745190866020086257820551233077444329101526898161622079761665;
    
    uint256 constant IC22x = 13335845942902245884436139247009927530285176879147581313991869758060554373543;
    uint256 constant IC22y = 8891145318022801223478963265099174737985572235806406143598502923940406842467;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[22] calldata _pubSignals) public view returns (bool) {
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
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
