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
    uint256 constant deltax1 = 10911307878965373606961508769703303935681783244502446586720554999206083689405;
    uint256 constant deltax2 = 17150397488323938111737788511850074939205773845899529526081180803200612006048;
    uint256 constant deltay1 = 4391815069527582511729958226823527931136093151275948772239544123619986411622;
    uint256 constant deltay2 = 5299137587408417330213412681416668588496860291652750747588268315183672070464;


    uint256 constant IC0x = 6292044914468724997257116353897110254735648261133999540292278959746314545472;
    uint256 constant IC0y = 17269289132300321296999040941101121478208746886076548050302958750918391962185;

    uint256 constant IC1x = 16870859384582156298068532953860507863422473250575441407357458547020502750905;
    uint256 constant IC1y = 6052311261617788670032466652310956266148912000370503538902868759718828131465;

    uint256 constant IC2x = 16997980745749768564568396577717327086591452636936125760893728930993986285225;
    uint256 constant IC2y = 11714021510205617037474506220291623804795827292458857305477265275933657651233;

    uint256 constant IC3x = 13974612759829345242043141769569764227472782840916133224478460993466974915273;
    uint256 constant IC3y = 753683364526894125711108846243410375357815867117418594428644870456039952655;

    uint256 constant IC4x = 5624515965079970209587321030489841602050399300399803894962963979677053392172;
    uint256 constant IC4y = 19119629852675100322599082523782004091299795528163264372333641909068067415873;

    uint256 constant IC5x = 14352898751333461099308474404740389568057290192592238894068724358832336746841;
    uint256 constant IC5y = 9750618597103877289108992516691888090442999025063572151752666589511953985460;

    uint256 constant IC6x = 13405106473614732593081628347725582870461660167033827606682438838441043286996;
    uint256 constant IC6y = 15603599629047853458807873990541375253974447903361973638854319776605749826839;

    uint256 constant IC7x = 1365701481973951374505088439280903077476262682616327657958378089276650706106;
    uint256 constant IC7y = 2702626921991693580042413652481654797147321844252679131519957878317809186182;

    uint256 constant IC8x = 18771391207794181947403691500885855464010755089560297002731122127151808779442;
    uint256 constant IC8y = 20220118775805577191726003170709123690402009570758807850056815712653076667501;

    uint256 constant IC9x = 6790455162390952736467160988500840680706634604812111502964818553559462137407;
    uint256 constant IC9y = 16313941290552781859356064850841445183174283571845514528171149090541713977242;

    uint256 constant IC10x = 12956770028278740021271057903876925859575507548420644327442768289034235842556;
    uint256 constant IC10y = 13067908745980681422297461635335717669763736952809437735541974414081217825020;

    uint256 constant IC11x = 19365528597855688241866148568820888368629886450483180958891855146580247090332;
    uint256 constant IC11y = 18755141141793733897048985143881583370493135086485001033768149369498759916361;

    uint256 constant IC12x = 14098771620681411897230931045090551629623355790219382554584430299723298441491;
    uint256 constant IC12y = 14284818211410358331756341848743462893077454193070906680894807943218910600346;

    uint256 constant IC13x = 9044157359370071425375951123595348867795089248319596557877051209060181978671;
    uint256 constant IC13y = 10029308326764328007808294953858448364866934515466031886929058799386860922447;

    uint256 constant IC14x = 20612830225467209600008844410699393450700185980228577628587469517301832301261;
    uint256 constant IC14y = 2527326916313111930174852053351378584279169323520229445975391878489924186014;

    uint256 constant IC15x = 4358475526176363861441635125503423126292788130799714402837125862761258862460;
    uint256 constant IC15y = 13770471888960358476392165107854177314772340125523274952687978470442516378676;

    uint256 constant IC16x = 1530269115518151929994496639611502638069125728606162624797278370845311999033;
    uint256 constant IC16y = 4259628332703959090478470471191855338767581204879708853360546678805430698546;

    uint256 constant IC17x = 14955242852867366030607655267631500588188014613735189278715778580963840733882;
    uint256 constant IC17y = 14506741050407880683101072303390885677522449734984405857747579536327516000111;

    uint256 constant IC18x = 15865423438904255839949814724991324966845539152202292572817642307340670657671;
    uint256 constant IC18y = 1957379658001780129635150280619337665657217762149858309041014219469748150460;

    uint256 constant IC19x = 15102575471286101698853324052134488981428694144982674230794305492436188161670;
    uint256 constant IC19y = 10756993193797439699594075760171429179549286503676113358354749718100089220316;

    uint256 constant IC20x = 3541935300415975814180987988737990110978052960279359013385118320949581400634;
    uint256 constant IC20y = 13645512577128860232353326979903234951231416943076651753725024551703875934186;

    uint256 constant IC21x = 7072473404972852469860273353037457795819978681747774604700627852675349636;
    uint256 constant IC21y = 10259476831531594337710283068588874267816236243312591562973851703433983879870;

    uint256 constant IC22x = 1421471675014946863840566837127330158707436742706912732414654933353660712255;
    uint256 constant IC22y = 4252604538753782068539650857747936625373445175223166917262096481553546815993;

    uint256 constant IC23x = 3148974740010484373969541825241950584258970965594873603536801372881733626961;
    uint256 constant IC23y = 7607536468116819273512898103142450619177307191145065874449808451745321754775;

    uint256 constant IC24x = 10214917011792524802881053725536496350148145248832671855034785174436011578596;
    uint256 constant IC24y = 3158876553281468309129663053147917240496507814161373034362662436569355621012;

    uint256 constant IC25x = 7264391949975695747641117665906644988052506468438031819411977500959340743556;
    uint256 constant IC25y = 10581856144838960111269977855340018718857960417920583282009553937775166033018;

    uint256 constant IC26x = 9350004514952499181068176880818382075006144620376852726052534119186495818774;
    uint256 constant IC26y = 20226853287892137997152526942938670720384110920113351004949159944826392656072;

    uint256 constant IC27x = 13853086829084715613807020597370224053759291326021872379124188766354163824700;
    uint256 constant IC27y = 12317829738004253830781544201086170373700125668924510612037902037874956262312;

    uint256 constant IC28x = 5815739701461034932404124247281944208574622975818434267844023906064111256941;
    uint256 constant IC28y = 9621583496556282686461080990376334476711374420206123527090523873955079079719;

    uint256 constant IC29x = 1068328564901486404719620745583201812952672626138858581119996489346618243185;
    uint256 constant IC29y = 18083188235451798780802631898494143171250332476851463846331003977149933402914;

    uint256 constant IC30x = 21623344836820506175542367828569433283123191058888210744738919676390913193024;
    uint256 constant IC30y = 20141010260361874058123985349880303656256114638868053373191035532882230912149;

    uint256 constant IC31x = 8108061892958148407701711277733267414395568595582993170222786146776403157540;
    uint256 constant IC31y = 4737906176218499954367184958061512810840900751838702438305106128489903431535;


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
