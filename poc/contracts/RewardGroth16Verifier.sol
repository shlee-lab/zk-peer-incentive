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
    uint256 constant deltax1 = 21088874285729572749667837875648961101931965158274338413210155067653826729661;
    uint256 constant deltax2 = 13555671933982986235006599619574811273964515186392075279604592129323383152402;
    uint256 constant deltay1 = 7928832327020240430741969813979924067414347882588342066079807045388316967789;
    uint256 constant deltay2 = 13178972204591873641706069277563849988700627517531871601573351283421485676476;


    uint256 constant IC0x = 12356355776175285948520820735221216937892507345188411207202339820231341470630;
    uint256 constant IC0y = 15598559525823633914402657699690660138914613872190368504524350616068252847069;

    uint256 constant IC1x = 6073725139676597380978858317676426847256427938496212775195275606352397793383;
    uint256 constant IC1y = 11970326241546884953192673772866170526560821730788249124456492016507921952180;

    uint256 constant IC2x = 721883399026160308461889950285265832147557770049088808256990589872578088556;
    uint256 constant IC2y = 6286675776675221673886940700908574779992707577760501070345874004754969853299;

    uint256 constant IC3x = 14994534413758763588716463028607009163849585072741570670158100792533123116487;
    uint256 constant IC3y = 10306147883443095211744181515837382259714590730118625749210931107455977053814;

    uint256 constant IC4x = 21718277461048199297141374658019099009589150877845944675137966330261415083529;
    uint256 constant IC4y = 14343513454794905228945961233048263896529602743088196972645588383692228527908;

    uint256 constant IC5x = 4597680815175185282500557921484650523179217769480818086251283607994833603714;
    uint256 constant IC5y = 9903865236408456886199526536333131227087479636545072626784764433658516440223;

    uint256 constant IC6x = 17004512130183441710362310992129150623434365500089675210285446364291280471307;
    uint256 constant IC6y = 17096261856485137643197187681800713393989944368701235321763943483915787646218;

    uint256 constant IC7x = 10794792478118301855140780108331200781921713061724605629867343492315700019949;
    uint256 constant IC7y = 19239231091036632471439908822307736873696488114154962554161997710732449770386;

    uint256 constant IC8x = 12749330650938002263192146350767134103790014253423250718349706103165978515683;
    uint256 constant IC8y = 1538334632970121099161319133094111309643066231321302028906409630279055179036;

    uint256 constant IC9x = 4177475688301227965543810012533481805470741122859507929795695425542293746952;
    uint256 constant IC9y = 9377235415090854060710179476955631555507828180350592311757975338139043341904;

    uint256 constant IC10x = 12455877149403978475350615426738695299572694802667091654932460955944807762030;
    uint256 constant IC10y = 11358726671579837723778996625585898715831008394964182005305941060356449682589;

    uint256 constant IC11x = 7504285874842433348799035029427854450005606978246818485054744068970994790664;
    uint256 constant IC11y = 4191061827740878960822908097964241792134863393062851618361021802292395547847;

    uint256 constant IC12x = 614453925324391511455622397492668674179260562901006501752941379257505801196;
    uint256 constant IC12y = 1647630328010179222639600196518155104330557788131617413523012701811321424892;

    uint256 constant IC13x = 6368433407435885177903626946640929334915472962426884040268786933844075605925;
    uint256 constant IC13y = 8684056080758295593323145843024033328061832904263575728341853151284021905233;

    uint256 constant IC14x = 8028535978153705082503732131655789868916670112608063545648799356332348203550;
    uint256 constant IC14y = 9363642950667996867438878805397701806711253753980123540449590990186378999287;

    uint256 constant IC15x = 20821411421683402700278964474289263076201384353591982688839922996719057724399;
    uint256 constant IC15y = 10437153479449446213568019888360603763126932067608172459483840213806920804684;

    uint256 constant IC16x = 7944691256760527121175326350450576745397441998809519864076711530158574630101;
    uint256 constant IC16y = 17621993754943995181421203415960520422158506075698473540157308736134006564745;

    uint256 constant IC17x = 18781301472060984276339425045194622783681086968417886080825482732484631167105;
    uint256 constant IC17y = 8474294327452165967979744573620288860499481322711372567336395961792878281498;

    uint256 constant IC18x = 14941193657080865138231234979011355257140033895347868170561498861447302649;
    uint256 constant IC18y = 8803043584189738593451499423434503889050466036715183839904280252188616760360;

    uint256 constant IC19x = 16241617175890687485125196014588474203228364680484673751387233309825697278037;
    uint256 constant IC19y = 9822542563523625947545204695981190084436316183934831292563462035884678341341;

    uint256 constant IC20x = 3303497450746592928578757706852427756977024818440194684294498569319801952678;
    uint256 constant IC20y = 12119801591465199422634501767668646873856060621860736926169670375395253491473;

    uint256 constant IC21x = 20908510897758807774430846982906567809946603157498040066777778052924764488957;
    uint256 constant IC21y = 11234383562065597860000771677774924106647512511534133695093943852890395237914;

    uint256 constant IC22x = 12131882941552529201885979014901627213057503973869760040399727047786052027289;
    uint256 constant IC22y = 7606496511645546058735671554074116722458215255768755053550908812927833839714;

    uint256 constant IC23x = 15914801994545322798048898920709384897978053343377669360959500213097935263611;
    uint256 constant IC23y = 12649938372706154458175477571263041493068449598838858498109124171855943584112;

    uint256 constant IC24x = 4325969516199334011236639879253931120692539924320273588070518613750122977758;
    uint256 constant IC24y = 2839987445015278585456162129840509769039655040242456746172321098120626088316;

    uint256 constant IC25x = 2480071953648650958876774577937173736051189817633146313895903806930154594611;
    uint256 constant IC25y = 8660745746872498452437894220245106373650923366261051577595800931283702837930;

    uint256 constant IC26x = 15709086305684380632969247181307516383851505357204691148349111388785889169999;
    uint256 constant IC26y = 15080626397154750629351528168804789722106483100729726473088820991834166278072;

    uint256 constant IC27x = 16393689078327315230530493236220602948537719726799494712325344004562019590714;
    uint256 constant IC27y = 21033806635783803538089565993545507918652167054323819587198537349011096141659;

    uint256 constant IC28x = 1283330122416149509832343505377969158064347289553603030249128976832672259649;
    uint256 constant IC28y = 21636211166900305149144887802872937359725551111237646858363792944560352988359;

    uint256 constant IC29x = 13538342565624099986988111034704864980843598911188355538288012699871663686953;
    uint256 constant IC29y = 13134425163487961287936420557229975612168704059282672797041644569750906476023;

    uint256 constant IC30x = 3662322419142084077369424546068747736130999728263329239180887618013839485027;
    uint256 constant IC30y = 14489607714115813420777025415227284317495043866233710715568677079269880637230;


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
