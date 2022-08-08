const {assert} = require('chai');
const MerkleTreeWithHistory = artifacts.require('MerkleTreeWithHistory');
const Hasher = artifacts.require('Hasher');

const MerkleTree = require('fixed-merkle-tree');

const {MERKLE_TREE_HEIGHT} = process.env

const bigInt = require("big-integer");

function toFixedHex (number, length = 32) {
    let str;
    str = bigInt(number);
    str = str.toString(16)

    while (str.length < length * 2) str = '0' + str
    str = '0x' + str
    return str
}

contract('MerkleTreeWithHistory', (accounts) => {
    let instance;
    let tree;
    let levels = MERKLE_TREE_HEIGHT || 20;
    let hasherInstance;
    before(async () => {
        hasherInstance = await Hasher.deployed();
        tree = new MerkleTree(levels);
        instance = await MerkleTreeWithHistory.deployed();
    })

    describe('deployment', async () => {
        it('should deploy successfully', async () => {
            const addr = await instance.address

            assert.notEqual(addr, "")
            assert.notEqual(addr, null)
            assert.notEqual(addr, undefined)
        })

        it('should initialize', async () => {
            const zeroValue = await instance.ZERO_VALUE()
            const firstSubtree = await instance.filledSubtrees(0)
            assert.equal(firstSubtree, toFixedHex(zeroValue))
            
            const firstZero = await instance.zeros(0)
            assert.equal(firstZero, toFixedHex(zeroValue))
          })
    })

    describe('insert', () => {
        it('should insert', async () => {
          let rootFromContract;
          for (let i = 1; i < 4; i++) {
            await instance.insert(toFixedHex(i));
            tree.insert(i)
            rootFromContract = await instance.getLastRoot()

            assert.equal(toFixedHex(tree.root()), rootFromContract.toString(), `failed at index ${i}`)
          }
        })
    
        it('should reject if tree is full', async () => {
          const levels = 3;
          const merkleTreeWithHistory = await MerkleTreeWithHistory.new(levels, hasherInstance.address)
    
          for (let i = 0; i < 2 ** levels; i++) {
            await merkleTreeWithHistory.insert(toFixedHex(i + 42))
          }
          try {
            await merkleTreeWithHistory.insert(toFixedHex(1337))
          } catch (error) {
            
          }
          
        })
    })
})