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
    uint256 constant deltax1 = 17504866000171501615188171616063031379960383215546383871699210666227190024505;
    uint256 constant deltax2 = 15399774273236858366055481364246418879037331197562189092141085917902317617506;
    uint256 constant deltay1 = 11655532566678910667307752417845833353276019541601168306283373549550545891739;
    uint256 constant deltay2 = 15715546254861006854003426891272687194526101382038305295244305874340133023040;


    uint256 constant IC0x = 4829686285625562463328942430005720803074904044850585199747515319761413118856;
    uint256 constant IC0y = 21141217654160322313398997303213854631305087443692805717080587247158210043775;

    uint256 constant IC1x = 1995414286613797556570101341867633646127737817089277269289063940194326283462;
    uint256 constant IC1y = 9295177740515087311733728305135616741778956828836052876728077565049048928851;

    uint256 constant IC2x = 17849557384684944650040640453270204530463423359454483006163339431191612665080;
    uint256 constant IC2y = 21230517644946883186188244643532832350571245924825358139544545021384814103244;

    uint256 constant IC3x = 14573884240482742845145681085621080499902232915136559343521784738277527419198;
    uint256 constant IC3y = 4461847277948911674638509605786734935293150372053182227994291942845131945255;

    uint256 constant IC4x = 18430354279144888269237233941766566858587119256437722611561743225039798728059;
    uint256 constant IC4y = 4259258971424923752548657364069827547299239163033989812742262792691743854266;

    uint256 constant IC5x = 1422668300033510557842279723383098006002732983177256097301424898111880952579;
    uint256 constant IC5y = 19274544331650360968281016313002509665943596267985660643754395450260389729658;

    uint256 constant IC6x = 257444972614072768922277040440998993631840974534577181076634665839705326770;
    uint256 constant IC6y = 1642027069244092006572225230035944081272480676599296765361993031134446273848;

    uint256 constant IC7x = 634231015830148370086996437884357072070328643841418972314868742281359359998;
    uint256 constant IC7y = 10796640388328762268828525716193757165479092062153991286431474807845577884531;

    uint256 constant IC8x = 7915625821094028310388202174407022564405758195284162698937989495715086035846;
    uint256 constant IC8y = 8186729619047957827401805516404903374985820871495438661093459286601946512178;

    uint256 constant IC9x = 16990483252792293616034266361524739140230829266644523814904236573351400914292;
    uint256 constant IC9y = 2028003770368727035829479617788477490325386139060949618861137830616293757265;

    uint256 constant IC10x = 4949475056112342578924766995646973328903837140136418601396646089730781184069;
    uint256 constant IC10y = 12512266476071566082366201423903670214227691066818395448640325348366658305351;

    uint256 constant IC11x = 3387697932638446241952340856201547174958534584544066035141061613719336103063;
    uint256 constant IC11y = 6793599238527472293425471599282388283431764731615104738161658055943754383947;

    uint256 constant IC12x = 16399573733186560404420017856383678476476758397165917948660490829235193252228;
    uint256 constant IC12y = 3334255422249671331086536361166333238744665254316216172632589889091725731393;

    uint256 constant IC13x = 14243349478672107305379255868995936595128919655478542020072127824415468047398;
    uint256 constant IC13y = 6544455356281467590967740365569198233071183465702615411930857637797127426852;

    uint256 constant IC14x = 6456967358802395979752334112150109368542209225194478853665005624021718709857;
    uint256 constant IC14y = 12941607557733764859751255782323969094435375222943726092646474078820179933791;

    uint256 constant IC15x = 1533305833062306523846215033410946165305569431934530676664929134430741454650;
    uint256 constant IC15y = 13794928783822606504838196795253955311623689167676081921837772260947976327194;

    uint256 constant IC16x = 20683184587147711824706052095226726497071592157583814708876505632711852639478;
    uint256 constant IC16y = 3491704134665680787885974997477827433922508699282107078908588617257254541742;

    uint256 constant IC17x = 6595716416956444631849698819015587995317930061954979322808323523329423047096;
    uint256 constant IC17y = 12150255482718124203876123856100859518457696666260240392957389276377731833731;

    uint256 constant IC18x = 1323526558488551371819586365970350275588204272096744041330078527933340027903;
    uint256 constant IC18y = 15023147436450103868622648156005101734337761963716167158918826867789491667250;

    uint256 constant IC19x = 14167565665096235649419873508898648616317641766865387193210926458816982570245;
    uint256 constant IC19y = 12577355983197021826843588065014122152264944410914151221425747732031399253486;

    uint256 constant IC20x = 14616587667857733678829552876551491276999804066404828222001758017977849727549;
    uint256 constant IC20y = 1427405789402439242327461978196581585226668948639692417945040664769483177374;

    uint256 constant IC21x = 11373886988166960267040805138064252619258585372748698553323414305171201749593;
    uint256 constant IC21y = 6567168510193754214356662059277418913301906872821300176462499584017151509315;

    uint256 constant IC22x = 20064337782125094018716382424250370581483507602234560177013713506214507871150;
    uint256 constant IC22y = 9305642293827343891285304494408219062925767168526205981856874096927501912714;

    uint256 constant IC23x = 8837109712155452561451436086219677592624868342841296152888195953239404256656;
    uint256 constant IC23y = 20308666279538487946061784130397205697937610628521027691913618536901963578122;

    uint256 constant IC24x = 16456815292667982633243103086872770699498880504195104930413409638818919372701;
    uint256 constant IC24y = 5558634394388074149853666031715446020334000268123708986050079663595297903225;

    uint256 constant IC25x = 5101877216536687641091261533537500438474890300753614872568572603257189667969;
    uint256 constant IC25y = 3474495826147326783812180224696323757977991532685834537644095410497250385299;

    uint256 constant IC26x = 3886454655184837578592104842052825917398304920580524900624076546572102974589;
    uint256 constant IC26y = 16954792245253335339172498013879271958735505866688825432368477208884941626492;

    uint256 constant IC27x = 21790690221859590616297439365040572488671397117285937069787361218781499470551;
    uint256 constant IC27y = 8614315958872673437890292396495178034589163669557060639752679137869172167932;

    uint256 constant IC28x = 11369582069820922610090315362076474441456311761857730035270284085041472105;
    uint256 constant IC28y = 10718197568582541156057465924572901876284466725586829561023463896226569527171;

    uint256 constant IC29x = 18059873651715230075588869384210812540460752814048732064071696061132477873755;
    uint256 constant IC29y = 6562367318676689383439450862968802870996975556602264099808541169098344955253;

    uint256 constant IC30x = 7401510980595504820765930805042055862182288819941978980311643467470761653400;
    uint256 constant IC30y = 17956590857366713670730906768042140573639171445631589639914540396853005706429;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[30] calldata _pubSignals) public view returns (bool) {
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


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
