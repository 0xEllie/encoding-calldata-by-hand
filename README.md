# Sample ABI Encode By Hand Project

This project demonstrates how to calculate a smart contract ABI(application binary interface) encoding and run it through calldata against EVM(Ethereum virtual machine). It contains a sample contract called TestABIencode which is deployed on Sepolia (an Ethereum public Testnet) and a test for our hand made ABI with Hardhat.

The metamask, coinbase or any other node is responsible for encoding call message with the function parameters that one wants to call that specific function and execute it against the EVM. I think its necessary for a smart contract developer to be able to put the calldata together manually in order to be able to build more secure and gas optimized contracts and also find out others smart contract's vulnerabilities.

consider result1 function from TestABIencode contract deployed on Sepolia testnet

function result1(uint amount, bytes[] calldata codes, address to) public pure returns(uint , bytes[] calldata , address){
return(amount, codes, to);
}

Let's call result1 with this parameters and see whether the result is same with the generated calldata by a third party node, like Metamask, or not.

amount=333
codes=["abi","encoding","specification"]
to="0xf4552dc4633e77a9f4552dc4633e77a9f4552dc4"

based on official documents https://docs.soliditylang.org/en/latest/abi-spec.html

to encode calldata to result1 function first thing we need to do is determine function signature which is the function name followed by its parameter types in parentheses with no space between and with full type as using unit256 instead of unit.

function signature : result1(uint256,bytes[],address)
hash function signature :
9cfc1269622fefaed6133722baeaa14a70972ffce465983472ba1f24bae2c54e

second thing we need to derive the function selector from the function signature.
a function selector is first four byte of the kecceck256 hash of the function signature :

the website to calculate the hash:
https://emn178.github.io/online-tools/keccak_256.html

first four bytes is : 9cfc1269

now back to official abi encode site, encode for a parameter of type uint256 is :

- uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is 32 bytes

Therefore enc(333)= hex(333) with left-padded with zeros up to 32bytes:

000000000000000000000000000000000000000000000000000000000000014D

next parameter is an array of bytes, encode for T[] where X has k elements (k is assumed to be of type uint256):

- enc(X) = enc(k) enc((X[0], ..., X[k-1]))

here for codes=["abi","encoding","specification"], k is 3

enc(["abi","encoding","specification"]) = enc(3)enc(codes[0],codes[1],codes[2])
till now from the previous step we know enc(3) will be :
0000000000000000000000000000000000000000000000000000000000000003

enc((X[0], ..., X[k-1])) based on the document is same as encoding for struct type which is :

- x=(T1,...,Tk) for k >= 0 and any types T1, …, Tk

enc(X) = head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(k))

where X = (X(1), ..., X(k)) and head and tail are defined for Ti as follows:

if Ti is static:

head(X(i)) = enc(X(i)) and tail(X(i)) = "" (the empty string)

otherwise, i.e. if Ti is dynamic:

head(X(i)) = enc(len( head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(i-1)) )) tail(X(i)) = enc(X(i))

also about the dynamic and static types the document says :

- The following types are called “dynamic”:

bytes

string

T[] for any T

T[k] for any dynamic T and any k >= 0

(T1,...,Tk) if Ti is dynamic for some 1 <= i <= k

All other types are called “static”.

In our case, each element of array is of type bytes which is a dynamic type. So the encoding will be :

head(X(i)) = enc(len( head(X(1)) ... head(X(k)) tail(X(1)) ... tail(X(i-1)) ))
tail(X(i)) = enc(X(i))

We now calculate the whole encoding for the codes array:

remember these from above :
enc(["abi","encoding","specification"]) = enc(3)enc(codes[0],codes[1],codes[2])

we formed enc(3). now we know how to encode the rest :
enc(["abi","encoding","specification"]) = enc(3)head(codes[0])head(codes[1])head(codes[2])tail(codes[0])tail(codes[1])tail(codes[2])

as the array type is a dynamic :
head(codes[0]) = enc(len(head(codes[0])head(codes[1])head(codes[2])))
head(codes[0]) = enc(32+32+32)= enc(96)
0000000000000000000000000000000000000000000000000000000000000060

head("abi")=
0000000000000000000000000000000000000000000000000000000000000060

head(codes[1]) = enc(len(head(codes[0])head(codes[1])head(codes[2])tail(codes[0])))

--note that as byte is a dynamic type each tail will take two 32 bytes; one for length and the other for the actual enc of value--
so:
head(codes[1]) = enc(32+32+32+(32+32))=en(160)
00000000000000000000000000000000000000000000000000000000000000a0

head("encoding")=
00000000000000000000000000000000000000000000000000000000000000a0

head(codes[2]) = enc(len(head(codes[0])head(codes[1])head(codes[2])tail(codes[0])tail(codes[1])))
head(codes[2]) = enc(32+32+32+(32+32)+(32+32))=
00000000000000000000000000000000000000000000000000000000000000e0

head("specification")=
00000000000000000000000000000000000000000000000000000000000000e0

the tails are encoded as:
tail(codes[0]) = enc(codes[0]) = enc("abi")

from documents the enc(x) when x is of bytes type :

- bytes, of length k (which is assumed to be of type uint256):

enc(X) = enc(k) pad_right(X), i.e. the number of bytes is encoded as a uint256 followed by the actual value of X as a byte sequence, followed by the minimum number of zero-bytes such that len(enc(X)) is a multiple of 32.

on out case each tail needs two buckets of 32 bytes ; one for enc(k) and one for the element value encoding (as we had (32+32) for each tail in our calculations above)

in fist element of codes array bytes k=3 :
tail(codes[0]) = enc("abi") = enc(3) right-pad ASCII("abi")
enc(3)=
0000000000000000000000000000000000000000000000000000000000000003
right-pad ASCII("abi")=
6162690000000000000000000000000000000000000000000000000000000000

tail("abi")=
0000000000000000000000000000000000000000000000000000000000000003
6162690000000000000000000000000000000000000000000000000000000000

tail(codes[1]): k=8
enc("encoding") = enc(8) right-pad ASCII("encoding")  
enc(8)=
0000000000000000000000000000000000000000000000000000000000000008
right-pad ASCII("encoding")=
656E636F64696E67000000000000000000000000000000000000000000000000

tail("encoding")=
0000000000000000000000000000000000000000000000000000000000000008
656E636F64696E67000000000000000000000000000000000000000000000000

tail(codes[2]): k=13
enc("specification") = enc(13) right-pad ASCII("specification")
enc(13)=
000000000000000000000000000000000000000000000000000000000000000d

right-pad ASCII("specification")=
73706563696669636174696F6E00000000000000000000000000000000000000

tail("specification")=
000000000000000000000000000000000000000000000000000000000000000d
73706563696669636174696F6E00000000000000000000000000000000000000

now we get to forth parameter which a type address. from document we have :
address: as in the uint160 case

enc(to)=
000000000000000000000000f4552dc4633e77a9f4552dc4633e77a9f4552dc4

now that we have formed encoding of all the parameters, we need to put them to gether, but how ? the encoding specification says :

- a call to the function f with parameters a_1, ..., a_n is encoded as

function_selector(f) enc((a_1, ..., a_n))

and the return values v_1, ..., v_k of f are encoded as

enc((v_1, ..., v_k))

i.e. the values are combined into a tuple and encoded.

last but not least, as we calculated function selector before , only thing we should from is encoding of parameters which is treated like tuple or struct type(note that this step also can be done at the beginning of the calculations). we form all the parameters as a struct elements:

enc(amount,codes,to) = head(amount)head(codes)head(to)tail(amount)tail(codes)tail(to)

"amount" is uint256 ====> static
"codes" is bytes array ====> dynamic
"to" is like uint160 ====> static

to put it simply, for static type head wil be the enc of the parameter value and tail will be empty and for dynamic type head will point to the place where tail is going to be written therefore, tail will contain the enc of the parameter value

enc(amount,codes,to) = enc(amount)head(codes)head(to)tail(amount)tail(codes)tail(to)

head(codes)= enc(len(head(amount)head(codes)head(to)tail(amount)))=enc(32+32+32+"")=enc(96)=
0000000000000000000000000000000000000000000000000000000000000060

tail(codes) = enc (codes)

enc(amount,codes,to) = enc(333)enc(96)enc(to)""enc(codes)""
enc(amount,codes,to) = enc(333)enc(96)enc(to)enc(codes[0],codes[1],codes[2])=
enc(333)enc(96)enc(to)enc(["abi","encoding","specification"]) =

enc(333)enc(96)enc(to)enc(3)head("abi")head("encoding")head("specification")tail("abi")tail("encoding")tail("specification")

now that we have all the elements in previous steps, we just put them together as the last formula above.first four bytes will be the function selector followed by parameters enc we have calculated before :

the final calldata ABI:

9cfc1269
000000000000000000000000000000000000000000000000000000000000014D
0000000000000000000000000000000000000000000000000000000000000060
000000000000000000000000f4552dc4633e77a9f4552dc4633e77a9f4552dc4
0000000000000000000000000000000000000000000000000000000000000003
0000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000a0
00000000000000000000000000000000000000000000000000000000000000e0
0000000000000000000000000000000000000000000000000000000000000003
6162690000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000008
656E636F64696E67000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000d
73706563696669636174696F6E00000000000000000000000000000000000000

for result2 function :

function result2(Person calldata user, bytes[4] calldata codes, uint8 number) public pure returns(Person calldata , bytes[4] calldata , uint8 ){
return(user, codes, number);
}

struct Person{
string name;
bool isTrue;
uint[] balances;
}

input parameters : ((Elena,true,[23,45]),[0x77,0x89,0x34,0x67],199)

function signature : result2((string,bool,uint256[]),bytes[4],uint8)
kecceck256 hash of function signature : f60185ef07007e8f4ace63d8f6d670aff763238c92dbcb7540626f4d0c2c92f9  
 fist fore bytes: function selector = f60185ef

enc(((name,isTrue,balances),codes,number))=head(name,isTrue,balances)head(codes)head(number)tail(name,isTrue,balances)tail(codes)tail(number)

- head(name,isTrue,balances) = enc(len(head(name,isTrue,balances)head(codes)head(number)))=enc(len(32+32+32)) = enc(96)

- head(codes) = enc(len(head(name,isTrue,balances)head(codes)head(number)tail(name,isTrue,balances))) =enc(len(32+32+32+(32+32+32+32+32+32+(32+32))))=enc(352)

head(number)=enc(number)
tail(number)=""

- tail(name,isTrue,balances) = head(name)head(isTrue)head(balances)tail(name)tail(isTrue)tail(balances)=
  enc(96)enc(isTrue)enc(160)enc(len(name))enc(name)""enc(len(balances))enc(balances[0])enc(balances[1]) ===> length tail = 32+32+32+32+32+32+(32+32)

head(name)=enc(len(head(name)head(isTrue)head(balances)))=enc(len(32+32+32))= enc(96)
head(isTrue)=enc(isTrue)
head(balances) = enc(len(head(name)head(isTrue)head(balances)tail(name)tail(isTrue)))= enc(len(32+32+32+(32+32)+(0)))= enc(160)
tail(name)=enc(len(name))enc(name) ===> length tail= 32+32
tail(isTrue)=""

- tail(balances)=enc(len(balances)) head(balances[0])head(balances[1])tail(balances[0])tail(balances[1])
  head(balances[0]) = enc(balances[0]) ===> length tail= 32
  head(balances[1]) = enc(balances[1]) ===> length tail= 32
  tail(balances[0]) = ""
  tail(balances[1]) = ""

- tail(codes)=head(codes[0])head(codes[1])head(codes[2])head(codes[3])tail(codes[0])tail(codes[1])tail(codes[2])tail(codes[3])=enc(128)enc(192)enc(256)enc(320)enc(len(codes[0])) right-pad(codes[0])enc(len(codes[1])) right-pad(codes[1])enc(len(codes[2])) right-pad(codes[2])enc(len(codes[3])) right-pad(codes[3])

head(codes[0])= enc(len(head(codes[0])head(codes[1])head(codes[2])head(codes[3])))= enc(32+32+32+32)=enc(128)

head(codes[1])= enc(len(head(codes[0])head(codes[1])head(codes[2])head(codes[3])tail(codes[0])))= enc(32+32+32+32+(32+32))= enc(192)

head(codes[2])= enc(len(head(codes[0])head(codes[1])head(codes[2])head(codes[3])tail(codes[0])tail(codes[1])))= enc(32+32+32+32+(32+32)+(32+32)) = enc(256)

head(codes[3])= enc(len(head(codes[0])head(codes[1])head(codes[2])head(codes[3])tail(codes[0])tail(codes[1])tail(codes[2])))= enc(32+32+32+32+(32+32)+(32+32)+(32+32))= enc(320)

tail(codes[0])= enc(len(codes[0])) right-pad(codes[0]) ===> length tail= 32+32
tail(codes[1])= enc(len(codes[1])) right-pad(codes[1]) ===> length tail= 32+32
tail(codes[2])= enc(len(codes[2])) right-pad(codes[2]) ===> length tail= 32+32
tail(codes[3])= enc(len(codes[3])) right-pad(codes[3]) ===> length tail= 32+32

input parameters : ((Elena,true,[23,45]),[0x7780,0x89,0x34,0x66755555],199)

enc(((name,isTrue,balances),codes,number)) = head(name,isTrue,balances)head(codes)head(number)tail(name,isTrue,balances)tail(codes)tail(number) =
enc(96)enc(352)enc(number)enc(96)enc(isTrue)enc(160)enc(len(name))enc(name)""enc(len(balances))enc(balances[0])enc(balances[1])enc(128)enc(192)enc(256)enc(320)enc(len(codes[0]))right-pad(codes[0])enc(len(codes[1])) right-pad(codes[1])enc(len(codes[2])) right-pad(codes[2])enc(len(codes[3])) right-pad(codes[3])""

put together all the values in one hex string :

f60185ef
0000000000000000000000000000000000000000000000000000000000000060 enc(96)
0000000000000000000000000000000000000000000000000000000000000160 enc(320)
00000000000000000000000000000000000000000000000000000000000000c7 enc(number)=enc(199)
0000000000000000000000000000000000000000000000000000000000000060 enc(96)
0000000000000000000000000000000000000000000000000000000000000001 enc(isTrue)=enc(true)
00000000000000000000000000000000000000000000000000000000000000a0 enc(160)
000000000000000000000000000000000000000000000000000000000000000c enc(len(name))
3078343536433631364536310000000000000000000000000000000000000000 enc(name)=enc("Elena")
0000000000000000000000000000000000000000000000000000000000000002 enc(len(balances))=en(2)
0000000000000000000000000000000000000000000000000000000000000017 enc(balances[0])=enc(23)
000000000000000000000000000000000000000000000000000000000000002d enc(balances[1])=enc(45)
0000000000000000000000000000000000000000000000000000000000000080 enc(128)
00000000000000000000000000000000000000000000000000000000000000c0 enc(192)
0000000000000000000000000000000000000000000000000000000000000100 enc(256)
0000000000000000000000000000000000000000000000000000000000000140 enc(320)  
0000000000000000000000000000000000000000000000000000000000000002 enc(len(codes[0]))
7780000000000000000000000000000000000000000000000000000000000000 right-pad(0x7780)
0000000000000000000000000000000000000000000000000000000000000001 enc(len(codes[1]))
8900000000000000000000000000000000000000000000000000000000000000 right-pad(0x89)
0000000000000000000000000000000000000000000000000000000000000001 enc(len(codes[2]))
3400000000000000000000000000000000000000000000000000000000000000 right-pad(0x34)
0000000000000000000000000000000000000000000000000000000000000003 enc(len(codes[3]))
6675550000000000000000000000000000000000000000000000000000000000 right-pad(0x667555)

if you want to try it with metamask hex string below and see the result is the same with inputting actual data to the function deployed :
f60185ef
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000160
00000000000000000000000000000000000000000000000000000000000000c7
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000a0
000000000000000000000000000000000000000000000000000000000000000c
3078343536433631364536310000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000017
000000000000000000000000000000000000000000000000000000000000002d
0000000000000000000000000000000000000000000000000000000000000080
00000000000000000000000000000000000000000000000000000000000000c0
0000000000000000000000000000000000000000000000000000000000000100
0000000000000000000000000000000000000000000000000000000000000140  
0000000000000000000000000000000000000000000000000000000000000002
7780000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
8900000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
3400000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000004
6675555500000000000000000000000000000000000000000000000000000000
now we are Done!

output from remix:
0xf60185ef
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000160
00000000000000000000000000000000000000000000000000000000000000c7
0000000000000000000000000000000000000000000000000000000000000060
0000000000000000000000000000000000000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000a0
000000000000000000000000000000000000000000000000000000000000000c
3078343536433631364536310000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000017
000000000000000000000000000000000000000000000000000000000000002d
0000000000000000000000000000000000000000000000000000000000000080
00000000000000000000000000000000000000000000000000000000000000c0
0000000000000000000000000000000000000000000000000000000000000100
0000000000000000000000000000000000000000000000000000000000000140
0000000000000000000000000000000000000000000000000000000000000002
7780000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
8900000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000001
3400000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000004
6675555500000000000000000000000000000000000000000000000000000000

as you can see the results from remix and what we calculated by hand is the same!

TestABIencode.sol contract address on Sepolia: 0x6552C18B78A5d3A0481540FDa73752bD7F857E15

If you want to donate, I would appreciate every cent up to one Million dollar :)

my eth address : 0x2587646515BE64708CCc7bA0810Bdd4dce314A7c
