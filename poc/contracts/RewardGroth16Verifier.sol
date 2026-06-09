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
    uint256 constant deltax1 = 18038234496364331017067011989696272505101603342311756997675841342552688329402;
    uint256 constant deltax2 = 11603823783684911305383639976723088687528585889241975414561746029844194881474;
    uint256 constant deltay1 = 13154157571761249622059883823277880313053889177725503004741700429674913341644;
    uint256 constant deltay2 = 12367159991274261361473862755185852652980572183732796171924781372557589608194;


    uint256 constant IC0x = 11234865318073616480833667929194210187305399868606480710051159676370649588004;
    uint256 constant IC0y = 12105311926961697374294217062263165807762915237029312204437918570079231539579;

    uint256 constant IC1x = 13598136395213349612492429853645327882741914579939074924764873307504113047234;
    uint256 constant IC1y = 21352854608867708038709353326506862495199789472581595458173131434632628493887;

    uint256 constant IC2x = 13099853262724120122702589729087353989889760564493129677249053013842775615195;
    uint256 constant IC2y = 2112778863388758853531945816067667020768517966700867527997961420046068107479;

    uint256 constant IC3x = 10145717903703013159920222313441012056025540340707339392236834421732420868512;
    uint256 constant IC3y = 10122669678793286193917829229163477855528149386422573298365055446246989832779;

    uint256 constant IC4x = 21147563843693153423204128870778200219343681849927614549214893899704915405695;
    uint256 constant IC4y = 6355573807285068193378025799193390051106187465887215352689655652516435491509;

    uint256 constant IC5x = 4277411186834866974410671794571004039164808979712947940943459984052693268811;
    uint256 constant IC5y = 21121486577346579662910823564735641675853961129077469478024299470475008013003;

    uint256 constant IC6x = 16716442270713859977697253392401928020714083575031230842441027898528003274398;
    uint256 constant IC6y = 5281372645879746983615888014842383683027872699497036291953566253369459863853;

    uint256 constant IC7x = 10352036215155350137492222647446301246759826887786027404193979368943620532754;
    uint256 constant IC7y = 15789161182368670470716698055419602942970555813818402064506328121335124259134;

    uint256 constant IC8x = 4968055001928210292192863766847506002909617968219880281611095585883958260834;
    uint256 constant IC8y = 4093160334796346590903139899654860913381359634586466204801619378924113460258;

    uint256 constant IC9x = 5978499253485541313554895474777997506389259183026707902413145120619367135108;
    uint256 constant IC9y = 16288957840124577225407718429733239822810609507117855058213062037283852367334;

    uint256 constant IC10x = 1646300394216567757552084097666298516452432351888863422453136973505942913798;
    uint256 constant IC10y = 1478474682084607506028113958073761242613031064812624463802429726419091930039;

    uint256 constant IC11x = 10563349398417443057725528564675930696757205894691673236385161526509923547636;
    uint256 constant IC11y = 5283115478482172157951065088599595473804301505989210279554822519476286246874;

    uint256 constant IC12x = 17103708457189175457017770314435961083158633550720290213026402729784491741214;
    uint256 constant IC12y = 17586982185581483342755533471265164050360664548310909461109347410752278303631;

    uint256 constant IC13x = 11937952741647566334619874890004487908793617057280940530104710788156811747376;
    uint256 constant IC13y = 3945183150791916955228812603332278507189174483459569019899316691118055623235;

    uint256 constant IC14x = 16968314654065056792492765567210377728340726641451593759854334189198265878270;
    uint256 constant IC14y = 19803525963958972627145137877628029571721227640589704063328194167445462796993;

    uint256 constant IC15x = 11212701549857384850846982476553024103606817828829950432821593923875990222214;
    uint256 constant IC15y = 17451248167800863605958560099622738761475662193551100208456416123640894803185;

    uint256 constant IC16x = 1221956082273400054523437830692174813456782174026114811962469751385915885484;
    uint256 constant IC16y = 14051476042572685571930777344836632336638159959157050086832053150686050115779;

    uint256 constant IC17x = 11452901732769218719261047423778689749495096298350278881503430555055236249652;
    uint256 constant IC17y = 12147006032564121888555744647661775396864650126978146280588908132230608442622;

    uint256 constant IC18x = 12416974881560417221817187129936992571776982621230736726660304002155786892585;
    uint256 constant IC18y = 2856904142203084189214024787305820237772208251626681417758849784718964124620;

    uint256 constant IC19x = 1153899442573063427524666044453333399085221956485159445223402554085926712522;
    uint256 constant IC19y = 18445080237957284084507228349035163371411287184017066798427049980682964584607;

    uint256 constant IC20x = 7568400930180695650888015953654568291693076485188533793618850331070735043897;
    uint256 constant IC20y = 6793881361263869938399194174626134433576748662982058164315132000048344588770;

    uint256 constant IC21x = 13878400834085327667335280481123734182475646948934161703646104529314493779022;
    uint256 constant IC21y = 11345438710824474248451123158657350041409588806707205059654617811781511768512;

    uint256 constant IC22x = 10620354963147361620417801998458899535648134885147273324984172540273932501235;
    uint256 constant IC22y = 19243994264011731163011958248352938348841783837676431111126613126789383886624;

    uint256 constant IC23x = 9940410486805089395874430925792420990195836371486862998534980107547744562599;
    uint256 constant IC23y = 9460524206753334887042710746070475871876695176124444704137271085839130173451;

    uint256 constant IC24x = 7195266624098484861381642461083168961436901243024678686203098759377097543798;
    uint256 constant IC24y = 18142515524836599781324049604120498021479660062680960235266824330342363790886;

    uint256 constant IC25x = 9907155395368074059583230637404816503824218772398586150484388299230741549046;
    uint256 constant IC25y = 5082512801506219746946267365948298079503795614170046740226825822730346165805;

    uint256 constant IC26x = 18365177006402320415037991945697884441298757774073187028371724056043630903523;
    uint256 constant IC26y = 20999351694443793625169016310970380703720749623855446878931801438462223877512;

    uint256 constant IC27x = 13192053852523309290645674455860960943911672512074045829347655813166551220689;
    uint256 constant IC27y = 17298264445943410255676606322853360539727119876179517585098516914795582405819;

    uint256 constant IC28x = 20286084355749298750128166250367032101592869800919509083805122683701313719211;
    uint256 constant IC28y = 21504586624852176467983760016863041829255465189939565277231650566668339959701;

    uint256 constant IC29x = 8602307073785685476462061662775869452055168677436008230835012894554847226401;
    uint256 constant IC29y = 8910222194960197529652164210686911929007181108789359245081997571623981833336;

    uint256 constant IC30x = 18661100668888540502580997933381269047071947407867406276138134596240897103806;
    uint256 constant IC30y = 3699399801926357170336753301371337153864478141600184758539363153828757771194;

    uint256 constant IC31x = 2076664690694064642645478306191569555603441865226180522850564105564285499837;
    uint256 constant IC31y = 6513743980611817286226012560008970451315416457513020355235450092279603351504;


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
