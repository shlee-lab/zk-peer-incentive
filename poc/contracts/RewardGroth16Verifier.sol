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
    uint256 constant deltax1 = 18579247661132965692246818017309678502589473869505238360690745180445198969165;
    uint256 constant deltax2 = 2641103769060992391888909256724059048231412635195685960150379839534681923627;
    uint256 constant deltay1 = 8725166979908599471110247696392765820796723527046904266728128374221356267765;
    uint256 constant deltay2 = 15046983437801400722157261009318419227182075079386454789537722549507645483651;

    
    uint256 constant IC0x = 9995669608000453844073778976212775214352401780337578355540775417315534947764;
    uint256 constant IC0y = 14866103001812682686118409905856630764424011264814400524437301355527154394812;
    
    uint256 constant IC1x = 3106422164999992576597078716193733260004327759963061888980275804656116065788;
    uint256 constant IC1y = 13417478967305484658684822994534647938830576052145351905361611469219698155304;
    
    uint256 constant IC2x = 7053676095983121427475422975133035484895009152079786027663323068228593126715;
    uint256 constant IC2y = 9976036212424186851272499765352427937593411184568586523865270444036572791344;
    
    uint256 constant IC3x = 10130697757948054801473551775511976612033070394195206039290979985500585616675;
    uint256 constant IC3y = 5447024685252853856510270847585085123546098388159694869870563892894115514716;
    
    uint256 constant IC4x = 3126476979816607744080753235182151760533815873546358544536219167946130694689;
    uint256 constant IC4y = 2192125101231112269977243968416265469712334756402498738787619533579250093817;
    
    uint256 constant IC5x = 11513700467117179823668673795054988151082602713151299076121884120099048620451;
    uint256 constant IC5y = 17853941808654462688422128594352519054082973593832466282814269979407180148753;
    
    uint256 constant IC6x = 16131171587781073190082535283459979744477352481412299786809569269668509917632;
    uint256 constant IC6y = 2117537756202049176890326721648648750021697592548951713037779132087912919592;
    
    uint256 constant IC7x = 12804225392491605874279511878045515661380554272218526348974437433747301965640;
    uint256 constant IC7y = 17141084260312549210355093002774474759178723400592605368066036032556988027275;
    
    uint256 constant IC8x = 10795235317434992112758500465663106873555432785549605942999876855836120574670;
    uint256 constant IC8y = 16971234381486459114741016146931379568539326621770351017783231225064745702838;
    
    uint256 constant IC9x = 13782485726551006190387453798487622859292366011335770474793999593999780795557;
    uint256 constant IC9y = 15433349315799306900507428919233396795369417632825062877080714822972363172204;
    
    uint256 constant IC10x = 18026141617095229764694961480534308190271596132976979983658732424237177066938;
    uint256 constant IC10y = 21753349637766173449398754975651888311584343968879864839493484947622195012042;
    
    uint256 constant IC11x = 9635533245326581120909419563269760532627462613866211159681812879366983213783;
    uint256 constant IC11y = 14391268656614690308664749734370222163380286126045522083706534356540872335626;
    
    uint256 constant IC12x = 4217998363751470836902612217411597256233960844211225549083780299928179328324;
    uint256 constant IC12y = 9569237952839362217566327229736906340358150052771325692672023773167486388781;
    
    uint256 constant IC13x = 17085323367018012155050532470499905485591383911827696887690373046783359745051;
    uint256 constant IC13y = 9293896842212704182085011989908190646061937404793060068362736211069634081457;
    
    uint256 constant IC14x = 17940426336267219128263960829329733204155441698438198135984179335927567194123;
    uint256 constant IC14y = 13660251346731436602947249657263073547724758842419905277759899900291429433328;
    
    uint256 constant IC15x = 11120977448676193916537675789736883023411319729314551643355444066210045300463;
    uint256 constant IC15y = 6747583115325499984232911865081252213289165096548942947396504714815509740019;
    
    uint256 constant IC16x = 5467275493642671324998009227851190296380528609407970114103197801355498011703;
    uint256 constant IC16y = 8956146475836288247461041341155395320761564469365064989968542691588539007273;
    
    uint256 constant IC17x = 14364468707449942811913814090418263826233560874997490192149192172061788446668;
    uint256 constant IC17y = 14906887062332997778711941595430184616201844979067154658897106394074955025982;
    
    uint256 constant IC18x = 2807201892907368495985317715298983824935842051373455261654316409317417649603;
    uint256 constant IC18y = 9383276723028051243498963294744505462877786413274089822767786021727087181337;
    
    uint256 constant IC19x = 9106210193914644870296437140410091804034798030928995989494845739311237169402;
    uint256 constant IC19y = 5873958292060760781748661418214193448633108028729989108329689613925627963016;
    
    uint256 constant IC20x = 14627020292216117849592760691453282772033109088702464985281112590828023602158;
    uint256 constant IC20y = 6722090347760453119119710439708550117773603262893838558655087394482424958103;
    
    uint256 constant IC21x = 15606878530869920546447309555876880187508262918798055412204417786113845221056;
    uint256 constant IC21y = 6094101433440248239519408897164412203176183202678663780734545212803574508874;
    
    uint256 constant IC22x = 10450098367675706680102339388578707657262818903645717794132732379371492710462;
    uint256 constant IC22y = 4675759511494267298392076370447337631958249052316230424227120005434963476617;
    
 
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
