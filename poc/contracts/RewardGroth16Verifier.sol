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
    uint256 constant deltax1 = 13609745086577288245894560752359507508787098962914073705302983966471102245080;
    uint256 constant deltax2 = 21474645016875107814274369114555728275173775510804582408154246698272743099459;
    uint256 constant deltay1 = 18809039749978567580850308761188807173158548191936556995541551409117825476022;
    uint256 constant deltay2 = 902381863192230629772240696090997799297562123116204089478182289797116823860;


    uint256 constant IC0x = 1891837086900887255064870420799075045807995154232074575590504714543848753126;
    uint256 constant IC0y = 9035679375266514365745239517546206576261516015335770002419195674737930992459;

    uint256 constant IC1x = 21045343067047284837667543999446396366705502992323941804854199809732604929864;
    uint256 constant IC1y = 224982542987874033921734241640159664310012978294975746021787443785132317362;

    uint256 constant IC2x = 20427640075755432799832176177191798108303374093415862752943748637878408821384;
    uint256 constant IC2y = 20866084756193263730752564654760065570918603393488167044539321113085692870694;

    uint256 constant IC3x = 6883887420904400630435005857224825940725533905935209581304710244056960701743;
    uint256 constant IC3y = 1716853528746732371507129517807012479139004694804373613173337490529794261517;

    uint256 constant IC4x = 11979100251536258708119447244923702015861455969416632111227336483515789993996;
    uint256 constant IC4y = 7032481842476815343391794233387380501593215095221914510945198281571759541513;

    uint256 constant IC5x = 14523011997708954573392700846467137119246548468402086765814437273368345783718;
    uint256 constant IC5y = 14722866080286767945056133528715727952775521668851346936337083320264513265378;

    uint256 constant IC6x = 6647800909845671798614144579190271315877253131432907058798094865170154921140;
    uint256 constant IC6y = 13747184157370353942510055966652559238926373015032560517733052362621031898852;

    uint256 constant IC7x = 7307168754069288654014249436846074929600695780486882989439903099086833317261;
    uint256 constant IC7y = 4822235925874817483720481869579691405153651789372163987100482411140457631885;

    uint256 constant IC8x = 21480006866831094169456331215348787095033006410742201737844324152906372220223;
    uint256 constant IC8y = 9706081363588563893447760576575516756263655818756560243236228786128697397503;

    uint256 constant IC9x = 20775111408183268483644742977482004110959803829854121432019154460467458265414;
    uint256 constant IC9y = 11092980727398408609571065398916014747954352829295093152119117538759346208899;

    uint256 constant IC10x = 19372384927800132603884717833605767742248693889636537001322072166928871624986;
    uint256 constant IC10y = 3650515060539481328733116193316076298812752431095589487985080249515765975382;

    uint256 constant IC11x = 6920708276146546702521087771775003938248042253677459006727343334385523138043;
    uint256 constant IC11y = 1936117553833057377030725505328312111025657507169445361683217996898435045006;

    uint256 constant IC12x = 7352436223396376322096774600918904928889846993262459815825039860944210864401;
    uint256 constant IC12y = 17473589794852632470922891378837697023491661310380204729003662648481213077202;

    uint256 constant IC13x = 12869552992302803582573444785898444965351494474467093464196890925707731248909;
    uint256 constant IC13y = 5584264902065589480149863605693512703861347292606781098764689060323182914737;

    uint256 constant IC14x = 5475109821097050076029427809832122210375812924301803135435469894753194405151;
    uint256 constant IC14y = 2588821528668445146015855015381806878341061568090244319127231111083503296222;

    uint256 constant IC15x = 246527426612274899230640555168408892001027612123127627817169670467946756022;
    uint256 constant IC15y = 534879503610478506423848011993888534052586660584305794065843842616164134158;

    uint256 constant IC16x = 4524187286338567227413595494816863738104409324029033136125433012531176716492;
    uint256 constant IC16y = 8331323098133942321401634594237726342618591427485343485340789958117968067104;

    uint256 constant IC17x = 3633117094974887339196910723059105207683568761713874567006680971899658978331;
    uint256 constant IC17y = 18401782139075429976955990587101911904762284437227881065668927976609270073085;

    uint256 constant IC18x = 10342482103296490092787461198818806138970078036553367343078115436320027004844;
    uint256 constant IC18y = 4675192359989539486500701606953049466140115613466006459382505414513509943629;

    uint256 constant IC19x = 9205836512290862042577431623731123584909807966932462467066600228433203929243;
    uint256 constant IC19y = 18469621736682430223589088000079730830998211532244957350045463579413802443893;

    uint256 constant IC20x = 14491613951791429701416894272943414670692661328324837660519761376497152471158;
    uint256 constant IC20y = 714801099753815855237497980746810614136707706120724010163225348403610482184;

    uint256 constant IC21x = 17950569522224974632536197786648084405724011070324845203408919236640462824084;
    uint256 constant IC21y = 14825830635164768870030180953945502662145907330312227633827823524670624216456;

    uint256 constant IC22x = 17998482055840272421600063830703668438523788844584453615369424933151488402903;
    uint256 constant IC22y = 8594806081313366579026930536669143046936024489178710211163976126902120002878;

    uint256 constant IC23x = 14243000427185181698213374492613069868921107000089352352693220432074640842598;
    uint256 constant IC23y = 8515397399041899790814429761349823834730183870488802438262518856223122365020;

    uint256 constant IC24x = 21499154609229693826585289884803184259014081152878083140497549263010039867579;
    uint256 constant IC24y = 21188560808891679259252610611418344393343003765804797216973121128324800746508;

    uint256 constant IC25x = 12025355008260245592962004865331359432689638756967926308186853703160235080462;
    uint256 constant IC25y = 12402366521841697645433476230995621627830928841362883944338171037829596748797;

    uint256 constant IC26x = 19127774731402906310338796470803108598581865553199882998383384186821305514746;
    uint256 constant IC26y = 14737948635072327030918841729932747887350936875079989557753949422118142988597;

    uint256 constant IC27x = 7901467713712431358032439603514410933109908652238475916601224625119160272266;
    uint256 constant IC27y = 17906822079893763113569070938444594782169485852208970669089505928255540602524;

    uint256 constant IC28x = 5474434588806152650273672181685901370490674468391687741060169189447097247658;
    uint256 constant IC28y = 21130147451206287460772281430510121770808536376252085875520084700760418523543;

    uint256 constant IC29x = 5518378863330761336026600814770857413440210470039531395727835194300602484882;
    uint256 constant IC29y = 1477741048525703411979944012052824581128232194193982335253308133924241183295;

    uint256 constant IC30x = 9718516477794331576663701014800387126459113476722104199962379186630639669100;
    uint256 constant IC30y = 9819720597941966734231454976667763882355296514477803516651726530030367424320;

    uint256 constant IC31x = 9037784643852851670076602502205467703382855169220304986412874339026908104148;
    uint256 constant IC31y = 670962594850545367946614597451985472136557397057053450126942096623657455104;

    uint256 constant IC32x = 6690576458654419364168154044188325669526181509549016191245794606264041945364;
    uint256 constant IC32y = 5325831340637065918405099951697561232088871228618727692980541454096019007930;

    uint256 constant IC33x = 18896057070476421740934087064088390990111113978427110359864049809650987585325;
    uint256 constant IC33y = 8541834399916438836945126118695427681179629259498239455963670224447996077690;

    uint256 constant IC34x = 5812900529382496866483378704706278497836796759462737319267106898516177021303;
    uint256 constant IC34y = 4232697285094758860714134341830568190305512445653395254986364661839251254788;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[34] calldata _pubSignals) public view returns (bool) {
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

                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))


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

            checkField(calldataload(add(_pubSignals, 1056)))


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
