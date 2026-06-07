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
    uint256 constant alphax  = 7073457169401219749883133852335060166110170551839084204053152249387860166940;
    uint256 constant alphay  = 10194639892983557596880240115619414483004284172694327343932692595245234790665;
    uint256 constant betax1  = 7600398268375942048085962272519997131118633558800412093284227136542684977766;
    uint256 constant betax2  = 9702855085032845228850225869323436744197841388748365970354721476494705182193;
    uint256 constant betay1  = 3620571941388343205918627981785468915601028783219545361432928102382440245114;
    uint256 constant betay2  = 4658853448781331683320274985264285773226995313090239242228182383433873662457;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 15343178516946557212037470663300620839400505805036355044322749260631207568899;
    uint256 constant deltax2 = 11706930578692698420869130954030173256967688645489684597031271457529065651075;
    uint256 constant deltay1 = 6606288293749438442920914743140455045598093559497090547352847004993241802937;
    uint256 constant deltay2 = 7326071583486317213325495173682764915395012051947087844979194335000478114242;

    
    uint256 constant IC0x = 20583117274879629284759219352465761127433396340546595561809550606273302347811;
    uint256 constant IC0y = 5254690450366069491773437901536482719092566314897369136702221971537833618878;
    
    uint256 constant IC1x = 8285831146143822395666941838330800888213022007868650673379814608175005877988;
    uint256 constant IC1y = 13481951256177203957879981688015960935244538259060646888200295703464189215416;
    
    uint256 constant IC2x = 21860779994004660985627167728609504909595897559366147521524202583851077802368;
    uint256 constant IC2y = 12049472872951880192942766325045039342259486757087451985538925753433786822663;
    
    uint256 constant IC3x = 387811874203572186280389235477736205416961871207457292672951965274023063444;
    uint256 constant IC3y = 1403224305630396870133912165240532878597819855240887064140260551871390008391;
    
    uint256 constant IC4x = 11239205044661404267560374448092597996378278327258620143502369573091033394556;
    uint256 constant IC4y = 6050685185732961350384108626089616230691330564397298810308536425926889551200;
    
    uint256 constant IC5x = 3622247322392219928089562949870940395783660424691812668168457118731140089830;
    uint256 constant IC5y = 14406180323720174522294288495717200740138902791899959839137295116024461083135;
    
    uint256 constant IC6x = 14641438095805860750969181089945081132499545172890431139322090989562743321931;
    uint256 constant IC6y = 4323413217693359274932404625872713116293003533931630943880288771003297734362;
    
    uint256 constant IC7x = 14277266621438055273531303442800255140227293375833144246099923538190384562685;
    uint256 constant IC7y = 9980256874811072058353472814453495826743847029650351526171318825850217794661;
    
    uint256 constant IC8x = 2119231363641543974500162843231394318664848471028831803040097691001117648232;
    uint256 constant IC8y = 13003196684226689768932691257744020120933430026514649955462910475350256406042;
    
    uint256 constant IC9x = 11592042585047526544378406781051380592989878353447086278348644175260627469816;
    uint256 constant IC9y = 4428970700776975472602919330507302105111112456792881987019821416808827156290;
    
    uint256 constant IC10x = 14066557315718666818609429008420088458537504284522416601176368702208574490384;
    uint256 constant IC10y = 21864079879455517010424862210860186796823068971721278779027745105264052522891;
    
    uint256 constant IC11x = 9292375467402821629019744875358443572234885595002238507458310331809130687744;
    uint256 constant IC11y = 12470909777592246075616490610990656499427585773588345530696147240532969810187;
    
    uint256 constant IC12x = 2579282629938431634436579233945540727539849709994983973443794483956299039490;
    uint256 constant IC12y = 2046956998477960561451811678855651679807266283419983008915873795308419750244;
    
    uint256 constant IC13x = 20766844800091608497990114013194726020085419947406967058801702040252501276648;
    uint256 constant IC13y = 12137676085127836782890551662566762479558078534168335468107782297127542995640;
    
    uint256 constant IC14x = 17990629223870901015241042767765500562887766256145219304969180817761708361252;
    uint256 constant IC14y = 7063100386260936672373450538867500320458167221748175626472652549436324092781;
    
    uint256 constant IC15x = 11788785992020779243157580703140486061834949374234192060088407263030415027825;
    uint256 constant IC15y = 1910342168339960972912686140649570522564499097619069476915777571416178686734;
    
    uint256 constant IC16x = 6986802924916843397649154227234986140545181641596959722987433852524272371234;
    uint256 constant IC16y = 9540161162532383027504255142735023968229973804592192080090451955566770229207;
    
    uint256 constant IC17x = 14047005844514113066410560270888786995183158310814872023355510204719928955745;
    uint256 constant IC17y = 1180280361649251583295965584615823867189421868471359549183922289544605352733;
    
    uint256 constant IC18x = 10214164887750525400153934430536774055473909312166898962695021073493041030765;
    uint256 constant IC18y = 11830850509131436355101049373665199073546340502907949706548599387856373490843;
    
    uint256 constant IC19x = 18456394268914855657432216872564884462990517294353326898787693783859181420851;
    uint256 constant IC19y = 8305205255631294643286970319444949883433719745878279522224680149879524236460;
    
    uint256 constant IC20x = 21488253960605245286038816232813146347821413102520842703937536087387145234881;
    uint256 constant IC20y = 4950087201831945125175384089220743876916575989247294153512969009824243005788;
    
    uint256 constant IC21x = 20093068924463692608306352697098871647956465809673211167148245771025332503337;
    uint256 constant IC21y = 15672383761508368233403457220786244498985760165848773602623272482350533341431;
    
    uint256 constant IC22x = 20812447298636683666140002158750905824156148773839417217388063311525893390708;
    uint256 constant IC22y = 10206287872747746644881671721218601029887160402249399721004214991943986643023;
    
 
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
